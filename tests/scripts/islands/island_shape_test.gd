extends GameTestSuite
## Tests for IslandShape: the lie of an island's land as numbers.


func test_the_waterline_is_at_sea_level() -> void:
	var shape: IslandShape = IslandShape.new()
	for x: float in [-60.0, -10.0, 0.0, 25.0, 70.0]:
		assert_float(shape.height_at(x, shape.shore_line(x))).is_equal_approx(0.0, 0.001)


func test_the_land_is_above_the_sea_and_the_seabed_below() -> void:
	var shape: IslandShape = IslandShape.new()
	for x: float in [-40.0, 0.0, 40.0]:
		var shore: float = shape.shore_line(x)
		assert_float(shape.height_at(x, shore - 3.0)).is_greater(0.0)
		assert_float(shape.height_at(x, shore - 30.0)).is_greater(0.0)
		assert_float(shape.height_at(x, shore + 3.0)).is_less(0.0)
		assert_float(shape.height_at(x, shore + 30.0)).is_less(0.0)


func test_inland_is_measured_from_the_waterline() -> void:
	var shape: IslandShape = IslandShape.new()
	var shore: float = shape.shore_line(12.0)
	assert_float(shape.inland(12.0, shore - 5.0)).is_equal_approx(5.0, 0.001)
	assert_float(shape.inland(12.0, shore + 5.0)).is_equal_approx(-5.0, 0.001)


func test_the_cove_bites_inland_in_the_middle() -> void:
	var shape: IslandShape = IslandShape.new()
	shape.shore_wander = 0.0
	assert_float(shape.shore_line(0.0)).is_equal_approx(shape.shore_z, 0.001)
	assert_float(shape.shore_line(70.0)).is_greater(shape.shore_z + shape.cove_depth * 0.9)
	assert_float(shape.shore_line(-70.0)).is_greater(shape.shore_z + shape.cove_depth * 0.9)


func test_the_beach_rises_gently() -> void:
	var shape: IslandShape = IslandShape.new()
	shape.beach_humps = 0.0
	var shore: float = shape.shore_line(0.0)
	assert_float(shape.height_at(0.0, shore - 2.0)).is_equal_approx(shape.beach_slope * 2.0, 0.01)


func test_the_bank_stands_above_the_beach() -> void:
	var shape: IslandShape = IslandShape.new()
	shape.bumps = 0.0
	shape.beach_humps = 0.0
	var shore: float = shape.shore_line(0.0)
	var top_of_beach: float = shape.height_at(0.0, shore - shape.beach_width)
	var top_of_bank: float = shape.height_at(0.0, shore - shape.beach_width - shape.dune_width)
	assert_float(top_of_bank - top_of_beach).is_greater(shape.dune_height * 0.99)


func test_the_shelf_is_shallow_then_the_bottom_drops_away() -> void:
	var shape: IslandShape = IslandShape.new()
	var shore: float = shape.shore_line(0.0)
	# Out over the shelf it falls no faster than the beach rises...
	var on_shelf: float = shape.height_at(0.0, shore + shape.shelf_width - 1.5)
	assert_float(on_shelf).is_equal_approx(-shape.beach_slope * (shape.shelf_width - 1.5), 0.01)
	# ...and past it, much faster.
	var past_a: float = shape.height_at(0.0, shore + shape.shelf_width + 2.0)
	var past_b: float = shape.height_at(0.0, shore + shape.shelf_width + 3.0)
	assert_float(past_a - past_b).is_equal_approx(shape.drop_slope, 0.01)


func test_the_seabed_stops_at_its_floor() -> void:
	var shape: IslandShape = IslandShape.new()
	assert_float(shape.height_at(0.0, shape.shore_line(0.0) + 55.0)).is_equal(shape.seabed_floor)


func test_the_beach_is_flatter_than_the_drop_off() -> void:
	var shape: IslandShape = IslandShape.new()
	var shore: float = shape.shore_line(0.0)
	assert_float(shape.slope_at(0.0, shore - 3.0)).is_less(0.25)
	assert_float(shape.slope_at(0.0, shore + shape.shelf_width + 3.0)).is_greater(0.3)


func test_normals_point_up_out_of_the_ground() -> void:
	var shape: IslandShape = IslandShape.new()
	var shore: float = shape.shore_line(0.0)
	var on_beach: Vector3 = shape.normal_at(0.0, shore - 3.0)
	assert_float(on_beach.length()).is_equal_approx(1.0, 0.001)
	assert_float(on_beach.y).is_greater(0.9)
	# The beach rises inland (towards -Z), so it faces a little out to sea.
	assert_float(on_beach.z).is_greater(0.0)


func test_covers_only_its_own_patch() -> void:
	var shape: IslandShape = IslandShape.new()
	assert_bool(shape.covers(0.0, 0.0)).is_true()
	assert_bool(shape.covers(shape.size.x / 2.0 + 1.0, 0.0)).is_false()
	assert_bool(shape.covers(0.0, -shape.size.y / 2.0 - 1.0)).is_false()
