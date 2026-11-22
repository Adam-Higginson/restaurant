extends GameTestSuite
## Tests for the lens over the underwater set's camera: it works out where
## the lantern is on screen so the water round him can shimmer, the shimmer
## covers more of the screen the nearer he is, nothing shimmers when he's
## behind the camera or not there, and the picture's brightness reaches the
## shader.

const SHADER: Shader = preload("res://shaders/underwater_lens.gdshader")
const SCREEN: Vector2 = Vector2(1152, 648)


func test_something_dead_ahead_is_in_the_middle_of_the_screen() -> void:
	var camera: Camera3D = _new_camera()

	var seen: Vector3 = UnderwaterLens.spot_on_screen(camera, Vector3(0, 0, -5),
			Vector2(camera.get_viewport().get_visible_rect().size))

	assert_float(seen.x).is_equal_approx(0.5, 0.01)
	assert_float(seen.y).is_equal_approx(0.5, 0.01)
	assert_float(seen.z).is_equal_approx(5.0, 0.001)


func test_something_up_and_to_the_right_is_up_and_to_the_right_on_screen() -> void:
	var camera: Camera3D = _new_camera()

	var seen: Vector3 = UnderwaterLens.spot_on_screen(camera, Vector3(1, 1, -5),
			Vector2(camera.get_viewport().get_visible_rect().size))

	assert_float(seen.x).is_greater(0.5)
	# Down the screen is bigger, so up is smaller.
	assert_float(seen.y).is_less(0.5)


func test_something_behind_the_camera_is_behind() -> void:
	var camera: Camera3D = _new_camera()

	var seen: Vector3 = UnderwaterLens.spot_on_screen(camera, Vector3(0, 0, 4), SCREEN)

	assert_float(seen.z).is_less(0.0)


func test_the_shimmer_covers_more_of_the_screen_the_nearer_he_is() -> void:
	var camera: Camera3D = _new_camera()
	var lens: UnderwaterLens = _new_lens(camera)

	var near: float = lens.reach_on_screen(camera, 1.5)
	var far: float = lens.reach_on_screen(camera, 8.0)

	assert_float(near).is_greater(far)
	assert_float(far).is_greater(0.0)
	assert_float(lens.reach_on_screen(camera, -1.0)).is_equal(0.0)


func test_the_water_shimmers_where_the_lantern_is_and_not_when_hes_behind() -> void:
	var camera: Camera3D = _new_camera()
	var lens: UnderwaterLens = _new_lens(camera)
	var lantern: Node3D = Node3D.new()
	camera.get_parent().add_child(lantern)
	lens.heat_source = lantern
	lens.heat = 0.8

	lantern.position = Vector3(0, 0, -4)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(_number(lens, "heat")).is_equal_approx(0.8, 0.001)
	var spot: Vector2 = (lens.material_override as ShaderMaterial).get_shader_parameter(
			"heat_spot")
	assert_float(spot.x).is_equal_approx(0.5, 0.01)

	lantern.position = Vector3(0, 0, 4)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(_number(lens, "heat")).is_equal(0.0)


func test_with_no_lantern_nothing_shimmers() -> void:
	var camera: Camera3D = _new_camera()
	var lens: UnderwaterLens = _new_lens(camera)

	await get_tree().process_frame
	await get_tree().process_frame

	assert_float(_number(lens, "heat")).is_equal(0.0)


func test_the_pictures_brightness_reaches_the_shader() -> void:
	var lens: UnderwaterLens = _new_lens(_new_camera())

	lens.exposure = 1.8

	assert_float(_number(lens, "exposure")).is_equal_approx(1.8, 0.001)


func _number(lens: UnderwaterLens, parameter: String) -> float:
	var value: float = (lens.material_override as ShaderMaterial).get_shader_parameter(parameter)
	return value


# A camera at the middle of a world of its own, looking along -Z.
func _new_camera() -> Camera3D:
	var world: Node3D = Node3D.new()
	auto_free(world)
	add_child(world)
	var camera: Camera3D = Camera3D.new()
	camera.fov = 60.0
	world.add_child(camera)
	camera.make_current()
	return camera


func _new_lens(camera: Camera3D) -> UnderwaterLens:
	var lens: UnderwaterLens = UnderwaterLens.new()
	lens.mesh = QuadMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	lens.material_override = material
	camera.add_child(lens)
	return lens
