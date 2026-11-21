class_name Ship
extends AnimatableBody3D
## The crew's ship. It sails along [member route] at [member speed], facing
## the way it's going, and stops at the route's end (the mooring point).
##
## The hull rocks gently on the waves, but only the [code]Visuals[/code] child
## rocks. The body and its collision shapes stay level, so anything standing
## on deck never slides about.

## Emitted once, when the ship reaches the end of its route and stops.
signal moored

## How far ahead and behind (in metres along the route) the ship looks to
## work out which way it's facing.
const LOOK_STEP: float = 0.5

## The path to sail along. The ship snaps to its start when it's ready.
@export var route: Path3D
## Sailing speed in metres per second.
@export var speed: float = 3.0
## Whether to set sail as soon as the scene starts.
@export var sail_on_ready: bool = true
## How far the hull rolls to each side, in degrees.
@export var rock_degrees: float = 1.5
## Seconds for one full roll, side to side and back.
@export var rock_period: float = 4.0

## Whether the ship is under way. False before it sets sail and once moored.
var is_sailing: bool:
	get:
		return _sailing

var _sailing: bool = false
## How far along the route the ship has come, in metres.
var _distance: float = 0.0
## Seconds since the scene started, for the rocking wave.
var _time: float = 0.0

@onready var _visuals: Node3D = $Visuals


func _ready() -> void:
	if _has_route():
		global_transform = _transform_at(0.0)
	if sail_on_ready:
		set_sail()


func _process(delta: float) -> void:
	_time += delta
	_visuals.rotation.z = deg_to_rad(_rock_angle(_time))


func _physics_process(delta: float) -> void:
	if not _sailing or speed <= 0.0:
		return
	var length: float = route.curve.get_baked_length()
	# Clamp, so a long frame stops the ship at the end rather than past it.
	_distance = minf(_distance + speed * delta, length)
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


# The hull's roll in degrees at [param time]: a sine wave that swings
# between -rock_degrees and +rock_degrees once every rock_period seconds.
func _rock_angle(time: float) -> float:
	if rock_period <= 0.0:
		return 0.0
	return rock_degrees * sin(TAU * time / rock_period)


func _has_route() -> bool:
	return route != null and route.curve != null and route.curve.point_count >= 2 \
			and route.curve.get_baked_length() > 0.0


# Where the ship stands [param distance] metres along the route, in world
# space, turned to face along the route and kept level.
func _transform_at(distance: float) -> Transform3D:
	var curve: Curve3D = route.curve
	var length: float = curve.get_baked_length()
	var behind: Vector3 = route.to_global(curve.sample_baked(maxf(distance - LOOK_STEP, 0.0)))
	var ahead: Vector3 = route.to_global(curve.sample_baked(minf(distance + LOOK_STEP, length)))
	var heading: Vector3 = ahead - behind
	# Ignore any climb or dip in the route, so the deck never tilts.
	heading.y = 0.0
	var basis_now: Basis = global_basis
	if not heading.is_zero_approx():
		basis_now = Basis.looking_at(heading, Vector3.UP)
	return Transform3D(basis_now, route.to_global(curve.sample_baked(distance)))
