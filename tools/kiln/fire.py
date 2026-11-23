"""The Kiln: fires one third-party model into our N64 look.

Run by Blender's command line, which Godot starts (KilnJob.command()):

    blender -b --factory-startup --python tools/kiln/fire.py -- <job.json>

The job file (written by KilnJob) says which model files to read and how to
fire them. The first source is the model; any others only lend their look
(the eyebrows painted onto the player's head). Steps:

1. Read the sources (glTF), in their rest pose.
2. Keep only the parts moved by [keep_bones], if given (a head off a body).
3. Crunch the copy that becomes the fired model: weld, merge nearly flat
   faces into big flats ("planar"), then collapse it to the triangle budget,
   keeping skin weights so a rig still bends it. Open edges are protected so
   parts that meet (a head and a collar) still meet.
4. Unwrap it afresh and work out a texture size that gives [pixels_per_metre]
   at the size it's drawn in the game.
5. Bake the original's colour onto it at 4x that size, and soft crease
   shading (ambient occlusion), then shrink it by averaging each 4x4 block:
   crisp, chunky pixels.
6. Export the fired model (.glb, without materials: Godot draws it with our
   own shader and the .png) plus the texture and a .kiln.json of what was
   made, and .import files that keep Godot from compressing the pixels.

Everything written goes beside [out] in the gitignored assets/third_party/.
"""
import json
import math
import os
import sys
import time

import bmesh
import bpy
import numpy
from mathutils import Vector

SUPERSAMPLE = 4
# The texture's sides stay between these, in pixels.
SMALLEST = 8


def main() -> None:
    job_path = sys.argv[sys.argv.index("--") + 1]
    with open(job_path, encoding="utf-8") as handle:
        job = json.load(handle)
    started = time.time()
    report = fire(job)
    report["seconds"] = round(time.time() - started, 2)
    report["fingerprint"] = job["fingerprint"]
    with open(job["out"] + ".kiln.json", "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=1)
    print("KILN DONE", json.dumps(report))


def fire(job: dict) -> dict:
    bpy.ops.wm.read_homefile(use_empty=True)
    scene = bpy.context.scene
    sources = []
    for index, path in enumerate(job["sources"]):
        before = set(bpy.data.objects)
        bpy.ops.import_scene.gltf(filepath=path, bone_heuristic="BLENDER")
        added = [obj for obj in bpy.data.objects if obj not in before]
        tint = job["tints"][index] if index < len(job.get("tints", [])) else None
        sources.append({"objects": added, "tint": tint})

    armature = next((obj for obj in sources[0]["objects"] if obj.type == "ARMATURE"), None)
    for source in sources:
        for obj in source["objects"]:
            if obj.type == "ARMATURE":
                obj.data.pose_position = "REST"
    drop = set(job.get("drop_meshes", []))
    meshes = []
    for index, source in enumerate(sources):
        for obj in source["objects"]:
            if obj.type != "MESH" or obj.name in drop:
                continue
            # A rigged model's loose, unrigged meshes are leftovers (the base
            # characters carry an icosphere).
            if armature is not None and not _is_skinned(obj):
                continue
            if source["tint"] is not None:
                _tint(obj, source["tint"])
            meshes.append((index, obj))
    if not meshes:
        raise SystemExit("KILN ERROR: no meshes in " + job["sources"][0])

    keep_bones = set(job.get("keep_bones", []))
    if keep_bones:
        for index, obj in meshes:
            if index == 0:
                _keep_only(obj, keep_bones)
    source_triangles = sum(_triangles(obj) for index, obj in meshes if index == 0)

    # The originals stay as they are, separate, to bake from: joining them
    # would fill colours missing from some parts (vertex colours) with black.
    high = [obj for index, obj in meshes]
    # The low copy: the model's own meshes joined, to crunch.
    low_parts = []
    for index, obj in meshes:
        if index == 0:
            part = obj.copy()
            part.data = obj.data.copy()
            scene.collection.objects.link(part)
            low_parts.append(part)
    low = _join(low_parts, "KilnLow")

    scale = _game_scale(job, high)
    bones_before = _moved_by(low)
    _crunch(low, job, scale)
    # Bones whose part was crunched away: they'd have nothing left to move.
    bones_lost = sorted(bones_before - _moved_by(low))
    _unwrap(low)
    size, achieved = _texture_size(low, job, scale)
    pixels = _bake(low, high, size, job, scale)
    _save_png(pixels, size, job["out_png"])
    for obj in high:
        bpy.data.objects.remove(obj)
    _strip_materials(low)
    if armature is not None:
        armature.data.pose_position = "POSE"
    _export(low, armature, job["out"])
    _write_imports(job)
    return {
        "source_triangles": source_triangles,
        "triangles": _triangles(low),
        "texture": size,
        "pixels_per_metre": round(achieved, 1),
        "game_scale": round(scale, 4),
        "rigged": armature is not None,
        "bones_lost": bones_lost,
    }


def _is_skinned(obj) -> bool:
    return any(mod.type == "ARMATURE" for mod in obj.modifiers) or obj.parent_type == "ARMATURE"


def _triangles(obj) -> int:
    return sum(len(poly.vertices) - 2 for poly in obj.data.polygons)


def _join(parts: list, name: str):
    bpy.ops.object.select_all(action="DESELECT")
    for part in parts:
        part.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    if len(parts) > 1:
        bpy.ops.object.join()
    joined = bpy.context.view_layer.objects.active
    joined.name = name
    return joined


# Multiplies every colour [obj]'s materials give by [tint] (the hair's grey
# texture is made for tinting).
def _tint(obj, tint: list) -> None:
    for slot in obj.material_slots:
        if slot.material is None or slot.material.node_tree is None:
            continue
        material = slot.material.copy()
        slot.material = material
        tree = material.node_tree
        for bsdf in [n for n in tree.nodes if n.type == "BSDF_PRINCIPLED"]:
            socket = bsdf.inputs["Base Color"]
            multiply = tree.nodes.new("ShaderNodeMix")
            multiply.data_type = "RGBA"
            multiply.blend_type = "MULTIPLY"
            multiply.inputs["Factor"].default_value = 1.0
            # Godot's colours are sRGB; Blender's shading is in linear light.
            colour = (_linear(tint[0]), _linear(tint[1]), _linear(tint[2]), 1.0)
            if socket.is_linked:
                tree.links.new(socket.links[0].from_socket, multiply.inputs["A"])
            else:
                multiply.inputs["A"].default_value = socket.default_value
            multiply.inputs["B"].default_value = colour
            tree.links.new(multiply.outputs["Result"], socket)


def _linear(srgb: float) -> float:
    if srgb <= 0.04045:
        return srgb / 12.92
    return ((srgb + 0.055) / 1.055) ** 2.4


# Deletes every face with a corner whose strongest bone isn't one of [keep]:
# the same rule as CharacterModel.cut_out.
def _keep_only(obj, keep: set) -> None:
    names = {group.index: group.name for group in obj.vertex_groups}
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    deform = mesh.verts.layers.deform.active
    doomed = []
    for vert in mesh.verts:
        weights = vert[deform] if deform is not None else {}
        strongest = max(weights.items(), key=lambda item: item[1])[0] if weights else -1
        if names.get(strongest, "") not in keep:
            doomed.append(vert)
    bmesh.ops.delete(mesh, geom=doomed, context="VERTS")
    mesh.to_mesh(obj.data)
    mesh.free()


# How much bigger (or smaller) the model is drawn in the game than it is in
# its file: the node's own scale, times fitting it into its box.
def _game_scale(job: dict, obj) -> float:
    scale = float(job.get("scale", 1.0))
    fit = job.get("fit_size", [0.0, 0.0, 0.0])
    if any(fit):
        dims = _dimensions(obj)
        # Godot's x, y, z are Blender's x, z, y.
        size = (dims.x, dims.z, dims.y)
        factors = [fit[axis] / size[axis] for axis in range(3) if size[axis] > 0.0]
        if factors:
            if job.get("stretch", False):
                scale *= math.prod(factors) ** (1.0 / len(factors))
            else:
                scale *= min(factors)
    return scale


def _dimensions(objs) -> Vector:
    """The size of the box round [objs] (one object or a list), in the world."""
    if not isinstance(objs, list):
        objs = [objs]
    corners = [obj.matrix_world @ Vector(corner) for obj in objs for corner in obj.bound_box]
    low = Vector((min(c.x for c in corners), min(c.y for c in corners), min(c.z for c in corners)))
    high = Vector((max(c.x for c in corners), max(c.y for c in corners), max(c.z for c in corners)))
    return high - low


def _moved_by(obj) -> set:
    """The names of the bones that are the strongest at some point of [obj]."""
    names = {group.index: group.name for group in obj.vertex_groups}
    found = set()
    for vert in obj.data.vertices:
        if vert.groups:
            found.add(names[max(vert.groups, key=lambda group: group.weight).group])
    return found


def _joints(mesh) -> set:
    """The indices of [mesh]'s points that sit where one bone's part meets
    another's: their strongest bone differs from a neighbour's. Empty if it
    isn't rigged."""
    deform = mesh.verts.layers.deform.active
    if deform is None:
        return set()
    strongest = {}
    for vert in mesh.verts:
        weights = vert[deform]
        strongest[vert.index] = max(weights.items(), key=lambda item: item[1])[0] \
                if weights else -1
    joints = set()
    for edge in mesh.edges:
        a, b = edge.verts
        if strongest[a.index] != strongest[b.index]:
            joints.add(a.index)
            joints.add(b.index)
    return joints


def _crunch(obj, job: dict, scale: float) -> None:
    diagonal = _dimensions(obj).length
    mesh = bmesh.new()
    mesh.from_mesh(obj.data)
    # Weld the seams the original's UVs split, so the crunch sees one surface.
    bmesh.ops.remove_doubles(mesh, verts=mesh.verts, dist=diagonal * 0.0005)
    flatten = math.radians(float(job.get("flatten_degrees", 0.0)))
    if flatten > 0.0:
        # On a rig, faces only merge within one bone's part: a point where
        # the strongest bone changes (a joint) is never merged away, or a
        # bone would be left with nothing to move (the crab's legs folded).
        joints = _joints(mesh)
        verts = [vert for vert in mesh.verts if vert.index not in joints]
        edges = [edge for edge in mesh.edges
                if not any(vert.index in joints for vert in edge.verts)]
        bmesh.ops.dissolve_limit(mesh, angle_limit=flatten, verts=verts, edges=edges,
                delimit=set())
    bmesh.ops.triangulate(mesh, faces=mesh.faces)
    # Open edges (a neckline, a collar) are kept where they are.
    boundary = {vert.index for edge in mesh.edges if edge.is_boundary for vert in edge.verts}
    mesh.to_mesh(obj.data)
    mesh.free()

    budget = int(job["triangles"])
    current = _triangles(obj)
    if budget <= 0 or current <= budget:
        return
    protect = float(job.get("protect_edges", 1.0))
    if protect > 0.0:
        # Weight 0 is kept: the crunch adds cost to collapsing those.
        keep = obj.vertex_groups.new(name="KilnKeep")
        keep.add([index for index in range(len(obj.data.vertices)) if index not in boundary],
                1.0, "REPLACE")
        if boundary:
            keep.add(list(boundary), 0.0, "REPLACE")
    bpy.context.view_layer.objects.active = obj
    for attempt in range(4):
        decimate = obj.modifiers.new("KilnCrunch", "DECIMATE")
        decimate.decimate_type = "COLLAPSE"
        decimate.ratio = max(budget / max(current, 1), 0.001)
        decimate.use_collapse_triangulate = True
        decimate.use_symmetry = bool(job.get("symmetric", False))
        decimate.symmetry_axis = "X"
        if protect > 0.0:
            decimate.vertex_group = "KilnKeep"
            decimate.vertex_group_factor = protect
        bpy.ops.object.modifier_move_to_index(modifier=decimate.name, index=0)
        bpy.ops.object.modifier_apply(modifier=decimate.name)
        current = _triangles(obj)
        if current <= budget * 1.1:
            break
    # Applying the modifier rebuilds the groups, so find it again by name.
    leftover = obj.vertex_groups.get("KilnKeep")
    if leftover is not None:
        obj.vertex_groups.remove(leftover)


def _unwrap(obj) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    while obj.data.uv_layers:
        obj.data.uv_layers.remove(obj.data.uv_layers[0])
    obj.data.uv_layers.new(name="Kiln")
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60.0), island_margin=0.0,
            area_weight=0.0, correct_aspect=True, scale_to_bounds=False)
    bpy.ops.uv.pack_islands(rotate=True, margin=0.01)
    bpy.ops.object.mode_set(mode="OBJECT")


# The texture side, in pixels, for [pixels_per_metre] at the game's size, and
# the density it actually gives.
def _texture_size(obj, job: dict, scale: float) -> tuple:
    mesh = obj.data
    # Areas are in the object's own units: count its own scale too.
    own = obj.matrix_world.to_scale()
    own_area = abs(own.x * own.y * own.z) ** (2.0 / 3.0)
    surface = sum(poly.area for poly in mesh.polygons) * own_area * scale * scale
    uv = mesh.uv_layers.active.data
    covered = 0.0
    for poly in mesh.polygons:
        corners = [uv[loop].uv for loop in poly.loop_indices]
        for k in range(1, len(corners) - 1):
            a, b, c = corners[0], corners[k], corners[k + 1]
            covered += abs((b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y)) / 2.0
    wanted = float(job["pixels_per_metre"])
    exact = wanted * math.sqrt(surface / max(covered, 1e-9))
    biggest = int(job["max_texture"])
    # Any multiple of 8 (not only powers of two), so every model lands close
    # to the same density: the same size of pixel everywhere.
    size = int(min(max(round(exact / SMALLEST) * SMALLEST, SMALLEST), biggest))
    achieved = size * math.sqrt(covered / max(surface, 1e-9))
    return size, achieved


def _bake(low, high, size: int, job: dict, scale: float):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    if scene.world is None:
        scene.world = bpy.data.worlds.new("KilnWorld")
    diagonal = _dimensions(high).length
    scene.world.light_settings.distance = diagonal * 0.15
    big = size * SUPERSAMPLE
    colour = _bake_pass(low, high, big, "DIFFUSE", diagonal)
    creases = float(job.get("creases", 0.0))
    if creases > 0.0:
        shade = _bake_pass(low, high, big, "AO", diagonal)
        colour[..., :3] *= (1.0 - creases) + creases * shade[..., :1]
    # Average each block down to one pixel.
    blocks = colour.reshape(size, SUPERSAMPLE, size, SUPERSAMPLE, 4).mean(axis=(1, 3))
    grain = float(job.get("grain", 0.0))
    if grain > 0.0:
        # A chunky speck per pixel, lighter or darker, the same every firing:
        # flat-coloured packs get the small busy texture N64 surfaces had.
        seed = sum(ord(letter) for letter in job["out"]) % (2 ** 32)
        specks = numpy.random.default_rng(seed).random((size, size, 1)).astype(numpy.float32)
        blocks[..., :3] *= 1.0 + (specks - 0.5) * 2.0 * grain
    blocks[..., 3] = 1.0
    return blocks


def _bake_pass(low, high, big: int, kind: str, diagonal: float):
    image = bpy.data.images.new("KilnBake_" + kind, big, big, alpha=False, float_buffer=True)
    material = bpy.data.materials.new("KilnBake")
    material.use_nodes = True
    node = material.node_tree.nodes.new("ShaderNodeTexImage")
    node.image = image
    material.node_tree.nodes.active = node
    low.data.materials.clear()
    low.data.materials.append(material)
    bpy.ops.object.select_all(action="DESELECT")
    for part in high:
        part.select_set(True)
    low.select_set(True)
    bpy.context.view_layer.objects.active = low
    bake = bpy.context.scene.render.bake
    bake.margin = SUPERSAMPLE * 3
    bake.margin_type = "EXTEND"
    options = {
        "type": kind,
        "use_selected_to_active": True,
        "cage_extrusion": diagonal * 0.02,
        "max_ray_distance": diagonal * 0.05,
        "use_clear": True,
        "margin": SUPERSAMPLE * 3,
    }
    if kind == "DIFFUSE":
        options["pass_filter"] = {"COLOR"}
    bpy.ops.object.bake(**options)
    pixels = numpy.empty(big * big * 4, dtype=numpy.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(big, big, 4)


def _save_png(pixels, size: int, path: str) -> None:
    image = bpy.data.images.new("KilnTexture", size, size, alpha=False)
    # The bake is in linear light; the PNG is sRGB, as Godot reads colour.
    linear = numpy.clip(pixels, 0.0, 1.0)
    rgb = linear[..., :3]
    srgb = numpy.where(rgb <= 0.0031308, rgb * 12.92, 1.055 * numpy.power(rgb, 1.0 / 2.4) - 0.055)
    out = numpy.concatenate([srgb, linear[..., 3:]], axis=-1)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(out.astype(numpy.float32).ravel())
    image.filepath_raw = path
    image.file_format = "PNG"
    os.makedirs(os.path.dirname(path), exist_ok=True)
    image.save()


def _strip_materials(obj) -> None:
    obj.data.materials.clear()


def _export(low, armature, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    low.select_set(True)
    if armature is not None:
        armature.select_set(True)
        low.parent = armature
    bpy.context.view_layer.objects.active = low
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
            export_materials="NONE", export_animations=armature is not None,
            export_skins=True, export_yup=True, export_apply=False)


# Import settings Godot uses when it first sees the files: the texture kept
# exactly (no compression, no mipmaps, which would blur the pixels), and the
# model without Godot's own simplified copies (it's already as simple as we
# want it).
def _write_imports(job: dict) -> None:
    with open(job["out_png"] + ".import", "w", encoding="utf-8") as handle:
        handle.write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                "[params]\n\ncompress/mode=0\nmipmaps/generate=false\n"
                "detect_3d/compress_to=0\n")
    with open(job["out"] + ".import", "w", encoding="utf-8") as handle:
        handle.write('[remap]\n\nimporter="scene"\ntype="PackedScene"\n\n'
                "[params]\n\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\n")


if __name__ == "__main__":
    main()
