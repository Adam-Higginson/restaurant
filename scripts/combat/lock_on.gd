class_name LockOn
extends Node
## Lock-on, as in Ocarina of Time: hold the button and the nearest thing
## worth fighting becomes the [member target]. The player then faces it
## (so walking sideways circles it), the camera keeps both in view, and the
## lantern hovers over it. With nothing in reach, the button swings the
## camera round behind the player instead.
##
## A child of the [Player3D]. Anything in the [constant GROUP] group can be
## locked on to; a fog-crab leaves the group when its fog clears.

## Emitted when the target changes (null when lock-on lets go).
signal target_changed(target: Node3D)

enum Mode {
	## Locked on while the button is held.
	HOLD,
	## Press to lock on, press again to let go.
	TOGGLE,
}

## Nodes in this group can be locked on to.
const GROUP: StringName = &"lock_on_target"

## Whether the button is held or toggled. (A settings menu can offer both
## later, as OoT did.)
@export var mode: Mode = Mode.HOLD
## How near something must be to lock on to it, in metres.
@export var reach: float = 9.0
## How far the target can get before lock-on lets go, in metres.
@export var release_distance: float = 12.0

## What's locked on to now, or null.
var target: Node3D:
	get:
		return _target

var _target: Node3D = null

@onready var _player: Player3D = get_parent() as Player3D


func _physics_process(_delta: float) -> void:
	if _target != null and not _can_keep(_target):
		release()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lock_on"):
		get_viewport().set_input_as_handled()
		press()
	elif event.is_action_released("lock_on"):
		let_go()


## The button going down: locks on to the nearest target in reach, or with
## none, turns the camera to look the way the player faces. In toggle mode a
## second press lets go.
func press() -> void:
	if not _player.controls_enabled:
		return
	if _target != null:
		if mode == Mode.TOGGLE:
			release()
		return
	var found: Node3D = nearest(_player.global_position, _candidates(), reach)
	if found == null:
		_player.camera_rig.look_along(_player.facing)
		return
	_set_target(found)


## The button coming up: in hold mode, lets go of the target.
func let_go() -> void:
	if mode == Mode.HOLD:
		release()


## Lets go of the target, if there is one.
func release() -> void:
	_set_target(null)


## The nearest of [param candidates] within [param max_distance] metres of
## [param from], measured flat along the ground, or null if none is.
static func nearest(from: Vector3, candidates: Array[Node3D], max_distance: float) -> Node3D:
	var best: Node3D = null
	var best_distance: float = max_distance
	for candidate: Node3D in candidates:
		var distance: float = flat_distance(from, candidate.global_position)
		if distance <= best_distance:
			best = candidate
			best_distance = distance
	return best


## The distance between two points ignoring height, in metres.
static func flat_distance(from: Vector3, to: Vector3) -> float:
	return Vector2(to.x - from.x, to.z - from.z).length()


func _set_target(value: Node3D) -> void:
	if value == _target:
		return
	_target = value
	_player.lock_target = value
	_player.camera_rig.look_target = value
	target_changed.emit(value)


# Everything in the scene that can be locked on to.
func _candidates() -> Array[Node3D]:
	var found: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var candidate: Node3D = node as Node3D
		if candidate != null:
			found.append(candidate)
	return found


# Whether lock-on can stay on [param what]: it still exists, can still be
# locked on to, is near enough, and the player is free to act.
func _can_keep(what: Node3D) -> bool:
	if not is_instance_valid(what) or not what.is_in_group(GROUP):
		return false
	if not _player.controls_enabled:
		return false
	return flat_distance(_player.global_position, what.global_position) <= release_distance
