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

## What his light is saying about a fight. See [method set_mood].
enum Mood {
	## Nothing to say: his usual glow.
	CALM,
	## Flickering hard: something is about to strike.
	WARNING,
	## Bright and steady: there's an opening.
	OPEN,
}

## A marker in this group is his home: he stays there instead of following.
const HOME_GROUP: StringName = &"lantern_home"

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

## How much warmth he loses a minute, 0 to 1. A warm meal shared with him
## brings it back (see [SupperSpot]).
@export var warmth_per_minute: float = 0.025
## The least warmth he fades to: dim, but never out.
@export var min_warmth: float = 0.25

## How near you must be for him to see what you do and say something about
## it, in metres, when he's at home rather than at your shoulder.
@export var earshot: float = 8.0

## The player he follows. Set by the scene (he's in the player's scene).
@export var player: Player3D
## The player's interaction detector, which tells him what you're facing.
@export var detector: InteractionDetector3D

## What he's looking at now (hovering over), or null when he's with you.
var attention: Node3D:
	get:
		return _attention

## How warm and bright he is, 0 to 1: it fades slowly, and a shared meal
## rekindles him. His light's brightness and reach follow it.
var warmth: float = 1.0:
	set(value):
		warmth = clampf(value, min_warmth, 1.0)
		if warmth > 0.45:
			_said_dim = false

## What his light is saying about a fight (see [method set_mood]).
var mood: Mood:
	get:
		return _mood

## Where he lives, if anywhere: he hovers there rather than following you,
## and you go to him. Found by [constant HOME_GROUP] when the scene starts.
var home: Node3D = null

var _attention: Node3D = null
## What he's been sent to hover over in a fight (the lock-on target), or null.
var _watched: Node3D = null
var _mood: Mood = Mood.CALM
## His light's usual waver, kept so a fight can change it and put it back.
var _calm_amount: float = 0.0
var _calm_speed: float = 0.0
## Whether he's been told to leave home and follow, so he doesn't look for
## a home again.
var _left_home: bool = false
## Where his home was last tick, so he rides along as the ship carries it.
var _home_was: Vector3 = Vector3.ZERO
## Somewhere he's been asked to go for a moment (a meal on a table).
var _visit: Node3D = null
var _visit_left: float = 0.0
var _said_dim: bool = false
var _candidate: Node3D = null
var _candidate_time: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
## Where he is, before his bob is added.
var _spot: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _blink_wait: float = 0.0
var _blink_left: float = 0.0
## Seconds left of an excited little dance.
var _excited: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _body: Node3D = $Body
@onready var _eyes: Node3D = $Body/Eyes
@onready var _light: Flicker = $Light
@onready var _voice: LanternVoice = $Voice
@onready var _hum: Hum = $Hum


func _ready() -> void:
	top_level = true
	_rng.randomize()
	_blink_wait = _rng.randf_range(blink_min, blink_max)
	_calm_amount = _light.amount
	_calm_speed = _light.speed
	if is_instance_valid(detector):
		detector.focus_changed.connect(_on_focus_changed)
	Game.memories.remembered.connect(func(_memory: Memory) -> void:
		if is_in_earshot():
			hum()
		tell(LanternLines.pick(LanternLines.REMEMBERED), &"news_memory"))
	# He's a child of the player, so he's ready before the player is: wait
	# until the player has its model before finding its shoulder.
	_settle.call_deferred()


func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	_time += delta
	_notice(delta)
	_cool(delta)
	_visit_left = maxf(_visit_left - delta, 0.0)
	# Ride along with whatever carries him (his home, or what the player
	# stands on), then drift towards where he wants to be.
	if is_instance_valid(home):
		_spot += home.global_position - _home_was
		_home_was = home.global_position
	else:
		_spot += player.get_platform_velocity() * delta
	var goal: Vector3 = goal_spot()
	if _spot.distance_to(goal) > leash:
		snap_to_player()
		return
	var pull: Vector3 = (goal - _spot) * stiffness - _velocity * damping
	_velocity += pull * delta
	_spot += _velocity * delta
	_excited = maxf(_excited - delta, 0.0)
	var hop: float = absf(sin(_time * 14.0)) * 0.14 * minf(_excited, 1.0)
	global_position = _spot + Vector3.UP * (bob_offset(_time) + hop)
	_face(delta)


func _process(delta: float) -> void:
	_blink(delta)


## Puts him straight back where he belongs, at rest: at home if he has one,
## otherwise by the player's shoulder.
func snap_to_player() -> void:
	if not is_instance_valid(player):
		return
	_velocity = Vector3.ZERO
	if is_instance_valid(home):
		_home_was = home.global_position
	_spot = goal_spot()
	global_position = _spot
	reset_physics_interpolation()


## Warms him back up by [param amount] (0 to 1): a meal shared with him.
func rekindle(amount: float) -> void:
	warmth += amount
	_apply_warmth()


## Goes to hover just over [param place] for [param seconds] (to eat
## something set down there), then comes back.
func visit(place: Node3D, seconds: float) -> void:
	_visit = place
	_visit_left = seconds


## Whether he's off visiting somewhere just now.
func is_visiting() -> bool:
	return _visit_left > 0.0 and is_instance_valid(_visit)


## Sends him to hover over [param target] and watch it (what the player is
## locked on to), or with null, calls him back. At home he stays put.
func watch(target: Node3D) -> void:
	_watched = target


## What he's been sent to watch, or null.
func watching() -> Node3D:
	return _watched if is_instance_valid(_watched) else null


## Makes his light say something about a fight: flickering hard as a
## warning, bright and steady for an opening, or back to his usual glow.
func set_mood(value: Mood) -> void:
	_mood = value
	_apply_warmth()


## Leaves home to follow at the player's shoulder, as he used to, and
## doesn't go back.
func leave_home() -> void:
	_left_home = true
	home = null
	snap_to_player()


## Whether he's near enough to see what you're doing: always, at your
## shoulder; within [member earshot] of you, at home.
func is_in_earshot() -> bool:
	if not is_instance_valid(home) or not is_instance_valid(player):
		return true
	return global_position.distance_to(player.global_position) <= earshot


## Says [param line] if he's near enough to have seen what it's about.
## Otherwise he missed it, and [param news] (if given) is flagged so he can
## bring it up when you next talk to him. Returns whether he said it.
func tell(line: String, news: StringName = &"") -> bool:
	if is_in_earshot():
		say(line)
		return true
	if news != &"":
		Game.dialogue.set_flag(news)
	return false


## Says [param line], in a few words floating beside him, with a hop.
func say(line: String) -> void:
	if line.is_empty():
		return
	_voice.say(line)
	excite()


## Hums the memory melody, the few notes of it you have so far.
func hum() -> void:
	_hum.hum()


## Whether he's humming right now.
func is_humming() -> bool:
	return _hum.is_humming


## What he's saying now, or "" when he's quiet.
func saying() -> String:
	return _voice.saying


## Hops about excitedly for a moment, a little brighter: something's
## happening (a fish on the line).
func excite() -> void:
	_excited = 1.6
	blink()
	if is_instance_valid(_light):
		_light.base_energy = 1.7


## Whether he's in the middle of an excited hop.
func is_excited() -> bool:
	return _excited > 0.0


## Blinks once, now.
func blink() -> void:
	_blink_left = blink_seconds


## Where he wants to be now: at home if he has one; otherwise hovering over
## what he's looking at, or by the player's shoulder.
func goal_spot() -> Vector3:
	if _visit_left > 0.0 and is_instance_valid(_visit):
		return _visit.global_position + Vector3.UP * 0.45
	if is_instance_valid(home):
		return home.global_position
	if is_instance_valid(_watched):
		return _hover_over(_watched)
	if is_instance_valid(_attention):
		return _hover_over(_attention)
	return follow_spot(player.global_position, player.facing, follow_offset)


## The spot by the shoulder of a player at [param player_position] facing
## [param facing], [param offset] metres to the right, up and behind.
static func follow_spot(player_position: Vector3, facing: Vector3, offset: Vector3) -> Vector3:
	var forward: Vector3 = Vector3(facing.x, 0.0, facing.z)
	forward = forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD
	var right: Vector3 = forward.cross(Vector3.UP)
	return player_position + right * offset.x + Vector3.UP * offset.y - forward * offset.z


# The spot just above [param what], leaning a little towards the player.
func _hover_over(what: Node3D) -> Vector3:
	var toward_player: Vector3 = player.global_position - what.global_position
	toward_player.y = 0.0
	var lean: Vector3 = toward_player.normalized() * 0.35 if toward_player.length() > 0.01 \
			else Vector3.ZERO
	return what.global_position + Vector3.UP * hover_height + lean


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


# Fades a little, and lets you know when he's getting low.
func _cool(delta: float) -> void:
	warmth -= warmth_per_minute * delta / 60.0
	_apply_warmth()
	if warmth < 0.4 and not _said_dim:
		_said_dim = true
		tell(LanternLines.pick(LanternLines.DIM))


# His light follows his warmth: dimmer and closer in when he's cold.
func _apply_warmth() -> void:
	if not is_instance_valid(_light):
		return
	_light.omni_range = lerpf(2.4, 4.5, warmth)
	var bright: float = 1.35 if _attention != null else 1.1
	_light.amount = _calm_amount
	_light.speed = _calm_speed
	match _mood:
		Mood.WARNING:
			_light.amount = 0.9
			_light.speed = 26.0
		Mood.OPEN:
			bright = 2.6
	# A fight's signal matters more than an excited hop's extra glow.
	if _excited <= 0.0 or _mood != Mood.CALM:
		_light.base_energy = bright * lerpf(0.4, 1.0, warmth)


# Finds his home, if the scene has one, and goes to where he belongs.
func _settle() -> void:
	if is_inside_tree() and not _left_home:
		home = get_tree().get_first_node_in_group(HOME_GROUP) as Node3D
	snap_to_player()


func _set_attention(target: Node3D) -> void:
	if target == _attention:
		return
	_attention = target
	# A little brighter when he's interested in something.
	_apply_warmth()
	attention_changed.emit(target)


func _on_focus_changed(interactable: Interactable3D) -> void:
	_candidate = interactable
	_candidate_time = 0.0


# Turns to look where he's going: at what he's interested in, or the way the
# player faces.
func _face(delta: float) -> void:
	var look: Vector3 = player.facing
	if is_instance_valid(home):
		# At home he watches you, when you're near enough to watch.
		if not is_in_earshot():
			return
		look = player.global_position - global_position
	elif is_instance_valid(_watched):
		look = _watched.global_position - global_position
	elif is_instance_valid(_attention):
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
