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


func _camera_following(target: Node3D) -> FollowCamera:
	var world: Node3D = Node3D.new()
	auto_free(world)
	world.add_child(target)
	var camera: FollowCamera = FollowCamera.new()
	camera.target = target
	world.add_child(camera)
	return camera
