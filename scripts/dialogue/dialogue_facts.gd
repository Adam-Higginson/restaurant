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
## heron_at_post    whether that crewmate is at their usual spot for the
##                  time of day (the captain by his stove at night), and not
##                  off somewhere (on deck for a drink): one for each of the
##                  crew, by their id (#176)
## [/codeblock]

## How hard it must rain (0 to 1) to count as raining.
const RAINING_FROM: float = 0.3
## How near their usual spot someone must be to count as at it, in metres.
const AT_POST_WITHIN: float = 1.5

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
	for person: Person in Catalog.load_default().crew:
		var fact: StringName = StringName("%s_at_post" % person.id)
		var id: StringName = person.id
		state.set_fact(fact, func() -> int: return 1 if is_at_post(id) else 0)
		_names.append(fact)


func _exit_tree() -> void:
	for fact: StringName in _names:
		Game.dialogue.remove_fact(fact)


## Whether the crewmate whose person is [param id] is within
## [constant AT_POST_WITHIN] of where they belong at this time of day (their
## [CrewStation]'s post). False if there's no such crewmate or station.
func is_at_post(id: StringName) -> bool:
	if not is_inside_tree():
		return false
	for node: Node in get_tree().get_nodes_in_group(Crewmate.GROUP):
		var crewmate: Crewmate = node as Crewmate
		if crewmate == null or crewmate.person == null or crewmate.person.id != id:
			continue
		for child: Node in crewmate.get_children():
			var station: CrewStation = child as CrewStation
			if station != null and station.post() != null:
				var gap: Vector3 = station.post().global_position - crewmate.global_position
				gap.y = 0.0
				return gap.length() <= AT_POST_WITHIN
	return false


func _is_morning() -> bool:
	var time: TimeOfDay = _time()
	return time != null and time.is_morning()


func _time() -> TimeOfDay:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
