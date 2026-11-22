"""Converts a Blender file to a binary glTF (.glb) Godot can import, with its
animations, and prints what's inside: meshes, bones and actions.

Run with Blender's command line (Godot itself can't open .blend files
without Blender set up in the editor settings):

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b <in.blend> \
        --python tools/blend_to_glb.py -- <out.glb>

Rigs that pose their limbs with IK (the fog crab's legs) only key the IK
targets, which glTF can't carry. So each action is first baked: Blender
plays it and keys where every bone actually ends up ("visual keying"), and
the IK is dropped. Then the baked actions are exported.

Used for third-party models that only come as .blend, e.g. the fog crab's
(assets/third_party/oga_crab/). The output stays in assets/third_party/.
"""
import sys

import bpy


def bake_actions(armature):
    """Bakes every action on [armature] so its bones carry the posed result."""
    bpy.context.view_layer.objects.active = armature
    armature.select_set(True)
    bpy.ops.object.mode_set(mode="POSE")
    if armature.animation_data is None:
        armature.animation_data_create()
    baked = []
    for action in list(bpy.data.actions):
        armature.animation_data.action = action
        start, end = (int(frame) for frame in action.frame_range)
        bpy.ops.pose.select_all(action="SELECT")
        bpy.ops.nla.bake(
            frame_start=start,
            frame_end=end,
            only_selected=False,
            visual_keying=True,
            clear_constraints=False,
            use_current_action=False,
            bake_types={"POSE"},
        )
        result = armature.animation_data.action
        result.name = action.name + "_baked"
        baked.append((action, result))
        print("BAKED", action.name, start, end)
    for source, result in baked:
        name = source.name
        bpy.data.actions.remove(source)
        result.name = name
        result.use_fake_user = True
    # Drop the IK so the baked bones are what's exported.
    for bone in armature.pose.bones:
        for constraint in list(bone.constraints):
            bone.constraints.remove(constraint)
    armature.animation_data.action = None
    bpy.ops.object.mode_set(mode="OBJECT")


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    if len(args) != 1:
        print("usage: blender -b in.blend --python blend_to_glb.py -- out.glb")
        sys.exit(1)
    out = args[0]
    for obj in bpy.data.objects:
        print("OBJECT", obj.name, obj.type, "parent:", obj.parent.name if obj.parent else "-")
        if obj.type == "ARMATURE":
            print("  BONES", [bone.name for bone in obj.data.bones])
    print("ACTIONS", [action.name for action in bpy.data.actions])
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            bake_actions(obj)
    bpy.ops.export_scene.gltf(
        filepath=out,
        export_format="GLB",
        export_animations=True,
        export_animation_mode="ACTIONS",
        export_apply=True,
    )
    print("WROTE", out)


main()
