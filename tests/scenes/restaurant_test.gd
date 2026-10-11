extends GameTestSuite
## Tests for the restaurant layout (scenes/restaurant.tscn) inside the main scene.

const MAIN_SCENE: String = "res://scenes/main.tscn"


# --- Contents -------------------------------------------------------------

func test_has_four_tables_each_with_a_seat() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var tables: Array[Node] = runner.scene().get_tree().get_nodes_in_group("tables")
	assert_int(tables.size()).is_equal(4)
	for table: Node in tables:
		assert_object(table.get_node_or_null("Seat")).is_not_null()


func test_has_a_stove_a_board_and_a_door() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object(runner.find_child("Stove")).is_not_null()
	assert_object(runner.find_child("BoardCounter")).is_instanceof(Counter)
	assert_object(runner.find_child("Door")).is_instanceof(Marker2D)


func test_has_a_fridge_a_cupboard_and_a_delivery_crate() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var fridge: StorageProp = runner.find_child("Fridge") as StorageProp
	var cupboard: StorageProp = runner.find_child("Cupboard") as StorageProp
	var crate: StorageProp = runner.find_child("Crate") as StorageProp
	assert_object(fridge).is_not_null()
	assert_object(cupboard).is_not_null()
	assert_object(crate).is_not_null()
	assert_object(runner.find_child("Pantry")).is_null()
	if fridge == null or cupboard == null or crate == null:
		return
	assert_int(fridge.kind).is_equal(Item.StorageKind.FRIDGE)
	assert_int(fridge.slots).is_equal(12)
	assert_int(cupboard.kind).is_equal(Item.StorageKind.CUPBOARD)
	assert_int(cupboard.slots).is_equal(12)
	assert_bool(crate.take_only).is_true()
	assert_int(crate.slots).is_equal(0)
	assert_bool(crate.is_in_group("delivery_crate")).is_true()


# --- Collision --------------------------------------------------------------

func test_outer_wall_blocks_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(40, 136))

	await walk(runner, "move_left", 90)

	# The left wall's inner edge is at x = 16; the player's collision box is 10px wide.
	assert_float(player.position.x).is_greater_equal(20.0)


func test_table_blocks_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(256, 104))

	await walk(runner, "move_up", 90)

	# Table1 is centred at y = 72; without collision the player would walk past it.
	assert_float(player.position.y).is_greater(72.0)


func test_counter_blocks_player_outside_the_gap() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(140, 56))

	await walk(runner, "move_right", 90)

	# The counter column starts at x = 160.
	assert_float(player.position.x).is_less_equal(160.0)


func test_gap_in_counter_lets_player_into_dining_area() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(140, 128))

	await walk(runner, "move_right", 90)

	assert_float(player.position.x).is_greater(176.0)


# --- Back room ----------------------------------------------------------------
# A walled room in the kitchen's bottom-left corner: floor tiles (1, 11) to
# (4, 14), so x 16 to 80 and y 176 to 240, with a doorway on its right side.

func test_back_room_top_wall_blocks_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(56, 136))

	await walk(runner, "move_down", 90)

	# The top wall is tile row 10, which starts at y = 160.
	assert_float(player.position.y).is_less(160.0)


func test_back_room_side_wall_blocks_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(104, 184))

	await walk(runner, "move_left", 90)

	# The side wall is tile column 5 (x 80 to 96); row 11 is wall, not doorway.
	assert_float(player.position.x).is_greater(96.0)


func test_back_room_doorway_lets_player_in() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, Vector2(104, 208))

	await walk(runner, "move_left", 90)

	assert_float(player.position.x).is_less(80.0)


func test_wake_spot_is_inside_the_back_room() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var wake_spot: Marker2D = runner.find_child("WakeSpot") as Marker2D
	assert_object(wake_spot).is_not_null()
	if wake_spot == null:
		return
	assert_bool(Rect2(16, 176, 64, 64).has_point(wake_spot.global_position)).is_true()


func test_fridge_and_cupboard_are_in_the_kitchen() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	# Inside the walls, above the back room and left of the dining room.
	var kitchen: Rect2 = Rect2(16, 16, 144, 144)
	for prop_name: String in ["Fridge", "Cupboard"]:
		var prop: StorageProp = runner.find_child(prop_name) as StorageProp
		var body: Rect2 = Rect2(prop.global_position - prop.size / 2.0, prop.size)
		assert_bool(kitchen.encloses(body)).override_failure_message(
			"%s should be inside the kitchen" % prop_name
		).is_true()


func test_crate_is_by_the_door() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var crate: Node2D = runner.find_child("Crate") as Node2D
	var door: Marker2D = runner.find_child("Door") as Marker2D
	assert_float(crate.global_position.distance_to(door.global_position)).is_less(48.0)


# --- Lighting -----------------------------------------------------------------

func test_every_table_has_a_lamp_over_it() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var tree: SceneTree = runner.scene().get_tree()
	for table: Node in tree.get_nodes_in_group("tables"):
		var table_position: Vector2 = (table as Node2D).global_position
		assert_bool(_has_lamp_within(tree, Rect2(table_position - Vector2(16, 16), Vector2(32, 32)))) \
				.override_failure_message("No lamp over %s" % table.name).is_true()


func test_the_kitchen_and_back_room_have_lamps() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var tree: SceneTree = runner.scene().get_tree()
	assert_bool(_has_lamp_within(tree, Rect2(16, 16, 144, 144))).is_true()
	assert_bool(_has_lamp_within(tree, Rect2(16, 176, 64, 64))).is_true()


func test_walls_block_light() -> void:
	var tile_set: TileSet = load("res://assets/placeholder/placeholder_tileset.tres") as TileSet
	assert_int(tile_set.get_occlusion_layers_count()).is_greater(0)
	var source: TileSetAtlasSource = tile_set.get_source(0) as TileSetAtlasSource
	# Every solid tile (one with collision) should cast a shadow too.
	for i: int in source.get_tiles_count():
		var coords: Vector2i = source.get_tile_id(i)
		var data: TileData = source.get_tile_data(coords, 0)
		if data.get_collision_polygons_count(0) > 0:
			assert_int(data.get_occluder_polygons_count(0)) \
					.override_failure_message("Tile %s is solid but lets light through" % coords) \
					.is_greater(0)


func _has_lamp_within(tree: SceneTree, area: Rect2) -> bool:
	for lamp: Node in tree.get_nodes_in_group(Lamp.GROUP):
		if area.has_point((lamp as Node2D).global_position):
			return true
	return false
