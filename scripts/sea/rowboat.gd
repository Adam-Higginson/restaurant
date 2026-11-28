class_name Rowboat
extends Node3D
## A small rowing boat you row yourself (#226): forward on the stick rows,
## left and right turn. Each stroke surges the boat on, then it glides.
##
## It isn't a physics body: a script moves it every physics tick, so it goes
## where you steer and can never capsize. Its height and tilt come from the
## sea: the waves are sampled at the bow, the stern and either side, and the
## boat sits on them, pitching and rolling with the swell (never more than
## [member max_tilt_degrees]).
##
## A [SeaCurrent] can take it over. As the current's [code]takeover[/code]
## rises, the water carries the boat along and your strokes and turns count
## for less; at full takeover the oars still move but do nothing.

## Emitted at the start of each stroke's drive, when the blades bite.
signal stroked

## The current that can carry the boat away. Optional.
@export var current: SeaCurrent
## Whether the stick rows it. Off, it drifts and glides.
@export var controls_enabled: bool = true

@export_group("Rowing")
## How hard a stroke pushes at its peak, in metres per second per second.
@export var stroke_power: float = 5.0
## Seconds per stroke, catch to catch.
@export var stroke_seconds: float = 1.3
## The share of each stroke spent pulling (the drive); the rest is the
## recovery, when the blades come back through the air.
@export_range(0.1, 0.9) var drive_share: float = 0.45
## How hard backing water pushes astern, as a share of a forward stroke.
@export_range(0.0, 1.0) var backing_share: float = 0.4
## How much the water slows the boat going forward, per second. Low: it glides.
@export var forward_drag: float = 0.45
## How much the water stops it sliding sideways, per second. High, like a keel.
@export var side_drag: float = 3.0

@export_group("Turning")
## How fast it turns with the stick hard over, in degrees per second.
@export var turn_speed: float = 40.0
## How quickly it starts and stops turning: higher is snappier.
@export var turn_response: float = 2.0
## How fast the current swings the bow round to run with it at full
## takeover, in degrees per second.
@export var current_turn_speed: float = 12.0

@export_group("Riding the sea")
## Half the boat's length and beam, in metres: where the waves are sampled.
@export var half_size: Vector2 = Vector2(0.7, 1.6)
## How far above the sea's surface the boat's origin sits, in metres.
@export var float_height: float = 0.0
## The most it pitches or rolls, in degrees.
@export var max_tilt_degrees: float = 12.0

@export_group("Oars")
## How far the oars sweep fore and aft of square, in degrees.
@export var oar_sweep_degrees: float = 32.0
## How far the blades dip into the water on the drive, in degrees.
@export var oar_dip_degrees: float = 9.0

## How fast the boat is moving over the ground, as x and z in metres per second.
var velocity: Vector2 = Vector2.ZERO
## Which way the bow points: radians about Y, 0 facing -Z.
var heading: float = 0.0

var _turn_rate: float = 0.0
var _stroke_phase: float = 0.0
var _stroking: bool = false
var _sea: Sea = null

@onready var _oar_port: Node3D = $OarPort
@onready var _oar_starboard: Node3D = $OarStarboard


func _ready() -> void:
	heading = rotation.y


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Forward on the stick is up, which get_vector gives as negative y.
	row(-input.y, input.x, delta)
	ride()
	_pose_oars()


## One tick of rowing: [param pull] from -1 (backing water) to 1 (rowing
## ahead), [param turn] from -1 (port) to 1 (starboard). Moves the boat over
## the water; [method ride] then sets its height and tilt.
func row(pull: float, turn: float, delta: float) -> void:
	var share: float = own_share()
	_advance_stroke(pull, delta)

	var forward: Vector2 = forward_of(heading)
	var thrust: float = stroke_push(_stroke_phase, drive_share) * stroke_power * share
	if _stroking:
		thrust *= pull if pull > 0.0 else pull * backing_share
	else:
		thrust = 0.0
	velocity += forward * thrust * delta

	# The water drags the boat towards moving with it: slowly ahead, hard
	# sideways.
	var water: Vector2 = current.flow() if current != null else Vector2.ZERO
	var through_water: Vector2 = velocity - water
	var right: Vector2 = right_of(heading)
	var ahead: float = through_water.dot(forward) * exp(-forward_drag * delta)
	var across: float = through_water.dot(right) * exp(-side_drag * delta)
	velocity = water + forward * ahead + right * across

	var wanted_turn: float = -turn * deg_to_rad(turn_speed) * share
	_turn_rate = lerpf(_turn_rate, wanted_turn, 1.0 - exp(-turn_response * delta))
	heading += _turn_rate * delta
	if current != null and current.takeover > 0.0 and water.length() > 0.0:
		var towards: float = atan2(-water.x, -water.y)
		var swing: float = deg_to_rad(current_turn_speed) * current.takeover * delta
		heading = rotate_toward(heading, towards, swing)

	position += Vector3(velocity.x, 0.0, velocity.y) * delta


## Sets the boat's height and tilt from the sea under it. Without a sea it
## stays level at its height.
func ride() -> void:
	var sea: Sea = _find_sea()
	if sea == null:
		basis = Basis.from_euler(Vector3(0.0, heading, 0.0))
		return
	var forward: Vector2 = forward_of(heading)
	var right: Vector2 = right_of(heading)
	var here: Vector2 = Vector2(global_position.x, global_position.z)
	var bow: float = _surface(sea, here + forward * half_size.y)
	var stern: float = _surface(sea, here - forward * half_size.y)
	var port: float = _surface(sea, here - right * half_size.x)
	var starboard: float = _surface(sea, here + right * half_size.x)
	global_position.y = (bow + stern + port + starboard) / 4.0 + float_height
	var tilt: Vector2 = tilt_from_heights(bow, stern, port, starboard, half_size,
			deg_to_rad(max_tilt_degrees))
	basis = Basis.from_euler(Vector3(tilt.x, heading, tilt.y))


## How much of the steering is still yours, 0 to 1: everything the current
## hasn't taken.
func own_share() -> float:
	return 1.0 - current.takeover if current != null else 1.0


## Where the oars are in their stroke, 0 to 1: 0 is the catch (blades in,
## forward), [member drive_share] is the end of the drive.
func stroke_phase() -> float:
	return _stroke_phase


## Whether the oars are working (rowing, or finishing a stroke).
func is_stroking() -> bool:
	return _stroking or _stroke_phase > 0.0


## The flat direction the bow points for [param yaw], as x and z.
static func forward_of(yaw: float) -> Vector2:
	return Vector2(-sin(yaw), -cos(yaw))


## The flat direction of the boat's starboard side for [param yaw], as x and z.
static func right_of(yaw: float) -> Vector2:
	return Vector2(cos(yaw), -sin(yaw))


## How hard a stroke pushes at [param phase] (0 to 1 through the stroke), 0
## to 1: a smooth surge through the drive, nothing on the recovery.
static func stroke_push(phase: float, drive: float) -> float:
	if phase <= 0.0 or phase >= drive:
		return 0.0
	return sin(PI * phase / drive)


## The pitch and roll, in radians, for a boat whose bow, stern, port and
## starboard sit at these sea heights, [param half] (half its beam and length)
## apart, each limited to [param max_tilt]. Positive pitch lifts the bow;
## positive roll lifts the starboard side.
static func tilt_from_heights(bow: float, stern: float, port: float, starboard: float,
		half: Vector2, max_tilt: float) -> Vector2:
	var pitch: float = atan2(bow - stern, half.y * 2.0)
	var roll: float = atan2(starboard - port, half.x * 2.0)
	return Vector2(clampf(pitch, -max_tilt, max_tilt), clampf(roll, -max_tilt, max_tilt))


# Moves the stroke on while rowing. Letting go finishes the stroke under way,
# so the oars come back to rest rather than freezing mid-air.
func _advance_stroke(pull: float, delta: float) -> void:
	var rowing: bool = absf(pull) > 0.1
	if not rowing and _stroke_phase <= 0.0:
		_stroking = false
		return
	var was: float = _stroke_phase
	_stroke_phase += delta / stroke_seconds
	if _stroke_phase >= 1.0:
		_stroke_phase = fmod(_stroke_phase, 1.0) if rowing else 0.0
	if rowing and (was <= 0.0 or _stroke_phase < was):
		stroked.emit()
	_stroking = rowing


# Swings the oars through the stroke: aft through the water on the drive,
# forward through the air on the recovery.
func _pose_oars() -> void:
	var sweep: float = deg_to_rad(oar_sweep_degrees)
	var angle: float = 0.0
	var dip: float = 0.0
	if is_stroking():
		if _stroke_phase < drive_share:
			var t: float = _stroke_phase / drive_share
			angle = lerpf(sweep, -sweep, t)
			dip = deg_to_rad(oar_dip_degrees) * sin(PI * t)
		else:
			var t: float = (_stroke_phase - drive_share) / (1.0 - drive_share)
			angle = lerpf(-sweep, sweep, t)
			dip = -deg_to_rad(oar_dip_degrees) * 0.5 * sin(PI * t)
	# The starboard oar reaches out along +X, the port oar along -X, so the
	# same stroke is mirrored between them.
	_oar_starboard.rotation = Vector3(0.0, angle, -dip)
	_oar_port.rotation = Vector3(0.0, -angle, dip)


func _surface(sea: Sea, spot: Vector2) -> float:
	return sea.global_position.y + sea.height_at(spot)


func _find_sea() -> Sea:
	if not is_instance_valid(_sea):
		_sea = get_tree().get_first_node_in_group(&"sea") as Sea
	return _sea
