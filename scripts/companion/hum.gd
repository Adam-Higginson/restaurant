class_name Hum
extends AudioStreamPlayer3D
## The lantern humming the memory melody: a few notes of a song from home
## (see Music in the GDD), soft and breathy, made on the fly with no
## recording, so it's always there. A sine with a little overtone, a gentle
## swell in and out on each note, and a slight waver, like someone humming
## under their breath.

## The memory melody so far, as MIDI note numbers: three notes, for now.
const MELODY: PackedInt32Array = [69, 72, 71]
## How long each note lasts, in seconds (the last one lingers).
const LENGTHS: PackedFloat32Array = [0.55, 0.55, 1.3]
## Samples a second. Low is fine for a hum, and cheap.
const MIX_RATE: float = 22050.0

## How loud the hum is, 0 to 1.
@export_range(0.0, 1.0) var loudness: float = 0.22

## Whether he's humming right now.
var is_humming: bool:
	get:
		return _time < melody_seconds()

var _time: float = INF
var _playback: AudioStreamGeneratorPlayback = null
## Seconds into the melody of the next sample to make.
var _sample_clock: float = 0.0


func _ready() -> void:
	var generator: AudioStreamGenerator = AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = 0.3
	stream = generator
	unit_size = 3.0


func _process(delta: float) -> void:
	if not is_humming:
		return
	_fill()
	_time += delta
	if not is_humming:
		stop()
		_playback = null


## Hums the memory melody, from the start.
func hum() -> void:
	_time = 0.0
	play()
	_playback = get_stream_playback() as AudioStreamGeneratorPlayback
	_sample_clock = 0.0


## How long the melody takes, in seconds.
static func melody_seconds() -> float:
	var total: float = 0.0
	for length: float in LENGTHS:
		total += length
	return total


## The frequency of MIDI note [param note], in hertz (69 is the A at 440).
static func pitch(note: int) -> float:
	return 440.0 * pow(2.0, float(note - 69) / 12.0)


## Which note is sounding [param t] seconds into the melody, and how far
## into it (seconds): (index, time into the note), or index -1 after the end.
static func note_at(t: float) -> Vector2:
	var start: float = 0.0
	for i: int in LENGTHS.size():
		if t < start + LENGTHS[i]:
			return Vector2(i, t - start)
		start += LENGTHS[i]
	return Vector2(-1, 0.0)


## The hum's level (-1 to 1, before [member loudness]) at [param t] seconds
## into the melody: silent outside it, swelling in and out on each note.
static func sample(t: float) -> float:
	var at: Vector2 = note_at(t)
	var index: int = int(at.x)
	if index < 0:
		return 0.0
	var into: float = at.y
	var length: float = LENGTHS[index]
	var swell: float = minf(into / 0.08, 1.0) * clampf((length - into) / 0.25, 0.0, 1.0)
	var freq: float = pitch(MELODY[index]) * (1.0 + 0.004 * sin(TAU * 5.0 * t))
	var phase: float = TAU * freq * t
	return swell * (sin(phase) * 0.8 + sin(phase * 2.0) * 0.2)


# Tops up the generator's buffer with as many samples as it has room for.
func _fill() -> void:
	if _playback == null:
		return
	var frames: int = _playback.get_frames_available()
	for i: int in frames:
		var level: float = sample(_sample_clock) * loudness
		_playback.push_frame(Vector2(level, level))
		_sample_clock += 1.0 / MIX_RATE
