class_name CrewStation
extends Node
## Where a crewmate is at night and where in the morning. Add it as a child
## of a [Crewmate]; it moves them to the right spot when the time changes,
## which only happens while the screen is black (asleep) or as a saved
## voyage is loaded, so nobody is seen popping from place to place.
##
## A stand-in until the crew can walk the ship on a schedule.

## Emitted when the crewmate has been moved to a spot.
signal moved(spot: Node3D)

## Where they stand at night: a marker in the ship. Unset means stay put.
@export var night_spot: Node3D
## Where they stand in the morning.
@export var morning_spot: Node3D

var _was_morning: bool = false


func _ready() -> void:
	# The time of day may be ready after us.
	_begin.call_deferred()


## The spot for now: the morning one in the morning, else the night one.
func spot_for(morning: bool) -> Node3D:
	return morning_spot if morning else night_spot


## Moves the crewmate to where they belong when it [param morning] or not.
func place(morning: bool) -> void:
	_was_morning = morning
	var spot: Node3D = spot_for(morning)
	var crewmate: Node3D = get_parent() as Node3D
	if not is_instance_valid(spot) or crewmate == null:
		return
	crewmate.global_transform = spot.global_transform
	crewmate.reset_physics_interpolation()
	moved.emit(spot)


func _begin() -> void:
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	if time == null:
		place(false)
		return
	place(time.is_morning())
	time.changed.connect(func(_dawn: float) -> void:
		if time.is_morning() != _was_morning:
			place(time.is_morning()))
