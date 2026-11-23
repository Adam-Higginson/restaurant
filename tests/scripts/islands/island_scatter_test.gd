extends GameTestSuite
## Tests for the things that stand plants and scenery about an island by
## rule and by seed: IslandScatter, GrassPatch, SunShafts and IslandBackdrop.


func test_spots_stay_in_their_band_on_the_ground() -> void:
	var scatter: IslandScatter = _new_scatter()
	var spots: Array[Vector3] = scatter.spots()
	assert_int(spots.size()).is_equal(12)
	for spot: Vector3 in spots:
		assert_float(spot.x).is_between(-30.0, 30.0)
		assert_float(scatter.shape.inland(spot.x, spot.z)).is_between(8.0, 20.0)
		assert_float(spot.y).is_equal_approx(scatter.shape.height_at(spot.x, spot.z), 0.0001)


func test_spots_keep_their_distance() -> void:
	var scatter: IslandScatter = _new_scatter()
	scatter.spacing = 5.0
	var spots: Array[Vector3] = scatter.spots()
	for first: int in spots.size():
		for second: int in range(first + 1, spots.size()):
			var apart: Vector2 = Vector2(spots[first].x - spots[second].x, spots[first].z - spots[second].z)
			assert_float(apart.length()).is_greater_equal(5.0)


func test_the_same_seed_gives_the_same_grove() -> void:
	var first: IslandScatter = _new_scatter()
	var second: IslandScatter = _new_scatter()
	assert_array(first.spots()).is_equal(second.spots())
	second.scatter_seed = 99
	assert_array(first.spots()).is_not_equal(second.spots())


func test_nothing_stands_on_ground_too_steep() -> void:
	var scatter: IslandScatter = _new_scatter()
	# Out over the drop-off, which is steeper than this allows.
	scatter.inland = Vector2(-12.0, -8.0)
	scatter.max_slope = 0.2
	assert_int(scatter.spots().size()).is_equal(0)


func test_fewer_stand_when_there_isnt_room() -> void:
	var scatter: IslandScatter = _new_scatter()
	scatter.count = 500
	scatter.spacing = 6.0
	assert_int(scatter.spots().size()).is_less(60)


func test_stands_a_copy_at_each_spot_sunk_and_sized() -> void:
	var scatter: IslandScatter = _new_scatter()
	scatter.sink = 0.5
	scatter.size_range = Vector2(2.0, 2.0)
	scatter.turn_degrees = Vector2(90.0, 90.0)
	scatter.lean_degrees = 0.0
	scatter.scatter()
	await get_tree().process_frame
	var spots: Array[Vector3] = scatter.spots()
	assert_int(scatter.get_child_count()).is_equal(spots.size())
	var copy: Node3D = scatter.get_child(0) as Node3D
	assert_vector(copy.position).is_equal_approx(spots[0] - Vector3(0.0, 0.5, 0.0), Vector3.ONE * 0.0001)
	assert_vector(copy.scale).is_equal_approx(Vector3.ONE * 2.0, Vector3.ONE * 0.0001)
	assert_float(copy.rotation_degrees.y).is_equal_approx(90.0, 0.01)


func test_grass_grows_in_its_band_and_frays_towards_the_sand() -> void:
	var grass: GrassPatch = GrassPatch.new()
	auto_free(grass)
	grass.shape = IslandShape.new()
	grass.count = 400
	grass.along = Vector2(-30.0, 30.0)
	grass.inland = Vector2(10.0, 30.0)
	grass.fray = 10.0
	add_child(grass)
	var tufts: Array[Vector4] = grass.tufts()
	assert_int(grass.multimesh.instance_count).is_equal(tufts.size())
	var near_edge: int = 0
	var further_in: int = 0
	for tuft: Vector4 in tufts:
		var back: float = grass.shape.inland(tuft.x, tuft.z)
		assert_float(back).is_between(10.0, 30.0)
		assert_float(tuft.y).is_equal_approx(grass.shape.height_at(tuft.x, tuft.z), 0.0001)
		if back < 15.0:
			near_edge += 1
		elif back > 25.0:
			further_in += 1
	# The same width of band, but far fewer tufts at the sandy edge.
	assert_int(near_edge).is_less(further_in)


func test_shafts_lie_along_the_suns_rays() -> void:
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	auto_free(sun)
	sun.rotation_degrees = Vector3(-30.0, 40.0, 0.0)
	add_child(sun)
	var shafts: SunShafts = SunShafts.new()
	auto_free(shafts)
	shafts.sun = sun
	shafts.shape = IslandShape.new()
	shafts.count = 8
	add_child(shafts)
	# A light shines along its -Z, so the sun is back along its +Z, and up.
	var to_sun: Vector3 = shafts.to_sun()
	assert_vector(to_sun).is_equal_approx(sun.global_transform.basis.z, Vector3.ONE * 0.0001)
	assert_float(to_sun.y).is_greater(0.0)
	assert_int(shafts.multimesh.instance_count).is_equal(8)
	var frames: Array[Transform3D] = shafts.shafts()
	assert_int(frames.size()).is_equal(8)
	for frame: Transform3D in frames:
		assert_vector(frame.basis.y.normalized()).is_equal_approx(to_sun, Vector3.ONE * 0.001)
		# Between 12 and 20 metres long, as its settings say.
		assert_float(frame.basis.y.length()).is_between(12.0, 20.0)


func test_far_ridges_stand_taller_the_further_back() -> void:
	var backdrop: IslandBackdrop = IslandBackdrop.new()
	auto_free(backdrop)
	backdrop.ridges = 3
	add_child(backdrop)
	assert_object(backdrop.mesh).is_not_null()
	# A ridge's lowest point is still above the tallest point of the one in front.
	var front_top: float = 0.0
	var behind_bottom: float = INF
	for step: int in 60:
		var x: float = -400.0 + step * 13.0
		front_top = maxf(front_top, backdrop.skyline(0, x))
		behind_bottom = minf(behind_bottom, backdrop.skyline(2, x))
	assert_float(behind_bottom).is_greater(front_top * 0.9)


func test_the_far_hills_are_covered_in_treetops() -> void:
	var backdrop: IslandBackdrop = IslandBackdrop.new()
	auto_free(backdrop)
	backdrop.ridges = 2
	backdrop.crowns_per_ridge = 60
	add_child(backdrop)
	var crowns: Array[Vector4] = backdrop.crowns()
	assert_int(crowns.size()).is_equal(120)
	for crown: Vector4 in crowns:
		assert_float(crown.w).is_greater(0.0)
		# Inland, and on a slope: never below a ridge's buried foot.
		assert_float(crown.z).is_less(0.0)
		assert_float(crown.y).is_greater(-IslandBackdrop.FOOT_DEPTH)
	assert_object(backdrop.get_node_or_null("Treetops")).is_not_null()
	# A crown at the top of a ridge's slope stands on its skyline.
	assert_float(backdrop.on_slope(1, 40.0, 1.0).y).is_equal_approx(backdrop.skyline(1, 40.0), 0.0001)
	backdrop.crowns_per_ridge = 0
	assert_int(backdrop.crowns().size()).is_equal(0)
	assert_object(backdrop.get_node_or_null("Treetops")).is_null()


func test_mist_is_thick_close_by_and_gone_from_far_off() -> void:
	var mist: NearMist = NearMist.new()
	auto_free(mist)
	mist.size = Vector3(20.0, 10.0, 8.0)
	mist.full_density = 0.04
	mist.thins_from = 10.0
	mist.gone_by = 50.0
	add_child(mist)
	mist.global_position = Vector3(0.0, 5.0, -30.0)
	# Inside it, and just beside it, it's as thick as it gets.
	assert_float(mist.distance_to(Vector3(3.0, 6.0, -31.0))).is_equal(0.0)
	assert_float(mist.density_at(0.0)).is_equal(0.04)
	assert_float(mist.density_at(9.0)).is_equal(0.04)
	# Twenty metres out to sea of its near face.
	assert_float(mist.distance_to(Vector3(0.0, 5.0, -6.0))).is_equal_approx(20.0, 0.0001)
	assert_float(mist.density_at(30.0)).is_between(0.005, 0.035)
	assert_float(mist.density_at(50.0)).is_equal(0.0)
	assert_float(mist.density_at(400.0)).is_equal(0.0)


func _new_scatter() -> IslandScatter:
	var prop: PackedScene = PackedScene.new()
	var marker: Node3D = Node3D.new()
	prop.pack(marker)
	marker.free()
	var scatter: IslandScatter = IslandScatter.new()
	auto_free(scatter)
	scatter.shape = IslandShape.new()
	scatter.prop = prop
	scatter.count = 12
	scatter.scatter_seed = 3
	scatter.along = Vector2(-30.0, 30.0)
	scatter.inland = Vector2(8.0, 20.0)
	scatter.spacing = 2.0
	add_child(scatter)
	return scatter
