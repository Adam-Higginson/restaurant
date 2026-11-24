"""Tucks one fitted clothing layer inside another (#206): a shirt into the
trousers, trousers into the boots.

Two layers fitted by fit_layer.py sit on the same body, each held 12 mm off
it, so where they overlap neither is inside the other: a shirt's hem hangs
over the trousers, and slim boots let the trouser legs poke through. This
pulls the inner layer in, wherever the outer one covers it, until it's
inside the outer one by a hair. The outer layer is left as it was.

How: the outer layer is measured in slices (by height, and by angle round
the middle of the body, or round each leg's middle for boots); in each
slice, the nearest any of it comes to the middle is the room inside it. Any
point of the inner layer in a covered slice that's further out than that is
moved straight in towards the middle until it fits. Points above the outer
layer's top edge (taken angle by angle) are left alone, so the cloth goes
in at the waistband or the boot top.

Run with Blender 4.4 from Git Bash:

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b \\
        -P tools/meshy/tuck_layer.py -- INNER.glb OUTER.glb OUT.glb MODE

MODE is "waist" (one middle: a shirt into trousers) or "legs" (a middle
per leg: trousers into boots). OUT may be INNER, to tuck it in place.
"""

import math
import sys

import bpy
from mathutils import Vector

# How far inside the outer layer the inner one ends up, in metres.
MARGIN = 0.006
# Slices: how tall each is, in metres, and how many round the middle.
SLICE = 0.01
ANGLES = 36
# Only this much of the outer layer is measured: the band where it can
# cover the inner one (from its top down), in metres. Below a boot top or a
# waistband the inner layer is pulled in all the way down this band.
DEPTH = {"waist": 0.22, "legs": 0.45}

args = sys.argv[sys.argv.index("--") + 1:]
inner_path, outer_path, out_path, mode = args[0], args[1], args[2], args[3]

bpy.ops.wm.read_factory_settings(use_empty=True)


def import_layer(path):
    before = set(bpy.context.scene.objects)
    bpy.ops.import_scene.gltf(filepath=path)
    added = [ob for ob in bpy.context.scene.objects if ob not in before]
    meshes = [ob for ob in added if ob.type == "MESH"]
    return added, max(meshes, key=lambda ob: len(ob.data.vertices))


inner_objects, inner = import_layer(inner_path)
outer_objects, outer = import_layer(outer_path)

outer_points = [outer.matrix_world @ v.co for v in outer.data.vertices]
top = max(p.z for p in outer_points)
band_low = top - DEPTH[mode]
outer_points = [p for p in outer_points if p.z >= band_low]


def side_of(p, middle_x):
    if mode == "waist":
        return 0
    return 1 if p.x > middle_x else -1


middle_x = sum(p.x for p in outer_points) / len(outer_points)

# The middle of each side's outer layer, slice by slice.
centres = {}
for p in outer_points:
    key = (side_of(p, middle_x), int((p.z - band_low) / SLICE))
    total = centres.setdefault(key, [0.0, 0.0, 0])
    total[0] += p.x
    total[1] += p.y
    total[2] += 1


def centre(side, level):
    for step in (0, -1, 1, -2, 2, -3, 3):
        total = centres.get((side, level + step))
        if total:
            return Vector((total[0] / total[2], total[1] / total[2]))
    return None


def angle_bin(dx, dy):
    return int((math.atan2(dy, dx) + math.pi) / (2.0 * math.pi) * ANGLES) % ANGLES


# The room inside the outer layer (its nearest to the middle), and how high
# it reaches, slice by slice and angle by angle.
room = {}
reach = {}
for p in outer_points:
    side = side_of(p, middle_x)
    level = int((p.z - band_low) / SLICE)
    middle = centre(side, level)
    dx, dy = p.x - middle.x, p.y - middle.y
    turn = angle_bin(dx, dy)
    radius = math.hypot(dx, dy)
    key = (side, level, turn)
    room[key] = min(room.get(key, radius), radius)
    reach[(side, turn)] = max(reach.get((side, turn), p.z), p.z)


def room_at(side, level, turn):
    # A slice with no outer point at that angle borrows its neighbours'.
    best = None
    for dl in (0, -1, 1):
        for dt in (0, -1, 1, -2, 2):
            r = room.get((side, level + dl, (turn + dt) % ANGLES))
            if r is not None and (best is None or r < best):
                best = r
    return best


moved = 0
inverse = inner.matrix_world.inverted()
for v in inner.data.vertices:
    p = inner.matrix_world @ v.co
    if p.z < band_low:
        continue
    side = side_of(p, middle_x)
    level = int((p.z - band_low) / SLICE)
    middle = centre(side, level)
    if middle is None:
        continue
    dx, dy = p.x - middle.x, p.y - middle.y
    turn = angle_bin(dx, dy)
    if p.z > reach.get((side, turn), top) - 0.002:
        continue
    limit = room_at(side, level, turn)
    if limit is None:
        continue
    radius = math.hypot(dx, dy)
    wanted = limit - MARGIN
    if radius <= wanted or radius < 1e-6:
        continue
    scale = max(wanted, 0.0) / radius
    p = Vector((middle.x + dx * scale, middle.y + dy * scale, p.z))
    v.co = inverse @ p
    moved += 1

print("tucked", moved, "of", len(inner.data.vertices), "points; band",
      round(band_low, 3), "to", round(top, 3))

for ob in outer_objects:
    bpy.data.objects.remove(ob, do_unlink=True)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=out_path, export_format="GLB", export_animations=False,
                          use_selection=True)
print("saved", out_path)
