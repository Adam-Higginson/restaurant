extends GameTestSuite
## Tests for the watch at the stern: the swing that dies away when it's
## switched off, and the gilt of the ship's name, which only shows by the
## lamp's light and by lightning.


func test_it_swings_from_side_to_side_within_its_reach() -> void:
	var swing: SternSwing = _new_swing()
	swing.reach = 0.6
	swing.period = 4.0

	assert_float(swing.angle_at(1.0)).is_equal_approx(0.6, 0.001)
	assert_float(swing.angle_at(3.0)).is_equal_approx(-0.6, 0.001)
	assert_float(swing.angle_at(2.0)).is_equal_approx(0.0, 0.001)


func test_switched_off_the_swing_dies_away_instead_of_stopping_dead() -> void:
	var swing: SternSwing = _new_swing()
	swing.settle_speed = 2.0
	await _frames(3)
	assert_float(swing.liveliness).is_equal(1.0)

	swing.swinging = false
	await _frames(6)
	assert_float(swing.liveliness).is_between(0.05, 0.98)

	await get_tree().create_timer(0.8).timeout
	assert_float(swing.liveliness).is_equal(0.0)
	assert_float(swing.rotation.z).is_equal_approx(0.0, 0.0001)


func test_switched_on_again_it_builds_back_up() -> void:
	var swing: SternSwing = _new_swing()
	swing.swinging = false
	swing.settle_speed = 4.0
	await get_tree().create_timer(0.5).timeout
	assert_float(swing.liveliness).is_equal(0.0)

	swing.swinging = true
	await get_tree().create_timer(0.5).timeout

	assert_float(swing.liveliness).is_equal(1.0)


func test_her_name_is_lit_only_while_the_lamp_is_there() -> void:
	var lamp: Node3D = Node3D.new()
	auto_free(lamp)
	add_child(lamp)
	var gilt: NameGilt = _new_gilt()
	assert_float(gilt.lamp_glow()).is_equal(0.0)

	gilt.lamp = lamp
	assert_float(gilt.lamp_glow()).is_equal(1.0)

	lamp.visible = false
	assert_float(gilt.lamp_glow()).is_equal(0.0)


func test_a_weaker_flame_lights_her_name_less() -> void:
	var face: LanternFace = (load("res://scenes/prototype/lantern_body.tscn") as PackedScene) \
			.instantiate() as LanternFace
	auto_free(face)
	add_child(face)
	var gilt: NameGilt = _new_gilt()
	gilt.lamp = face
	gilt.lamp_face = face

	face.strength = 1.0
	var strong: float = gilt.lamp_glow()
	face.strength = 0.0
	var weak: float = gilt.lamp_glow()

	assert_float(strong).is_equal(1.0)
	assert_float(weak).is_between(0.05, 0.5)


func test_the_letters_are_told_where_the_lamp_is_and_about_lightning() -> void:
	var lamp: Node3D = Node3D.new()
	auto_free(lamp)
	add_child(lamp)
	lamp.global_position = Vector3(1.5, 5, 16)
	var gilt: NameGilt = _new_gilt()
	gilt.lamp = lamp
	gilt.set_lightning(0.7)
	await _frames(2)

	var material: ShaderMaterial = gilt.material_override as ShaderMaterial
	var sent: Vector3 = material.get_shader_parameter("lamp")
	assert_vector(sent).is_equal_approx(Vector3(1.5, 5, 16), Vector3(0.001, 0.001, 0.001))
	var flash: float = material.get_shader_parameter("flash")
	var glow: float = material.get_shader_parameter("lamp_glow")
	assert_float(flash).is_equal_approx(0.7, 0.001)
	assert_float(glow).is_equal(1.0)


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _new_swing() -> SternSwing:
	var swing: SternSwing = SternSwing.new()
	auto_free(swing)
	add_child(swing)
	return swing


func _new_gilt() -> NameGilt:
	var gilt: NameGilt = NameGilt.new()
	auto_free(gilt)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/nameboard_gilt.gdshader") as Shader
	gilt.material_override = material
	add_child(gilt)
	return gilt
