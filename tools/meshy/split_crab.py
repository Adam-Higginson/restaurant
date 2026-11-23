"""Cuts a Meshy crab into a body, two claws and eight legs that can move (#168).

Meshy makes a creature as one fused mesh and can only rig people, so a crab
arrives unable to move a leg. This takes everything inside an oval round the
shell (seen from above) as the body; what is left outside falls apart into
separate limbs, each joined to the rest only through the body. Every limb
becomes its own object whose origin is where it joined the shell, so turning
it about its origin swings it from its joint. All go into one glTF:

    Body, ClawL, ClawR, LegL1..LegL4, LegR1..LegR4

(L and R are the model's own -X and +X; legs are numbered from the front.)
The game moves them in code ([Crab]).

Run with Blender 4.4 from Git Bash:

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b \
        -P tools/meshy/split_crab.py -- IN.glb OUT.glb [RX RY CY]

RX and RY are the oval's half-width and half-length in Blender's metres and CY
how far back its middle is (defaults 0.28 0.22 0). Too small an oval leaves
limbs joined to each other; too big cuts them short. The script says how many
limbs it found: it must be two claws and eight legs.

Meshy models face +Z in Godot, which is -Y in Blender, so the front of the
crab is at the smallest Blender Y.
"""

import sys

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst = args[0], args[1]
rx = float(args[2]) if len(args) > 2 else 0.28
ry = float(args[3]) if len(args) > 3 else 0.22
cy = float(args[4]) if len(args) > 4 else 0.0
# A piece outside the oval with fewer points than this is a scrap of shell.
SMALLEST_LIMB = 60

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [ob for ob in bpy.context.scene.objects if ob.type == "MESH"]
if len(meshes) != 1:
    raise SystemExit("expected one mesh, found %d" % len(meshes))
whole = meshes[0]
bpy.context.view_layer.objects.active = whole
whole.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Weld the points the import split along texture seams, so "joined" means
# joined in shape. Each corner keeps its own place in the texture.
mesh = bmesh.new()
mesh.from_mesh(whole.data)
bmesh.ops.remove_doubles(mesh, verts=mesh.verts, dist=1e-5)
mesh.verts.ensure_lookup_table()
mesh.faces.ensure_lookup_table()

outside = set(v.index for v in mesh.verts
              if (v.co.x / rx) ** 2 + ((v.co.y - cy) / ry) ** 2 > 1.0)
pieces = []
seen = set()
for start in outside:
    if start in seen:
        continue
    seen.add(start)
    stack = [mesh.verts[start]]
    piece = []
    while stack:
        vert = stack.pop()
        piece.append(vert)
        for edge in vert.link_edges:
            other = edge.other_vert(vert)
            if other.index in outside and other.index not in seen:
                seen.add(other.index)
                stack.append(other)
    pieces.append(piece)


def centre(verts):
    total = Vector((0.0, 0.0, 0.0))
    for vert in verts:
        total += vert.co
    return total / len(verts)


# A limb is a big enough piece out to one side; anything else outside the
# oval (the front of the face, scraps) stays part of the body.
limbs = [p for p in pieces if len(p) >= SMALLEST_LIMB and abs(centre(p).x) > rx * 0.5]
limbs.sort(key=len, reverse=True)
claws, legs = limbs[:2], limbs[2:]
print("SPLIT found %d claws and %d legs (sizes %s)" % (
    len(claws), len(legs), [len(p) for p in limbs]))
if len(claws) != 2 or len(legs) != 8:
    raise SystemExit("SPLIT wanted 2 claws and 8 legs: try another oval")

named = {}
for claw in claws:
    named["ClawL" if centre(claw).x < 0.0 else "ClawR"] = claw
for side, sign in (("L", -1.0), ("R", 1.0)):
    row = sorted((leg for leg in legs if centre(leg).x * sign > 0.0), key=lambda leg: centre(leg).y)
    if len(row) != 4:
        raise SystemExit("SPLIT wanted four legs a side, found %d on %s" % (len(row), side))
    for number, leg in enumerate(row, start=1):
        named["Leg%s%d" % (side, number)] = leg

# Which limb each point belongs to, and where each limb joins the shell: the
# middle of its points that touch one that isn't its own.
owner = {}
joints = {}
for name, piece in named.items():
    for vert in piece:
        owner[vert.index] = name
for name, piece in named.items():
    rim = [v for v in piece if any(owner.get(e.other_vert(v).index) != name for e in v.link_edges)]
    joints[name] = centre(rim if rim else piece)
    print("SPLIT %-6s %4d points, joint at x %+.3f y %+.3f z %+.3f" % (
        name, len(piece), joints[name].x, joints[name].y, joints[name].z))

# A face is a limb's only if every corner is; the rest is the body.
face_owner = []
for face in mesh.faces:
    owners = set(owner.get(v.index, "Body") for v in face.verts)
    face_owner.append(owners.pop() if len(owners) == 1 else "Body")

collection = bpy.context.scene.collection
for name in ["Body"] + sorted(named):
    part = mesh.copy()
    part.faces.ensure_lookup_table()
    unwanted = [f for f in part.faces if face_owner[f.index] != name]
    bmesh.ops.delete(part, geom=unwanted, context="FACES")
    # Close the open end where it was cut, so nothing looks hollow as it turns.
    bmesh.ops.holes_fill(part, edges=[e for e in part.edges if e.is_boundary], sides=0)
    joint = joints.get(name, Vector((0.0, 0.0, 0.0)))
    bmesh.ops.translate(part, verts=part.verts, vec=-joint)
    data = bpy.data.meshes.new(name)
    part.to_mesh(data)
    part.free()
    for material in whole.data.materials:
        data.materials.append(material)
    for polygon in data.polygons:
        polygon.use_smooth = True
    obj = bpy.data.objects.new(name, data)
    obj.location = joint
    collection.objects.link(obj)

bpy.data.objects.remove(whole, do_unlink=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True)
print("SPLIT wrote", dst)
