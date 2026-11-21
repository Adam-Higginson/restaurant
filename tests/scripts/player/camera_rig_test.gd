extends GameTestSuite
## Tests for CameraRig: orbiting, pitch limits, following the player, the
## spring arm pulling in when something is in the way, and gliding to and
## from a camera zone's fixed shot.

const NEAR: Vector3 = Vector3(0.05, 0.05, 0.05)


func test_pitch_stops_at_its_limits() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	scene_runner(rig.get_parent().get_parent())

	rig.orbit(0.0, -500.0)
	assert_float(rad_to_deg(rig.pitch)).is_equal_approx(CameraRig.PITCH_MIN_DEGREES, 0.01)

	rig.orbit(0.0, 500.0)
	assert_float(rad_to_deg(rig.pitch)).is_equal_approx(CameraRig.PITCH_MAX_DEGREES, 0.01)


func test_orbit_turns_left_for_positive_yaw() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	scene_runner(rig.get_parent().get_parent())

	rig.orbit(30.0, 0.0)

	assert_float(rad_to_deg(rig.yaw)).is_equal_approx(30.0, 0.01)


func test_yaw_wraps_round_instead_of_growing() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	scene_runner(rig.get_parent().get_parent())

	rig.orbit(270.0, 0.0)

	assert_float(rad_to_deg(rig.yaw)).is_equal_approx(-90.0, 0.01)


func test_right_stick_right_turns_the_camera_right() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())

	await walk(runner, "camera_right", 20)

	# Turning right (clockwise seen from above) is a negative yaw.
	assert_float(rig.yaw).is_less(-0.1)


func test_right_stick_up_tilts_the_camera_up() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	var start: float = rig.pitch

	await walk(runner, "camera_up", 10)

	assert_float(rig.pitch).is_greater(start)


func test_follows_the_player() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var rig: CameraRig = _rig_of(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	place_player_3d(runner, Vector3(5, 0, -3))

	await physics_ticks(runner, 5)

	var expected: Vector3 = player.global_position + Vector3.UP * rig.height
	assert_vector(rig.global_position).is_equal_approx(expected, Vector3(0.05, 0.05, 0.05))


func test_the_arm_is_full_length_in_open_space() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var arm: SpringArm3D = rig.get_node("Pitch/SpringArm3D") as SpringArm3D
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())

	await physics_ticks(runner, 5)

	assert_float(arm.get_hit_length()).is_equal_approx(arm.spring_length, 0.01)


func test_the_arm_pulls_in_when_something_is_in_the_way() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var rig: CameraRig = _rig_of(player)
	var arm: SpringArm3D = rig.get_node("Pitch/SpringArm3D") as SpringArm3D
	# A wall 2 m behind the player, between it and the camera (which sits
	# behind along +Z at yaw 0).
	var wall: StaticBody3D = static_box(Vector3(10, 10, 0.5), Vector3(0, 2, 2))
	player.get_parent().add_child(wall)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 5)

	assert_float(arm.get_hit_length()).is_less(2.5)


# --- Camera zones -------------------------------------------------------------

func test_glides_to_the_shot_in_a_zone() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var zone: CameraZone = _add_far_zone(rig)
	rig.blend_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	await physics_ticks(runner, 2)

	rig.enter_zone(zone)
	await physics_ticks(runner, 30)

	assert_float(rig.blend).is_equal(1.0)
	assert_vector(_camera_of(rig).global_position).is_equal_approx(
			zone.shot.global_position, NEAR)
	assert_float(CameraRig.yaw_of(_camera_of(rig).global_basis)).is_equal_approx(
			PI / 2.0, 0.01)


func test_glides_back_to_the_free_camera_after_leaving() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var zone: CameraZone = _add_far_zone(rig)
	rig.blend_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	rig.enter_zone(zone)
	await physics_ticks(runner, 30)

	rig.leave_zone(zone)
	await physics_ticks(runner, 30)

	assert_object(rig.active_zone).is_null()
	assert_float(rig.blend).is_equal(0.0)
	var free_spot: Marker3D = rig.get_node("Pitch/SpringArm3D/FreeSpot") as Marker3D
	assert_vector(_camera_of(rig).global_position).is_equal_approx(
			free_spot.global_position, NEAR)


func test_leaving_half_way_glides_back_from_there() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var zone: CameraZone = _add_far_zone(rig)
	rig.blend_seconds = 2.0
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	rig.enter_zone(zone)
	await physics_ticks(runner, 30)
	var part_way: float = rig.blend
	assert_float(part_way).is_between(0.05, 0.95)

	rig.leave_zone(zone)
	await physics_ticks(runner, 5)

	# Heading back down from where it was, not jumping to either end.
	assert_float(rig.blend).is_less(part_way)
	assert_float(rig.blend).is_greater(0.0)


func test_leaving_an_inner_zone_returns_to_the_outer_one() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var outer: CameraZone = _add_far_zone(rig)
	var inner: CameraZone = _add_far_zone(rig)
	scene_runner(rig.get_parent().get_parent())

	rig.enter_zone(outer)
	rig.enter_zone(inner)
	assert_object(rig.active_zone).is_same(inner)

	rig.leave_zone(inner)
	assert_object(rig.active_zone).is_same(outer)

	rig.leave_zone(outer)
	assert_object(rig.active_zone).is_null()


func test_the_camera_cant_be_turned_in_a_zone() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	rig.enter_zone(_add_far_zone(rig))

	await walk(runner, "camera_right", 20)

	assert_float(rig.yaw).is_equal(0.0)


func test_view_yaw_is_the_free_yaw_outside_zones() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())

	rig.yaw = 1.0
	await physics_ticks(runner, 2)

	assert_float(rig.view_yaw).is_equal_approx(1.0, 0.001)


func test_view_yaw_is_the_shot_yaw_in_a_zone() -> void:
	var rig: CameraRig = _rig_of(new_player_3d_on_floor())
	var zone: CameraZone = _add_far_zone(rig)
	rig.blend_seconds = 0.0
	var runner: GdUnitSceneRunner = scene_runner(rig.get_parent().get_parent())
	rig.yaw = 1.0

	rig.enter_zone(zone)
	await physics_ticks(runner, 2)

	assert_float(rig.view_yaw).is_equal_approx(PI / 2.0, 0.001)


func test_yaw_of_reads_the_turn_and_ignores_tilt() -> void:
	assert_float(CameraRig.yaw_of(Basis.IDENTITY)).is_equal_approx(0.0, 0.001)
	assert_float(CameraRig.yaw_of(Basis(Vector3.UP, 1.0))).is_equal_approx(1.0, 0.001)
	# Turned 1 radian, then tilted 30° down.
	var tilted: Basis = Basis.from_euler(Vector3(deg_to_rad(-30.0), 1.0, 0.0))
	assert_float(CameraRig.yaw_of(tilted)).is_equal_approx(1.0, 0.001)
	# Looking straight down with the top of the view towards -X: the same
	# yaw as looking along -X, a quarter turn left.
	var down: Basis = Basis.looking_at(Vector3.DOWN, Vector3.LEFT)
	assert_float(CameraRig.yaw_of(down)).is_equal_approx(PI / 2.0, 0.001)


func test_blend_curve_runs_from_free_to_the_shot() -> void:
	assert_float(CameraRig.blend_curve(0.0)).is_equal_approx(0.0, 0.001)
	assert_float(CameraRig.blend_curve(1.0)).is_equal_approx(1.0, 0.001)
	# Always moving towards the shot, never back.
	var last: float = 0.0
	for i: int in range(1, 11):
		var now: float = CameraRig.blend_curve(i / 10.0)
		assert_float(now).is_greater_equal(last)
		last = now


func _rig_of(player: Player3D) -> CameraRig:
	return player.get_node("CameraRig") as CameraRig


func _camera_of(rig: CameraRig) -> Camera3D:
	return rig.get_node("Camera3D") as Camera3D


# A zone far from the player, so only direct enter_zone calls use it. Its
# shot is 3 m up, turned a quarter turn left (looking along -X).
func _add_far_zone(rig: CameraRig) -> CameraZone:
	var shot: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0, 3, 0))
	var zone: CameraZone = new_camera_zone(Vector3(2, 2, 2), Vector3(15, 1, 15), shot)
	rig.get_parent().get_parent().add_child(zone)
	return zone
