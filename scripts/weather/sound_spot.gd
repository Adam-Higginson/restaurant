class_name SoundSpot
extends AudioStreamPlayer3D
## A place aboard that makes a sound now and then: the mast's timbers
## creaking, the rigging groaning, the sail cracking in a gust, the bell
## knocking as the swell rolls it. Every so often it plays one of its
## recordings, picked at random, from where it stands, so the sound comes from
## the right direction as you walk about. With [member loop] it plays one
## recording over and over instead, like rain drumming on the sail.
##
## The recordings are third-party and live in assets/third_party/ (not in the
## repo). Any that are missing are skipped; with none, the spot stays silent.

## The recordings to pick from.
@export_file("*.ogg", "*.wav") var recordings: Array[String] = []
## The shortest wait between sounds, in seconds.
@export var min_gap: float = 4.0
## The longest wait between sounds, in seconds.
@export var max_gap: float = 12.0
## Whether to play the first recording on a loop rather than now and then.
@export var loop: bool = false
## Whether it plays by itself now and then. Off for sounds something else
## starts, like the bell when it's rung (see [method play_now]).
@export var automatic: bool = true
## If above 0, each sound fades out over a couple of seconds once it has
## played this long, in seconds: a few tolls of a long peal of bells.
@export var fade_after: float = 0.0

var _streams: Array[AudioStream] = []
var _wait: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _full_volume: float = 0.0
var _fade: Tween = null


func _ready() -> void:
	_rng.randomize()
	_full_volume = volume_db
	bus = Ambience.BUS
	for path: String in recordings:
		if Ambience.has_sound(path):
			_streams.append(load(path) as AudioStream)
	if loop and not _streams.is_empty():
		var stream_now: AudioStream = _streams[0]
		if stream_now is AudioStreamOggVorbis:
			(stream_now as AudioStreamOggVorbis).loop = true
		elif stream_now is AudioStreamWAV:
			(stream_now as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream = stream_now
		play()
	_wait = next_gap()


func _process(delta: float) -> void:
	if loop or not automatic or _streams.is_empty():
		return
	_wait -= delta
	if _wait <= 0.0:
		play_now()
		_wait = next_gap()


## Plays one of its recordings now, picked at random, if it has any.
func play_now() -> void:
	if _streams.is_empty():
		return
	stream = _streams[_rng.randi_range(0, _streams.size() - 1)]
	pitch_scale = _rng.randf_range(0.9, 1.1)
	volume_db = _full_volume
	play()
	if fade_after > 0.0:
		if _fade != null:
			_fade.kill()
		_fade = create_tween()
		_fade.tween_interval(fade_after)
		_fade.tween_property(self, "volume_db", -60.0, 2.5)
		_fade.tween_callback(stop)


## Whether it has any recordings to play.
func is_audible() -> bool:
	return not _streams.is_empty()


## How long to wait before the next sound: between [member min_gap] and
## [member max_gap] seconds.
func next_gap() -> float:
	return _rng.randf_range(min_gap, max_gap)
