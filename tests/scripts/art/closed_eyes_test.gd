extends GameTestSuite
## Tests for ClosedEyes: it writes where a character's eyes are into a
## stylised material, only on the body (not the clothes), and the boy has
## them.


func test_it_writes_each_eye_and_the_lash_into_a_material() -> void:
	var eyes: ClosedEyes = ClosedEyes.new()
	eyes.right_eye = Vector4(-3.7, 10.3, 2.4, 1.6)
	eyes.left_eye = Vector4(4.4, 10.6, 2.5, 1.8)
	eyes.tilt = Vector2(-0.2, 0.25)
	eyes.lash_sag = 0.4
	var material: ShaderMaterial = _material()

	eyes.apply(material)

	assert_that(material.get_shader_parameter(&"lid_right")).is_equal(Vector4(-3.7, 10.3, 2.4, 1.6))
	assert_that(material.get_shader_parameter(&"lid_left")).is_equal(Vector4(4.4, 10.6, 2.5, 1.8))
	assert_that(material.get_shader_parameter(&"lid_tilt")).is_equal(Vector2(-0.2, 0.25))
	var sag: float = material.get_shader_parameter(&"lash_sag")
	assert_float(sag).is_equal_approx(0.4, 0.0001)


func test_they_are_drawn_on_the_body_not_the_clothes() -> void:
	var body: MeshInstance3D = _styled_mesh("Body")
	var shirt: MeshInstance3D = _styled_mesh("Outfit_Shirt")
	var meshes: Array[MeshInstance3D] = [body, shirt]
	var eyes: ClosedEyes = ClosedEyes.new()
	eyes.left_eye = Vector4(4.0, 10.0, 2.0, 1.5)

	var drawn: Array[MeshInstance3D] = CharacterModel.draw_closed_eyes(meshes, eyes)

	assert_array(drawn).contains_exactly([body])
	assert_that(_material_of(body).get_shader_parameter(&"lid_left")).is_equal(eyes.left_eye)
	assert_that(_material_of(shirt).get_shader_parameter(&"lid_left")).is_null()


func test_without_closed_eyes_nothing_is_drawn() -> void:
	var meshes: Array[MeshInstance3D] = [_styled_mesh("Body")]

	assert_array(CharacterModel.draw_closed_eyes(meshes, null)).is_empty()


func test_the_boys_eyes_are_drawn_closed() -> void:
	# The real resource: his face has a ring round each eye, so painting the
	# eye over leaves it looking blank, not shut.
	var boy: CharacterParts = load("res://data/characters/boy.tres") as CharacterParts

	assert_object(boy.whole_closed_eyes).is_not_null()
	assert_float(boy.whole_closed_eyes.left_eye.z).is_greater(0.0)


func _material() -> ShaderMaterial:
	return CharacterStyle.new().make_material(StandardMaterial3D.new())


func _styled_mesh(called: String) -> MeshInstance3D:
	var mesh_node: MeshInstance3D = MeshInstance3D.new()
	mesh_node.name = called
	mesh_node.mesh = BoxMesh.new()
	mesh_node.set_surface_override_material(0, _material())
	auto_free(mesh_node)
	return mesh_node


func _material_of(mesh_node: MeshInstance3D) -> ShaderMaterial:
	return mesh_node.get_active_material(0) as ShaderMaterial
