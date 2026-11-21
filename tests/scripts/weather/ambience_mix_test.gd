extends GameTestSuite
## Tests for AmbienceMix: open on deck, muffled under a roof, and a smooth
## glide between them.

var _mix: AmbienceMix


func before_test() -> void:
	_mix = AmbienceMix.new()
	_mix.fade_seconds = 1.0


func test_starts_outside_and_unmuffled() -> void:
	assert_float(_mix.shelter).is_equal(0.0)
	assert_float(_mix.cutoff_hz()).is_equal_approx(AmbienceMix.OPEN_CUTOFF_HZ, 0.5)


func test_glides_under_a_roof_over_the_fade() -> void:
	_mix.step(0.5, true)
	assert_float(_mix.shelter).is_equal_approx(0.5, 0.0001)
	var halfway: float = _mix.cutoff_hz()
	assert_float(halfway).is_less(AmbienceMix.OPEN_CUTOFF_HZ)
	assert_float(halfway).is_greater(AmbienceMix.SHELTERED_CUTOFF_HZ)

	_mix.step(0.5, true)
	_mix.step(0.5, true)

	assert_float(_mix.shelter).is_equal(1.0)
	assert_float(_mix.cutoff_hz()).is_equal_approx(AmbienceMix.SHELTERED_CUTOFF_HZ, 0.5)


func test_glides_back_out() -> void:
	_mix.snap(true)
	_mix.step(0.25, false)
	assert_float(_mix.shelter).is_equal_approx(0.75, 0.0001)


func test_halfway_sounds_halfway_on_a_log_scale() -> void:
	_mix.step(0.5, true)
	var middle: float = sqrt(AmbienceMix.OPEN_CUTOFF_HZ * AmbienceMix.SHELTERED_CUTOFF_HZ)
	assert_float(_mix.cutoff_hz()).is_equal_approx(middle, 1.0)


func test_no_fade_jumps_straight_there() -> void:
	_mix.fade_seconds = 0.0
	_mix.step(0.01, true)
	assert_float(_mix.shelter).is_equal(1.0)


func test_rain_is_quieter_under_a_roof_and_silent_when_dry() -> void:
	var outside: float = _mix.rain_volume_db(1.0)
	_mix.snap(true)
	assert_float(_mix.rain_volume_db(1.0)).is_equal_approx(
			outside + AmbienceMix.SHELTERED_DROP_DB, 0.001)
	assert_float(_mix.rain_volume_db(0.0)).is_equal(-80.0)
	assert_float(_mix.rain_volume_db(0.5)).is_less(_mix.rain_volume_db(1.0))
