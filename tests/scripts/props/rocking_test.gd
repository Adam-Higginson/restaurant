extends GameTestSuite
## Tests for Rocking: things on the table tip gently about how they were
## placed, within their angle, and never turn or slide.


func test_never_tips_past_its_angle_or_turns() -> void:
	var rock: Rocking = _new_rock(2.0, 1.3, 0.0)
	var widest: float = deg_to_rad(2.0) + 0.0001
	for step: int in 200:
		var tip: Vector3 = rock.tip_at(step * 0.029)
		assert_float(absf(tip.z)).is_less_equal(widest)
		assert_float(absf(tip.x)).is_less_equal(widest)
		assert_float(tip.y).is_equal(0.0)


func test_comes_back_after_one_period() -> void:
	var rock: Rocking = _new_rock(1.5, 2.0, 0.3)
	assert_float(rock.tip_at(2.0).z).is_equal_approx(rock.tip_at(0.0).z, 0.0001)


func test_rocks_about_how_it_was_placed_and_stays_put() -> void:
	var rock: Rocking = _new_rock(3.0, 1.0, 0.25)
	rock.position = Vector3(0.4, 0.9, -0.1)
	rock.rotation.y = 0.8
	var runner: GdUnitSceneRunner = scene_runner(rock)
	await physics_ticks(runner, 20)

	assert_vector(rock.position).is_equal(Vector3(0.4, 0.9, -0.1))
	# Still facing the way it was put down, give or take the small tip.
	assert_float(rock.rotation.y).is_equal_approx(0.8, deg_to_rad(4.0))


func test_holds_still_without_a_period() -> void:
	var rock: Rocking = _new_rock(2.0, 0.0, 0.0)
	assert_vector(rock.tip_at(1.0)).is_equal(Vector3.ZERO)


func _new_rock(degrees: float, period: float, phase: float) -> Rocking:
	var rock: Rocking = Rocking.new()
	rock.tip_degrees = degrees
	rock.period = period
	rock.phase = phase
	auto_free(rock)
	return rock
