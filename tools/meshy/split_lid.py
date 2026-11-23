"""Splits a Meshy chest into a body and a lid that can swing open (#152).

Meshy makes a chest as one closed mesh. This cuts it with a flat plane at
the seam, puts everything above the plane in a "Lid" object and the rest in
a "Body", and moves the lid's origin to its back edge on the cut, so turning
the lid about its own X axis opens it on a hinge. Both go into one glTF.

Run with Blender 4.4 from Git Bash:

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b \
        -P tools/meshy/split_lid.py -- IN.glb OUT.glb SEAM [PREVIEW.png]

SEAM is the cut's height in Blender's metres from the model's middle (Meshy
centres its models), found by eye: run with a PREVIEW path to render the
chest with its lid swung open and look at where the cut fell.

Meshy models face +Z in Godot, which is -Y in Blender, so the back of the
chest (where the hinge goes) is at the largest Blender Y.
"""

import math
import sys

import bmesh
import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index("--") + 1:]
src, dst, seam = args[0], args[1], float(args[2])
preview = args[3] if len(args) > 3 else ""

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [ob for ob in bpy.context.scene.objects if ob.type == "MESH"]
if len(meshes) != 1:
    raise SystemExit("expected one mesh, found %d" % len(meshes))
body = meshes[0]
# Bake the import's transform into the vertices so heights are world heights.
bpy.context.view_layer.objects.active = body
body.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
body.name = "Body"
body.data.name = "Body"

# Cut every face the seam crosses, so nothing straddles the line.
mesh = bmesh.new()
mesh.from_mesh(body.data)
geometry = mesh.verts[:] + mesh.edges[:] + mesh.faces[:]
bmesh.ops.bisect_plane(mesh, geom=geometry, plane_co=Vector((0, 0, seam)),
        plane_no=Vector((0, 0, 1)))
mesh.to_mesh(body.data)
mesh.free()

# Everything above the seam becomes the lid.
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.select_all(action="DESELECT")
bpy.ops.object.mode_set(mode="OBJECT")
for face in body.data.polygons:
    face.select = face.center.z > seam
bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.separate(type="SELECTED")
bpy.ops.object.mode_set(mode="OBJECT")
lid = [ob for ob in bpy.context.scene.objects if ob.type == "MESH" and ob != body][0]
lid.name = "Lid"
lid.data.name = "Lid"

# The hinge: the lid's back edge, on the cut. Measured only on the cut line:
# the dome can bulge further back higher up, and a hinge out there would
# leave the lid floating behind the box as it opens.
on_cut = [v.co.y for v in lid.data.vertices if abs(v.co.z - seam) < 0.002]
back = max(on_cut)
hinge = Vector((0, back, seam))
for vertex in lid.data.vertices:
    vertex.co -= hinge
lid.location = hinge

print("SPLIT body %d faces, lid %d faces, hinge %s"
        % (len(body.data.polygons), len(lid.data.polygons), tuple(hinge)))

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True)

if preview:
    # Swing the lid open and photograph the chest from the front, to judge
    # where the cut fell. Only for looking at: the export is already done.
    # glTF imports turn by quaternion, which ignores rotation_euler.
    lid.rotation_mode = "XYZ"
    lid.rotation_euler.x = math.radians(-70)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.display.shading.color_type = "TEXTURE"
    scene.display.shading.light = "STUDIO"
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    scene.render.filepath = preview
    camera_data = bpy.data.cameras.new("Camera")
    camera = bpy.data.objects.new("Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    # From the front three-quarters, then straight from the side, where a
    # gap at the hinge would show.
    for suffix, place in (("", (1.3, -1.9, 1.1)), ("_side", (2.6, 0.0, 0.2))):
        camera.location = place
        direction = Vector((0, 0, 0.05)) - camera.location
        camera.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.render.filepath = preview.replace(".png", suffix + ".png")
        bpy.ops.render.render(write_still=True)
