class_name Ambience
extends Node
## The sound of the weather at sea: rain and waves, looping on the
## "Ambience" audio bus. Under a roof the bus's low-pass filter muffles them
## and the rain drops a little, gliding as you go through the hatch (see
## [AmbienceMix]).
##
## The recordings are third-party and live in assets/third_party/ (not in the
## repo). If one is missing, as on CI or a fresh clone, its player stays
## silent and the game carries on.

## The audio bus the loops play on, with a low-pass filter as its first effect.
const BUS: StringName = &"Ambience"

## The weather this follows: rain intensity, and whether the player is sheltered.
@export var weather: Weather
## The rain loop.
@export_file("*.ogg", "*.wav") var rain_path: String = "res://assets/third_party/audio/rain_shower.ogg"
## The waves loop.
@export_file("*.ogg", "*.wav") var waves_path: String = "res://assets/third_party/audio/waves_shore.ogg"
## How loud the waves are, in decibels.
@export_range(-40.0, 6.0) var waves_volume_db: float = -10.0

## The mix: how sheltered the sound is now.
var mix: AmbienceMix = AmbienceMix.new()
## Whether we're hearing the weather from under the water: a dull rumble.
## A cutscene sets this (see [StormCues]).
var submerged: bool = false
## Whether the weather has been hushed altogether, for a moment of silence.
## A cutscene sets this too. It quietens the whole bus, so the creaks and
## drips that play on it (see [SoundSpot]) go with the rain.
var hushed: bool = false

@onready var _rain: AudioStreamPlayer = $Rain
@onready var _waves: AudioStreamPlayer = $Waves


func _ready() -> void:
	_rain.bus = BUS
	_waves.bus = BUS
	_start(_rain, rain_path)
	_start(_waves, waves_path)
	if is_instance_valid(weather):
		mix.snap(weather.sheltered)
	_apply()


func _process(delta: float) -> void:
	if is_instance_valid(weather):
		mix.step(delta, weather.sheltered)
	mix.sink(delta, submerged)
	mix.quiet(delta, hushed)
	_apply()


func _exit_tree() -> void:
	# The bus outlives this scene: never leave it silent.
	var bus: int = AudioServer.get_bus_index(BUS)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, 0.0)


## Whether [param path] holds a sound that can be loaded.
static func has_sound(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)


# Plays the loop at [param path] on [param player], if it's there.
func _start(player: AudioStreamPlayer, path: String) -> void:
	if not has_sound(path):
		return
	var stream: AudioStream = load(path) as AudioStream
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	player.stream = stream
	player.play()


func _apply() -> void:
	var intensity: float = weather.intensity if is_instance_valid(weather) else 1.0
	_rain.volume_db = mix.rain_volume_db(intensity)
	_waves.volume_db = waves_volume_db + mix.submerged_drop_db()
	var bus: int = AudioServer.get_bus_index(BUS)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, mix.hush_db())
	if AudioServer.get_bus_effect_count(bus) == 0:
		return
	var filter: AudioEffectLowPassFilter = AudioServer.get_bus_effect(bus, 0) \
			as AudioEffectLowPassFilter
	if filter != null:
		filter.cutoff_hz = mix.cutoff_hz()
