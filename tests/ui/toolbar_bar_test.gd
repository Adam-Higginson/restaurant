extends GameTestSuite
## Tests for ToolbarBar: the 3D player's twelve toolbar slots along the bottom
## of the screen, redrawn as the toolbar changes.

const TOMATO: Item = preload("res://data/items/tomato.tres")


func test_is_as_wide_as_twelve_slots() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: ToolbarBar = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())
	var width: int = Toolbar.SLOT_COUNT * (ToolbarBar.SLOT_SIZE + ToolbarBar.GAP) \
			- ToolbarBar.GAP
	assert_float(bar.custom_minimum_size.x).is_equal(float(width))
	assert_float(bar.slot_rect(Toolbar.SLOT_COUNT - 1).end.x).is_equal(float(width))


func test_redraws_when_the_toolbar_changes() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: ToolbarBar = _bar(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	assert_bool(player.toolbar.changed.is_connected(bar.queue_redraw)).is_true()

	await press(runner, "select_slot_2")
	player.arms.add(ItemInstance.new(TOMATO))

	assert_int(player.toolbar.selected_index).is_equal(1)


func test_fits_on_the_smallest_screen() -> void:
	var width: int = Toolbar.SLOT_COUNT * (ToolbarBar.SLOT_SIZE + ToolbarBar.GAP)
	var screen: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	assert_int(width).is_less(screen)


func _bar(hud: Hud3D) -> ToolbarBar:
	return hud.find_child("Toolbar") as ToolbarBar
