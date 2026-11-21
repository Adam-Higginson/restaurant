extends GameTestSuite
## Tests for CameraRig: orbiting, pitch limits, following the player, and the
## spring arm pulling in when something is in the way.


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


func _rig_of(player: Player3D) -> CameraRig:
	return player.get_node("CameraRig") as CameraRig
