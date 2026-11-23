"""Fits a Meshy clothing piece onto a rigged Meshy character as a layer (#168).

A piece (a shirt, trousers, boots) is made in Meshy on its own, so it comes
out about a metre across, centred on nothing, with no bones. This puts it on
the character's body:

1. scales it to its slot's band of the body (the shirt from the belt to the
   collar, trousers from the belt to inside the boots, boots from the floor
   to mid-calf) and centres it there; each boot goes onto its own foot;
2. pushes any part that sinks into the body back outside it, by a hair;
3. copies the body's skin weights onto it, so each bit follows the body
   part under it;
4. binds it to the character's armature and saves the piece and the
   armature (not the body) as a glTF.

A piece whose sleeves stick out further than the character's arms (Meshy
draws the arms in a steep A-pose; clothes on their own come out with arms
wider) is bound with the arms raised to meet the sleeves: that pose becomes
the piece's own rest pose. Godot keeps a rest pose per skinned mesh, so it
still follows the same skeleton's animations.

Run with Blender 4.4 from Git Bash:

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b \\
        -P tools/meshy/fit_layer.py -- BODY.glb PIECE.glb OUT.glb SLOT

SLOT is top, legs, feet, coat or boots (see SLOTS). A coat is a top that
reaches the thighs and sits outside the trousers; boots are feet that reach
below the knee, slimmed to the leg. Heights are in metres for a 1.6 m
character, measured off the outfit's concept picture; they scale with the
body's height.
"""

import math
import sys

import bpy
from mathutils import Vector

# Each slot: the band of the body it covers (bottom and top, metres on a
# 1.6 m body), how far in from the middle counts as the trunk (to measure
# the body without the arms), and how far to raise the arms (degrees).
SLOTS = {
    "top": {"band": (0.91, 1.34), "trunk": 0.16, "raise": 0.0},
    "legs": {"band": (0.33, 0.97), "trunk": 0.3, "raise": 0.0},
    "feet": {"band": (0.0, 0.385), "trunk": 0.3, "raise": 0.0},
    # "raise" below zero lowers the arms. "trim_top" cuts that share off the
    # top of the piece first (a coat's peg). "gap" holds it further off the
    # body than GAP, to clear the clothes under it.
    "coat": {"band": (0.72, 1.41), "trunk": 0.16, "raise": 0.0, "gap": 0.03},
    # A coat made hanging from a peg, sleeves straight down: the peg is cut
    # off and the arms lowered into the sleeves. It fits poorly (the sleeves
    # are fused to the coat's body); make coats on the body, as "coat".
    "hung_coat": {"band": (0.7, 1.4), "trunk": 0.16, "raise": -38.0, "trim_top": 0.1, "gap": 0.03},
    # "slim" narrows each boot about its own middle after it's sized by
    # height, so a chunky pair hugs a thin leg.
    "boots": {"band": (0.0, 0.41), "trunk": 0.3, "raise": 0.0, "pair": True, "slim": 0.74},
}
## The gap left between body and cloth, in metres: wider than the body's
## outline (at most 8 mm), or the outline shows through the cloth.
GAP = 0.012
BODY_HEIGHT = 1.6

args = sys.argv[sys.argv.index("--") + 1:]
body_path, piece_path, out_path, slot = args[0], args[1], args[2], args[3]
settings = SLOTS[slot]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=body_path)
armature = next(ob for ob in bpy.context.scene.objects if ob.type == "ARMATURE")
body = max((ob for ob in bpy.context.scene.objects if ob.type == "MESH"),
           key=lambda ob: len(ob.vertex_groups))
extras = [ob for ob in bpy.context.scene.objects if ob.type == "MESH" and ob != body]


def world_points(ob):
    return [ob.matrix_world @ v.co for v in ob.data.vertices]


def select_only(ob):
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob


def bone_head(name):
    return armature.matrix_world @ armature.pose.bones[name].head


# Raise (or lower) the arms to meet the sleeves, checking each way turns the
# arm the way that's wanted.
lowering = settings["raise"] < 0.0
if settings["raise"] != 0.0:
    select_only(armature)
    bpy.ops.object.mode_set(mode="POSE")
    for side in ("Left", "Right"):
        bone = armature.pose.bones[side + "Arm"]
        bone.rotation_mode = "XYZ"
        # Try turning about each of the bone's cross axes, both ways, and
        # keep whichever lifts the elbow highest: that's raising it sideways.
        best = None
        for axis in (0, 2):
            for sign in (1.0, -1.0):
                bone.rotation_euler = (0.0, 0.0, 0.0)
                bone.rotation_euler[axis] = sign * math.radians(abs(settings["raise"]))
                bpy.context.view_layer.update()
                lift = bone_head(side + "ForeArm").z
                if lowering:
                    lift = -lift
                if best is None or lift > best[0]:
                    best = (lift, axis, sign)
        bone.rotation_euler = (0.0, 0.0, 0.0)
        bone.rotation_euler[best[1]] = best[2] * math.radians(abs(settings["raise"]))
        bpy.context.view_layer.update()
    bpy.ops.object.mode_set(mode="OBJECT")

# The body as it now stands, as a plain mesh in world space.
depsgraph = bpy.context.evaluated_depsgraph_get()
posed_mesh = bpy.data.meshes.new_from_object(body.evaluated_get(depsgraph))
posed = bpy.data.objects.new("PosedBody", posed_mesh)
bpy.context.scene.collection.objects.link(posed)
posed.matrix_world = body.matrix_world.copy()
select_only(posed)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
for group in body.vertex_groups:
    if group.name not in posed.vertex_groups:
        posed.vertex_groups.new(name=group.name)

body_top = max(p.z for p in world_points(posed))
scale_to_body = body_top / BODY_HEIGHT
low, high = (h * scale_to_body for h in settings["band"])

bpy.ops.import_scene.gltf(filepath=piece_path)
piece = next(ob for ob in bpy.context.selected_objects if ob.type == "MESH")
piece.name = "Outfit_" + slot
piece.parent = None
select_only(piece)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
if settings.get("trim_top", 0.0) > 0.0:
    import bmesh
    heights = [v.co.z for v in piece.data.vertices]
    cut = max(heights) - (max(heights) - min(heights)) * settings["trim_top"]
    trimmed = bmesh.new()
    trimmed.from_mesh(piece.data)
    bmesh.ops.delete(trimmed, geom=[v for v in trimmed.verts if v.co.z > cut], context="VERTS")
    trimmed.to_mesh(piece.data)
    trimmed.free()


def bounds(points):
    lo = Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points)))
    hi = Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points)))
    return lo, hi


def region(points, z_low, z_high, x_test):
    return [p for p in points if z_low <= p.z <= z_high and x_test(p.x)]


def fit(ob, target_points, height):
    """Scales [ob] evenly to [height], deepens it to the body's depth if it's
    thinner, and centres it on [target_points] with its bottom at [low]."""
    lo, hi = bounds(world_points(ob))
    size = hi - lo
    factor = height / size.z
    t_lo, t_hi = bounds(target_points)
    depth = max(1.0, (t_hi.y - t_lo.y) * 1.08 / (size.y * factor))
    for v in ob.data.vertices:
        p = ob.matrix_world @ v.co
        centred = p - Vector(((lo.x + hi.x) / 2.0, (lo.y + hi.y) / 2.0, lo.z))
        v.co = Vector((centred.x * factor, centred.y * factor * depth, centred.z * factor))
    ob.matrix_world.identity()
    centre = (t_lo + t_hi) / 2.0
    ob.location = Vector((centre.x, centre.y, low))
    select_only(ob)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)


def widen_to_body(ob, target_points, z_mid):
    """Scales [ob] across (x and y, about its middle) so its cross-section
    halfway up its band is at least a little wider and deeper than the
    body's there: the cloth then sits outside the body from the start."""
    near = 0.04
    cloth = [p for p in world_points(ob) if abs(p.z - z_mid) < near]
    flesh = [p for p in target_points if abs(p.z - z_mid) < near]
    if not cloth or not flesh:
        return
    c_lo, c_hi = bounds(cloth)
    f_lo, f_hi = bounds(flesh)
    grow_x = max(1.0, (f_hi.x - f_lo.x) * 1.05 / (c_hi.x - c_lo.x))
    grow_y = max(1.0, (f_hi.y - f_lo.y) * 1.08 / (c_hi.y - c_lo.y))
    middle = (c_lo + c_hi) / 2.0
    for v in ob.data.vertices:
        p = v.co
        v.co = Vector((middle.x + (p.x - middle.x) * grow_x, middle.y + (p.y - middle.y) * grow_y, p.z))


def drop_lining(ob, target):
    """Deletes the faces of [ob] that face the body: the inside of a garment
    made as a thick shell. Nothing needs them (the body fills the inside),
    and pushed out of the body they'd show through the cloth. A face is
    lining only if it faces the body and looking out along it you'd hit the
    body close by: near the shoulders the nearest bit of body can be off to
    one side, and outside faces there mustn't go."""
    import bmesh
    from mathutils.bvhtree import BVHTree
    tree = BVHTree.FromObject(target, bpy.context.evaluated_depsgraph_get())
    mesh = bmesh.new()
    mesh.from_mesh(ob.data)
    inside = []
    for face in mesh.faces:
        centre = face.calc_center_median()
        nearest = tree.find_nearest(centre)[0]
        if nearest is None or face.normal.dot(centre - nearest) >= 0.0:
            continue
        hit = tree.ray_cast(centre + face.normal * 0.001, face.normal, 0.25)[0]
        if hit is not None:
            inside.append(face)
    bmesh.ops.delete(mesh, geom=inside, context="FACES")
    mesh.to_mesh(ob.data)
    mesh.free()
    print("dropped lining faces:", len(inside))


body_points = world_points(posed)
trunk = settings["trunk"]
if slot == "feet" or settings.get("pair", False):
    # A boot per foot: split the pair, fit each to its own foot. Measure the
    # pair first: after splitting, the piece is only one loose part.
    lo, hi = bounds(world_points(piece))
    select_only(piece)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="LOOSE")
    bpy.ops.object.mode_set(mode="OBJECT")
    parts = [ob for ob in bpy.context.selected_objects if ob.type == "MESH"]
    sides = {1.0: [], -1.0: []}
    for part in parts:
        p_lo, p_hi = bounds(world_points(part))
        sides[1.0 if (p_lo.x + p_hi.x) / 2.0 > (lo.x + hi.x) / 2.0 else -1.0].append(part)
    boots = []
    for sign, group in sides.items():
        select_only(group[0])
        for part in group[1:]:
            part.select_set(True)
        bpy.ops.object.join()
        boot = bpy.context.view_layer.objects.active
        foot = region(body_points, low, high, lambda x, s=sign: x * s > 0.0)
        b_lo, b_hi = bounds(world_points(boot))
        fit(boot, foot, (high - low) * (b_hi.z - b_lo.z) / (hi.z - lo.z))
        slim = settings.get("slim", 1.0)
        if slim != 1.0:
            s_lo, s_hi = bounds(world_points(boot))
            mid = (s_lo + s_hi) / 2.0
            for v in boot.data.vertices:
                v.co = Vector((mid.x + (v.co.x - mid.x) * slim, mid.y + (v.co.y - mid.y) * slim, v.co.z))
        boots.append(boot)
    select_only(boots[0])
    boots[1].select_set(True)
    bpy.ops.object.join()
    piece = bpy.context.view_layer.objects.active
    piece.name = "Outfit_" + slot
else:
    trunk_points = region(body_points, low, high, lambda x: abs(x) < trunk)
    fit(piece, trunk_points, high - low)
    widen_to_body(piece, trunk_points, (low + high) / 2.0)
    # drop_lining(piece, posed) tore holes at the shoulders; with the cloth
    # drawn on both sides and held 12 mm off the body it isn't needed.

# Push anything inside the body back out, by a hair.
select_only(piece)
wrap = piece.modifiers.new("OutsideBody", "SHRINKWRAP")
wrap.target = posed
wrap.wrap_method = "NEAREST_SURFACEPOINT"
wrap.wrap_mode = "OUTSIDE"
wrap.offset = settings.get("gap", GAP)
bpy.ops.object.modifier_apply(modifier=wrap.name)

# Each vertex takes the skin weights of the body nearest it.
transfer = piece.modifiers.new("Weights", "DATA_TRANSFER")
transfer.object = posed
transfer.use_vert_data = True
transfer.data_types_verts = {"VGROUP_WEIGHTS"}
transfer.vert_mapping = "POLYINTERP_NEAREST"
transfer.layers_vgroup_select_src = "ALL"
transfer.layers_vgroup_select_dst = "NAME"
bpy.ops.object.datalayout_transfer(modifier=transfer.name)
bpy.ops.object.modifier_apply(modifier=transfer.name)

# The pose it was fitted in becomes the armature's rest pose for this piece.
if settings["raise"] != 0.0:
    select_only(armature)
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")

# Bind it, drop the body, save.
for ob in [body, posed] + extras:
    bpy.data.objects.remove(ob, do_unlink=True)
select_only(piece)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature
bpy.ops.object.parent_set(type="OBJECT", keep_transform=True)
bind = piece.modifiers.new("Armature", "ARMATURE")
bind.object = armature
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", export_animations=False)
print("fitted", slot, "band", round(low, 3), round(high, 3), "->", out_path)
