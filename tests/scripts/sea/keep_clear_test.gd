extends GameTestSuite
## Tests for KeepClear: the invisible round wall that keeps the rowboat off
## the island and out of the buoy.

const BOAT_SCENE: String = "res://scenes/prototype/intro/rowboat.tscn"


func test_a_spot_outside_is_left_alone() -> void:
	var spot: Vector2 = Vector2(12, 0)

	assert_vector(KeepClear.push_out(spot, Vector2.ZERO, 10.0)).is_equal(spot)


func test_a_spot_inside_is_moved_out_to_the_edge() -> void:
	var out: Vector2 = KeepClear.push_out(Vector2(3, 4), Vector2.ZERO, 10.0)

	assert_vector(out).is_equal_approx(Vector2(6, 8), Vector2(0.001, 0.001))


func test_the_very_middle_still_goes_somewhere() -> void:
	var out: Vector2 = KeepClear.push_out(Vector2(5, 5), Vector2(5, 5), 2.0)

	assert_float(out.distance_to(Vector2(5, 5))).is_equal_approx(2.0, 0.001)


func test_it_stops_a_boat_heading_in_but_lets_it_slide_along() -> void:
	var world: Node3D = auto_free(Node3D.new())
	var wall: KeepClear = KeepClear.new()
	wall.radius = 10.0
	world.add_child(wall)
	var boat: Rowboat = (load(BOAT_SCENE) as PackedScene).instantiate() as Rowboat
	world.add_child(boat)
	add_child(world)
	boat.global_position = Vector3(0, 0, 9)
	# Heading in towards the middle, and sideways along the wall.
	boat.velocity = Vector2(1.5, -2.0)

	assert_bool(wall.hold_off(boat)).is_true()

	assert_vector(boat.global_position).is_equal_approx(Vector3(0, 0, 10), Vector3.ONE * 0.001)
	assert_vector(boat.velocity).is_equal_approx(Vector2(1.5, 0), Vector2(0.001, 0.001))
	assert_bool(wall.hold_off(boat)).is_false()
