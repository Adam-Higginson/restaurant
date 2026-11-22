extends GameTestSuite
## Tests that the galley's furniture leaves room to walk: from the bunk-room
## doorway to the cooking row, round behind the table, and between the table
## and the hearth. The player walks at 5 m/s, so 12 physics ticks a metre.
## Up on the stick walks towards the bow, right towards starboard.

const DOORWAY: Vector3 = Vector3(-2.72, 1.05, 8.6)


func test_you_can_walk_from_the_doorway_to_the_cooking_row() -> void:
	var ship: Ship = new_moored_ship_with_player(DOORWAY)[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 24)
	await walk(runner, "move_right", 18)
	await walk(runner, "move_up", 60)

	# Up against the front of the counters, clear of the bookshelf and post.
	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_less(2.6)
	assert_float(at.x).is_between(-1.8, -0.6)


func test_you_can_walk_round_behind_the_table() -> void:
	var ship: Ship = new_moored_ship_with_player(DOORWAY)[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 24)
	await walk(runner, "move_right", 70)

	# Past the aft bench (and the jacket on it) to the starboard side.
	assert_float(_player_on(ship, runner).x).is_greater(2.8)


func test_you_can_walk_between_the_table_and_the_hearth() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-1.5, 1.05, 3.2))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 60)

	assert_float(_player_on(ship, runner).x).is_greater(3.0)


func _player_on(ship: Ship, runner: GdUnitSceneRunner) -> Vector3:
	var player: Player3D = runner.find_child("Player") as Player3D
	return ship.to_local(player.global_position)
