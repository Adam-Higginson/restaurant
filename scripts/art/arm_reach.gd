class_name ArmReach
extends SkeletonModifier3D
## Lifts one arm of a character towards a point, leaving the rest of the
## body exactly as its animation has it. It's a [SkeletonModifier3D]: a
## node under a [Skeleton3D] that gets a turn to change bones after the
## animation has posed them, every frame.
##
## It turns the upper arm so it points at the target, then the forearm so
## it carries on in the same line: a straight arm, reaching. [member amount]
## blends from the animation's own arm (0) to the full reach (1), so a clip
## can raise the arm slowly.

## The bones of the arm, from the shoulder out: upper arm, forearm, hand.
@export var upper_bone: StringName = &"upperarm_l"
@export var lower_bone: StringName = &"lowerarm_l"
@export var hand_bone: StringName = &"hand_l"
## How far the arm has gone from where the animation has it (0) to
## reaching for the target (1).
@export_range(0.0, 1.0) var amount: float = 0.0
## Where it's reaching, in the world.
var target: Vector3 = Vector3.ZERO


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or amount <= 0.0:
		return
	var aim_at: Vector3 = skeleton.global_transform.affine_inverse() * target
	aim(skeleton, upper_bone, lower_bone, aim_at, amount)
	aim(skeleton, lower_bone, hand_bone, aim_at, amount)


## How long the arm is from shoulder to wrist in [param skeleton]'s own
## space, in metres: the furthest it can reach. 0 if a bone is missing.
func arm_length(skeleton: Skeleton3D) -> float:
	var lower: int = skeleton.find_bone(lower_bone)
	var hand: int = skeleton.find_bone(hand_bone)
	if lower < 0 or hand < 0:
		return 0.0
	return skeleton.get_bone_rest(lower).origin.length() + skeleton.get_bone_rest(hand).origin.length()


## Turns [param bone] so that the joint of [param tip] (a child of it) lies
## on the line from [param bone]'s own joint to [param aim_at], a point in
## [param skeleton]'s space. With [param how_far] below 1 it turns only that
## share of the way. Does nothing if a bone is missing or already there.
static func aim(skeleton: Skeleton3D, bone: StringName, tip: StringName, aim_at: Vector3,
		how_far: float) -> void:
	var bone_index: int = skeleton.find_bone(bone)
	var tip_index: int = skeleton.find_bone(tip)
	if bone_index < 0 or tip_index < 0:
		return
	var here: Transform3D = skeleton.get_bone_global_pose(bone_index)
	var points: Vector3 = skeleton.get_bone_global_pose(tip_index).origin - here.origin
	var wanted: Vector3 = aim_at - here.origin
	if points.is_zero_approx() or wanted.is_zero_approx():
		return
	var turn: Quaternion = Quaternion(points.normalized(), wanted.normalized())
	turn = Quaternion.IDENTITY.slerp(turn, clampf(how_far, 0.0, 1.0))
	var turned: Basis = Basis(turn) * here.basis
	# Poses are kept relative to the bone above, so work back to that.
	var parent_index: int = skeleton.get_bone_parent(bone_index)
	var above: Basis = Basis.IDENTITY
	if parent_index >= 0:
		above = skeleton.get_bone_global_pose(parent_index).basis
	skeleton.set_bone_pose_rotation(bone_index,
			(above.inverse() * turned).orthonormalized().get_rotation_quaternion())
