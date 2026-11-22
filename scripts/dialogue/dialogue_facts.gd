class_name DialogueFacts
extends Node
## Tells conversations what the world is like right now, so a script can
## write [code]? night[/code] or [code]? raining and sailing[/code]. Each is
## a fact in [code]Game.dialogue[/code] (see [DialogueState]), there while
## this node is in the scene.
##
## [codeblock]
## night, morning   which it is (1 or 0)
## day              which day at sea, from 1
## raining          whether it's raining hard enough to notice
## sailing          whether the ship is under way
## [/codeblock]

## How hard it must rain (0 to 1) to count as raining.
const RAINING_FROM: float = 0.3

## The ship, for [code]sailing[/code].
@export var ship: Ship
## The weather, for [code]raining[/code].
@export var weather: Weather

var _names: Array[StringName] = [&"night", &"morning", &"day", &"raining", &"sailing"]


func _ready() -> void:
	var state: DialogueState = Game.dialogue
	state.set_fact(&"night", func() -> int: return 0 if _is_morning() else 1)
	state.set_fact(&"morning", func() -> int: return 1 if _is_morning() else 0)
	state.set_fact(&"day", func() -> int: return _time().day if _time() != null else 1)
	state.set_fact(&"raining", func() -> int:
		return 1 if is_instance_valid(weather) and weather.intensity >= RAINING_FROM else 0)
	state.set_fact(&"sailing", func() -> int:
		return 1 if is_instance_valid(ship) and ship.is_sailing else 0)


func _exit_tree() -> void:
	for fact: StringName in _names:
		Game.dialogue.remove_fact(fact)


func _is_morning() -> bool:
	var time: TimeOfDay = _time()
	return time != null and time.is_morning()


func _time() -> TimeOfDay:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
