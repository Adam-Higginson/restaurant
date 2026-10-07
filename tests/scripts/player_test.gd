extends GameTestSuite
## Tests for scripts/player.gd.

const PLAYER_SCENE: String = "res://scenes/player.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"


func _new_player() -> Player:
	var player: Player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	auto_free(player)
	return player


# --- Facing direction ---------------------------------------------------------

func test_faces_dominant_horizontal_direction() -> void:
	var player: Player = _new_player()
	assert_vector(player._to_cardinal(Vector2(0.9, 0.3))).is_equal(Vector2.RIGHT)
	assert_vector(player._to_cardinal(Vector2(-0.9, -0.3))).is_equal(Vector2.LEFT)


func test_faces_dominant_vertical_direction() -> void:
	var player: Player = _new_player()
	assert_vector(player._to_cardinal(Vector2(0.3, -0.9))).is_equal(Vector2.UP)
	assert_vector(player._to_cardinal(Vector2(-0.3, 0.9))).is_equal(Vector2.DOWN)


func test_exact_diagonal_keeps_current_facing_when_it_is_held() -> void:
	var player: Player = _new_player()
	player.facing = Vector2.RIGHT
	assert_vector(player._to_cardinal(Vector2(1, -1).normalized())).is_equal(Vector2.RIGHT)


func test_exact_diagonal_falls_back_to_vertical() -> void:
	var player: Player = _new_player()
	player.facing = Vector2.RIGHT
	assert_vector(player._to_cardinal(Vector2(-1, -1).normalized())).is_equal(Vector2.UP)


# --- Movement in a running scene -------------------------------------------------

func test_moves_right_and_faces_right() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player
	var start: Vector2 = player.position

	await walk(runner, "move_right", 20)

	assert_float(player.position.x).is_greater(start.x)
	assert_float(player.position.y).is_equal_approx(start.y, 0.01)
	assert_vector(player.facing).is_equal(Vector2.RIGHT)


func test_diagonal_is_not_faster_than_straight() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player

	runner.simulate_action_press("move_up")
	runner.simulate_action_press("move_left")
	await physics_ticks(runner, 5)

	assert_float(player.velocity.length()).is_equal_approx(player.speed, 0.01)


func test_stops_when_input_released() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player

	await walk(runner, "move_down", 5)

	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_vector(player.facing).is_equal(Vector2.DOWN)


# --- Carrying --------------------------------------------------------------------

func test_starts_with_empty_arms() -> void:
	assert_bool(_new_player().arms.is_empty()).is_true()


func test_rotate_stack_changes_the_top_item() -> void:
	# In the main scene, because gdUnit delivers input twice to a scene's root
	# node, which would rotate twice per press.
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = runner.find_child("Player") as Player
	var tomato: ItemInstance = ItemInstance.new(Item.new())
	var plate: ItemInstance = ItemInstance.new(Item.new())
	player.arms.add(tomato)
	player.arms.add(plate)

	await press(runner, "rotate_stack")

	assert_object(player.arms.top()).is_same(tomato)
	assert_array(player.arms.get_items()).contains_exactly([plate, tomato])


# --- Tool belt -------------------------------------------------------------------

func test_starts_with_the_knife_in_the_first_slot_selected() -> void:
	var player: Player = _new_player()
	add_child(player)
	var knife: HandTool = Catalog.load_default().find_tool(&"chefs_knife")
	assert_object(player.belt.get_tool(0)).is_same(knife)
	assert_int(player.belt.selected_index).is_equal(0)
	assert_object(player.belt.selected_tool()).is_same(knife)


func test_number_keys_select_belt_slots() -> void:
	# In the main scene, so input isn't delivered twice (see rotate_stack above).
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = runner.find_child("Player") as Player

	await press(runner, "select_slot_3")
	assert_int(player.belt.selected_index).is_equal(2)

	await press(runner, "select_slot_1")
	assert_int(player.belt.selected_index).is_equal(0)


func test_next_and_previous_cycle_through_belt_slots() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = runner.find_child("Player") as Player

	await press(runner, "select_slot_next")
	assert_int(player.belt.selected_index).is_equal(1)

	await press(runner, "select_slot_previous")
	await press(runner, "select_slot_previous")
	assert_int(player.belt.selected_index).is_equal(ToolBelt.SLOT_COUNT - 1)


func test_selecting_a_slot_works_while_carrying() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = runner.find_child("Player") as Player
	player.arms.add(ItemInstance.new(Item.new()))

	await press(runner, "select_slot_2")

	assert_int(player.belt.selected_index).is_equal(1)
