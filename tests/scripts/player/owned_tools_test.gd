extends GameTestSuite
## Tests that the tools you own come onto your toolbar (#152): a tool is owned
## when its conversation flag is set (found in a chest, or given by a
## script), and flags are saved, so a found tool stays found.

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func after_test() -> void:
	Game.dialogue.reset()


func test_a_tool_is_owned_by_its_flag() -> void:
	assert_str(String(KNIFE.owned_flag)).is_equal("has_chefs_knife")


func test_a_player_owns_no_knife_until_its_flag_is_set() -> void:
	var player: Player3D = _player_without_tools()

	assert_bool(player.toolbar.has_tool(&"chefs_knife")).is_false()


func test_setting_the_flag_puts_the_tool_on_the_toolbar() -> void:
	var player: Player3D = _player_without_tools()

	Game.dialogue.set_flag(KNIFE.owned_flag)

	assert_bool(player.toolbar.has_tool(&"chefs_knife")).is_true()


func test_a_tool_owned_before_the_player_arrives_is_there_from_the_start() -> void:
	Game.dialogue.set_flag(KNIFE.owned_flag)
	var player: Player3D = _player_without_tools()

	assert_bool(player.toolbar.has_tool(&"chefs_knife")).is_true()


func test_giving_owned_tools_keeps_the_selected_slot() -> void:
	var player: Player3D = _player_without_tools()
	player.toolbar.select(4)

	Game.dialogue.set_flag(KNIFE.owned_flag)

	assert_int(player.toolbar.selected_index).is_equal(4)


func test_the_game_starts_you_with_no_tools() -> void:
	var sea: PackedScene = load("res://scenes/prototype/sea.tscn") as PackedScene
	var state: SceneState = sea.get_state()
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"Player":
			continue
		for property: int in state.get_node_property_count(node):
			if state.get_node_property_name(node, property) == &"start_tools":
				var tools: Array = state.get_node_property_value(node, property)
				assert_array(tools).is_empty()
				return
	fail("the sea scene's Player doesn't set start_tools")


# The player from player.tscn starts with the knife, for the scenes that need
# it (the duel arena); the real game's player doesn't.
func _player_without_tools() -> Player3D:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var player: Player3D = (load("res://scenes/prototype/player.tscn") as PackedScene) \
			.instantiate() as Player3D
	player.start_tools = []
	world.add_child(player)
	add_child(world)
	return player
