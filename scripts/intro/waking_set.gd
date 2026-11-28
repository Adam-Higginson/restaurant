extends Node3D
## Samples the imported wake and stand clips as the bedside shots play.

class RestingArms extends SkeletonModifier3D:
	var berth: Node3D
	var release: float = 0.0

	func _process_modification() -> void:
		var rig: Skeleton3D = get_skeleton()
		if rig == null or not is_instance_valid(berth):
			return
		var amount: float = 1.0 - release
		var to_rig: Transform3D = rig.global_transform.affine_inverse() * berth.global_transform
		ArmReach.aim(rig, &"RightArm", &"RightForeArm",
				to_rig * Vector3(5.02, 1.90, 13.16), amount)
		ArmReach.aim(rig, &"RightForeArm", &"RightHand",
				to_rig * Vector3(5.17, 2.04, 13.20), amount)
		ArmReach.aim(rig, &"LeftForeArm", &"LeftHand",
				to_rig * Vector3(5.45, 1.91, 13.38), amount)
		for side: String in ["_r", "_l"]:
			ArmReach.close_hand(rig, side, 0.12 * amount, 0.07 * amount)


var stir: float = 0.0:
	set(value):
		stir = value
		if is_node_ready():
			_sleeper.hold(&"LayToIdle", value)
			if is_instance_valid(_arms):
				_arms.release = clampf(value / 0.33, 0.0, 1.0)
var rise: float = 0.0:
	set(value):
		rise = value
		if is_node_ready():
			_seated.hold(&"Sitting_Exit", value)

var _arms: RestingArms = null

@onready var _sleeper: CharacterModel = $Props/SleepingYou/Character
@onready var _seated: CharacterModel = $Props/SeatedYou/Character


func _ready() -> void:
	_sleeper.dressed.connect(_attach_resting_arms)
	_attach_resting_arms(true)


func _attach_resting_arms(shown: bool) -> void:
	if not shown or _sleeper.skeleton == null or is_instance_valid(_arms):
		return
	_arms = RestingArms.new()
	_arms.berth = self
	_sleeper.skeleton.add_child(_arms)
