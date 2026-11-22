extends GameTestSuite
## Tests for CandleFlame: a flame that wavers within its limits, keeps
## changing, and never moves in step with the candle beside it.


func test_never_leans_or_stretches_past_its_limits() -> void:
	var flame: CandleFlame = _new_flame()
	var widest: float = deg_to_rad(flame.lean_degrees) + 0.0001
	for step: int in 300:
		var shape: Vector3 = flame.shape_at(step * 0.053)
		assert_float(absf(shape.x)).is_less_equal(widest)
		assert_float(absf(shape.z)).is_less_equal(widest)
		assert_float(shape.y).is_between(1.0 - flame.stretch - 0.0001,
				1.0 + flame.stretch + 0.0001)


func test_keeps_wavering_as_time_passes() -> void:
	var flame: CandleFlame = _new_flame()
	var runner: GdUnitSceneRunner = scene_runner(flame)
	var before: Transform3D = flame.transform
	await physics_ticks(runner, 20)
	assert_bool(flame.transform.is_equal_approx(before)).is_false()


func test_two_candles_waver_their_own_ways() -> void:
	var one: CandleFlame = _new_flame()
	var other: CandleFlame = _new_flame()
	var differ: int = 0
	for step: int in 20:
		if not one.shape_at(step * 0.25).is_equal_approx(other.shape_at(step * 0.25)):
			differ += 1
	assert_int(differ).is_greater(15)


func _new_flame() -> CandleFlame:
	var flame: CandleFlame = CandleFlame.new()
	auto_free(flame)
	return flame
