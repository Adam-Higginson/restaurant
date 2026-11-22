class_name Lightning
extends Node
## Distant lightning in a storm: every so often the sky flashes, a quick
## double flicker that fades out. It only strikes while it's raining hard
## (its parent [Weather]'s intensity), and it tells everything that shows it
## (the "lightning_lit" group, such as each [Porthole]) how bright the flash
## is right now, from 0 (dark) to 1 (the brightest moment).

## Emitted the moment a flash begins.
signal struck

## The group of nodes told about each flash. They need a
## [code]set_lightning(brightness: float)[/code] method.
const LIT_GROUP: StringName = &"lightning_lit"

## The shortest wait between flashes, in seconds.
@export var min_gap: float = 8.0
## The longest wait between flashes, in seconds.
@export var max_gap: float = 24.0
## How long one flash takes to fade out, in seconds.
@export var flash_seconds: float = 0.7
## How hard it must be raining (0 to 1) before lightning strikes.
@export_range(0.0, 1.0) var min_intensity: float = 0.6
## A fixed seed gives the same storm every time (for tests). 0 picks one.
@export var storm_seed: int = 0

## How bright the flash is right now: 0 dark, 1 the brightest moment.
var brightness: float = 0.0

## How hard it's raining. Read from the parent [Weather] if there is one.
var intensity: float = 1.0:
	get:
		var weather: Weather = get_parent() as Weather
		if weather != null:
			return weather.intensity
		return intensity

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _until_next: float = 0.0
# Seconds since the last strike. Starts long past, so it begins dark.
var _since_strike: float = INF


func _ready() -> void:
	if storm_seed != 0:
		_rng.seed = storm_seed
	else:
		_rng.randomize()
	_until_next = _rng.randf_range(min_gap, max_gap)


func _process(delta: float) -> void:
	advance(delta)


## Moves the storm on by [param delta] seconds: counts down to the next
## strike (only while it's raining hard enough), and updates [member brightness]
## and everything lit by it.
func advance(delta: float) -> void:
	_since_strike += delta
	_until_next -= delta
	if _until_next <= 0.0:
		_until_next = _rng.randf_range(min_gap, max_gap)
		if intensity >= min_intensity:
			strike()
	var now: float = brightness_at(_since_strike, flash_seconds)
	if not is_equal_approx(now, brightness):
		brightness = now
		if is_inside_tree():
			get_tree().call_group(LIT_GROUP, &"set_lightning", brightness)


## Flashes now, whatever the timing.
func strike() -> void:
	_since_strike = 0.0
	struck.emit()


## How bright a flash is [param seconds] after it struck, for one lasting
## [param duration] seconds: a bright flicker, a dip, a second flicker, then
## a fade to dark. Always between 0 and 1.
static func brightness_at(seconds: float, duration: float) -> float:
	if seconds < 0.0 or duration <= 0.0 or seconds >= duration:
		return 0.0
	var t: float = seconds / duration
	if t < 0.08:
		return 1.0
	if t < 0.16:
		return 0.25
	if t < 0.26:
		return 0.75
	# The fade after the second flicker, eased so it lingers then goes.
	var fade: float = 1.0 - (t - 0.26) / 0.74
	return 0.75 * fade * fade
