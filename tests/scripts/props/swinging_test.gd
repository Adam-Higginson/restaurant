extends GameTestSuite
## Tests for Swinging: a gentle sway that stays within its angle.


func test_starts_where_its_phase_says() -> void:
	var swing: Swinging = _new_swing(4.0, 2.0, 0.25)
	# A quarter of the way through, the side-to-side sway is at its widest.
	assert_float(rad_to_deg(swing.angle_at(0.0).z)).is_equal_approx(4.0, 0.001)


func test_never_swings_past_its_angle() -> void:
	var swing: Swinging = _new_swing(5.0, 1.7, 0.0)
	var widest: float = deg_to_rad(5.0) + 0.0001
	for step: int in 200:
		var angle: Vector3 = swing.angle_at(step * 0.037)
		assert_float(absf(angle.z)).is_less_equal(widest)
		assert_float(absf(angle.x)).is_less_equal(widest)
		assert_float(angle.y).is_equal(0.0)


func test_comes_back_after_one_period() -> void:
	var swing: Swinging = _new_swing(4.0, 3.0, 0.1)
	assert_float(swing.angle_at(3.0).z).is_equal_approx(swing.angle_at(0.0).z, 0.0001)


func test_hangs_still_without_a_period() -> void:
	var swing: Swinging = _new_swing(4.0, 0.0, 0.0)
	assert_vector(swing.angle_at(1.0)).is_equal(Vector3.ZERO)


func test_moves_as_time_passes() -> void:
	var swing: Swinging = _new_swing(4.0, 2.0, 0.0)
	var runner: GdUnitSceneRunner = scene_runner(swing)
	await physics_ticks(runner, 10)
	assert_float(swing.rotation.z).is_not_equal(0.0)


func _new_swing(degrees: float, period: float, phase: float) -> Swinging:
	var swing: Swinging = Swinging.new()
	swing.swing_degrees = degrees
	swing.period = period
	swing.phase = phase
	auto_free(swing)
	return swing
