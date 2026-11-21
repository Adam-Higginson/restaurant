extends GameTestSuite
## Tests for ThirdPartyModel: dressing a scene with a model when its file is
## there, fitting it to a box, and leaving the greybox when it isn't.
##
## Third-party files aren't in the repo, so these use one of our own scenes as
## the "model": the counter, a 1.1 x 0.9 x 0.6 m box sitting on its origin.

const STAND_IN_MODEL: String = "res://scenes/prototype/props/counter.tscn"


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


func test_gives_the_model_the_chunky_n64_grain() -> void:
	var dresser: ThirdPartyModel = _new_dresser(STAND_IN_MODEL)[0] as ThirdPartyModel
	var mesh: MeshInstance3D = dresser.model.get_node("Mesh") as MeshInstance3D
	# Our counter colours itself with one material over the whole mesh.
	var material: ShaderMaterial = mesh.material_override as ShaderMaterial
	assert_object(material).is_not_null()
	assert_object(material.shader).is_same(ThirdPartyModel.N64_SHADER)
	assert_object(material.get_shader_parameter(&"grain")).is_same(ThirdPartyModel.GRAIN)


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
	# The counter already sits centred on its origin, so it stays put.
	assert_vector(dresser.model.position).is_equal_approx(Vector3.ZERO, Vector3.ONE * 0.001)


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
