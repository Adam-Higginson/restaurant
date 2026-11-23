extends GameTestSuite
## Tests for the hand of fire the lantern offers: it's not there until it
## reaches, its shape, grip and strength reach the shader that draws it, the
## light in its palm rides out with it and dims with it, and it's as strong
## as whoever's hand it is.

const SHADER: Shader = preload("res://shaders/flame_hand.gdshader")
const BODY: PackedScene = preload("res://scenes/prototype/lantern_body.tscn")
const NEAR: Vector3 = Vector3(0.001, 0.001, 0.001)


func test_it_isnt_there_until_it_reaches() -> void:
	var hand: FlameHand = _new_hand()
	assert_bool(hand.visible).is_false()

	hand.reach = 0.4

	assert_bool(hand.visible).is_true()
	assert_float(_number(hand, "reach")).is_equal_approx(0.4, 0.001)


func test_its_shape_and_grip_reach_the_shader() -> void:
	var hand: FlameHand = _new_hand()

	hand.form = 0.25
	hand.grip = 0.8

	assert_float(_number(hand, "form")).is_equal_approx(0.25, 0.001)
	assert_float(_number(hand, "grip")).is_equal_approx(0.8, 0.001)


func test_what_its_given_stays_between_nothing_and_all() -> void:
	var hand: FlameHand = _new_hand()

	hand.reach = 3.0
	hand.form = -2.0

	assert_float(hand.reach).is_equal(1.0)
	assert_float(hand.form).is_equal(0.0)


func test_the_palm_rides_out_along_the_arm_as_it_reaches() -> void:
	var hand: FlameHand = _new_hand()

	hand.reach = 0.0
	var near: float = hand.palm_position().x
	hand.reach = 1.0
	var far: float = hand.palm_position().x

	# The sheet is 1.6 long, running along -X from the wrist.
	assert_float(far).is_equal_approx(-1.6 * FlameHand.PALM_AT_FULL_REACH, 0.001)
	assert_float(far).is_less(near)


func test_the_light_in_its_palm_goes_out_with_it_and_dims_with_it() -> void:
	var hand: FlameHand = _new_hand()
	var light: OmniLight3D = OmniLight3D.new()
	hand.get_parent().add_child(light)
	hand.light = light
	hand.light_energy = 2.0
	hand.position = Vector3(1, 2, 3)

	hand.reach = 1.0
	assert_float(light.light_energy).is_equal_approx(2.0, 0.001)
	assert_vector(light.position).is_equal_approx(
			Vector3(1, 2, 3) + hand.palm_position(), NEAR)

	# A wisp lights less than a hand, and a weak flame less than a strong one.
	hand.form = 0.0
	var as_a_wisp: float = light.light_energy
	assert_float(as_a_wisp).is_less(2.0)
	hand.strength = 0.1
	assert_float(light.light_energy).is_less(as_a_wisp)
	assert_float(light.light_color.b).is_greater(light.light_color.r)

	hand.reach = 0.0
	assert_float(light.light_energy).is_equal(0.0)


func test_shafts_of_light_fan_out_only_once_it_closes_on_yours() -> void:
	var hand: FlameHand = _new_hand()
	var rays: MeshInstance3D = MeshInstance3D.new()
	rays.mesh = QuadMesh.new()
	var fan: ShaderMaterial = ShaderMaterial.new()
	fan.shader = preload("res://shaders/light_rays.gdshader")
	rays.material_override = fan
	hand.get_parent().add_child(rays)
	hand.rays = rays
	hand.rays_brightness = 2.0

	# Held out but not taken: no shafts. (The sheet is drawn, dark, so
	# nothing has to be prepared when the hands meet.)
	hand.reach = 1.0
	assert_bool(rays.visible).is_true()
	assert_float(hand.rays_now()).is_equal(0.0)
	var before: float = fan.get_shader_parameter("brightness")
	assert_float(before).is_equal(0.0)

	# Closed on yours: they fan out from the palm, at their brightest
	# when he's strong.
	hand.grip = 1.0
	assert_bool(rays.visible).is_true()
	assert_float(hand.rays_now()).is_equal_approx(2.0, 0.001)
	assert_vector(rays.position).is_equal_approx(hand.palm_position(), NEAR)
	var sent: float = fan.get_shader_parameter("brightness")
	assert_float(sent).is_equal_approx(2.0, 0.001)

	hand.strength = 0.1
	assert_float(hand.rays_now()).is_between(0.1, 1.0)


func test_its_as_strong_as_whoevers_hand_it_is() -> void:
	var hand: FlameHand = _new_hand()
	var face: LanternFace = BODY.instantiate() as LanternFace
	hand.get_parent().add_child(face)
	hand.face = face
	hand.reach = 1.0

	face.strength = 0.2
	await get_tree().process_frame
	await get_tree().process_frame

	assert_float(hand.strength).is_equal_approx(0.2, 0.001)
	assert_float(_number(hand, "strength")).is_equal_approx(0.2, 0.001)


func test_each_hand_has_its_own_material() -> void:
	var one: FlameHand = _new_hand()
	var other: FlameHand = _new_hand()

	one.reach = 1.0

	assert_float(_number(other, "reach")).is_equal_approx(0.0, 0.001)


# A number the hand's shader has been given.
func _number(hand: FlameHand, parameter: String) -> float:
	var value: float = (hand.material_override as ShaderMaterial).get_shader_parameter(parameter)
	return value


# A hand on a sheet 1.6 long, under a parent of its own, not reaching yet.
func _new_hand() -> FlameHand:
	var parent: Node3D = Node3D.new()
	auto_free(parent)
	add_child(parent)
	var hand: FlameHand = FlameHand.new()
	var sheet: QuadMesh = QuadMesh.new()
	sheet.size = Vector2(1.6, 1.0)
	hand.mesh = sheet
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	hand.material_override = material
	parent.add_child(hand)
	return hand
