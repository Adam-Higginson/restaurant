class_name CrabSounds
extends Node3D
## What a crab sounds like, so a fight can be read by ear as well as by eye:
## its claws rattle faster and faster as it rears up (the tell), and there's
## a rush as it lunges. Flipped, it lands on its back with a thud, and its
## legs clatter frantically until it's up again. Killed, its shell cracks
## and it thuds over.
##
## A child of the [Crab]. Each sound is a child [AudioStreamPlayer3D]
## (heard from where the crab is, quieter with distance) whose stream is an
## [AudioStreamRandomizer] in [code]assets/audio/combat/[/code].

## One clack of its claws or clatter of its legs.
const CLICK: StringName = &"Click"
## The rush of its lunge.
const LUNGE: StringName = &"Lunge"
## Its shell cracking as it dies: its clacks, deep.
const CRACK: StringName = &"Crack"
## The thud of landing on its back.
const FLIP: StringName = &"Flip"

## Seconds between claw clacks as the windup starts, and as it ends: the
## rattle speeds up, so you can hear the attack coming.
@export var rattle_gap_start: float = 0.2
@export var rattle_gap_end: float = 0.06
## Seconds between clatters of its legs while it's on its back.
@export var flail_gap: float = 0.09

## How many times each sound has played, by name.
var _played: Dictionary[StringName, int] = {}
## Seconds since the last click.
var _since_click: float = 0.0

@onready var _crab: Crab = get_parent() as Crab


func _ready() -> void:
	_crab.cycle.attacked.connect(play.bind(LUNGE))
	_crab.flipped.connect(play.bind(FLIP))
	_crab.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	_since_click += delta
	var gap: float = click_gap()
	if gap > 0.0 and _since_click >= gap:
		_since_click = 0.0
		play(CLICK)


## Seconds to leave between clicks right now, or 0 for no clicking: a
## quickening rattle while it rears up, a frantic clatter on its back.
func click_gap() -> float:
	if _crab.cycle.state == CrabCycle.State.WINDUP:
		return lerpf(rattle_gap_start, rattle_gap_end, _crab.cycle.progress)
	if _crab.is_flipped():
		return flail_gap
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


func _on_died() -> void:
	play(CRACK)
	play(FLIP)
