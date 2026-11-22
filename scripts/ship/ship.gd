class_name Ship
extends AnimatableBody3D
## The crew's ship. It sails along [member route] at [member speed], facing
## the way it's going, and stops at the route's end (the mooring point).
##
## The ship never tilts or rocks: the deck stays level and still, so walking
## and cooking feel steady and the floor you see is the floor you stand on.
## The sea moves around the hull instead (see [Sea]), and hanging things like
## the lanterns swing ([Swinging]).

## Emitted once, when the ship reaches the end of its route and stops.
signal moored
## Emitted when the ship has eased to a stop after [method heave_to].
signal hove_to
## Emitted when the ship starts easing up to speed after [method get_under_way].
signal got_under_way

## How far ahead and behind (in metres along the route) the ship looks to
## work out which way it's facing.
const LOOK_STEP: float = 0.5

## The path to sail along. The ship snaps to its start when it's ready.
@export var route: Path3D
## Sailing speed in metres per second.
@export var speed: float = 3.0
## Whether to set sail as soon as the scene starts.
@export var sail_on_ready: bool = true
## Whether to sail round and round the route forever instead of mooring at
## its end. The route should be a closed loop (its last point on its first).
@export var loop_route: bool = false
## How long the ship takes to ease from a stop to full speed, or back, when it
## heaves to or gets under way (at the bell), in seconds.
@export var ease_seconds: float = 5.0

## Whether the ship is under way. False before it sets sail and once moored.
var is_sailing: bool:
	get:
		return _sailing

## How fast and which way the ship is moving, in metres per second.
var velocity: Vector3:
	get:
		if not _sailing:
			return Vector3.ZERO
		return -global_basis.z * speed * _way

## How much of its full speed the ship is making, 0 to 1. Eases down when it
## heaves to and up when it gets under way; the wake and spray follow it.
var way: float:
	get:
		return _way if _sailing else 0.0

## Whether the ship is easing to a stop after [method heave_to].
var is_heaving_to: bool:
	get:
		return _sailing and _way_goal == 0.0

var _sailing: bool = false
var _way: float = 1.0
var _way_goal: float = 1.0
## How far along the route the ship has come, in metres.
var _distance: float = 0.0


func _ready() -> void:
	if _has_route():
		global_transform = _transform_at(0.0)
		# A jump, not a move: draw it there at once rather than gliding over.
		reset_physics_interpolation()
	if sail_on_ready:
		set_sail()


func _physics_process(delta: float) -> void:
	if not _sailing or speed <= 0.0:
		return
	_ease_way(delta)
	if not _sailing:
		return
	var step: float = speed * _way * delta
	var length: float = route.curve.get_baked_length()
	if loop_route:
		# Round again: past the end is the start of the next lap.
		_distance = fposmod(_distance + step, length)
		global_transform = _transform_at(_distance)
		return
	# Clamp, so a long frame stops the ship at the end rather than past it.
	_distance = minf(_distance + step, length)
	global_transform = _transform_at(_distance)
	if _distance >= length:
		_sailing = false
		moored.emit()


## Starts sailing from wherever the ship is along its route. Does nothing
## without a usable route, or once the ship has reached the end.
func set_sail() -> void:
	if not _has_route() or _distance >= route.curve.get_baked_length():
		return
	_sailing = true
	_way = 1.0
	_way_goal = 1.0


## Eases the ship to a stop where it is, over [member ease_seconds]. It stays
## on its route and can [method get_under_way] again. Does nothing unless
## it's sailing.
func heave_to() -> void:
	if _sailing:
		_way_goal = 0.0


## Eases the ship back up to speed along its route, over
## [member ease_seconds]: after [method heave_to], or from a standstill.
func get_under_way() -> void:
	if not _has_route() or _distance >= route.curve.get_baked_length():
		return
	if not _sailing:
		_sailing = true
		_way = 0.0
	_way_goal = 1.0
	got_under_way.emit()


func _ease_way(delta: float) -> void:
	var rate: float = 1.0 / ease_seconds if ease_seconds > 0.0 else INF
	_way = move_toward(_way, _way_goal, rate * delta)
	if _way_goal == 0.0 and _way == 0.0:
		_sailing = false
		hove_to.emit()


func _has_route() -> bool:
	return route != null and route.curve != null and route.curve.point_count >= 2 \
			and route.curve.get_baked_length() > 0.0


# Where the ship stands [param distance] metres along the route, in world
# space, turned to face along the route and kept level.
func _transform_at(distance: float) -> Transform3D:
	var curve: Curve3D = route.curve
	var length: float = curve.get_baked_length()
	var behind: Vector3 = route.to_global(curve.sample_baked(_along(distance - LOOK_STEP, length)))
	var ahead: Vector3 = route.to_global(curve.sample_baked(_along(distance + LOOK_STEP, length)))
	var heading: Vector3 = ahead - behind
	# Ignore any climb or dip in the route, so the deck never tilts.
	heading.y = 0.0
	var basis_now: Basis = global_basis
	if not heading.is_zero_approx():
		basis_now = Basis.looking_at(heading, Vector3.UP)
	return Transform3D(basis_now, route.to_global(curve.sample_baked(distance)))


# A distance along the route, kept on it: wrapped round a loop, or held at
# the ends of a one-way route.
func _along(distance: float, length: float) -> float:
	if loop_route:
		return fposmod(distance, length)
	return clampf(distance, 0.0, length)
