extends GameTestSuite
## Tests for ThirdPartyModel: dressing a scene with a model when its file is
## there, fitting it to a box, and leaving the greybox when it isn't.
##
## Third-party files aren't in the repo, so these use a small test scene as
## the "model": a painted 1.1 x 0.9 x 0.6 m box sitting on its origin.

const STAND_IN_MODEL: String = "res://tests/fixtures/box_model.tscn"


func test_keeps_the_greybox_when_the_file_is_missing() -> void:
	var rig: Array[Node3D] = _new_dresser("res://assets/third_party/no_such_model.gltf")
	var dresser: ThirdPartyModel = rig[0] as ThirdPartyModel
	var greybox: MeshInstance3D = rig[1] as MeshInstance3D

	assert_object(dresser.model).is_null()
	assert_bool(greybox.visible).is_true()


func test_shows_the_model_and_hides_the_greybox() -> void:
	var rig: Array[Node3D] = _new_dresser(STAND_IN_MODEL)
	var dresser: ThirdPartyModel = rig[0] as ThirdPartyModel
	var greybox: MeshInstance3D = rig[1] as MeshInstance3D

	assert_object(dresser.model).is_not_null()
	assert_bool(greybox.visible).is_false()


func test_fits_evenly_inside_its_box() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL, Vector3(2.2, 5.0, 5.0))[0] \
			as ThirdPartyModel
	# 2.2 / 1.1 is the tightest fit, so it doubles evenly.
	assert_vector(dresser.model.scale).is_equal_approx(Vector3(2, 2, 2), Vector3.ONE * 0.001)


func test_stretches_to_fill_its_box() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL, Vector3(2.2, 0.45, 1.2), true)[0] \
			as ThirdPartyModel
	assert_vector(dresser.model.scale).is_equal_approx(Vector3(2, 0.5, 2), Vector3.ONE * 0.001)


func test_sits_on_its_origin_centred() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL, Vector3(2.2, 1.8, 1.2))[0] \
			as ThirdPartyModel
	# The box already sits centred on its origin, so it stays put.
	assert_vector(dresser.model.position).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)


func test_a_model_can_be_told_to_cast_no_shadow() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	var meshes: Array[Node] = dresser.model.find_children("*", "MeshInstance3D", true, false)
	assert_int(meshes.size()).is_greater(0)
	for node: Node in meshes:
		assert_int((node as MeshInstance3D).cast_shadow).is_not_equal(
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	dresser.casts_shadow = false
	dresser.dress()
	for node: Node in dresser.model.find_children("*", "MeshInstance3D", true, false):
		assert_int((node as MeshInstance3D).cast_shadow).is_equal(
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)


func test_with_a_style_it_draws_the_model_stylised() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	dresser.style = CharacterStyle.new()

	var material: ShaderMaterial = _box_material(dresser) as ShaderMaterial
	assert_object(material).is_not_null()
	assert_object(material.shader).is_same(CharacterStyle.SHADER)
	# It keeps the box's own paint.
	assert_that(material.get_shader_parameter(&"albedo_color")).is_equal(Color(0.6, 0.4, 0.2))


func test_clearing_the_style_draws_it_as_made_again() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	dresser.style = CharacterStyle.new()

	dresser.style = null

	var material: StandardMaterial3D = _box_material(dresser) as StandardMaterial3D
	assert_object(material).is_not_null()
	assert_that(material.albedo_color).is_equal(Color(0.6, 0.4, 0.2))


func test_changes_to_its_style_show_at_once() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	var style: CharacterStyle = CharacterStyle.new()
	dresser.style = style

	style.shadow_threshold = 0.4
	style.outline = false

	var material: ShaderMaterial = _box_material(dresser) as ShaderMaterial
	var threshold: float = material.get_shader_parameter(&"shadow_threshold")
	assert_float(threshold).is_equal_approx(0.4, 0.0001)
	assert_object(material.next_pass).is_null()


func test_a_style_left_behind_no_longer_changes_it() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	var old: CharacterStyle = CharacterStyle.new()
	dresser.style = old
	dresser.style = CharacterStyle.new()

	old.shadow_threshold = 0.9

	var material: ShaderMaterial = _box_material(dresser) as ShaderMaterial
	var threshold: float = material.get_shader_parameter(&"shadow_threshold")
	assert_float(threshold).is_less(0.5)


# The material over the test box's mesh.
func _box_material(dresser: ThirdPartyModel) -> Material:
	return (dresser.model.get_node("Mesh") as MeshInstance3D).material_override


# A greybox mesh and a ThirdPartyModel that hides it, in the tree. Returns
# [the model node, the greybox].
func _new_dresser(path: String, fit: Vector3 = Vector3.ZERO,
		stretch: bool = false) -> Array[Node3D]:
	var holder: Node3D = Node3D.new()
	auto_free(holder)
	var greybox: MeshInstance3D = MeshInstance3D.new()
	greybox.mesh = BoxMesh.new()
	holder.add_child(greybox)
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = path
	dresser.fit_size = fit
	dresser.stretch = stretch
	dresser.stand_ins = [greybox]
	holder.add_child(dresser)
	add_child(holder)
	var rig: Array[Node3D] = [dresser, greybox]
	return rig


func test_a_model_is_loaded_once_and_kept() -> void:
	# Making the ship again (as every test does) mustn't load its models from
	# disk again (#196).
	var first: PackedScene = ThirdPartyModel._load_model(STAND_IN_MODEL)
	assert_object(first).is_not_null()
	assert_object(ThirdPartyModel._load_model(STAND_IN_MODEL)).is_same(first)

func test_tints_a_copy_of_the_source_material() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	var original: BaseMaterial3D = _box_material(dresser) as BaseMaterial3D
	dresser.tint = Color(0.5, 0.75, 1.0)
	dresser.dress()

	var tinted: BaseMaterial3D = _box_material(dresser) as BaseMaterial3D
	assert_object(tinted).is_not_same(original)
	assert_that(tinted.albedo_color).is_equal(original.albedo_color * dresser.tint)
	assert_that(original.albedo_color).is_equal(Color(0.6, 0.4, 0.2))
