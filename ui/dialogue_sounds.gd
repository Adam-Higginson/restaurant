class_name DialogueSounds
extends Node
## The sounds of a conversation: a soft blip as each speaker's words type
## out (lower for a gruff voice, higher for a bright one), a click as you
## move on, a tick as the cursor moves, and a chime as you pick a reply.
##
## The clicks are recordings (Kenney's Interface Sounds, CC0). The blip is
## made here from a short fading tone, so every speaker can have their own
## pitch without a file each.

const ADVANCE: AudioStream = preload("res://assets/audio/ui/click_002.wav")
const MOVE: AudioStream = preload("res://assets/audio/ui/tick_001.wav")
const CHOOSE: AudioStream = preload("res://assets/audio/ui/confirmation_001.wav")
const CLOSE: AudioStream = preload("res://assets/audio/ui/close_001.wav")

## Samples a second in the blip.
const MIX_RATE: int = 22050
## The blip's note, in hertz, before a speaker's pitch is applied.
const BLIP_HERTZ: float = 520.0
## How long the blip lasts, in seconds.
const BLIP_SECONDS: float = 0.045

## How loud the blip and the clicks are, in decibels.
@export var blip_db: float = -16.0
@export var click_db: float = -10.0
## A blip sounds for every this-many letters, so fast text doesn't buzz.
@export var letters_per_blip: int = 2
## How far each blip's pitch wanders from the speaker's, as a fraction.
@export var pitch_wander: float = 0.06

## The pitch blips are playing at: the speaker's [member Person.voice_pitch].
var voice_pitch: float = 1.0

var _letters: int = 0
var _blip: AudioStreamPlayer = null
var _click: AudioStreamPlayer = null


func _ready() -> void:
	_blip = AudioStreamPlayer.new()
	_click = AudioStreamPlayer.new()
	_blip.stream = make_blip()
	_blip.volume_db = blip_db
	add_child(_blip)
	_click.volume_db = click_db
	add_child(_click)


## Listens to [param conversation] and [param box], and plays along.
func setup(conversation: Conversation, box: DialogueBox) -> void:
	box.letter_typed.connect(on_letter)
	conversation.line_said.connect(func(speaker: Person) -> void:
		voice_pitch = speaker.voice_pitch if speaker != null else 1.0
		_letters = 0)
	conversation.advanced.connect(_play.bind(ADVANCE))
	conversation.choice_moved.connect(_play.bind(MOVE))
	conversation.choice_made.connect(_play.bind(CHOOSE))
	conversation.ended.connect(func(_tree_id: StringName) -> void: _play(CLOSE))


## Blips for [param letter] as it's typed, if it's this letter's turn.
## Spaces are silent. Returns whether it blipped.
func on_letter(letter: String) -> bool:
	if letter.strip_edges().is_empty():
		return false
	_letters += 1
	if (_letters - 1) % maxi(letters_per_blip, 1) != 0:
		return false
	if _blip == null:
		return true
	_blip.pitch_scale = maxf(voice_pitch * randf_range(1.0 - pitch_wander, 1.0 + pitch_wander),
			0.05)
	_blip.play()
	return true


## The blip: a short tone with a little overtone that fades away quickly.
static func make_blip() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * BLIP_SECONDS)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		var time: float = float(i) / MIX_RATE
		var fade: float = pow(1.0 - float(i) / count, 2.0)
		var wave: float = sin(TAU * BLIP_HERTZ * time) + 0.3 * sin(TAU * BLIP_HERTZ * 2.0 * time)
		data.encode_s16(i * 2, int(clampf(wave * fade * 0.6, -1.0, 1.0) * 32767.0))
	var blip: AudioStreamWAV = AudioStreamWAV.new()
	blip.format = AudioStreamWAV.FORMAT_16_BITS
	blip.mix_rate = MIX_RATE
	blip.data = data
	return blip


func _play(sound: AudioStream) -> void:
	if _click == null:
		return
	_click.stream = sound
	_click.play()
