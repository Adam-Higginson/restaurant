extends GameTestSuite
## Tests for FishShoal: fish that cruise the shallows and dart away.


func test_the_shoal_stays_in_the_water_above_the_seabed() -> void:
	var shoal: FishShoal = _new_shoal()
	for step: int in 40:
		var phase: float = TAU * step / 40.0
		var centre: Vector3 = shoal.centre_at(phase)
		assert_float(centre.y).is_less(0.0)
		assert_float(centre.y).is_greater(shoal.shape.height_at(centre.x, centre.z))


func test_the_shoal_roams_about_its_home() -> void:
	var shoal: FishShoal = _new_shoal()
	for step: int in 40:
		var centre: Vector3 = shoal.centre_at(TAU * step / 40.0)
		assert_float(centre.x).is_between(shoal.home_x - shoal.roam.x, shoal.home_x + shoal.roam.x)
		var out: float = -shoal.shape.inland(centre.x, centre.z)
		assert_float(out).is_between(shoal.out_by - shoal.roam.y - 0.001, shoal.out_by + shoal.roam.y + 0.001)


func test_every_fish_is_under_water() -> void:
	var shoal: FishShoal = _new_shoal()
	assert_int(shoal.multimesh.instance_count).is_equal(shoal.count)
	for index: int in shoal.count:
		var fish: Vector3 = shoal.fish_position(index)
		assert_float(fish.y).is_less(0.0)
		assert_float(fish.y).is_greater(shoal.shape.height_at(fish.x, fish.z))


func test_the_shoal_swims_on() -> void:
	var shoal: FishShoal = _new_shoal()
	var before: Vector3 = shoal.centre()
	for tick: int in 30:
		shoal._process(1.0 / 60.0)
	assert_float(shoal.centre().distance_to(before)).is_greater(0.1)


func test_it_darts_when_someone_comes_too_close() -> void:
	var shoal: FishShoal = _new_shoal()
	var wader: Node3D = Node3D.new()
	auto_free(wader)
	add_child(wader)
	shoal.wary_of = wader
	wader.global_position = shoal.centre() + Vector3(30.0, 0.0, 0.0)
	var darts: Dictionary[String, int] = {"count": 0}
	shoal.startled.connect(func() -> void: darts["count"] += 1)
	shoal._process(1.0 / 60.0)
	assert_bool(shoal.is_darting()).is_false()
	wader.global_position = shoal.centre() + Vector3(1.0, 0.6, 0.0)
	shoal._process(1.0 / 60.0)
	assert_bool(shoal.is_darting()).is_true()
	assert_int(darts["count"]).is_equal(1)


func test_a_darting_shoal_swims_faster_then_calms() -> void:
	var calm: FishShoal = _new_shoal()
	var startled: FishShoal = _new_shoal()
	startled.startle()
	var calm_from: Vector3 = calm.centre()
	var startled_from: Vector3 = startled.centre()
	for tick: int in 20:
		calm._process(1.0 / 60.0)
		startled._process(1.0 / 60.0)
	assert_float(startled.centre().distance_to(startled_from)).is_greater(
			calm.centre().distance_to(calm_from) * 2.0)
	for tick: int in int(FishShoal.DART_SECONDS * 60.0) + 5:
		startled._process(1.0 / 60.0)
	assert_bool(startled.is_darting()).is_false()


func _new_shoal() -> FishShoal:
	var shoal: FishShoal = FishShoal.new()
	auto_free(shoal)
	shoal.shape = IslandShape.new()
	shoal.home_x = 5.0
	shoal.count = 12
	shoal.shoal_seed = 4
	# Tests step it themselves.
	shoal.set_process(false)
	add_child(shoal)
	return shoal
