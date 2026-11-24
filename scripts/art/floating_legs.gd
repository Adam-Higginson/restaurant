class_name FloatingLegs
extends SkeletonModifier3D
## Makes a character's legs hang as they do in water instead of standing:
## knees a little bent, one leg trailing behind the other, feet pointed,
## all of it drifting slowly. Like [ArmReach], it's a [SkeletonModifier3D]:
## it changes the leg bones after the animation has posed them, and leaves
## everything above the hips alone.
##
## Each joint is swung about the body's side-to-side line: a positive angle
## carries what's below it backwards.

## How much of the float is applied: 0 the animation's own legs, 1 floating.
@export_range(0.0, 1.0) var amount: float = 1.0
## How far each thigh swings back (or forward, if negative), in radians.
@export var thigh_left: float = 0.32
@export var thigh_right: float = 0.02
## How far each knee bends, in radians.
@export var knee_left: float = 0.3
@export var knee_right: float = 0.52
## How far the feet point, in radians.
@export var foot_point: float = 0.55
## How far everything drifts either way, in radians, and how many seconds
## one drift takes.
@export var drift: float = 0.1
@export var drift_seconds: float = 5.0

## Another skeleton's names for the leg bones (the packs' name to its own),
## for a character that isn't built from the packs. Empty uses the packs'.
@export var bones: Dictionary[String, String] = {}

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta


func _process_modification() -> void:
	var skeleton: Skeleton3D = get_skeleton()
	if skeleton == null or amount <= 0.0:
		return
	var sway: float = drift_now(_time)
	swing(skeleton, _named("thigh_l"), (thigh_left + sway) * amount)
	swing(skeleton, _named("thigh_r"), (thigh_right - sway) * amount)
	swing(skeleton, _named("calf_l"), (knee_left + sway * 0.6) * amount)
	swing(skeleton, _named("calf_r"), (knee_right - sway * 0.6) * amount)
	swing(skeleton, _named("foot_l"), foot_point * amount)
	swing(skeleton, _named("foot_r"), foot_point * amount)


func _named(pack_name: String) -> StringName:
	var own: String = bones[pack_name] if bones.has(pack_name) else pack_name
	return StringName(own)


## How far the drift has carried the legs [param seconds] in, in radians:
## slowly one way and back the other.
func drift_now(seconds: float) -> float:
	if drift_seconds <= 0.0:
		return 0.0
	return sin(seconds / drift_seconds * TAU) * drift


## Swings [param bone], and everything below it, by [param angle] radians
## about [param skeleton]'s side-to-side line (its X): positive carries a
## hanging limb backwards. Does nothing if the bone is missing.
static func swing(skeleton: Skeleton3D, bone: StringName, angle: float) -> void:
	var bone_index: int = skeleton.find_bone(bone)
	if bone_index < 0 or is_zero_approx(angle):
		return
	var here: Transform3D = skeleton.get_bone_global_pose(bone_index)
	var turned: Basis = Basis(Vector3.RIGHT, angle) * here.basis
	var parent_index: int = skeleton.get_bone_parent(bone_index)
	var above: Basis = Basis.IDENTITY
	if parent_index >= 0:
		above = skeleton.get_bone_global_pose(parent_index).basis
	skeleton.set_bone_pose_rotation(bone_index,
			(above.inverse() * turned).orthonormalized().get_rotation_quaternion())
