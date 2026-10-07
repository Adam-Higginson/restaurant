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


func test_has_a_stove_a_board_a_pantry_and_a_door() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object(runner.find_child("Stove")).is_not_null()
	assert_object(runner.find_child("BoardCounter")).is_instanceof(Counter)
	assert_object(runner.find_child("Pantry")).is_not_null()
	assert_object(runner.find_child("Door")).is_instanceof(Marker2D)


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
