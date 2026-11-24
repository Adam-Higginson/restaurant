extends GameTestSuite
## Tests for the leaping fish (#197): none jump until they're turned on;
## then they jump out of the sea beside the ship and arc forward, nose first;
## turned off, the ones in the air land and no more jump.


func test_none_leap_until_turned_on() -> void:
	var fish: LeapingFish = _fish()
	var runner: GdUnitSceneRunner = scene_runner(fish.get_parent())

	await physics_ticks(runner, 120)

	assert_int(fish.in_the_air()).is_equal(0)


func test_turned_on_they_jump_beside_her_and_forward_over_the_sea() -> void:
	var fish: LeapingFish = _fish()
	var runner: GdUnitSceneRunner = scene_runner(fish.get_parent())
	await physics_ticks(runner, 2)

	fish.leaping = true
	var highest: float = -INF
	var seen: int = 0
	for i: int in 180:
		await physics_ticks(runner, 1)
		for at: Vector3 in fish.fish_positions():
			seen += 1
			highest = maxf(highest, at.y)
			# Out from her side, never under her.
			assert_float(absf(at.x)).is_greater(fish.out_from.x - 2.0)
			assert_float(at.y).is_greater_equal(fish.sea_level - 0.001)

	assert_int(seen).is_greater(0)
	assert_float(highest).is_between(fish.height.x * 0.5, fish.height.y + 0.01)


func test_each_flies_nose_first() -> void:
	var fish: LeapingFish = _fish()
	fish.count = 1
	var runner: GdUnitSceneRunner = scene_runner(fish.get_parent())
	await physics_ticks(runner, 2)
	fish.leaping = true
	for i: int in 240:
		if fish.in_the_air() > 0:
			break
		await physics_ticks(runner, 1)
	var before: Vector3 = fish.fish_positions()[0]
	await physics_ticks(runner, 3)
	var body: Node3D = fish.get_node("Fish0") as Node3D

	var moved: Vector3 = body.position - before
	# Forward is her -Z, and the fish's own -Z leads.
	assert_float(moved.z).is_less(0.0)
	assert_float((-body.basis.z).dot(moved.normalized())).is_greater(0.8)


func test_turned_off_the_ones_in_the_air_land_and_no_more_leap() -> void:
	var fish: LeapingFish = _fish()
	var runner: GdUnitSceneRunner = scene_runner(fish.get_parent())
	await physics_ticks(runner, 2)
	fish.leaping = true
	await physics_ticks(runner, 90)
	assert_int(fish.in_the_air()).is_greater(0)

	fish.leaping = false
	# The longest jump lasts airtime.y seconds.
	await physics_ticks(runner, int(fish.airtime.y * 60.0) + 10)

	assert_int(fish.in_the_air()).is_equal(0)
	await physics_ticks(runner, 120)
	assert_int(fish.in_the_air()).is_equal(0)


func _fish() -> LeapingFish:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var fish: LeapingFish = LeapingFish.new()
	fish.name = "LeapingFish"
	world.add_child(fish)
	return fish
