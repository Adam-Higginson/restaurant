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


func test_its_material_gets_the_brush_strokes_at_the_shadows_edge() -> void:
	var style: CharacterStyle = CharacterStyle.new()
	style.brush_strength = 0.35
	style.brush_scale = 90.0

	var material: ShaderMaterial = style.make_material(_painted())

	var strength: float = material.get_shader_parameter(&"brush_strength")
	var scale: float = material.get_shader_parameter(&"brush_scale")
	assert_float(strength).is_equal_approx(0.35, 0.0001)
	assert_float(scale).is_equal_approx(90.0, 0.0001)


func test_the_games_characters_have_painted_shadow_edges_and_no_outline() -> void:
	# The real style (#172): the painted look, without ink.
	var style: CharacterStyle = load("res://data/art/styles/character.tres") as CharacterStyle

	assert_bool(style.outline).is_false()
	assert_float(style.brush_strength).is_greater(0.0)


func _painted() -> StandardMaterial3D:
	var source: StandardMaterial3D = StandardMaterial3D.new()
	source.albedo_color = Color(0.7, 0.5, 0.3)
	source.albedo_texture = PlaceholderTexture2D.new()
	return source
