extends GameTestSuite
## Tests for Drips: dripping only while it's wet, and as much as it's wet.


func test_drips_as_much_as_it_is_wet() -> void:
	var drips: Drips = _new_drips()
	drips.set_wetness(0.4)
	assert_bool(drips.emitting).is_true()
	assert_float(drips.amount_ratio).is_equal_approx(0.4, 0.0001)


func test_stops_when_dry_and_clamps() -> void:
	var drips: Drips = _new_drips()
	drips.set_wetness(-1.0)
	assert_bool(drips.emitting).is_false()
	drips.set_wetness(5.0)
	assert_float(drips.wetness).is_equal(1.0)


func test_drops_move_with_what_they_drip_from() -> void:
	assert_bool(_new_drips().local_coords).is_true()


func test_a_spout_pours_out_sideways_before_falling() -> void:
	var drips: Drips = Drips.new()
	drips.spout = 1.5
	add_child(drips)
	auto_free(drips)
	var motion: ParticleProcessMaterial = drips.process_material as ParticleProcessMaterial

	assert_float(motion.direction.z).is_greater(0.5)
	assert_float(motion.initial_velocity_min).is_greater(1.0)


func test_more_drops_for_a_faster_rate() -> void:
	var slow: Drips = _new_drips(4.0)
	var fast: Drips = _new_drips(20.0)
	assert_int(fast.amount).is_greater(slow.amount)


func test_the_weather_makes_them_drip() -> void:
	var drips: Drips = _new_drips()
	var weather: Weather = (load("res://scenes/prototype/weather/weather.tscn") as PackedScene) \
			.instantiate() as Weather
	add_child(weather)
	auto_free(weather)

	weather.intensity = 0.0
	assert_bool(drips.emitting).is_false()
	weather.intensity = 0.6
	assert_float(drips.wetness).is_equal_approx(0.6, 0.0001)


func _new_drips(rate: float = 12.0) -> Drips:
	var drips: Drips = Drips.new()
	drips.rate = rate
	add_child(drips)
	auto_free(drips)
	return drips
