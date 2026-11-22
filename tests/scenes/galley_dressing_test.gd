extends GameTestSuite
## Tests for the galley's dressing scenes: they load on their own (so they
## can be reused anywhere), and their pack models get the N64 treatment.

const DRESSING: Array[String] = [
	"veg_crate", "lettuce_crate", "hanging_ham", "meat_rack", "pot_rail", "crockery_shelf",
	"jar_row", "stool", "books", "bookshelf", "herb_pot", "picture_frame", "kettle", "mug",
]
## Our own pieces that tell the crew's story (#82): no pack models in them.
const STORYTELLING: Array[String] = [
	"firewood", "open_door", "coat_hooks", "dropped_jacket", "ships_bell", "chart_corner",
	"recipe_note", "lifebuoy", "fishing_net", "ship_in_bottle",
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


func test_the_storytelling_pieces_load_on_their_own() -> void:
	for name: String in STORYTELLING:
		var path: String = "res://scenes/prototype/dressing/%s.tscn" % name
		var scene: PackedScene = load(path) as PackedScene
		assert_object(scene).override_failure_message("%s won't load" % path).is_not_null()
		var piece: Node3D = scene.instantiate() as Node3D
		add_child(piece)
		auto_free(piece)
		assert_int(piece.find_children("*", "MeshInstance3D").size()).override_failure_message(
				"%s has nothing to see" % name).is_greater(0)


func test_the_net_and_the_bell_sway_with_the_sea() -> void:
	for path: String in ["fishing_net.tscn:Net", "ships_bell.tscn:Swing"]:
		var parts: PackedStringArray = path.split(":")
		var piece: Node = (load("res://scenes/prototype/dressing/" + parts[0]) as PackedScene) \
				.instantiate()
		auto_free(piece)
		assert_object(piece.get_node(parts[1]) as Swinging).override_failure_message(
				"%s doesn't sway" % parts[0]).is_not_null()


func test_pack_models_are_drawn_crude_for_the_n64_look() -> void:
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = "res://tests/fixtures/box_model.tscn"
	dresser.detail = 0.05
	add_child(dresser)
	auto_free(dresser)
	var mesh: MeshInstance3D = dresser.model.get_node("Mesh") as MeshInstance3D
	assert_float(mesh.lod_bias).is_equal_approx(0.05, 0.0001)


func test_you_cannot_walk_through_the_stool() -> void:
	# The stool stands at the head of the table. Walking towards the bow from
	# behind it, it's in the way.
	var ship: Ship = new_moored_ship_with_player(Vector3(3.15, 1.05, 6.3))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 60)

	var player: Player3D = runner.find_child("Player") as Player3D
	assert_float(ship.to_local(player.global_position).z).is_greater(5.5)


func test_crates_stool_and_bookshelf_are_solid() -> void:
	for name: String in ["veg_crate", "lettuce_crate", "stool", "bookshelf"]:
		var piece: Node = (load("res://scenes/prototype/dressing/%s.tscn" % name) as PackedScene) 				.instantiate()
		auto_free(piece)
		assert_object(piece as StaticBody3D).override_failure_message(
				"%s isn't solid" % name).is_not_null()


func _models_in(node: Node) -> Array[ThirdPartyModel]:
	var found: Array[ThirdPartyModel] = []
	var model: ThirdPartyModel = node as ThirdPartyModel
	if model != null:
		found.append(model)
	for child: Node in node.get_children():
		found.append_array(_models_in(child))
	return found
