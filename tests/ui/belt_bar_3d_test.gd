extends GameTestSuite
## Tests for BeltBar3D: following the 3D player's belt and dimming while
## their hands are full.

const TOMATO: Item = preload("res://data/items/tomato.tres")


func test_bright_with_free_hands_and_dimmed_while_holding() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: BeltBar3D = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())
	assert_bool(bar.is_dimmed()).is_false()

	player.arms.add(ItemInstance.new(TOMATO))
	assert_bool(bar.is_dimmed()).is_true()

	player.arms.take_top()
	assert_bool(bar.is_dimmed()).is_false()


func test_redraws_when_the_selection_changes() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: BeltBar3D = _bar(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	assert_bool(player.belt.changed.is_connected(bar.queue_redraw)).is_true()

	await press(runner, "select_slot_2")

	assert_int(player.belt.selected_index).is_equal(1)


func test_is_as_wide_as_four_slots() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: BeltBar3D = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())
	var width: int = ToolBelt.SLOT_COUNT * (BeltBar3D.SLOT_SIZE + BeltBar3D.GAP) \
			- BeltBar3D.GAP
	assert_float(bar.custom_minimum_size.x).is_equal(float(width))


func _bar(hud: Hud3D) -> BeltBar3D:
	return hud.find_child("BeltBar") as BeltBar3D
