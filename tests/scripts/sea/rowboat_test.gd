extends GameTestSuite
## Tests for Rowboat: rowing ahead and astern, turning, gliding, riding the
## swell, and a current taking the boat over.

const BOAT_SCENE: String = "res://scenes/prototype/intro/rowboat.tscn"
const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"


func test_rowing_ahead_moves_the_boat_forward() -> void:
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_up", 120)

	# The bow faces -Z. From a standstill it takes a few strokes to gather
	# way, so two seconds' rowing goes a couple of metres.
	assert_float(boat.position.z).is_less(-2.0)
	assert_float(absf(boat.position.x)).is_less(0.2)


func test_it_glides_on_after_you_stop_rowing() -> void:
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_up", 120)
	var speed_when_stopped: float = boat.velocity.length()
	var where_stopped: float = boat.position.z
	await physics_ticks(runner, 60)

	# Still moving ahead, but slowing.
	assert_float(boat.position.z).is_less(where_stopped - 0.5)
	assert_float(boat.velocity.length()).is_less(speed_when_stopped)
	assert_float(boat.velocity.length()).is_greater(0.0)


func test_backing_water_moves_it_astern() -> void:
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_down", 120)

	assert_float(boat.position.z).is_greater(0.5)


func test_turning_swings_the_bow_round() -> void:
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_right", 60)
	var to_starboard: float = boat.heading
	await walk(runner, "move_left", 120)

	# Turning right is clockwise from above: the heading goes down.
	assert_float(to_starboard).is_less(-0.3)
	assert_float(boat.heading).is_greater(to_starboard + 0.3)


func test_with_controls_off_the_stick_does_nothing() -> void:
	var boat: Rowboat = _boat_in_world()
	boat.controls_enabled = false
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_up", 60)

	assert_vector(boat.position).is_equal(Vector3.ZERO)
	assert_bool(boat.is_stroking()).is_false()


func test_letting_go_finishes_the_stroke_then_rests_the_oars() -> void:
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_up", 20)
	assert_bool(boat.is_stroking()).is_true()
	# A stroke is 1.3 seconds: well over by then.
	await physics_ticks(runner, 90)

	assert_bool(boat.is_stroking()).is_false()
	assert_float(boat.stroke_phase()).is_equal(0.0)


func test_each_stroke_is_heard_once() -> void:
	var boat: Rowboat = _boat_in_world()
	var strokes: Array[int] = [0]
	boat.stroked.connect(func() -> void: strokes[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	# 2.5 strokes' worth of rowing: the catch of the first, second and third.
	await walk(runner, "move_up", roundi(boat.stroke_seconds * 2.5 * 60.0))

	assert_int(strokes[0]).is_equal(3)


func test_at_full_takeover_the_current_carries_the_boat() -> void:
	# The water runs towards -X; the boat is pointing -Z and rowing hard.
	var current: SeaCurrent = _current(90.0, 3.0, 1.0)
	var boat: Rowboat = _boat_in_world(current)
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await walk(runner, "move_up", 180)

	assert_float(boat.position.x).is_less(-6.0)
	# None of the rowing counted.
	assert_float(absf(boat.position.z)).is_less(0.5)


func test_at_full_takeover_the_oars_still_move() -> void:
	var boat: Rowboat = _boat_in_world(_current(90.0, 3.0, 1.0))
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await hold(runner, "move_up")
	await physics_ticks(runner, 20)

	assert_bool(boat.is_stroking()).is_true()
	assert_float(boat.stroke_phase()).is_greater(0.0)
	await release(runner, "move_up")


func test_at_full_takeover_the_bow_swings_round_with_the_water() -> void:
	var boat: Rowboat = _boat_in_world(_current(90.0, 3.0, 1.0))
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	await physics_ticks(runner, 600)

	# Running towards -X is a heading of a quarter turn.
	assert_float(boat.heading).is_equal_approx(PI / 2.0, 0.05)


func test_a_full_current_outruns_the_hardest_rowing() -> void:
	# Being swept away should feel like the sea taking over, so the current
	# at its full strength (as set up by default) must carry the boat clearly
	# faster than it can row itself.
	var boat: Rowboat = _boat_in_world()
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())
	await walk(runner, "move_up", 300)
	var cruising_from: float = boat.position.z
	await walk(runner, "move_up", 300)
	var cruising_speed: float = (cruising_from - boat.position.z) / 5.0

	var full_current: SeaCurrent = SeaCurrent.new()
	var current_speed: float = full_current.speed
	full_current.free()
	assert_float(current_speed).is_greater(cruising_speed * 1.15)


func test_the_current_takes_its_share_of_the_steering() -> void:
	var current: SeaCurrent = _current(0.0, 3.0, 0.0)
	var boat: Rowboat = _boat_in_world(current)

	assert_float(boat.own_share()).is_equal(1.0)
	current.takeover = 0.25
	assert_float(boat.own_share()).is_equal(0.75)
	current.takeover = 1.0
	assert_float(boat.own_share()).is_equal(0.0)


func test_half_taken_it_rows_less_far() -> void:
	var free_boat: Rowboat = _boat_in_world()
	var free_runner: GdUnitSceneRunner = scene_runner(free_boat.get_parent())
	await walk(free_runner, "move_up", 120)
	var free_distance: float = -free_boat.position.z

	# A current running across the boat's line, so it doesn't add to its way.
	var held_boat: Rowboat = _boat_in_world(_current(90.0, 0.0, 0.5))
	var held_runner: GdUnitSceneRunner = scene_runner(held_boat.get_parent())
	await walk(held_runner, "move_up", 120)

	assert_float(-held_boat.position.z).is_less(free_distance * 0.75)
	assert_float(-held_boat.position.z).is_greater(free_distance * 0.25)


func test_it_rides_on_the_sea() -> void:
	var boat: Rowboat = _boat_in_world(null, true)
	var sea: Sea = boat.get_parent().get_node("Sea") as Sea
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())

	for check: int in 4:
		await physics_ticks(runner, 30)
		assert_float(boat.global_position.y - boat.float_height).is_equal_approx(
				FloatOnSea.surface_height(sea, boat.global_position), 0.3)


func test_it_never_tilts_past_its_limit() -> void:
	var boat: Rowboat = _boat_in_world(null, true)
	boat.max_tilt_degrees = 3.0
	var runner: GdUnitSceneRunner = scene_runner(boat.get_parent())
	var limit: float = deg_to_rad(3.0) + 0.001
	var most: float = 0.0

	for tick: int in 120:
		await physics_ticks(runner, 1)
		most = maxf(most, maxf(absf(boat.rotation.x), absf(boat.rotation.z)))

	assert_float(most).is_less_equal(limit)
	# The night swell is rough enough to reach it.
	assert_float(most).is_greater(deg_to_rad(1.0))


func test_a_stroke_pushes_through_the_drive_only() -> void:
	assert_float(Rowboat.stroke_push(0.0, 0.5)).is_equal(0.0)
	assert_float(Rowboat.stroke_push(0.25, 0.5)).is_equal_approx(1.0, 0.0001)
	assert_float(Rowboat.stroke_push(0.1, 0.5)).is_between(0.1, 0.9)
	assert_float(Rowboat.stroke_push(0.5, 0.5)).is_equal(0.0)
	assert_float(Rowboat.stroke_push(0.8, 0.5)).is_equal(0.0)


func test_tilt_follows_the_heights_under_it() -> void:
	var half: Vector2 = Vector2(0.5, 1.5)
	var limit: float = deg_to_rad(30.0)

	var flat: Vector2 = Rowboat.tilt_from_heights(0.2, 0.2, 0.2, 0.2, half, limit)
	assert_vector(flat).is_equal(Vector2.ZERO)

	# The bow on a crest: it pitches up.
	var bow_up: Vector2 = Rowboat.tilt_from_heights(0.3, 0.0, 0.0, 0.0, half, limit)
	assert_float(bow_up.x).is_equal_approx(atan2(0.3, 3.0), 0.0001)
	assert_float(bow_up.y).is_equal(0.0)

	# The starboard side on a crest: it rolls to port, starboard side up.
	var starboard_up: Vector2 = Rowboat.tilt_from_heights(0.0, 0.0, 0.0, 0.2, half, limit)
	assert_float(starboard_up.y).is_equal_approx(atan2(0.2, 1.0), 0.0001)


func test_tilt_is_limited() -> void:
	var tilt: Vector2 = Rowboat.tilt_from_heights(5.0, -5.0, 5.0, -5.0, Vector2(0.5, 1.5), 0.1)

	assert_vector(tilt).is_equal(Vector2(0.1, -0.1))


func test_forward_and_starboard_are_square_to_each_other() -> void:
	var yaws: Array[float] = [0.0, 0.7, PI / 2.0, -2.0]
	for yaw: float in yaws:
		assert_float(Rowboat.forward_of(yaw).dot(Rowboat.right_of(yaw))).is_equal_approx(0.0, 0.0001)
	assert_vector(Rowboat.forward_of(0.0)).is_equal_approx(Vector2(0, -1), Vector2(0.0001, 0.0001))
	assert_vector(Rowboat.right_of(0.0)).is_equal_approx(Vector2(1, 0), Vector2(0.0001, 0.0001))


# A rowboat at the origin facing -Z, in a world freed after the test, with
# [param current] (if any) and a sea (if [param with_sea]) beside it.
func _boat_in_world(current: SeaCurrent = null, with_sea: bool = false) -> Rowboat:
	var world: Node3D = Node3D.new()
	auto_free(world)
	if current != null:
		world.add_child(current)
	if with_sea:
		var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
		sea.name = "Sea"
		world.add_child(sea)
	var boat: Rowboat = (load(BOAT_SCENE) as PackedScene).instantiate() as Rowboat
	boat.current = current
	world.add_child(boat)
	return boat


func _current(degrees: float, speed: float, takeover: float) -> SeaCurrent:
	var current: SeaCurrent = SeaCurrent.new()
	current.direction_degrees = degrees
	current.speed = speed
	current.takeover = takeover
	return current
