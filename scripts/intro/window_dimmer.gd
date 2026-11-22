class_name WindowDimmer
extends Node
## Turns the glow of the ship's lit windows down and back up, gently. On the
## title the gallery windows sit right behind her name, and at full
## brightness they drown it: dimmed, the lantern's passing light is what you
## see. A clip switches [member dimmed].
##
## The windows all share one material, so this dims every lit window aboard
## while it's on. It always puts the glow back: when it's switched off, and
## when the scene closes.

## The glowing material the windows are drawn with.
@export var glow: StandardMaterial3D
## Whether the windows are turned down. A clip switches this.
@export var dimmed: bool = false
## How bright the windows are when turned down, as a share of their usual glow.
@export_range(0.0, 1.0) var dim_to: float = 0.12
## How long turning them all the way down or up takes, in seconds.
@export var seconds: float = 1.2

## How bright the windows are now, as a share of their usual glow.
var level: float:
	get:
		return _level

var _level: float = 1.0
## The windows' usual glow, to scale and to put back.
var _full: float = 0.0


func _ready() -> void:
	if glow != null:
		_full = glow.emission_energy_multiplier


func _process(delta: float) -> void:
	if glow == null:
		return
	var target: float = dim_to if dimmed else 1.0
	if seconds <= 0.0:
		_level = target
	else:
		_level = move_toward(_level, target, delta / seconds)
	glow.emission_energy_multiplier = _full * _level


func _exit_tree() -> void:
	# The material is shared and outlives this scene: leave it as it was.
	if glow != null and _full > 0.0:
		glow.emission_energy_multiplier = _full
