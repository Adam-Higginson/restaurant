extends GameTestSuite
## Tests for Lightning: the shape of a flash, striking only in a storm, and
## lighting everything in the "lightning_lit" group.


func test_dark_before_a_strike_and_after_the_flash_fades() -> void:
	assert_float(Lightning.brightness_at(-0.1, 0.7)).is_equal(0.0)
	assert_float(Lightning.brightness_at(0.7, 0.7)).is_equal(0.0)
	assert_float(Lightning.brightness_at(5.0, 0.7)).is_equal(0.0)


func test_a_flash_starts_at_its_brightest() -> void:
	assert_float(Lightning.brightness_at(0.0, 0.7)).is_equal(1.0)


func test_a_flash_flickers_twice_then_fades() -> void:
	var first: float = Lightning.brightness_at(0.02, 1.0)
	var dip: float = Lightning.brightness_at(0.12, 1.0)
	var second: float = Lightning.brightness_at(0.2, 1.0)
	var fading: float = Lightning.brightness_at(0.6, 1.0)
	assert_float(dip).is_less(first)
	assert_float(second).is_greater(dip)
	assert_float(fading).is_less(second)
	assert_float(fading).is_greater(0.0)


func test_brightness_stays_between_zero_and_one() -> void:
	for i: int in 100:
		var b: float = Lightning.brightness_at(i * 0.01, 0.9)
		assert_float(b).is_between(0.0, 1.0)


func test_it_strikes_within_the_longest_gap_in_a_storm() -> void:
	var lightning: Lightning = _new_lightning(1.0)
	var strikes: Array[int] = [0]
	lightning.struck.connect(func() -> void: strikes[0] += 1)
	_advance(lightning, lightning.max_gap + 0.5)
	assert_int(strikes[0]).is_greater(0)


func test_no_lightning_in_light_rain() -> void:
	var lightning: Lightning = _new_lightning(0.2)
	var strikes: Array[int] = [0]
	lightning.struck.connect(func() -> void: strikes[0] += 1)
	_advance(lightning, lightning.max_gap * 3.0)
	assert_int(strikes[0]).is_equal(0)
	assert_float(lightning.brightness).is_equal(0.0)


func test_a_flash_lights_everything_in_the_group() -> void:
	var lightning: Lightning = _new_lightning(1.0)
	var lit: LitThing = LitThing.new()
	lit.add_to_group(Lightning.LIT_GROUP)
	add_child(lit)
	auto_free(lit)
	lightning.strike()
	lightning.advance(0.01)
	assert_float(lit.brightness).is_equal(1.0)
	_advance(lightning, lightning.flash_seconds + 0.1)
	assert_float(lit.brightness).is_equal(0.0)


# A Weather at [param intensity] with a Lightning under it, in the tree, with
# a fixed seed so the storm is the same every run.
func _new_lightning(intensity: float) -> Lightning:
	var weather: Weather = Weather.new()
	weather.intensity = intensity
	var lightning: Lightning = Lightning.new()
	lightning.storm_seed = 7
	weather.add_child(lightning)
	add_child(weather)
	auto_free(weather)
	# Only advanced by hand, so the test controls time.
	lightning.set_process(false)
	return lightning


func _advance(lightning: Lightning, seconds: float) -> void:
	var step: float = 1.0 / 60.0
	var time: float = 0.0
	while time < seconds:
		lightning.advance(step)
		time += step


## Something lit by lightning, which just remembers how brightly.
class LitThing:
	extends Node

	var brightness: float = 0.0

	func set_lightning(value: float) -> void:
		brightness = value
