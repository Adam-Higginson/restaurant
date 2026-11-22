extends GameTestSuite
## Tests for the watch at the stern: the swing that dies away when it's
## switched off, the ship's carved name, lit from wherever the lamp is and
## by lightning, and the lit windows turned down behind it.


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
	var carved: CarvedName = _new_name()
	assert_float(carved.lamp_glow()).is_equal(0.0)

	carved.lamp = lamp
	assert_float(carved.lamp_glow()).is_equal(1.0)

	lamp.visible = false
	assert_float(carved.lamp_glow()).is_equal(0.0)


func test_a_weaker_flame_lights_her_name_less() -> void:
	var face: LanternFace = (load("res://scenes/prototype/lantern_body.tscn") as PackedScene) \
			.instantiate() as LanternFace
	auto_free(face)
	add_child(face)
	var carved: CarvedName = _new_name()
	carved.lamp = face
	carved.lamp_face = face

	face.strength = 1.0
	var strong: float = carved.lamp_glow()
	face.strength = 0.0
	var weak: float = carved.lamp_glow()

	assert_float(strong).is_equal(1.0)
	assert_float(weak).is_between(0.05, 0.5)


func test_the_letters_are_told_where_the_lamp_is_and_about_lightning() -> void:
	var lamp: Node3D = Node3D.new()
	auto_free(lamp)
	add_child(lamp)
	lamp.global_position = Vector3(1.5, 5, 16)
	var carved: CarvedName = _new_name()
	carved.lamp = lamp
	carved.set_lightning(0.7)
	await _frames(2)

	var material: ShaderMaterial = carved.material_override as ShaderMaterial
	# Told in the plank's own space: the plank is at the origin here.
	var sent: Vector3 = material.get_shader_parameter("lamp")
	assert_vector(sent).is_equal_approx(Vector3(1.5, 5, 16), Vector3(0.001, 0.001, 0.001))
	var flash: float = material.get_shader_parameter("flash")
	var glow: float = material.get_shader_parameter("lamp_glow")
	assert_float(flash).is_equal_approx(0.7, 0.001)
	assert_float(glow).is_equal(1.0)


func test_the_lamps_place_is_measured_from_the_plank_whichever_way_it_faces() -> void:
	var lamp: Node3D = Node3D.new()
	auto_free(lamp)
	add_child(lamp)
	lamp.global_position = Vector3(10, 2, 0)
	var carved: CarvedName = _new_name()
	carved.lamp = lamp
	# The plank is 8 m along x and turned a quarter turn, as on a ship
	# sailing another way.
	carved.global_position = Vector3(8, 2, 0)
	carved.rotation.y = PI / 2.0
	await _frames(2)

	var material: ShaderMaterial = carved.material_override as ShaderMaterial
	var sent: Vector3 = material.get_shader_parameter("lamp")
	assert_vector(sent).is_equal_approx(carved.to_local(lamp.global_position),
			Vector3(0.001, 0.001, 0.001))
	assert_float(sent.length()).is_equal_approx(2.0, 0.001)


func test_the_name_is_written_on_the_mask_the_carving_is_cut_from() -> void:
	var carved: CarvedName = _new_name()
	assert_str(carved.written()).is_equal("SALT AND EMBER")

	carved.text = "HERON"

	assert_str(carved.written()).is_equal("HERON")
	var words: Label = carved.get_node("Mask/Words") as Label
	assert_str(words.text).is_equal("HERON")


func test_the_windows_turn_down_gently_and_back_up() -> void:
	var glow: StandardMaterial3D = _new_glow(2.4)
	var dimmer: WindowDimmer = _new_dimmer(glow)
	dimmer.dim_to = 0.25
	dimmer.seconds = 0.4
	await _frames(2)
	assert_float(glow.emission_energy_multiplier).is_equal_approx(2.4, 0.001)

	dimmer.dimmed = true
	await _frames(6)
	assert_float(dimmer.level).is_between(0.3, 0.98)

	await get_tree().create_timer(0.6).timeout
	assert_float(dimmer.level).is_equal_approx(0.25, 0.001)
	assert_float(glow.emission_energy_multiplier).is_equal_approx(0.6, 0.001)

	dimmer.dimmed = false
	await get_tree().create_timer(0.6).timeout
	assert_float(glow.emission_energy_multiplier).is_equal_approx(2.4, 0.001)


func test_switched_right_off_a_window_is_a_dark_pane_and_lit_again_after() -> void:
	var glow: StandardMaterial3D = _new_glow(2.4)
	glow.albedo_color = Color(1.0, 0.7, 0.36)
	var dimmer: WindowDimmer = _new_dimmer(glow)
	dimmer.dim_to = 0.0
	dimmer.seconds = 0.0
	dimmer.unlit = Color(0.1, 0.1, 0.1)

	dimmer.dimmed = true
	await _frames(3)
	assert_float(glow.emission_energy_multiplier).is_equal(0.0)
	assert_bool(glow.albedo_color.is_equal_approx(Color(0.1, 0.1, 0.1))).is_true()

	dimmer.dimmed = false
	await _frames(3)
	assert_float(glow.emission_energy_multiplier).is_equal_approx(2.4, 0.001)
	assert_bool(glow.albedo_color.is_equal_approx(Color(1.0, 0.7, 0.36))).is_true()


func test_the_windows_glow_is_put_back_when_the_scene_closes() -> void:
	var glow: StandardMaterial3D = _new_glow(2.4)
	var dimmer: WindowDimmer = WindowDimmer.new()
	dimmer.glow = glow
	dimmer.seconds = 0.0
	dimmer.dimmed = true
	add_child(dimmer)
	await _frames(3)
	assert_float(glow.emission_energy_multiplier).is_less(1.0)

	dimmer.free()

	assert_float(glow.emission_energy_multiplier).is_equal_approx(2.4, 0.001)


func test_a_dimmer_with_no_windows_does_nothing() -> void:
	var dimmer: WindowDimmer = _new_dimmer(null)
	dimmer.dimmed = true
	await _frames(3)

	assert_float(dimmer.level).is_equal(1.0)


func _new_glow(energy: float) -> StandardMaterial3D:
	var glow: StandardMaterial3D = StandardMaterial3D.new()
	glow.emission_enabled = true
	glow.emission_energy_multiplier = energy
	return glow


func _new_dimmer(glow: StandardMaterial3D) -> WindowDimmer:
	var dimmer: WindowDimmer = WindowDimmer.new()
	auto_free(dimmer)
	dimmer.glow = glow
	add_child(dimmer)
	return dimmer


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


func _new_swing() -> SternSwing:
	var swing: SternSwing = SternSwing.new()
	auto_free(swing)
	add_child(swing)
	return swing


func _new_name() -> CarvedName:
	var carved: CarvedName = CarvedName.new()
	auto_free(carved)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/carved_name.gdshader") as Shader
	carved.material_override = material
	# The mask the letters are cut from: an off-screen screen with a label.
	var mask: SubViewport = SubViewport.new()
	mask.name = "Mask"
	var words: Label = Label.new()
	words.name = "Words"
	mask.add_child(words)
	carved.add_child(mask)
	add_child(carved)
	return carved
