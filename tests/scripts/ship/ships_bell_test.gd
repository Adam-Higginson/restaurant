extends GameTestSuite
## Tests for the ship's bell (it just rings since #207) and the ship's own
## heaving to (ease to a stop) and getting under way (back up to speed).


func test_heaving_to_eases_the_ship_to_a_stop() -> void:
	var ship: Ship = _sailing_ship()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	ship.heave_to()
	await physics_ticks(runner, 15)
	# Half a second into a one-second ease: slowing, not stopped.
	assert_float(ship.way).is_between(0.3, 0.8)
	assert_bool(ship.is_sailing).is_true()

	await physics_ticks(runner, 60)
	assert_float(ship.way).is_equal(0.0)
	assert_bool(ship.is_sailing).is_false()


func test_a_ship_hove_to_stays_put() -> void:
	var ship: Ship = _sailing_ship()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)
	ship.heave_to()
	await physics_ticks(runner, 75)
	var stopped_at: Vector3 = ship.global_position

	await physics_ticks(runner, 30)

	assert_vector(ship.global_position).is_equal_approx(stopped_at,
			Vector3(0.001, 0.001, 0.001))


func test_getting_under_way_eases_back_up_to_speed() -> void:
	var ship: Ship = _sailing_ship()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)
	ship.heave_to()
	await physics_ticks(runner, 75)

	ship.get_under_way()
	await physics_ticks(runner, 15)
	assert_float(ship.way).is_between(0.2, 0.8)

	await physics_ticks(runner, 60)
	assert_float(ship.way).is_equal(1.0)


func test_pulling_the_rope_rings_the_bell() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 6.25, -11.9))
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bell: ShipsBell = _bell(ship)
	var rings: Array[int] = [0]
	bell.rung.connect(func() -> void: rings[0] += 1)
	await physics_ticks(runner, 5)

	# Face aft, towards the rope over the top of the stairs, and pull it.
	await walk(runner, "move_down", 2)
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	assert_int(rings[0]).is_equal(1)


func test_ringing_swings_the_bell_hard() -> void:
	var ship: Ship = _sailing_ship()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bell: ShipsBell = _bell(ship)
	var swinging: Swinging = bell.get_node("Bell") as Swinging
	await physics_ticks(runner, 5)

	bell.ring()
	var widest: float = 0.0
	for i: int in 40:
		await physics_ticks(runner, 1)
		widest = maxf(widest, absf(swinging.rotation.x))

	assert_float(rad_to_deg(widest)).is_greater(10.0)


func _sailing_ship() -> Ship:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	ship.ease_seconds = 1.0
	ship.set_sail()
	return ship


func _bell(ship: Ship) -> ShipsBell:
	return ship.get_node("Visuals/UpperDeck/Belfry") as ShipsBell


func test_ringing_the_bell_no_longer_stops_the_ship() -> void:
	var ship: Ship = _sailing_ship()
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bell: ShipsBell = _bell(ship)
	await physics_ticks(runner, 5)
	assert_str(bell.prompt()).is_equal("Ring the bell")

	bell.ring()
	await physics_ticks(runner, 75)

	assert_bool(ship.is_sailing).is_true()
	assert_float(ship.way).is_equal(1.0)
