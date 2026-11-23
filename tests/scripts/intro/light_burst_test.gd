extends GameTestSuite
## Tests for the burst of light when the lantern catches alight again:
## nothing shows until it begins, it shoots out and slows, it's brightest
## as it starts, and it's gone when it's spent.

const SHADER: Shader = preload("res://shaders/light_burst.gdshader")


func test_nothing_shows_until_it_begins_or_once_its_spent() -> void:
	var burst: LightBurst = _new_burst()
	assert_bool(burst.is_showing()).is_false()
	assert_float(burst.brightness_now()).is_equal(0.0)
	assert_float(_brightness_sent(burst)).is_equal(0.0)

	burst.spread = 0.3
	assert_bool(burst.is_showing()).is_true()

	burst.spread = 1.0
	assert_bool(burst.is_showing()).is_false()
	assert_float(burst.brightness_now()).is_equal(0.0)
	assert_float(_brightness_sent(burst)).is_equal(0.0)
	# It's drawn all along, dark, so nothing has to be prepared mid-scene.
	assert_bool(burst.visible).is_true()


func test_it_shoots_out_and_then_slows() -> void:
	var burst: LightBurst = _new_burst()
	burst.reach = 40.0

	burst.spread = 0.25
	var early: float = burst.size_now()
	burst.spread = 0.5
	var middle: float = burst.size_now()
	burst.spread = 1.0
	var spent: float = burst.size_now()

	# More ground covered in the first quarter than in the second.
	assert_float(early).is_greater(middle - early)
	assert_float(spent).is_equal_approx(40.0, 0.001)
	assert_float(burst.scale.x).is_equal_approx(40.0, 0.001)


func test_its_brightest_as_it_starts_and_fades_as_it_spreads() -> void:
	var burst: LightBurst = _new_burst()
	burst.brightness = 2.0

	burst.spread = 0.05
	var at_first: float = burst.brightness_now()
	burst.spread = 0.6
	var later: float = burst.brightness_now()

	assert_float(at_first).is_greater(later)
	assert_float(later).is_greater(0.0)
	assert_float(_brightness_sent(burst)).is_equal_approx(later, 0.001)


func _brightness_sent(burst: LightBurst) -> float:
	var value: float = (burst.material_override as ShaderMaterial).get_shader_parameter(
			"brightness")
	return value


func _new_burst() -> LightBurst:
	var burst: LightBurst = LightBurst.new()
	auto_free(burst)
	burst.mesh = SphereMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	burst.material_override = material
	add_child(burst)
	return burst
