class_name Clang
extends AudioStreamPlayer
## The clang of a frying pan turning a blow away. Made on the fly with no
## recording: a pan rings at several pitches at once that aren't in tune
## with each other (which is what makes metal sound like metal), the high
## ones dying away fastest, with a short burst of noise for the knock.
##
## A child of the [Player3D]; the [Duellist] rings it when a parry lands.

## Samples a second.
const MIX_RATE: int = 22050
## How long the clang rings, in seconds.
const SECONDS: float = 0.7
## The pitches a pan rings at, in hertz. Not whole multiples of each other.
const PARTIALS: PackedFloat32Array = [587.0, 1361.0, 2113.0, 3187.0, 4409.0]
## How loud each of those is, to start with.
const LEVELS: PackedFloat32Array = [1.0, 0.7, 0.55, 0.4, 0.25]
## How quickly each dies away: higher is quicker.
const DECAYS: PackedFloat32Array = [5.0, 7.0, 10.0, 14.0, 20.0]

## How loud the clang is, 0 to 1.
@export_range(0.0, 1.0) var loudness: float = 0.6
## How far the pitch varies from one clang to the next, as a fraction, so
## two in a row don't sound stamped out.
@export_range(0.0, 0.3) var pitch_wander: float = 0.06

## How many times it has rung.
var times_rung: int = 0


func _ready() -> void:
	stream = make()
	volume_db = linear_to_db(loudness)


## Rings the pan, from the start, at a slightly different pitch each time.
func ring() -> void:
	times_rung += 1
	pitch_scale = randf_range(1.0 - pitch_wander, 1.0 + pitch_wander)
	play()


## The clang's level (-1 to 1) at [param t] seconds in: loudest at the
## knock, ringing away to nothing, and silent before and after.
static func sample(t: float) -> float:
	if t < 0.0 or t >= SECONDS:
		return 0.0
	var ring_level: float = 0.0
	var total: float = 0.0
	for i: int in PARTIALS.size():
		ring_level += LEVELS[i] * exp(-DECAYS[i] * t) * sin(TAU * PARTIALS[i] * t)
		total += LEVELS[i]
	# The knock: a few milliseconds of noise. The same every time, so the
	# sound is too: it's worked out from the time, not rolled.
	var scrambled: float = sin(t * 91345.7) * 43758.5453
	var knock: float = ((scrambled - floorf(scrambled)) * 2.0 - 1.0) * exp(-180.0 * t)
	# Fade the very end, so it doesn't stop with a click.
	var tail: float = clampf((SECONDS - t) / 0.05, 0.0, 1.0)
	return clampf((ring_level / total) * 0.85 + knock * 0.35, -1.0, 1.0) * tail


## The whole clang as a sound Godot can play.
static func make() -> AudioStreamWAV:
	var count: int = int(MIX_RATE * SECONDS)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		data.encode_s16(i * 2, int(sample(float(i) / MIX_RATE) * 32767.0))
	var clang: AudioStreamWAV = AudioStreamWAV.new()
	clang.format = AudioStreamWAV.FORMAT_16_BITS
	clang.mix_rate = MIX_RATE
	clang.data = data
	return clang
