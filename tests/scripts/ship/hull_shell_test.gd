extends GameTestSuite
## Tests for fitting the Meshy hull round the ship (#196): stretching it along
## the ship, mirroring its good half, telling its outside from its inside, and
## letting it out round the rooms. A small made-up hull stands in for the art,
## which isn't on every computer.



func test_length_follows_the_pairs_and_runs_on_past_them() -> void:
	assert_float(HullShell.length_at(-0.5, _map())).is_equal_approx(-5.0, 0.001)
	assert_float(HullShell.length_at(0.5, _map())).is_equal_approx(15.0, 0.001)
	assert_float(HullShell.length_at(2.0, _map())).is_equal_approx(60.0, 0.001)


func test_the_stretch_is_each_stretchs_own() -> void:
	assert_float(HullShell.stretch_at(-0.5, _map())).is_equal_approx(10.0, 0.001)
	assert_float(HullShell.stretch_at(0.5, _map())).is_equal_approx(30.0, 0.001)


func test_mirroring_keeps_the_starboard_half_and_copies_it_to_port() -> void:
	# One triangle across the centreline: cut there, then mirrored.
	var arrays: Array = _triangle(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, 1.0),
			Vector3(1.0, 0.0, -1.0))
	var mirrored: Array = HullShell.mirrored(arrays)
	var vertices: PackedVector3Array = mirrored[Mesh.ARRAY_VERTEX]
	var half: int = vertices.size() / 2
	assert_int(vertices.size() % 6).is_zero()
	for at: int in half:
		assert_float(vertices[at].z).is_less_equal(0.0)
		var copy: Vector3 = vertices[half + at]
		assert_float(copy.z).is_greater_equal(0.0)


func test_mirrored_triangles_still_face_the_same_way_round() -> void:
	var arrays: Array = _triangle(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, -1.0),
			Vector3(1.0, 0.0, -1.0))
	var vertices: PackedVector3Array = HullShell.mirrored(arrays)[Mesh.ARRAY_VERTEX]
	var kept: Vector3 = (vertices[2] - vertices[0]).cross(vertices[1] - vertices[0])
	var copy: Vector3 = (vertices[5] - vertices[3]).cross(vertices[4] - vertices[3])
	# Facing -z on the starboard side, its copy faces +z: mirror images.
	assert_float(kept.z * copy.z).is_less(0.0)


func test_the_outside_is_skin_and_the_inside_is_not() -> void:
	# Ship space: x is across. A wall at x = 6 facing out, one at x = 5.8
	# facing in (the inner planking), and a deck-like face looking up.
	var vertices: PackedVector3Array = PackedVector3Array()
	vertices.append_array(_facing(Vector3(6.0, 3.0, 0.0), Vector3.RIGHT))
	vertices.append_array(_facing(Vector3(5.8, 3.0, 0.0), Vector3.LEFT))
	vertices.append_array(_facing(Vector3(6.0, 6.0, 0.0), Vector3.UP))
	vertices.append_array(_facing(Vector3(4.0, 3.0, 2.0), Vector3.BACK))
	vertices.append_array(_facing(Vector3(4.0, 3.0, 16.0), Vector3.BACK))
	var colours: PackedColorArray = HullShell.outer_skin(vertices)
	assert_that(colours[0]).is_equal(Color.WHITE)
	assert_that(colours[3]).is_equal(Color.BLACK)
	assert_that(colours[6]).is_equal(Color.WHITE)
	# Facing aft amidships is a frame's side; at the very stern, the transom.
	assert_that(colours[9]).is_equal(Color.BLACK)
	assert_that(colours[12]).is_equal(Color.WHITE)


func test_the_hull_is_let_out_round_the_rooms() -> void:
	# A slim made-up hull: at its least width it would be 0.2 * 30 = 6 m wide,
	# narrower than rooms 8 m across.
	var shell: HullShell = HullShell.new()
	auto_free(shell)
	shell.length_map = PackedVector2Array([Vector2(-1.0, -20.0), Vector2(1.0, 20.0)])
	shell.width = 30.0
	shell.height = 20.0
	shell.depth = 20.0
	shell.model_rim = 0.1
	shell.rim_y = 6.0
	shell.room_half_width = 4.0
	shell.room_from_z = -5.0
	shell.room_to_z = 5.0
	shell.room_floor_y = 2.0
	shell.room_top_y = 5.0
	shell.mirror = false
	var fitted: ArrayMesh = shell.fit_mesh(_slim_hull(), Transform3D.IDENTITY)
	var vertices: PackedVector3Array = fitted.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var widest_by_rooms: float = 0.0
	var widest_at_ends: float = 0.0
	for point: Vector3 in vertices:
		if absf(point.z) < 4.0 and point.y > 2.5 and point.y < 4.5:
			widest_by_rooms = maxf(widest_by_rooms, absf(point.x))
		if absf(point.z) > 15.0:
			widest_at_ends = maxf(widest_at_ends, absf(point.x))
	# (Read between the measured cells, it can fall a centimetre short.)
	assert_float(widest_by_rooms).is_greater_equal(3.95)
	# Far from the rooms it keeps its own width.
	assert_float(widest_at_ends).is_less(3.6)


func test_without_the_model_the_greybox_stays() -> void:
	var stand_in: MeshInstance3D = MeshInstance3D.new()
	auto_free(stand_in)
	var shell: HullShell = HullShell.new()
	auto_free(shell)
	shell.stand_ins = [stand_in]
	shell.path = "res://assets/third_party/meshy/not_a_hull/model.glb"
	stand_in.visible = false
	assert_bool(shell.dress()).is_false()
	assert_bool(stand_in.visible).is_true()
	assert_object(shell.model).is_null()


func test_without_the_model_the_patches_over_its_holes_hide() -> void:
	var patch: MeshInstance3D = MeshInstance3D.new()
	auto_free(patch)
	var shell: HullShell = HullShell.new()
	auto_free(shell)
	shell.with_hull = [patch]
	shell.path = "res://assets/third_party/meshy/not_a_hull/model.glb"
	assert_bool(shell.dress()).is_false()
	assert_bool(patch.visible).is_false()


## Model x to ship z: -1 to -10, 0 to 0, 1 to 30.
func _map() -> PackedVector2Array:
	return PackedVector2Array([Vector2(-1.0, -10.0), Vector2(0.0, 0.0), Vector2(1.0, 30.0)])


func _triangle(a: Vector3, b: Vector3, c: Vector3) -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([a, b, c])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.ONE, Vector2.RIGHT])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2])
	return arrays


## A small triangle at [param centre] whose front (clockwise, as Godot draws
## it) faces [param facing].
func _facing(centre: Vector3, facing: Vector3) -> PackedVector3Array:
	var across: Vector3 = facing.cross(Vector3.UP if absf(facing.y) < 0.9 else Vector3.RIGHT)
	var up: Vector3 = across.cross(facing)
	var a: Vector3 = centre - across * 0.1
	var b: Vector3 = centre + up * 0.1
	var c: Vector3 = centre + across * 0.1
	# Clockwise seen from the front means (c - a) x (b - a) points out of it.
	if (c - a).cross(b - a).dot(facing) < 0.0:
		return PackedVector3Array([a, c, b])
	return PackedVector3Array([a, b, c])


## A model-sized box hull 2 long (x), 0.2 across (z) and 0.3 tall (y),
## starboard and port sides only, in a grid of small squares.
func _slim_hull() -> ArrayMesh:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side: float in PackedFloat32Array([-0.1, 0.1]):
		for along: int in 10:
			for up: int in 6:
				var x0: float = -1.0 + along * 0.2
				var y0: float = -0.2 + up * 0.05
				var square: PackedVector3Array = PackedVector3Array([
					Vector3(x0, y0, side), Vector3(x0 + 0.2, y0, side),
					Vector3(x0 + 0.2, y0 + 0.05, side), Vector3(x0, y0, side),
					Vector3(x0 + 0.2, y0 + 0.05, side), Vector3(x0, y0 + 0.05, side)])
				for corner: Vector3 in square:
					tool.set_normal(Vector3(0.0, 0.0, signf(side)))
					tool.set_uv(Vector2(corner.x, corner.y))
					tool.add_vertex(corner)
	tool.index()
	return tool.commit()
