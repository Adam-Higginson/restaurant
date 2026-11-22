class_name DuelSounds
extends Node
## What the player's side of a duel sounds like. It only listens: the
## [Duellist] says what happened with its signals, and this plays the sound
## for it.
##
## Each sound is a child [AudioStreamPlayer] named after it, whose stream is
## an [AudioStreamRandomizer] in [code]assets/audio/combat/[/code]: a few
## recordings, one picked at random each time (never the same twice running)
## at a slightly different pitch, so a repeated sound doesn't feel stamped
## out. The recordings are Kenney's (CC0); their licences are beside them.

## The knife sweeping through the air, as a cut starts (each [KnifeCut]
## names its own swing sound; this is the plain one).
const SWING: StringName = &"Swing"
## The knife landing a strike that counts.
const SLICE: StringName = &"Slice"
## The knife glancing off a creature that isn't open.
const TINK: StringName = &"Tink"
## The pan going up.
const PAN_UP: StringName = &"PanUp"
## The pan turning a blow away.
const CLANG: StringName = &"Clang"
## A blow landing on the player.
const HURT: StringName = &"Hurt"
## The player's heart thumping while they're down to their last one: the
## punch recordings, an octave down.
const HEARTBEAT: StringName = &"Heartbeat"
## The cleave's swing: the plain swing's recordings, lower and heavier.
const SWING_HEAVY: StringName = &"SwingHeavy"
## The fillet's spin (and the weak one's): a swish of cloth, low.
const SPIN: StringName = &"Spin"
## A charge starting: a swish that rises in pitch as the charge fills.
const CHARGE: StringName = &"Charge"
## The charge full: a glassy glint.
const CHARGED: StringName = &"Charged"
## A dodge taking off: belt and cloth.
const DODGE: StringName = &"Dodge"
## A dodge landing: a footstep.
const LAND: StringName = &"Land"

## Seconds from one heartbeat to the next.
@export var heartbeat_seconds: float = 0.9
## Seconds between the two thumps of a beat ("lub" and "dub").
@export var heartbeat_gap: float = 0.22
## The charge's pitch as it starts, and when it's full.
@export var charge_pitch_start: float = 0.8
@export var charge_pitch_full: float = 1.5

## How many times each sound has played, by name.
var _played: Dictionary[StringName, int] = {}
## Seconds into the current heartbeat, or below 0 while the heart is calm.
var _beat_time: float = -1.0
## Whether the player was mid-dodge last frame, to hear them land.
var _was_dodging: bool = false

@onready var _duellist: Duellist = $"../Duellist"
@onready var _player: Player3D = get_parent() as Player3D
@onready var _charge: AudioStreamPlayer = get_node_or_null(NodePath(CHARGE)) as AudioStreamPlayer


func _ready() -> void:
	_duellist.combo.charge_started.connect(play.bind(CHARGE))
	_duellist.combo.charge_filled.connect(play.bind(CHARGED))
	_duellist.combo.charge_cancelled.connect(_stop_charge)
	_player.dodged.connect(func(_move: DodgeMove) -> void: play(DODGE))
	_duellist.cut_started.connect(func(cut: KnifeCut) -> void: play(cut.sound))
	_duellist.struck.connect(_on_struck)
	_duellist.glanced.connect(play.bind(TINK))
	_duellist.pan_raised.connect(play.bind(PAN_UP))
	_duellist.parried.connect(play.bind(CLANG))
	_duellist.hurt.connect(_on_hurt)


func _process(delta: float) -> void:
	_beat(delta)
	if _charge != null and _duellist.is_charging():
		_charge.pitch_scale = lerpf(charge_pitch_start, charge_pitch_full,
				_duellist.combo.charge())
	if _was_dodging and not _player.is_dodging():
		play(LAND)
	_was_dodging = _player.is_dodging()


## Plays the sound called [param sound] (one of the names above), from the start.
func play(sound: StringName) -> void:
	var player: AudioStreamPlayer = get_node_or_null(NodePath(sound)) as AudioStreamPlayer
	if player == null:
		push_error("DuelSounds: no sound called %s" % sound)
		return
	_played[sound] = times_played(sound) + 1
	player.play()


## How many times the sound called [param sound] has played.
func times_played(sound: StringName) -> int:
	return _played.get(sound, 0)


func _on_struck(hit: bool) -> void:
	if hit:
		play(SLICE)


func _on_hurt(_halves: int) -> void:
	play(HURT)


func _stop_charge() -> void:
	if _charge != null:
		_charge.stop()


# Thumps "lub-dub" once a beat while the player is on their last heart.
func _beat(delta: float) -> void:
	if not _duellist.hearts.is_last_heart():
		_beat_time = -1.0
		return
	if _beat_time < 0.0:
		_beat_time = 0.0
		play(HEARTBEAT)
		return
	var before: float = _beat_time
	_beat_time += delta
	if before < heartbeat_gap and _beat_time >= heartbeat_gap:
		play(HEARTBEAT)
	if _beat_time >= heartbeat_seconds:
		_beat_time -= heartbeat_seconds
		play(HEARTBEAT)
