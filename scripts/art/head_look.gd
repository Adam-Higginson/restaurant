class_name HeadLook
extends SkeletonModifier3D
## Turns a character's head to look at a point, leaving the rest of the
## body as its animation has it. Like [ArmReach], it's a
## [SkeletonModifier3D]: it changes one bone after the animation has posed
## them all. [member amount] blends from the animation's own head (0) to
## looking straight at the target (1), so a clip can raise the head slowly.
## A neck only turns so far: past [member most] it stops.

## The bone to turn.
@export var head_bone: StringName = &"Head"
## Which way the face points when the skeleton is at rest, in the
## skeleton's own space. The characters' packs face +Z.
@export var face_forward: Vector3 = Vector3.BACK
## How far the head has turned from where the animation has it (0) to
## looking at the target (1).
@export_range(0.0, 1.0) var amount: float = 0.0
## The furthest the head may turn from where the animation has it, in radians.
@export var most: float = 1.2
## Where it's looking, in the world.
var target: Vector3 = Vector3.ZERO


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or amount <= 0.0:
		return
	look(skeleton, head_bone, skeleton.global_transform.affine_inverse() * target,
			amount, face_forward, most)


## Turns [param bone] so its face points at [param look_at], a point in
## [param skeleton]'s space. [param forward] is which way the face points
## at rest. With [param how_far] below 1 it turns only that share of the
## way, and never more than [param limit] radians. Does nothing if the bone
## is missing.
static func look(skeleton: Skeleton3D, bone: StringName, look_at: Vector3, how_far: float,
		forward: Vector3 = Vector3.BACK, limit: float = PI) -> void:
	var bone_index: int = skeleton.find_bone(bone)
	if bone_index < 0:
		return
	var here: Transform3D = skeleton.get_bone_global_pose(bone_index)
	# Which way the face points now: its rest direction, carried along by
	# however far the bone has turned from rest.
	var rest: Basis = skeleton.get_bone_global_rest(bone_index).basis
	var facing: Vector3 = (here.basis * rest.inverse() * forward).normalized()
	var wanted: Vector3 = look_at - here.origin
	if facing.is_zero_approx() or wanted.is_zero_approx():
		return
	var turn: Quaternion = Quaternion(facing, wanted.normalized())
	var angle: float = turn.get_angle()
	var share: float = clampf(how_far, 0.0, 1.0)
	if angle > limit and angle > 0.0:
		share *= limit / angle
	turn = Quaternion.IDENTITY.slerp(turn, share)
	var turned: Basis = Basis(turn) * here.basis
	var parent_index: int = skeleton.get_bone_parent(bone_index)
	var above: Basis = Basis.IDENTITY
	if parent_index >= 0:
		above = skeleton.get_bone_global_pose(parent_index).basis
	skeleton.set_bone_pose_rotation(bone_index,
			(above.inverse() * turned).orthonormalized().get_rotation_quaternion())
