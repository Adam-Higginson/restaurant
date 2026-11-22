extends GameTestSuite
## Tests for the spray thrown up at the bow: only while the ship is under way,
## at uneven gaps.


func test_the_bow_is_quiet_while_moored() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var spray: BowSpray = _quick_spray(ship)
	var bursts: Array[int] = [0]
	spray.burst_thrown.connect(func() -> void: bursts[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	await physics_ticks(runner, 30)

	assert_int(bursts[0]).is_equal(0)


func test_spray_bursts_at_the_bow_while_sailing() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var spray: BowSpray = _quick_spray(ship)
	var bursts: Array[int] = [0]
	spray.burst_thrown.connect(func() -> void: bursts[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()

	await physics_ticks(runner, 30)

	# Gaps of 0.1 to 0.2 s over half a second.
	assert_int(bursts[0]).is_between(2, 5)


func test_gaps_between_bursts_stay_in_range() -> void:
	var spray: BowSpray = BowSpray.new()
	auto_free(spray)
	spray.min_gap = 2.0
	spray.max_gap = 5.0

	for i: int in 50:
		assert_float(spray.next_gap()).is_between(2.0, 5.0)


# The ship's bow spray, set to burst every 0.1 to 0.2 s so tests are quick.
func _quick_spray(ship: Ship) -> BowSpray:
	var spray: BowSpray = ship.get_node("BowSpray") as BowSpray
	spray.min_gap = 0.1
	spray.max_gap = 0.2
	return spray
