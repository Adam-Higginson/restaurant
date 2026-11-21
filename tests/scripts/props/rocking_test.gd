extends GameTestSuite
## Tests for Rocking: loose things lean and slide together with the sea's
## roll, a little, and come back to where they were put.


func test_rolls_between_port_and_starboard() -> void:
	var rock: Rocking = _new_rock(0.0)
	for step: int in 200:
		assert_float(absf(rock.roll_at(step * 0.07))).is_less_equal(1.0001)


func test_everything_rolls_together_on_one_clock() -> void:
	var first: Rocking = _new_rock(0.0)
	var second: Rocking = _new_rock(0.0)
	assert_float(first.roll_at(3.3)).is_equal(second.roll_at(3.3))


func test_comes_back_after_one_period() -> void:
	var rock: Rocking = _new_rock(0.1)
	assert_float(rock.roll_at(rock.period)).is_equal_approx(rock.roll_at(0.0), 0.0001)


func test_holds_still_without_a_period() -> void:
	var rock: Rocking = _new_rock(0.0)
	rock.period = 0.0
	assert_float(rock.roll_at(2.0)).is_equal(0.0)


func test_never_strays_far_from_where_it_was_put() -> void:
	var rock: Rocking = _new_rock(0.0)
	rock.position = Vector3(0.4, 0.9, -0.1)
	rock.rotation.y = 0.8
	var runner: GdUnitSceneRunner = scene_runner(rock)
	for check: int in 5:
		await physics_ticks(runner, 17)
		assert_float(rock.position.distance_to(Vector3(0.4, 0.9, -0.1))).is_less_equal(
				rock.slide_metres + 0.0001)
		assert_float(rock.rotation.y).is_equal_approx(0.8, deg_to_rad(2.0))


func _new_rock(phase: float) -> Rocking:
	var rock: Rocking = Rocking.new()
	rock.phase = phase
	auto_free(rock)
	return rock
