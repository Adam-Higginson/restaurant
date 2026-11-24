extends GameTestSuite
## Tests for the lantern spirit's face: his eyes take each look's shape and
## ease between them, he blinks unless his eyes are shut, his flame follows
## his strength and his lean, his glass fogs, streaks and cracks, and a
## cutscene can take his look over and give it back.

const BODY: String = "res://scenes/prototype/lantern_body.tscn"


func test_every_look_has_its_own_eye_shape() -> void:
	var seen: Array[Vector3] = []
	for look: LanternFace.Look in LanternFace.Look.values():
		var shape: Vector3 = LanternFace.SHAPES[look]
		assert_bool(seen.has(shape)).override_failure_message(
				"%s has the same shape as another look" % LanternFace.Look.keys()[look]).is_false()
		seen.append(shape)
	assert_int(seen.size()).is_equal(9)


func test_determined_slants_in_and_worried_slants_out() -> void:
	assert_float(LanternFace.SHAPES[LanternFace.Look.DETERMINED].z).is_greater(0.2)
	assert_float(LanternFace.SHAPES[LanternFace.Look.WORRIED].z).is_less(-0.2)
	# Surprise is bigger than calm; tired and asleep are flat.
	assert_float(LanternFace.SHAPES[LanternFace.Look.SURPRISED].y).is_greater(1.2)
	assert_float(LanternFace.SHAPES[LanternFace.Look.TIRED].y).is_less(0.4)
	assert_float(LanternFace.SHAPES[LanternFace.Look.ASLEEP].y).is_less(0.2)


func test_a_new_look_eases_in_and_arrives() -> void:
	var face: LanternFace = _new_face()
	face.blend_speed = 6.0
	await _frames(2)

	face.expression = LanternFace.Look.SURPRISED
	await _frames(4)
	var part_way: float = face.eye_shape().y
	assert_float(part_way).is_between(1.01, 1.34)

	await get_tree().create_timer(1.2).timeout
	assert_float(face.eye_shape().y).is_equal_approx(1.35, 0.01)
	var left: Node3D = face.get_node("Eyes/EyeLeft") as Node3D
	assert_float(left.scale.y).is_equal_approx(1.35, 0.01)


func test_the_two_eyes_tilt_as_mirror_images() -> void:
	var face: LanternFace = _new_face()
	face.expression = LanternFace.Look.DETERMINED
	face.snap()
	var left: Node3D = face.get_node("Eyes/EyeLeft") as Node3D
	var right: Node3D = face.get_node("Eyes/EyeRight") as Node3D

	assert_float(right.rotation.z).is_equal_approx(0.5, 0.001)
	assert_float(left.rotation.z).is_equal_approx(-0.5, 0.001)


func test_he_blinks_and_his_eyes_open_again() -> void:
	var face: LanternFace = _new_face()
	var eyes: Node3D = face.get_node("Eyes") as Node3D
	await _frames(2)
	assert_float(eyes.scale.y).is_equal(1.0)

	face.blink()
	var smallest: float = 1.0
	for i: int in 12:
		await get_tree().process_frame
		smallest = minf(smallest, eyes.scale.y)
	assert_float(smallest).is_less(0.6)

	await get_tree().create_timer(0.3).timeout
	assert_float(eyes.scale.y).is_equal(1.0)


func test_he_doesnt_blink_with_his_eyes_shut() -> void:
	var face: LanternFace = _new_face()
	var eyes: Node3D = face.get_node("Eyes") as Node3D
	for look: LanternFace.Look in [LanternFace.Look.ASLEEP, LanternFace.Look.EFFORT]:
		face.expression = look
		assert_bool(face.can_blink()).is_false()
		face.blink()
		await _frames(4)
		assert_float(eyes.scale.y).is_equal(1.0)
	face.expression = LanternFace.Look.TIRED
	assert_bool(face.can_blink()).is_true()


func test_his_flame_is_amber_when_strong_and_blue_when_nearly_out() -> void:
	var strong: Color = LanternFace.colour_for(1.0)
	var weak: Color = LanternFace.colour_for(0.0)

	assert_float(strong.r).is_greater(strong.b)
	assert_float(weak.b).is_greater(weak.r)
	# From about half strength up he's fully amber.
	assert_bool(LanternFace.colour_for(0.6).is_equal_approx(strong)).is_true()


func test_his_flame_and_his_light_follow_his_strength() -> void:
	var face: LanternFace = _new_face()
	var light: OmniLight3D = OmniLight3D.new()
	face.add_child(light)
	face.light = light
	face.light_energy = 2.0
	face.snap()
	assert_float(face.flame_size()).is_equal_approx(1.0, 0.001)
	assert_float(light.light_energy).is_equal_approx(2.0, 0.001)

	face.strength = 0.0
	face.snap()

	assert_float(face.flame_size()).is_equal_approx(0.3, 0.001)
	assert_float(light.light_energy).is_less(0.4)
	assert_float(light.light_color.b).is_greater(light.light_color.r)
	assert_float(_glass_number(face, "strength")).is_equal_approx(0.0, 0.001)


func test_his_flame_tips_the_way_he_leans_but_only_so_far() -> void:
	var face: LanternFace = _new_face()

	face.lean = Vector3(5, 0, 0)
	face.snap()

	assert_vector(face.flame_lean()).is_equal_approx(Vector3(1, 0, 0), Vector3(0.001, 0.001, 0.001))
	var glass: ShaderMaterial = _glass(face)
	var sent: Vector3 = glass.get_shader_parameter("lean")
	assert_float(sent.x).is_equal_approx(1.0, 0.001)


func test_his_flame_stands_taller_when_it_swells_and_draws_in_again() -> void:
	var face: LanternFace = _new_face()
	face.strength = 0.5
	face.snap()
	var usual: float = face.flame_size()

	face.swell = 2.0
	face.snap()
	assert_float(face.flame_size()).is_equal_approx(usual * 2.0, 0.001)
	assert_float(_glass_number(face, "swell")).is_equal_approx(2.0, 0.001)

	face.swell = 0.6
	face.snap()
	assert_float(face.flame_size()).is_less(usual)


func test_swelling_eases_in_rather_than_jumping() -> void:
	var face: LanternFace = _new_face()
	face.blend_speed = 6.0
	await _frames(2)

	face.swell = 2.0
	await _frames(3)

	assert_float(face.flame_size()).is_between(1.01, 1.99)


func test_his_door_is_shut_until_he_opens_it_and_then_swings_wide() -> void:
	var face: LanternFace = _new_face()
	var door: Node3D = face.get_node("Door") as Node3D
	assert_float(face.door_open()).is_equal(0.0)
	assert_float(door.rotation.y).is_equal_approx(0.0, 0.001)

	face.door = 1.0
	face.snap()

	assert_float(face.door_open()).is_equal(1.0)
	assert_float(door.rotation.y).is_equal_approx(LanternFace.DOOR_SWING, 0.001)
	# It opens outwards, away from the flame: his front is -Z.
	var edge: Node3D = door.get_node("Edge") as Node3D
	assert_float(face.to_local(edge.global_position).z).is_less(-0.15)


func test_his_glass_fogs_streaks_and_cracks() -> void:
	var face: LanternFace = _new_face()
	face.snap()
	assert_vector(face.glass_state()).is_equal(Vector3.ZERO)

	face.fogged = true
	face.streaked = true
	face.cracked = true
	face.snap()

	assert_vector(face.glass_state()).is_equal(Vector3.ONE)
	assert_float(_glass_number(face, "fog")).is_equal(1.0)
	assert_float(_glass_number(face, "streaks")).is_equal(1.0)
	assert_float(_glass_number(face, "crack")).is_equal(1.0)


func test_a_crack_creeps_in_rather_than_appearing() -> void:
	var face: LanternFace = _new_face()
	await _frames(2)

	face.cracked = true
	await _frames(6)

	assert_float(face.glass_state().z).is_between(0.01, 0.9)


func test_each_lantern_has_its_own_glass_so_one_doesnt_change_another() -> void:
	var one: LanternFace = _new_face()
	var other: LanternFace = _new_face()

	one.fogged = true
	one.snap()
	other.snap()

	assert_float(one.glass_state().x).is_equal(1.0)
	assert_float(other.glass_state().x).is_equal(0.0)
	assert_float(_glass_number(other, "fog")).is_equal(0.0)


func test_his_glass_shader_has_a_dial_for_everything_he_sends() -> void:
	# A shader quietly ignores a value it has no uniform for, so check the
	# glass's shader declares each one (read from its code: headless test
	# runs don't compile shaders).
	var code: String = _glass(_new_face()).shader.code
	for uniform: String in ["float seed", "float strength", "vec3 lean", "float swell",
			"float fog", "float streaks", "float crack"]:
		assert_str(code).override_failure_message("no uniform %s" % uniform) \
				.contains("uniform %s" % uniform)


func test_a_cutscene_can_take_his_look_over_and_give_it_back() -> void:
	var face: LanternFace = _new_face()
	assert_bool(face.directed).is_false()

	assert_bool(face.direct("determined")).is_true()
	assert_int(face.expression).is_equal(LanternFace.Look.DETERMINED)
	assert_bool(face.directed).is_true()

	assert_bool(face.direct("cracked")).is_true()
	assert_bool(face.cracked).is_true()
	assert_bool(face.direct("mended")).is_true()
	assert_bool(face.cracked).is_false()

	face.release()
	assert_bool(face.directed).is_false()


func test_a_word_that_isnt_a_look_changes_nothing() -> void:
	var face: LanternFace = _new_face()

	assert_bool(face.direct("grumpy")).is_false()

	assert_bool(face.directed).is_false()
	assert_int(face.expression).is_equal(LanternFace.Look.CALM)
	assert_bool(LanternFace.knows("pleased")).is_true()
	assert_bool(LanternFace.knows("streaked")).is_true()
	assert_bool(LanternFace.knows("grumpy")).is_false()


func test_every_word_a_script_can_use_does_something() -> void:
	var face: LanternFace = _new_face()
	for word: String in LanternFace.LOOK_WORDS:
		assert_bool(face.direct(word)).override_failure_message(word).is_true()
	for word: String in LanternFace.GLASS_WORDS:
		assert_bool(face.direct(word)).override_failure_message(word).is_true()
	assert_int(LanternFace.LOOK_WORDS.size()).is_equal(LanternFace.Look.size())


# The material his glass is drawn with: his own copy.
func _glass(face: LanternFace) -> ShaderMaterial:
	return (face.get_node("Glass") as MeshInstance3D).material_override as ShaderMaterial


# A number the glass's shader has been given.
func _glass_number(face: LanternFace, parameter: String) -> float:
	var value: float = _glass(face).get_shader_parameter(parameter)
	return value


func _frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame


# A lantern body that never blinks by itself, so tests decide when.
func _new_face() -> LanternFace:
	var face: LanternFace = (load(BODY) as PackedScene).instantiate() as LanternFace
	auto_free(face)
	face.blink_min = 999.0
	face.blink_max = 999.0
	add_child(face)
	return face
