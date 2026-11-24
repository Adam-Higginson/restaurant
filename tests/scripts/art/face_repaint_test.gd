extends GameTestSuite
## Tests for FaceRepaint: it writes its mouth and brows into a stylised
## material, takes them off again, and the boy's face has one.


func test_it_turns_the_mouth_on_in_a_material_with_its_measurements() -> void:
	var face: FaceRepaint = FaceRepaint.new()
	face.mouth_centre = Vector2(0.3, 6.5)
	face.mouth_size = Vector2(4.0, 1.2)
	face.line_centre = Vector2(0.1, 6.4)
	face.line_half_width = 1.5
	face.line_curve = -0.2
	var material: ShaderMaterial = _material()

	face.apply(material)

	assert_float(_number(material, &"mouth_paint")).is_equal(1.0)
	assert_that(material.get_shader_parameter(&"mouth_area")).is_equal(Vector4(0.3, 6.5, 4.0, 1.2))
	assert_that(material.get_shader_parameter(&"mouth_line")).is_equal(Vector3(0.1, 6.4, 1.5))
	assert_float(_number(material, &"mouth_curve")).is_equal_approx(-0.2, 0.0001)


func test_the_brows_are_only_repainted_when_asked() -> void:
	var face: FaceRepaint = FaceRepaint.new()
	var material: ShaderMaterial = _material()

	face.apply(material)

	assert_float(_number(material, &"brow_paint")).is_equal(0.0)


func test_with_brows_it_writes_the_new_brows_ends_and_shape() -> void:
	var face: FaceRepaint = FaceRepaint.new()
	face.brows = true
	face.brow_inner = Vector2(1.3, 13.3)
	face.brow_outer = Vector2(5.3, 13.55)
	face.brow_thickness = Vector2(0.7, 0.2)
	var material: ShaderMaterial = _material()

	face.apply(material)

	assert_float(_number(material, &"brow_paint")).is_equal(1.0)
	assert_that(material.get_shader_parameter(&"brow_line")).is_equal(Vector4(1.3, 13.3, 5.3, 13.55))
	assert_that(material.get_shader_parameter(&"brow_thickness")).is_equal(Vector2(0.7, 0.2))


func test_clearing_it_shows_the_faces_own_mouth_and_brows_again() -> void:
	var face: FaceRepaint = FaceRepaint.new()
	face.brows = true
	var material: ShaderMaterial = _material()
	face.apply(material)

	FaceRepaint.clear(material)

	assert_float(_number(material, &"mouth_paint")).is_equal(0.0)
	assert_float(_number(material, &"brow_paint")).is_equal(0.0)


func test_the_boys_face_is_repainted_mouth_and_brows() -> void:
	# The real resource: his model is made grinning, with brows that read as
	# a scowl from above.
	var boy: CharacterParts = load("res://data/characters/boy.tres") as CharacterParts

	assert_object(boy.whole_face).is_not_null()
	assert_bool(boy.whole_face.brows).is_true()


func _material() -> ShaderMaterial:
	return CharacterStyle.new().make_material(StandardMaterial3D.new())


func _number(material: ShaderMaterial, parameter: StringName) -> float:
	return material.get_shader_parameter(parameter)
