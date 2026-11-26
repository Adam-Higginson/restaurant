extends Node3D
## Samples the imported wake and stand clips as the bedside shots play.

var stir: float = 0.0:
	set(value):
		stir = value
		if is_node_ready():
			_sleeper.hold(&"LayToIdle", value)
var rise: float = 0.0:
	set(value):
		rise = value
		if is_node_ready():
			_seated.hold(&"Sitting_Exit", value)

@onready var _sleeper: CharacterModel = $Props/SleepingYou/Character
@onready var _seated: CharacterModel = $Props/SeatedYou/Character
