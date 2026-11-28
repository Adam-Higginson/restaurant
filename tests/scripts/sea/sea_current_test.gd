extends GameTestSuite
## Tests for SeaCurrent: which way it runs, how much of a boat it takes, and
## sweeping that up over time.


func test_it_runs_the_same_way_round_as_the_waves() -> void:
	var current: SeaCurrent = _new_current()

	current.direction_degrees = 0.0
	assert_vector(current.direction()).is_equal_approx(Vector2(0, -1), Vector2(0.0001, 0.0001))
	current.direction_degrees = 90.0
	assert_vector(current.direction()).is_equal_approx(Vector2(-1, 0), Vector2(0.0001, 0.0001))


func test_still_water_has_no_flow() -> void:
	var current: SeaCurrent = _new_current()
	current.speed = 4.0

	assert_vector(current.flow()).is_equal(Vector2.ZERO)


func test_flow_grows_with_takeover() -> void:
	var current: SeaCurrent = _new_current()
	current.direction_degrees = 0.0
	current.speed = 4.0

	current.takeover = 0.5
	assert_vector(current.flow()).is_equal_approx(Vector2(0, -2), Vector2(0.0001, 0.0001))
	current.takeover = 1.0
	assert_vector(current.flow()).is_equal_approx(Vector2(0, -4), Vector2(0.0001, 0.0001))


func test_takeover_stays_between_none_and_all() -> void:
	var current: SeaCurrent = _new_current()

	current.takeover = 3.0
	assert_float(current.takeover).is_equal(1.0)
	current.takeover = -1.0
	assert_float(current.takeover).is_equal(0.0)


func test_it_says_once_when_it_has_the_boat() -> void:
	var current: SeaCurrent = _new_current()
	var heard: Array[int] = [0]
	current.took_over.connect(func() -> void: heard[0] += 1)

	current.takeover = 0.9
	current.takeover = 1.0
	current.takeover = 1.0

	assert_int(heard[0]).is_equal(1)


func test_a_sweep_takes_the_boat_over_time() -> void:
	var current: SeaCurrent = SeaCurrent.new()
	var world: Node = Node.new()
	auto_free(world)
	world.add_child(current)
	var runner: GdUnitSceneRunner = scene_runner(world)

	current.sweep(1.0, 1.0)
	await physics_ticks(runner, 30)
	var halfway: float = current.takeover
	var done: bool = await wait_for_signal(current.took_over, 3.0)

	# It eases in: slow at first.
	assert_float(halfway).is_between(0.05, 0.5)
	assert_bool(done).is_true()
	assert_float(current.takeover).is_equal(1.0)


func test_releasing_gives_the_boat_back() -> void:
	var current: SeaCurrent = SeaCurrent.new()
	var world: Node = Node.new()
	auto_free(world)
	world.add_child(current)
	var runner: GdUnitSceneRunner = scene_runner(world)

	current.sweep(1.0, 1.0)
	await physics_ticks(runner, 20)
	current.release()
	await physics_ticks(runner, 40)

	assert_float(current.takeover).is_equal(0.0)


# A current outside the scene tree, freed after the test.
func _new_current() -> SeaCurrent:
	var current: SeaCurrent = SeaCurrent.new()
	auto_free(current)
	return current
