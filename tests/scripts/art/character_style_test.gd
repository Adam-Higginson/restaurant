extends GameTestSuite
## Tests for CharacterStyle: the stylised look's materials carry each
## surface's own paint, get the style's settings and an outline.


func test_its_material_keeps_the_surfaces_own_texture_and_colour() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	var source: StandardMaterial3D = _painted()

	var material: ShaderMaterial = style.make_material(source)

	assert_object(material.shader).is_same(CharacterStyle.SHADER)
	assert_object(material.get_shader_parameter(&"albedo_texture")).is_same(source.albedo_texture)
	assert_that(material.get_shader_parameter(&"albedo_color")).is_equal(source.albedo_color)


func test_its_material_gets_the_styles_settings() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	style.shadow_threshold = 0.3
	style.bands = 3
	style.shadow_color = Color(0.6, 0.4, 0.3)

	var material: ShaderMaterial = style.make_material(_painted())

	var threshold: float = material.get_shader_parameter(&"shadow_threshold")
	var bands: int = material.get_shader_parameter(&"bands")
	assert_float(threshold).is_equal_approx(0.3, 0.0001)
	assert_int(bands).is_equal(3)
	assert_that(material.get_shader_parameter(&"shadow_color")).is_equal(Color(0.6, 0.4, 0.3))


func test_every_surface_shares_one_outline_drawn_after_it() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	style.outline_thickness = 2.5

	var first: ShaderMaterial = style.make_material(_painted())
	var second: ShaderMaterial = style.make_material(_painted())

	var outline: ShaderMaterial = first.next_pass as ShaderMaterial
	assert_object(outline).is_not_null()
	assert_object(outline.shader).is_same(CharacterStyle.OUTLINE_SHADER)
	assert_object(second.next_pass).is_same(outline)
	var thickness: float = outline.get_shader_parameter(&"thickness")
	assert_float(thickness).is_equal_approx(2.5, 0.0001)


func test_without_an_outline_nothing_is_drawn_after_it() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	style.outline = false

	assert_object(style.make_material(_painted()).next_pass).is_null()


func test_changing_a_setting_says_so() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	var heard: Array[bool] = [false]
	style.changed.connect(func() -> void: heard[0] = true)

	style.rim_strength = 0.8

	assert_bool(heard[0]).is_true()


func _painted() -> StandardMaterial3D:
	var source: StandardMaterial3D = StandardMaterial3D.new()
	source.albedo_color = Color(0.7, 0.5, 0.3)
	source.albedo_texture = PlaceholderTexture2D.new()
	return source
