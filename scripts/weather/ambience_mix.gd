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
## The low-pass cutoff underwater: a dull rumble and nothing else.
const SUBMERGED_CUTOFF_HZ: float = 260.0
## How much quieter the weather is underwater, in decibels.
const SUBMERGED_DROP_DB: float = -6.0
## How much quieter everything is when it's hushed, in decibels: silent.
const HUSHED_DROP_DB: float = -80.0

## Seconds to glide between outside and sheltered.
var fade_seconds: float = 0.8

## How sheltered the sound is now: 0 outside, 1 under a roof.
var shelter: float:
	get:
		return _shelter

## How far under the water the sound is now: 0 in the air, 1 underwater.
var depth: float:
	get:
		return _depth

## How far the weather has been hushed: 0 as usual, 1 silent.
var hush: float:
	get:
		return _hush

var _shelter: float = 0.0
var _depth: float = 0.0
var _hush: float = 0.0


## Moves [member shelter] towards [param sheltered] for [param delta] seconds.
func step(delta: float, sheltered: bool) -> void:
	var target: float = 1.0 if sheltered else 0.0
	if fade_seconds <= 0.0:
		_shelter = target
		return
	_shelter = move_toward(_shelter, target, delta / fade_seconds)


## Moves [member depth] towards [param submerged] for [param delta] seconds,
## in [param seconds] from one to the other (0 jumps): going under is quick.
func sink(delta: float, submerged: bool, seconds: float = 0.25) -> void:
	var target: float = 1.0 if submerged else 0.0
	if seconds <= 0.0:
		_depth = target
		return
	_depth = move_toward(_depth, target, delta / seconds)


## Moves [member hush] towards [param hushed] for [param delta] seconds, in
## [param seconds] from one to the other (0 jumps): the sound drops away
## almost at once, like a held breath.
func quiet(delta: float, hushed: bool, seconds: float = 0.12) -> void:
	var target: float = 1.0 if hushed else 0.0
	if seconds <= 0.0:
		_hush = target
		return
	_hush = move_toward(_hush, target, delta / seconds)


## Jumps straight to outside or sheltered, with no glide (the scene starting).
func snap(sheltered: bool) -> void:
	_shelter = 1.0 if sheltered else 0.0


## The low-pass cutoff for the current [member shelter], in hertz. Glides on
## a log scale, the way we hear pitch, so the muffling sounds even.
func cutoff_hz() -> float:
	var open_log: float = log(OPEN_CUTOFF_HZ)
	var shut_log: float = log(SHELTERED_CUTOFF_HZ)
	var in_air: float = lerpf(open_log, shut_log, _shelter)
	return exp(lerpf(in_air, log(SUBMERGED_CUTOFF_HZ), _depth))


## The rain's volume for the current [member shelter] and a weather
## [param intensity] (0 to 1), in decibels. Silent with no rain.
func rain_volume_db(intensity: float) -> float:
	if intensity <= 0.0:
		return -80.0
	return linear_to_db(intensity) + SHELTERED_DROP_DB * _shelter + submerged_drop_db()


## How much quieter everything is for the current [member depth], in decibels.
func submerged_drop_db() -> float:
	return SUBMERGED_DROP_DB * _depth


## How loud the whole of the weather is for the current [member hush], in
## decibels: 0 as usual, down to silence.
func hush_db() -> float:
	return HUSHED_DROP_DB * _hush
