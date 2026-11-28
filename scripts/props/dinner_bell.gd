class_name DinnerBell
extends Node3D
## The brass bell on the galley wall, rung to call the ship to supper (#207).
## Interact rings it: it shivers and clangs, and the [SupperTable] calls
## whoever you've cooked for to come and eat what's set out.

## Emitted each time the bell is rung.
signal rung

## How far the bell shivers when it's rung, in degrees, and for how long.
@export var shiver_degrees: float = 6.0
@export var shiver_seconds: float = 0.6

@onready var _reach: Interactable3D = $Reach
@onready var _sound: AudioStreamPlayer3D = $RingSound
@onready var _swing: Swinging = $Swing
@onready var _model: Node3D = get_node_or_null("Meshy") as Node3D


func _ready() -> void:
	_reach.interacted.connect(ring)
	_reach.describe_interact = func(_player: Player3D) -> String:
		var table: SupperTable = _supper_table()
		return "Set a meal on the table first" if table != null and table.dish() == null \
				else "Ring for supper"


## Rings the bell, calling [param player]'s company to the table. Returns
## whether anyone came to eat.
func ring(player: Player3D) -> bool:
	_swing.kick(shiver_degrees * 3.0)
	_shiver()
	_sound.play()
	rung.emit()
	var table: SupperTable = _supper_table()
	return table != null and player != null and table.call_to_supper(player)


func _supper_table() -> SupperTable:
	return get_tree().get_first_node_in_group(SupperTable.GROUP) as SupperTable


# The Meshy bell is fixed to its bracket, so it shivers rather than swings.
func _shiver() -> void:
	if _model == null:
		return
	var rest: Vector3 = _model.rotation
	var tween: Tween = create_tween()
	var steps: int = 6
	for i: int in steps:
		var fade: float = 1.0 - float(i) / float(steps)
		var side: float = 1.0 if i % 2 == 0 else -1.0
		tween.tween_property(_model, "rotation:x",
				rest.x + deg_to_rad(shiver_degrees) * side * fade, shiver_seconds / steps)
	tween.tween_property(_model, "rotation", rest, 0.05)
