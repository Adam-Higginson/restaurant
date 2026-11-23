extends GameTestSuite
## Tests for IslandGround: the mesh, collision and height picture built from
## an IslandShape.


func test_builds_a_mesh_and_a_collision_grid() -> void:
	var ground: IslandGround = _new_ground()
	var mesh: MeshInstance3D = ground.get_node("Mesh") as MeshInstance3D
	var collision: CollisionShape3D = ground.get_node("Shape") as CollisionShape3D
	assert_object(mesh.mesh).is_not_null()
	var grid: HeightMapShape3D = collision.shape as HeightMapShape3D
	assert_int(grid.map_width).is_equal(41)
	assert_int(grid.map_depth).is_equal(31)


func test_the_collision_follows_the_land() -> void:
	var ground: IslandGround = _new_ground()
	var grid: HeightMapShape3D = (ground.get_node("Shape") as CollisionShape3D).shape as HeightMapShape3D
	# The grid's first row is the inland edge (the smallest Z); pick a point
	# well up the land.
	var column: int = 20
	var row: int = 2
	var x: float = -20.0 + column
	var z: float = -15.0 + row
	var height: float = ground.shape.height_at(x, z)
	assert_float(height).is_greater(0.0)
	assert_float(grid.map_data[row * grid.map_width + column]).is_equal_approx(height, 0.0001)


func test_you_can_wade_in_only_so_deep() -> void:
	var ground: IslandGround = _new_ground()
	ground.wade_depth = 0.4
	ground.build()
	await get_tree().process_frame
	var grid: HeightMapShape3D = (ground.get_node("Shape") as CollisionShape3D).shape as HeightMapShape3D
	var lowest: float = INF
	for height: float in grid.map_data:
		lowest = minf(lowest, height)
	assert_float(lowest).is_equal_approx(-0.4, 0.0001)
	# The land itself does go deeper than that.
	assert_float(ground.shape.height_at(0.0, 14.0)).is_less(-0.4)


func test_the_picture_holds_height_and_distance_inland() -> void:
	var ground: IslandGround = _new_ground()
	var picture: Image = ground.height_texture().get_image()
	assert_int(picture.get_width()).is_equal(41)
	assert_int(picture.get_height()).is_equal(31)
	var pixel: Color = picture.get_pixel(20, 2)
	assert_float(pixel.r).is_equal_approx(ground.shape.height_at(0.0, -13.0), 0.0001)
	assert_float(pixel.g).is_equal_approx(ground.shape.inland(0.0, -13.0), 0.0001)


func test_the_picture_covers_the_ground_and_half_a_cell_more() -> void:
	var ground: IslandGround = _new_ground()
	var rect: Rect2 = ground.height_rect()
	assert_vector(rect.position).is_equal(Vector2(-20.5, -15.5))
	assert_vector(rect.size).is_equal(Vector2(41.0, 31.0))


func test_rebuilds_when_the_shape_changes() -> void:
	var ground: IslandGround = _new_ground()
	var built: Dictionary[String, int] = {"times": 0}
	ground.built.connect(func() -> void: built["times"] += 1)
	ground.shape.dune_height = 4.0
	ground.shape.emit_changed()
	assert_int(built["times"]).is_equal(1)


func test_is_empty_without_a_shape() -> void:
	var ground: IslandGround = IslandGround.new()
	auto_free(ground)
	add_child(ground)
	assert_object(ground.height_texture()).is_null()
	assert_object(ground.get_node_or_null("Mesh")).is_null()


# A small patch of ground: 40 m by 30 m, its waterline at z = 5.
func _new_ground() -> IslandGround:
	var shape: IslandShape = IslandShape.new()
	shape.size = Vector2(40.0, 30.0)
	shape.shore_z = 5.0
	shape.cove_depth = 0.0
	shape.shore_wander = 0.0
	var ground: IslandGround = IslandGround.new()
	auto_free(ground)
	ground.shape = shape
	add_child(ground)
	return ground
