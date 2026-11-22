class_name Lookout
extends Area3D
## The bow, as a place to stand and look out. Walk out onto it at night and
## your lantern notices the far light in the fog, and has a guess about it.
## Not every time: he has a think between guesses.

## Seconds before he'll guess again.
@export var cooldown_seconds: float = 90.0

var _since: float = INF


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_since += delta


## Whether he'd say something if you walked out now.
func would_speak() -> bool:
	if _since < cooldown_seconds:
		return false
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	return time == null or not time.is_morning()


func _on_body_entered(body: Node3D) -> void:
	var player: Player3D = body as Player3D
	if player == null or not would_speak():
		return
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit == null:
		return
	_since = 0.0
	spirit.say(LanternLines.pick(LanternLines.FAR_LIGHT))
