extends GameTestSuite
## Tests for the chopping prototype: real input feeding the reaction engine.

const SCENE: String = "res://scenes/prototypes/chopping_prototype.tscn"


func test_starts_with_a_whole_tomato() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	assert_str(_top_item(runner)).is_equal("tomato")


func test_use_tool_slices_then_dices_the_tomato() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	await press(runner, "use_tool")
	assert_str(_top_item(runner)).is_equal("tomato")
	await press(runner, "use_tool")
	assert_str(_top_item(runner)).is_equal("sliced_tomato")
	for i: int in 3:
		await press(runner, "use_tool")
	assert_str(_top_item(runner)).is_equal("diced_tomato")


func test_reset_swaps_in_a_fresh_lettuce() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var prototype: ChoppingPrototype = runner.scene() as ChoppingPrototype
	prototype.reset(&"lettuce")
	assert_str(_top_item(runner)).is_equal("lettuce")
	for i: int in 3:
		await press(runner, "use_tool")
	assert_str(_top_item(runner)).is_equal("chopped_lettuce")


func _top_item(runner: GdUnitSceneRunner) -> String:
	var prototype: ChoppingPrototype = runner.scene() as ChoppingPrototype
	var contents: Array[ItemInstance] = prototype.get_board().get_contents()
	return String(contents[0].item.id) if not contents.is_empty() else ""
