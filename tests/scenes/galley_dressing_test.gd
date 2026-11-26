extends GameTestSuite
## Tests for the galley's dressing scenes: they load on their own (so they
## can be reused anywhere).

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


func test_you_cannot_walk_through_the_stool() -> void:
	# The stool stands at the head of the table. Walking towards the bow from
	# behind it, it's in the way.
	var ship: Ship = new_moored_ship_with_player(Vector3(3.15, 1.05, 6.3))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 60)

	var player: Player3D = runner.find_child("Player") as Player3D
	assert_float(ship.to_local(player.global_position).z).is_greater(5.5)
	# It's low (as low as it's drawn), but you don't climb onto it either.
	assert_float(ship.to_local(player.global_position).y).is_less(1.15)


func test_the_stool_collides_where_it_is_drawn() -> void:
	var stool: StaticBody3D = (load("res://scenes/prototype/dressing/stool.tscn") as PackedScene) \
			.instantiate() as StaticBody3D
	auto_free(stool)
	var model: ThirdPartyModel = stool.get_node("Model") as ThirdPartyModel
	var shape: CollisionShape3D = stool.get_node("Shape") as CollisionShape3D
	var box: BoxShape3D = shape.shape as BoxShape3D
	# The model is fitted into fit_size, standing on the floor; the shape
	# fills the same box, so you bump into exactly what you see.
	assert_vector(box.size).is_equal(model.fit_size)
	assert_float(shape.position.y).is_equal_approx(model.fit_size.y / 2.0, 0.001)


func test_crates_stool_and_bookshelf_are_solid() -> void:
	for name: String in ["veg_crate", "lettuce_crate", "stool", "bookshelf"]:
		var piece: Node = (load("res://scenes/prototype/dressing/%s.tscn" % name) as PackedScene) \
				.instantiate()
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
