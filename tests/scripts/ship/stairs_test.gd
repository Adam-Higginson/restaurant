extends GameTestSuite
## Tests for the hatch stairs (#204): solid steps whose treads straddle the
## slope you walk on, wall to wall in the corridor down from the hatch.


func test_it_builds_one_box_per_step() -> void:
	var stairs: Stairs = Stairs.new()
	stairs.steps = 10
	add_child(stairs)
	auto_free(stairs)
	assert_int(stairs.get_children(true).size()).is_equal(10)
	stairs.steps = 12
	assert_int(stairs.get_children(true).size()).is_equal(12)


func test_each_tread_straddles_the_slope() -> void:
	var stairs: Stairs = Stairs.new()
	for index: int in stairs.steps:
		var box: AABB = stairs.step_box(index)
		var middle: float = -box.get_center().z
		# The tread's middle is on the slope, so neither edge is more than
		# half a step off it.
		assert_float(box.end.y).is_equal_approx(stairs.slope_height(middle), 0.001)
		assert_float(absf(box.end.y - stairs.slope_height(-box.position.z))) \
				.is_less_equal(stairs.step_rise() / 2.0 + 0.001)
	stairs.free()


func test_the_steps_climb_without_gaps() -> void:
	var stairs: Stairs = Stairs.new()
	for index: int in stairs.steps - 1:
		var lower: AABB = stairs.step_box(index)
		var upper: AABB = stairs.step_box(index + 1)
		# Each step starts where the last one ends, and its block reaches
		# down past the last one's tread, so the flight is solid.
		assert_float(upper.end.z).is_equal_approx(lower.position.z, 0.001)
		assert_float(upper.position.y).is_less(lower.end.y)
	assert_float(stairs.step_box(0).position.y).is_equal(0.0)
	stairs.free()


func test_the_hatch_stairs_fill_the_corridor_along_the_ramp() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var stairs: Stairs = ship.get_node("Visuals/HatchStairs") as Stairs
	# Visuals sits at the ship's origin, so the stairs' position is in ship space.
	var foot: Vector3 = stairs.position
	# From the bunk room's floor up to the main deck, where the ramp runs.
	assert_float(foot.y).is_equal_approx(1.0, 0.01)
	assert_float(foot.y + stairs.rise).is_equal_approx(5.3, 0.01)
	var ramp: CollisionShape3D = ship.get_node("RampShape") as CollisionShape3D
	assert_float(foot.x).is_equal_approx(ramp.position.x, 0.01)
	# Wall to wall: from the hull's wall (inside face at -5.7) to the
	# corridor's wall (-3.48), no gap down either side.
	assert_float(foot.x - stairs.width / 2.0).is_less_equal(-5.69)
	assert_float(foot.x + stairs.width / 2.0).is_greater_equal(-3.49)
