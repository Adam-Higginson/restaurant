extends GameTestSuite
## Tests for FollowCamera: it sits behind and above what it follows, swings
## round after it when it turns, and never rolls with it.


func test_it_starts_behind_and_above() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())

	await physics_ticks(runner, 2)

	# The target faces -Z, so behind is +Z.
	assert_vector(camera.global_position).is_equal_approx(
			Vector3(0, camera.height, camera.distance), Vector3(0.01, 0.01, 0.01))


func test_it_swings_round_after_a_turn() -> void:
	var target: Node3D = Node3D.new()
	var camera: FollowCamera = _camera_following(target)
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	# A quarter turn to port: now facing -X, so behind is +X.
	target.rotation.y = PI / 2.0
	await physics_ticks(runner, 5)
	var partway: Vector3 = camera.global_position
	await physics_ticks(runner, 300)

	assert_float(partway.z).is_greater(1.0)
	assert_vector(camera.global_position).is_equal_approx(
			Vector3(camera.distance, camera.height, 0), Vector3(0.05, 0.05, 0.05))


func test_it_doesnt_roll_with_what_it_follows() -> void:
	var target: Node3D = Node3D.new()
	var camera: FollowCamera = _camera_following(target)
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())

	target.rotation = Vector3(0.2, 0.0, 0.3)
	await physics_ticks(runner, 30)

	# Its own right-hand side stays level.
	assert_float(camera.global_basis.x.y).is_equal_approx(0.0, 0.001)


func test_it_is_not_smoothed_a_second_time() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())

	await physics_ticks(runner, 1)

	# It follows where the target is drawn, which is already smoothed.
	assert_int(camera.physics_interpolation_mode) \
			.is_equal(Node.PHYSICS_INTERPOLATION_MODE_OFF)


func test_look_turns_the_camera_round_the_target() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	camera.look(90.0, 0.0)
	await physics_ticks(runner, 1)

	# Looking left (as CameraRig does for a positive yaw) puts the camera on
	# the target's right (+X), the target facing -Z.
	assert_float(camera.look_yaw).is_equal_approx(PI / 2.0, 0.001)
	assert_vector(camera.global_position).is_equal_approx(
			Vector3(camera.distance, camera.height, 0), Vector3(0.05, 0.05, 0.05))


func test_look_keeps_the_distance_when_it_tilts() -> void:
	var target: Node3D = Node3D.new()
	var camera: FollowCamera = _camera_following(target)
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)
	var focus: Vector3 = Vector3.UP * camera.look_height
	var before: float = camera.global_position.distance_to(focus)

	camera.look(0.0, -30.0)
	await physics_ticks(runner, 1)

	assert_float(camera.global_position.distance_to(focus)).is_equal_approx(before, 0.01)
	# Looking down lifts the camera.
	assert_float(camera.global_position.y).is_greater(camera.height)


func test_holding_the_stick_turns_it_at_stick_speed() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	runner.simulate_action_press("camera_right")
	await physics_ticks(runner, 30)
	runner.simulate_action_release("camera_right")

	# About half a second at 150 degrees a second, turning right (negative).
	assert_float(rad_to_deg(camera.look_yaw)).is_equal_approx(-camera.stick_speed * 0.5, 15.0)


func test_pitch_stays_within_its_limits() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	camera.look(0.0, 1000.0)
	assert_float(rad_to_deg(camera.look_pitch)).is_equal_approx(
			FollowCamera.PITCH_MAX_DEGREES, 0.001)
	camera.look(0.0, -5000.0)
	await physics_ticks(runner, 1)

	assert_float(rad_to_deg(camera.look_pitch)).is_equal_approx(
			FollowCamera.PITCH_MIN_DEGREES, 0.001)
	assert_bool(camera.global_position.is_finite()).is_true()


func test_it_eases_back_behind_after_looking() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	camera.look(120.0, -40.0)
	# return_delay of 1.5 s is 90 ticks; then it eases back.
	await physics_ticks(runner, 90 + 400)

	assert_float(camera.look_yaw).is_equal_approx(0.0, 0.01)
	assert_float(camera.look_pitch).is_equal_approx(0.0, 0.01)
	assert_vector(camera.global_position).is_equal_approx(
			Vector3(0, camera.height, camera.distance), Vector3(0.05, 0.05, 0.05))


func test_it_doesnt_drift_back_while_the_player_is_still_looking() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)

	camera.look(60.0, 0.0)
	for i: int in 20:
		await physics_ticks(runner, 5)
		camera.look(0.1, 0.0)

	# 100 ticks passed, but none with 1.5 s (90 ticks) of quiet.
	assert_float(rad_to_deg(camera.look_yaw)).is_greater(60.0)


func test_zoom_stays_within_its_limits() -> void:
	var camera: FollowCamera = _camera_following(Node3D.new())
	var runner: GdUnitSceneRunner = scene_runner(camera.get_parent())
	await physics_ticks(runner, 2)
	var ratio: float = camera.height / camera.distance

	for i: int in 40:
		runner.simulate_action_pressed("zoom_out")
	await physics_ticks(runner, 120)
	assert_float(camera.distance).is_equal_approx(camera.zoom_max, 0.05)
	assert_float(camera.global_position.y).is_equal_approx(
			camera.zoom_max * ratio, 0.05)

	for i: int in 40:
		runner.simulate_action_pressed("zoom_in")
	await physics_ticks(runner, 120)
	assert_float(camera.distance).is_equal_approx(camera.zoom_min, 0.05)


func _camera_following(target: Node3D) -> FollowCamera:
	var world: Node3D = Node3D.new()
	auto_free(world)
	world.add_child(target)
	var camera: FollowCamera = FollowCamera.new()
	camera.target = target
	world.add_child(camera)
	return camera
