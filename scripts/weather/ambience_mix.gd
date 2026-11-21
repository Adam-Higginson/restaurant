class_name AmbienceMix
extends RefCounted
## How the weather sounds where the player is: wide open on deck, muffled
## and a little quieter under a roof, and a smooth glide between the two as
## they go through the hatch. Plain logic: [Ambience] applies it to the
## audio bus every frame.

## The low-pass cutoff outside: everything gets through.
const OPEN_CUTOFF_HZ: float = 20000.0
## The low-pass cutoff under a roof: only the deep drumming gets through.
const SHELTERED_CUTOFF_HZ: float = 700.0
## How much quieter the rain is under a roof, in decibels.
const SHELTERED_DROP_DB: float = -8.0

## Seconds to glide between outside and sheltered.
var fade_seconds: float = 0.8

## How sheltered the sound is now: 0 outside, 1 under a roof.
var shelter: float:
	get:
		return _shelter

var _shelter: float = 0.0


## Moves [member shelter] towards [param sheltered] for [param delta] seconds.
func step(delta: float, sheltered: bool) -> void:
	var target: float = 1.0 if sheltered else 0.0
	if fade_seconds <= 0.0:
		_shelter = target
		return
	_shelter = move_toward(_shelter, target, delta / fade_seconds)


## Jumps straight to outside or sheltered, with no glide (the scene starting).
func snap(sheltered: bool) -> void:
	_shelter = 1.0 if sheltered else 0.0


## The low-pass cutoff for the current [member shelter], in hertz. Glides on
## a log scale, the way we hear pitch, so the muffling sounds even.
func cutoff_hz() -> float:
	var open_log: float = log(OPEN_CUTOFF_HZ)
	var shut_log: float = log(SHELTERED_CUTOFF_HZ)
	return exp(lerpf(open_log, shut_log, _shelter))


## The rain's volume for the current [member shelter] and a weather
## [param intensity] (0 to 1), in decibels. Silent with no rain.
func rain_volume_db(intensity: float) -> float:
	if intensity <= 0.0:
		return -80.0
	return linear_to_db(intensity) + SHELTERED_DROP_DB * _shelter
