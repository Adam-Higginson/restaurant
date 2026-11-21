extends GameTestSuite
## Tests for the galley's dressing scenes: they load on their own (so they
## can be reused anywhere), and their pack models get the N64 treatment.

const DRESSING: Array[String] = [
	"veg_crate", "hanging_ham", "pot_rail", "crockery_shelf", "jar_row", "stool", "books",
	"picture_frame", "kettle", "mug",
]


func test_every_dressing_scene_loads_on_its_own() -> void:
	for name: String in DRESSING:
		var path: String = "res://scenes/prototype/dressing/%s.tscn" % name
		var scene: PackedScene = load(path) as PackedScene
		assert_object(scene).override_failure_message("%s won't load" % path).is_not_null()
		var piece: Node3D = scene.instantiate() as Node3D
		add_child(piece)
		auto_free(piece)
		assert_int(_models_in(piece).size()).override_failure_message(
				"%s has no models" % name).is_greater(0)


func test_pack_models_are_drawn_crude_for_the_n64_look() -> void:
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = "res://tests/fixtures/box_model.tscn"
	dresser.detail = 0.05
	add_child(dresser)
	auto_free(dresser)
	var mesh: MeshInstance3D = dresser.model.get_node("Mesh") as MeshInstance3D
	assert_float(mesh.lod_bias).is_equal_approx(0.05, 0.0001)


func _models_in(node: Node) -> Array[ThirdPartyModel]:
	var found: Array[ThirdPartyModel] = []
	var model: ThirdPartyModel = node as ThirdPartyModel
	if model != null:
		found.append(model)
	for child: Node in node.get_children():
		found.append_array(_models_in(child))
	return found
