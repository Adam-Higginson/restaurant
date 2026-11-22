extends GameTestSuite
## Tests for the thing's eye: shut, there's nothing to see whatever the
## light; open, it shows only while lightning is on it and for a moment
## after; and how far it's open and how much light is on it reach the
## shader that draws it.

const SHADER: Shader = preload("res://shaders/thing_eye.gdshader")


func test_in_the_dark_theres_nothing_to_see_even_open() -> void:
	var eye: ThingEye = _new_eye()

	eye.open = 1.0

	assert_bool(eye.is_showing()).is_false()
	assert_bool(eye.visible).is_false()
	assert_bool(eye.is_in_group(Lightning.LIT_GROUP)).is_true()


func test_shut_theres_nothing_to_see_even_in_a_flash() -> void:
	var eye: ThingEye = _new_eye()

	eye.set_lightning(1.0)

	assert_bool(eye.is_showing()).is_false()
	assert_bool(eye.visible).is_false()


func test_open_in_a_flash_it_shows() -> void:
	var eye: ThingEye = _new_eye()
	eye.open = 0.8

	eye.set_lightning(0.9)

	assert_bool(eye.is_showing()).is_true()
	assert_bool(eye.visible).is_true()
	assert_float(_number(eye, "open")).is_equal_approx(0.8, 0.001)
	assert_float(_number(eye, "shine")).is_equal_approx(0.9, 0.001)


func test_it_lingers_a_moment_after_the_flash_and_then_its_gone() -> void:
	var eye: ThingEye = _new_eye()
	eye.linger_seconds = 0.5
	eye.open = 1.0
	eye.set_lightning(1.0)
	eye.set_lightning(0.0)

	# The flash is over, but the eye hasn't gone yet.
	assert_float(eye.shine()).is_equal(1.0)
	eye.fade(0.25)
	assert_float(eye.shine()).is_equal_approx(0.5, 0.001)
	assert_bool(eye.is_showing()).is_true()

	eye.fade(0.3)
	assert_float(eye.shine()).is_equal(0.0)
	assert_bool(eye.is_showing()).is_false()


func test_while_the_flash_lasts_it_doesnt_fade() -> void:
	var eye: ThingEye = _new_eye()
	eye.open = 1.0
	eye.set_lightning(0.75)

	eye.fade(5.0)

	assert_float(eye.shine()).is_equal_approx(0.75, 0.001)


func _number(eye: ThingEye, parameter: String) -> float:
	var value: float = (eye.material_override as ShaderMaterial).get_shader_parameter(parameter)
	return value


# An eye, shut, in the dark. It doesn't fade by itself: tests say when.
func _new_eye() -> ThingEye:
	var eye: ThingEye = ThingEye.new()
	auto_free(eye)
	eye.mesh = QuadMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	eye.material_override = material
	add_child(eye)
	eye.set_process(false)
	return eye
