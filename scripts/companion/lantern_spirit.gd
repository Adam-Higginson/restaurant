class_name LanternSpirit
extends Node3D
## The lantern spirit: a small floating lantern with eyes who pulled you from
## the sea and now never leaves your side. He floats by your shoulder with a
## lazy bob, lighting the way; when you stop at something for a moment he
## drifts over to hover above it, curious; he blinks now and then.
##
## He lives in the world, not on the player (he's top-level), so he lags a
## little behind when you walk off and catches up. Whatever you stand on
## (the sailing ship) carries him along too, so he never trails behind the
## ship as it sails.

## Emitted when he settles on something new to look at, or null when he
## comes back to you.
signal attention_changed(target: Node3D)

## Where he floats relative to the player, in metres: to the right, up, and
## behind (along the way the player faces).
@export var follow_offset: Vector3 = Vector3(0.55, 1.7, 0.45)
## How hard he's pulled towards where he wants to be.
@export var stiffness: float = 16.0
## How quickly his drifting settles (higher is less floaty).
@export var damping: float = 7.5
## How far he bobs up and down, in metres, and how often, per second.
@export var bob_height: float = 0.07
@export var bob_rate: float = 0.6
## How far above something he hovers when he goes to look at it, in metres.
@export var hover_height: float = 1.45
## How long you must face something before he goes to look at it, in seconds,
## so he doesn't dart about as you walk past things.
@export var dwell_seconds: float = 0.6
## If he's ever further than this from you (say, after you're moved), he
## simply reappears by your side.
@export var leash: float = 6.0
## The shortest and longest wait between blinks, in seconds.
@export var blink_min: float = 2.5
@export var blink_max: float = 6.0
## How long a blink takes, in seconds.
@export var blink_seconds: float = 0.14

## The player he follows. Set by the scene (he's in the player's scene).
@export var player: Player3D
## The player's interaction detector, which tells him what you're facing.
@export var detector: InteractionDetector3D

## What he's looking at now (hovering over), or null when he's with you.
var attention: Node3D:
	get:
		return _attention

var _attention: Node3D = null
var _candidate: Node3D = null
var _candidate_time: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
## Where he is, before his bob is added.
var _spot: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _blink_wait: float = 0.0
var _blink_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _body: Node3D = $Body
@onready var _eyes: Node3D = $Body/Eyes
@onready var _light: Flicker = $Light


func _ready() -> void:
	top_level = true
	_rng.randomize()
	_blink_wait = _rng.randf_range(blink_min, blink_max)
	if is_instance_valid(detector):
		detector.focus_changed.connect(_on_focus_changed)
	# He's a child of the player, so he's ready before the player is: wait
	# until the player has its model before finding its shoulder.
	snap_to_player.call_deferred()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_time += delta
	_notice(delta)
	# Ride along with whatever the player stands on, then drift towards where
	# he wants to be.
	_spot += player.get_platform_velocity() * delta
	var goal: Vector3 = goal_spot()
	if _spot.distance_to(goal) > leash:
		snap_to_player()
		return
	var pull: Vector3 = (goal - _spot) * stiffness - _velocity * damping
	_velocity += pull * delta
	_spot += _velocity * delta
	global_position = _spot + Vector3.UP * bob_offset(_time)
	_face(delta)


func _process(delta: float) -> void:
	_blink(delta)


## Puts him straight back by the player's shoulder, at rest.
func snap_to_player() -> void:
	if not is_instance_valid(player):
		return
	_velocity = Vector3.ZERO
	_spot = goal_spot()
	global_position = _spot
	reset_physics_interpolation()


## Blinks once, now.
func blink() -> void:
	_blink_left = blink_seconds


## Where he wants to be now: hovering over what he's looking at, or by the
## player's shoulder.
func goal_spot() -> Vector3:
	if is_instance_valid(_attention):
		var toward_player: Vector3 = player.global_position - _attention.global_position
		toward_player.y = 0.0
		var lean: Vector3 = toward_player.normalized() * 0.35 if toward_player.length() > 0.01 \
				else Vector3.ZERO
		return _attention.global_position + Vector3.UP * hover_height + lean
	return follow_spot(player.global_position, player.facing, follow_offset)


## The spot by the shoulder of a player at [param player_position] facing
## [param facing], [param offset] metres to the right, up and behind.
static func follow_spot(player_position: Vector3, facing: Vector3, offset: Vector3) -> Vector3:
	var forward: Vector3 = Vector3(facing.x, 0.0, facing.z)
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var right: Vector3 = forward.cross(Vector3.UP)
	return player_position + right * offset.x + Vector3.UP * offset.y - forward * offset.z


## How far up or down his bob has taken him at [param time] seconds.
func bob_offset(time: float) -> float:
	return sin(time * TAU * bob_rate) * bob_height


# Decides whether to go and look at what the player's facing: only once
# they've faced it for a moment.
func _notice(delta: float) -> void:
	if _candidate == _attention:
		return
	if _candidate == null:
		_set_attention(null)
		return
	_candidate_time += delta
	if _candidate_time >= dwell_seconds:
		_set_attention(_candidate)


func _set_attention(target: Node3D) -> void:
	if target == _attention:
		return
	_attention = target
	# A little brighter when he's interested in something.
	if is_instance_valid(_light):
		_light.base_energy = 1.35 if target != null else 1.1
	attention_changed.emit(target)


func _on_focus_changed(interactable: Interactable3D) -> void:
	_candidate = interactable
	_candidate_time = 0.0


# Turns to look where he's going: at what he's interested in, or the way the
# player faces.
func _face(delta: float) -> void:
	var look: Vector3 = player.facing
	if is_instance_valid(_attention):
		look = _attention.global_position - global_position
	look.y = 0.0
	if look.length() < 0.01:
		return
	var yaw: float = atan2(-look.x, -look.z)
	_body.rotation.y = rotate_toward(_body.rotation.y, yaw, delta * 4.0)


func _blink(delta: float) -> void:
	if _blink_left > 0.0:
		_blink_left -= delta
		var t: float = clampf(_blink_left / blink_seconds, 0.0, 1.0)
		# Shut in the middle of the blink, open at either end.
		_eyes.scale.y = maxf(absf(t * 2.0 - 1.0), 0.1)
		return
	_eyes.scale.y = 1.0
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		blink()
		_blink_wait = _rng.randf_range(blink_min, blink_max)
