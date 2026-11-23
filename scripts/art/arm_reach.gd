class_name ArmReach
extends SkeletonModifier3D
## Lifts one arm of a character towards a point, leaving the rest of the
## body exactly as its animation has it. It's a [SkeletonModifier3D]: a
## node under a [Skeleton3D] that gets a turn to change bones after the
## animation has posed them, every frame.
##
## It turns the upper arm so it points at the target, then the forearm so
## it carries on in the same line, then the hand: a straight arm and wrist,
## reaching. [member amount] blends from the animation's own arm (0) to the
## full reach (1), so a clip can raise the arm slowly. [member grip] curls
## the fingers and thumb, to hold something.

## The fingers, by the start of their bones' names: each has three joints,
## [code]<name>_01[/code] to [code]_03[/code], then the side
## ([code]_l[/code]).
const FINGERS: PackedStringArray = ["index", "middle", "ring", "pinky"]

## The bones of the arm, from the shoulder out: upper arm, forearm, hand.
@export var upper_bone: StringName = &"upperarm_l"
@export var lower_bone: StringName = &"lowerarm_l"
@export var hand_bone: StringName = &"hand_l"
## The collarbone, which lifts a share of the way too when the arm reaches
## high ([member shoulder_share]): a real shoulder rises with a raised arm,
## and without it the arm looks short and bunched at the top. Empty leaves
## the shoulder as the animation has it.
@export var shoulder_bone: StringName = &""
@export_range(0.0, 1.0) var shoulder_share: float = 0.35
## The side the bones are on, as their names end.
@export var side: String = "_l"
## How far the arm has gone from where the animation has it (0) to
## reaching for the target (1).
@export_range(0.0, 1.0) var amount: float = 0.0
## How far the fingers have closed: 0 as the animation has them, 1 holding.
@export_range(0.0, 1.0) var grip: float = 0.0
## How far each finger joint bends at a full grip, in radians, and each of
## the thumb's.
@export var finger_curl: float = 0.62
@export var thumb_curl: float = 0.45
## Which way a finger joint bends to close the hand, about its own axis, and
## which way the thumb's do (the thumb lies across the others).
@export var curl_axis: Vector3 = Vector3(0, 0, 1)
@export var thumb_axis: Vector3 = Vector3(1, 0, 0)
## Where it's reaching, in the world.
var target: Vector3 = Vector3.ZERO


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null:
		return
	if amount > 0.0:
		var aim_at: Vector3 = skeleton.global_transform.affine_inverse() * target
		if shoulder_bone != &"":
			aim(skeleton, shoulder_bone, upper_bone, aim_at, amount * shoulder_share)
		aim(skeleton, upper_bone, lower_bone, aim_at, amount)
		aim(skeleton, lower_bone, hand_bone, aim_at, amount)
		# The wrist straight too, so the hand doesn't hang off the end.
		aim(skeleton, hand_bone, StringName("middle_01" + side), aim_at, amount)
	if grip > 0.0:
		close_hand(skeleton, side, grip * finger_curl, grip * thumb_curl, curl_axis, thumb_axis)


## Bends every joint of the fingers on [param hand_side] by
## [param finger_angle] radians, and the thumb's by [param thumb_angle],
## about [param axis] (each bone's own; the thumb's about [param thumb]):
## closing the hand. Missing bones are left alone.
static func close_hand(skeleton: Skeleton3D, hand_side: String, finger_angle: float,
		thumb_angle: float, axis: Vector3 = Vector3(0, 0, 1),
		thumb: Vector3 = Vector3(1, 0, 0)) -> void:
	for finger: String in FINGERS:
		for joint: int in [1, 2, 3]:
			bend(skeleton, StringName("%s_0%d%s" % [finger, joint, hand_side]), finger_angle, axis)
	for joint: int in [1, 2, 3]:
		bend(skeleton, StringName("thumb_0%d%s" % [joint, hand_side]), thumb_angle, thumb)


## Turns [param bone] by [param angle] radians about [param axis], in its own
## space, on top of its pose. Does nothing if it's missing.
static func bend(skeleton: Skeleton3D, bone: StringName, angle: float, axis: Vector3) -> void:
	var index: int = skeleton.find_bone(bone)
	if index < 0 or is_zero_approx(angle):
		return
	skeleton.set_bone_pose_rotation(index,
			skeleton.get_bone_pose_rotation(index) * Quaternion(axis.normalized(), angle))


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
