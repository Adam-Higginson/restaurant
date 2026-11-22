class_name Bedside
extends Node3D
## Your bunk, as something to do: Interact to sleep. The screen fades to
## black, the night passes (or the day), a title says so, and you wake to the
## other: a misty dawn after the storm, or night again. The [TimeOfDay] does
## the changing; this is the going to sleep.

## Emitted after you wake, with whether it's morning now.
signal woke(morning: bool)

## How long you're asleep, with the screen black, in seconds.
@export var sleep_seconds: float = 1.4

## Whether you're asleep right now.
var is_sleeping: bool:
	get:
		return _sleeping

var _sleeping: bool = false

@onready var _reach: Interactable3D = $Reach
@onready var _fade: ScreenFade = $ScreenFade


func _ready() -> void:
	_reach.interacted.connect(sleep)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


## What Interact would do now, for the HUD.
func prompt() -> String:
	if _sleeping:
		return ""
	var time: TimeOfDay = _time_of_day()
	if time != null and time.is_morning():
		return "Rest until nightfall"
	return "Sleep until morning"


## Sleeps, moving the time on, while [param player] can't move.
func sleep(player: Player3D) -> void:
	if _sleeping:
		return
	_sleeping = true
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	await _fade.fade_out()
	var time: TimeOfDay = _time_of_day()
	var morning: bool = time == null or not time.is_morning()
	if time != null:
		time.dawn = 1.0 if morning else 0.0
	await _fade.show_title("Morning" if morning else "Night")
	await get_tree().create_timer(sleep_seconds).timeout
	await _fade.fade_in()
	player.set_physics_process(true)
	_sleeping = false
	woke.emit(morning)


func _time_of_day() -> TimeOfDay:
	return get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
