class_name CrewWalker
extends Node
## Walks its crewmate (its parent) about the ship (#157): along the ship's
## [Walkways] to a mark, turning to face the way they're going, then turning
## to face the way the mark does once there. Never popping from place to
## place.
##
## They wait, rather than push through, while the player stands in their way
## and while someone is talking with them; then they carry on. The walk is in
## the walkways' space, so the ship carries them as she sails.

## Emitted when they set off, and when they stop or start again on the way
## (waiting for the player, or talking): [param moving] says which.
signal walking_changed(moving: bool)
## Emitted when they've reached where they were going.
signal arrived
## Emitted when a walk is over, whether they got there or were stopped.
signal walk_ended

## How fast they walk, in metres a second.
@export var speed: float = 1.1
## How fast they turn, in degrees a second.
@export var turn_speed: float = 300.0
## How close the player can be in front of them before they stop and wait,
## in metres.
@export var personal_space: float = 1.0

## Whether they're on their way somewhere (even if waiting just now).
var is_walking: bool:
	get:
		return not _path.is_empty()
## Whether they're on their way but stopped, waiting for the player to move
## or a conversation to end.
var is_waiting: bool:
	get:
		return is_walking and not _moving

var _crewmate: Node3D = null
var _walkways: Walkways = null
## The way still to go, in the walkways' space.
var _path: PackedVector3Array = PackedVector3Array()
var _next: int = 0
## Where to face on arrival, as a turn about the up axis in the crewmate's
## parent's space, or NAN to face the way they arrived.
var _end_yaw: float = NAN
var _moving: bool = false


func _ready() -> void:
	_crewmate = get_parent() as Node3D
	for child: Node in _crewmate.get_children():
		if child is CrewStation:
			# Moved to their spot while you slept: whatever walk was under way
			# is over.
			(child as CrewStation).moved.connect(func(_spot: Node3D) -> void: stop())


## Sets off for [param target] (a mark), to stand on it facing the way its
## -Z points. Returns whether there's a way there.
func walk_to(target: Node3D) -> bool:
	var ahead: Vector3 = -target.global_basis.z
	return walk_to_point(target.global_position, ahead)


## Sets off for [param point] (in world space), to face [param facing] (a
## world direction) once there, or the way they arrived if it's zero.
## Returns whether there's a way there.
func walk_to_point(point: Vector3, facing: Vector3 = Vector3.ZERO) -> bool:
	_walkways = Walkways.find(self)
	if _walkways == null or _crewmate == null:
		return false
	var from: Vector3 = _walkways.to_local(_crewmate.global_position)
	var path: PackedVector3Array = _walkways.route(from, _walkways.to_local(point))
	if path.is_empty():
		return false
	_path = path
	_next = 0
	_end_yaw = NAN if facing.is_zero_approx() else _yaw_of(facing)
	if _crewmate is Crewmate:
		(_crewmate as Crewmate).rest()
	_set_moving(true)
	return true


## Sets off back to where they belong at this time of day: their
## [CrewStation]'s spot. Returns whether there's a way there (false with no
## station).
func walk_home() -> bool:
	for child: Node in _crewmate.get_children():
		if child is CrewStation:
			var post: Node3D = (child as CrewStation).post()
			return post != null and walk_to(post)
	return false


## Stops where they are, going nowhere.
func stop() -> void:
	var was_walking: bool = is_walking
	_path = PackedVector3Array()
	_next = 0
	_set_moving(false)
	if was_walking:
		walk_ended.emit()


## The way still to go (in the walkways' space), for tests and the editor.
func remaining() -> PackedVector3Array:
	return _path.slice(_next)


func _physics_process(delta: float) -> void:
	if _crewmate == null:
		return
	if not is_walking:
		if not is_nan(_end_yaw):
			_turn_to(_end_yaw, delta)
			if is_zero_approx(angle_difference(_crewmate.rotation.y, _end_yaw)):
				_end_yaw = NAN
		return
	if _is_held():
		_set_moving(false)
		return
	_set_moving(true)
	var here: Vector3 = _walkways.to_local(_crewmate.global_position)
	var step: float = speed * delta
	while step > 0.0 and _next < _path.size():
		var to_goal: Vector3 = _path[_next] - here
		var distance: float = to_goal.length()
		if distance <= step:
			here = _path[_next]
			step -= distance
			_next += 1
		else:
			here += to_goal / distance * step
			step = 0.0
	_crewmate.global_position = _walkways.to_global(here)
	if _next >= _path.size():
		stop()
		arrived.emit()
		return
	var heading: Vector3 = _walkways.global_basis * (_path[_next] - here)
	if Vector2(heading.x, heading.z).length() > 0.001:
		_turn_to(_yaw_of(heading), delta)


# Whether something is stopping them for now: someone talking with them, or
# the player standing in their way.
func _is_held() -> bool:
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and conversation.is_active() and conversation.partner == _crewmate:
		return true
	var player: Node3D = get_tree().get_first_node_in_group(Player3D.GROUP) as Node3D
	if player == null or not player.visible:
		return false
	var here: Vector3 = _walkways.to_local(_crewmate.global_position)
	var them: Vector3 = _walkways.to_local(player.global_position)
	var ahead: Vector3 = _path[_next] - here
	var gap: Vector3 = them - here
	if absf(gap.y) > 1.5:
		return false
	ahead.y = 0.0
	gap.y = 0.0
	if gap.length() > personal_space or ahead.length() < 0.001:
		return false
	return gap.normalized().dot(ahead.normalized()) > 0.3


# A world direction as a turn about the up axis in the crewmate's parent's
# space, where 0 faces -Z.
func _yaw_of(direction: Vector3) -> float:
	var parent: Node3D = _crewmate.get_parent() as Node3D
	var local: Vector3 = direction
	if parent != null:
		local = parent.global_basis.inverse() * direction
	return atan2(-local.x, -local.z)


func _turn_to(yaw: float, delta: float) -> void:
	_crewmate.rotation.y = rotate_toward(_crewmate.rotation.y, yaw, deg_to_rad(turn_speed) * delta)


func _set_moving(moving: bool) -> void:
	if moving == _moving:
		return
	_moving = moving
	walking_changed.emit(moving)
