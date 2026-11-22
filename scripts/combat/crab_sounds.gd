class_name CrabSounds
extends Node3D
## What a fog-crab sounds like, so a fight can be read by ear as well as by
## eye: its claws rattle faster and faster as it rears up (the tell), there's
## a rush as it lunges, and a soft chime when its fog clears. After that its
## legs tick quietly as it wanders off.
##
## A child of the [FogCrab]. Each sound is a child [AudioStreamPlayer3D]
## (heard from where the crab is, quieter with distance) whose stream is an
## [AudioStreamRandomizer] in [code]assets/audio/combat/[/code].

## One clack of its claws or tick of its legs.
const CLICK: StringName = &"Click"
## The rush of its lunge.
const LUNGE: StringName = &"Lunge"
## The chime of its fog clearing.
const CLEAR: StringName = &"Clear"

## Seconds between claw clacks as the windup starts, and as it ends: the
## rattle speeds up, so you can hear the attack coming.
@export var rattle_gap_start: float = 0.2
@export var rattle_gap_end: float = 0.06
## Seconds between leg ticks as it wanders, once cleared.
@export var scuttle_gap: float = 0.28
## How much quieter its wandering is than its rattle, in decibels.
@export var scuttle_quieter_db: float = 12.0

## How many times each sound has played, by name.
var _played: Dictionary[StringName, int] = {}
## Seconds since the last click.
var _since_click: float = 0.0
## The click's loudness as set in the scene.
var _click_db: float = 0.0

@onready var _crab: FogCrab = get_parent() as FogCrab
@onready var _click: AudioStreamPlayer3D = $Click


func _ready() -> void:
	_click_db = _click.volume_db
	_crab.cycle.attacked.connect(play.bind(LUNGE))
	_crab.fog_cleared.connect(play.bind(CLEAR))


func _physics_process(delta: float) -> void:
	_since_click += delta
	var gap: float = click_gap()
	if gap > 0.0 and _since_click >= gap:
		_since_click = 0.0
		_click.volume_db = _click_db - (scuttle_quieter_db if _crab.is_cleared() else 0.0)
		play(CLICK)


## Seconds to leave between clicks right now, or 0 for no clicking: a
## quickening rattle while it rears up, a slow tick while it wanders.
func click_gap() -> float:
	if _crab.cycle.state == CrabCycle.State.WINDUP:
		return lerpf(rattle_gap_start, rattle_gap_end, _crab.cycle.progress)
	if _crab.is_cleared() and Vector2(_crab.velocity.x, _crab.velocity.z).length() > 0.1:
		return scuttle_gap
	return 0.0


## Plays the sound called [param sound] (one of the names above), from the start.
func play(sound: StringName) -> void:
	var player: AudioStreamPlayer3D = get_node_or_null(NodePath(sound)) as AudioStreamPlayer3D
	if player == null:
		push_error("CrabSounds: no sound called %s" % sound)
		return
	_played[sound] = times_played(sound) + 1
	player.play()


## How many times the sound called [param sound] has played.
func times_played(sound: StringName) -> int:
	return _played.get(sound, 0)
