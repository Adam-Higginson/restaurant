extends GameTestSuite
## Tests for the treasure chest (#152): opening it plays its cutscene, which
## gives you what's inside; it opens only once, and stays open in a saved
## voyage; a full toolbar is told so; the galley's chest holds the knife; and
## a chest can hold an item instead (the pan on the cove's beach, #187).

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const PAN: Item = preload("res://data/items/frying_pan.tres")
const CHEST: PackedScene = preload("res://scenes/prototype/props/treasure_chest.tscn")
const FLAG: StringName = &"opened_test_chest"

var _player: Player3D
var _chest: TreasureChest
var _conversation: Conversation
var _cues: ChestCues


func after_test() -> void:
	Game.dialogue.reset()


func test_a_shut_chest_offers_to_open() -> void:
	_build()

	assert_str(_chest.prompt(_player)).is_equal("Open")
	assert_bool(_chest.is_opened()).is_false()


func test_opening_it_gives_you_what_is_inside() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 2)

	assert_bool(_chest.open_for(_player)).is_true()
	assert_bool(_conversation.is_cutscene()).is_true()
	_conversation.skip()
	await physics_ticks(runner, 5)

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.toolbar.has_tool(&"chefs_knife")).is_true()
	assert_bool(Game.dialogue.is_set(KNIFE.owned_flag)).is_true()


func test_afterwards_the_camera_is_yours_again() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 2)

	_chest.open_for(_player)
	await physics_ticks(runner, 120)
	_conversation.skip()
	await physics_ticks(runner, 5)

	assert_object(_player.camera_rig.held_shot()).is_null()


func test_a_shot_held_before_comes_back_afterwards() -> void:
	var runner: GdUnitSceneRunner = _build()
	var before: Marker3D = new_marker(_player.get_parent(), &"shots", "Before",
			Transform3D(Basis.IDENTITY, Vector3(0, 2, 4)))
	await physics_ticks(runner, 2)
	_player.camera_rig.hold_shot(before, true)

	_chest.open_for(_player)
	await physics_ticks(runner, 120)
	_conversation.skip()
	await physics_ticks(runner, 5)

	assert_object(_player.camera_rig.held_shot()).is_same(before)


func test_it_opens_only_once() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 2)
	_chest.open_for(_player)
	_conversation.skip()
	await physics_ticks(runner, 5)

	assert_bool(_chest.is_opened()).is_true()
	assert_bool(Game.dialogue.is_set(FLAG)).is_true()
	assert_str(_chest.prompt(_player)).is_empty()
	assert_bool(_chest.open_for(_player)).is_false()


func test_a_chest_opened_in_a_saved_voyage_is_open() -> void:
	Game.dialogue.set_flag(FLAG)
	_build()

	assert_bool(_chest.is_opened()).is_true()
	assert_float(absf(_chest.lid().rotation.x)).is_greater(1.5)
	assert_str(_chest.prompt(_player)).is_empty()


func test_the_lid_swings_open() -> void:
	_build()

	_chest.swing_open(true)

	assert_float(absf(_chest.lid().rotation_degrees.x)).is_equal_approx(_chest.open_degrees, 0.01)


func test_a_full_toolbar_is_told_so() -> void:
	_build()
	for i: int in Toolbar.SLOT_COUNT:
		_player.toolbar.add(ItemInstance.new(TOMATO))

	assert_str(_chest.prompt(_player)).is_equal("Your toolbar is full")
	assert_bool(_chest.open_for(_player)).is_false()


func test_the_treasure_is_held_up_and_put_away_after() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 2)
	_chest.open_for(_player)

	# The lid takes about a second and a half; then the knife rises.
	var held_up: bool = false
	for tick: int in 300:
		await physics_ticks(runner, 1)
		if _cues.treasure() != null:
			held_up = true
			break
	assert_bool(held_up).override_failure_message("the knife was never held up").is_true()
	_conversation.skip()
	await physics_ticks(runner, 5)

	assert_object(_cues.treasure()).is_null()


func test_a_chest_can_hold_an_item_and_gives_it_to_you() -> void:
	var runner: GdUnitSceneRunner = _build()
	_chest.contents = null
	_chest.item = PAN
	await physics_ticks(runner, 2)
	assert_str(String(_chest.treasure_id())).is_equal("frying_pan")

	assert_bool(_chest.open_for(_player)).is_true()
	_conversation.skip()
	await physics_ticks(runner, 10)

	assert_bool(Game.dialogue.is_set(&"has_frying_pan")).is_true()
	assert_bool(_player.toolbar.has_item(&"frying_pan")).is_true()
	assert_bool(_chest.is_opened()).is_true()


func test_the_galley_chest_holds_the_knife() -> void:
	# The galley is a scene of its own, placed in the ship (#196).
	var state: SceneState = (load("res://scenes/prototype/galley.tscn") as PackedScene).get_state()
	var contents: HandTool = null
	var flag: StringName = &""
	for node: int in state.get_node_count():
		if state.get_node_name(node) != &"GalleyChest":
			continue
		for property: int in state.get_node_property_count(node):
			match state.get_node_property_name(node, property):
				&"contents":
					var value: Object = state.get_node_property_value(node, property)
					contents = value as HandTool
				&"flag":
					flag = state.get_node_property_value(node, property)

	assert_object(contents).is_same(KNIFE)
	assert_str(String(flag)).is_not_empty()


func test_the_chest_cutscene_has_a_section_for_the_knife() -> void:
	var tree: DialogueTree = DialogueLibrary.find(TreasureChest.CUTSCENE)

	assert_bool(tree.has_section(KNIFE.id)).is_true()


# A player with no tools in front of a chest holding the knife, with a
# conversation and the chest's cues, in a world that's freed after the test.
func _build() -> GdUnitSceneRunner:
	var world: Node3D = Node3D.new()
	auto_free(world)
	world.add_child(static_box(Vector3(20, 1, 20), Vector3(0, -0.5, 0)))
	_player = (load("res://scenes/prototype/player.tscn") as PackedScene).instantiate() as Player3D
	_player.start_tools = []
	world.add_child(_player)
	_chest = CHEST.instantiate() as TreasureChest
	_chest.contents = KNIFE
	_chest.flag = FLAG
	_chest.position = Vector3(0, 0, -2)
	world.add_child(_chest)
	_conversation = new_conversation(_player)
	_cues = ChestCues.new()
	_cues.player = _player
	world.add_child(_cues)
	return scene_runner(world)
