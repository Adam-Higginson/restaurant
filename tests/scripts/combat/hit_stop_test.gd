extends GameTestSuite
## Tests for HitStop: a freeze slows the game almost to a stop for an exact
## number of physics ticks, overlapping freezes don't add up, and the game's
## speed always comes back, even if the freeze is freed part-way.


func after_test() -> void:
	# Never let one test's freeze slow the next.
	Engine.time_scale = 1.0


func test_a_freeze_stops_time_for_its_ticks_then_lets_go() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)

	hit_stop.freeze(4)

	assert_bool(hit_stop.is_frozen()).is_true()
	assert_float(Engine.time_scale).is_equal(HitStop.FROZEN_SCALE)
	assert_int(hit_stop.ticks_left).is_equal(4)
	# Still frozen as the fourth tick starts: it lets go during that tick.
	await physics_ticks(runner, 4)
	assert_bool(hit_stop.is_frozen()).is_true()
	await physics_ticks(runner, 1)
	assert_bool(hit_stop.is_frozen()).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)


func test_a_longer_freeze_wins_and_a_shorter_one_doesnt_cut_it() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)

	hit_stop.freeze(4)
	hit_stop.freeze(10)
	hit_stop.freeze(2)

	assert_int(hit_stop.ticks_left).is_equal(10)
	await physics_ticks(runner, 6)
	assert_bool(hit_stop.is_frozen()).is_true()


func test_freezes_dont_add_up() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)

	hit_stop.freeze(4)
	hit_stop.freeze(4)

	assert_int(hit_stop.ticks_left).is_equal(4)


func test_a_freeze_of_nothing_does_nothing() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)

	hit_stop.freeze(0)

	assert_bool(hit_stop.is_frozen()).is_false()
	assert_float(Engine.time_scale).is_equal(1.0)


func test_freeing_it_mid_freeze_puts_the_speed_back() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)
	hit_stop.freeze(10)

	hit_stop.get_parent().remove_child(hit_stop)
	hit_stop.free()

	assert_float(Engine.time_scale).is_equal(1.0)


func test_it_runs_even_while_the_game_is_paused() -> void:
	var hit_stop: HitStop = _new_hit_stop()
	var runner: GdUnitSceneRunner = scene_runner(hit_stop.get_parent())
	await physics_ticks(runner, 2)

	assert_int(hit_stop.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


# A HitStop in a world of its own, freed after the test.
func _new_hit_stop() -> HitStop:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var hit_stop: HitStop = HitStop.new()
	world.add_child(hit_stop)
	return hit_stop
