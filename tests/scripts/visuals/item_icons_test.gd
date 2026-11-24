extends GameTestSuite
## Tests for ItemIcons (#206): pictures of the real models for the toolbar,
## kept by what they show, asked for once and queued. (What the pictures look
## like isn't tested; headless, nothing is drawn.)

const TOMATO: Item = preload("res://data/items/tomato.tres")
const BOWL: Item = preload("res://data/items/bowl.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func test_two_of_the_same_thing_share_a_picture() -> void:
	var one: ItemInstance = ItemInstance.new(TOMATO)
	var other: ItemInstance = ItemInstance.new(TOMATO)
	other.quality = 3

	assert_str(ItemIcons.key_of(one)).is_equal(ItemIcons.key_of(other))


func test_a_bowl_is_pictured_with_whats_in_it() -> void:
	var empty: ItemInstance = ItemInstance.new(BOWL)
	var full: ItemInstance = ItemInstance.new(BOWL)
	full.contents.add_item(ItemInstance.new(TOMATO))

	assert_str(ItemIcons.key_of(full)).is_not_equal(ItemIcons.key_of(empty))
	assert_str(ItemIcons.key_of(full)).contains("tomato")


func test_items_and_tools_are_kept_apart() -> void:
	assert_str(ItemIcons.key_of_tool(KNIFE)).is_not_equal(
			ItemIcons.key_of(ItemInstance.new(TOMATO)))


func test_asking_queues_one_picture_however_often_its_asked_for() -> void:
	var icons: ItemIcons = ItemIcons.new()
	auto_free(icons)
	add_child(icons)

	assert_object(icons.icon_for_item(ItemInstance.new(TOMATO))).is_null()
	assert_object(icons.icon_for_item(ItemInstance.new(TOMATO))).is_null()
	assert_object(icons.icon_for_tool(KNIFE)).is_null()

	assert_int(icons.waiting()).is_equal(2)


func test_the_toolbar_has_a_studio_for_its_pictures() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var hud: Hud3D = new_hud_3d(player)
	scene_runner(player.get_parent())
	var bar: ToolbarBar = hud.find_child("Toolbar") as ToolbarBar

	assert_object(bar.icons()).is_not_null()
	assert_bool(bar.icons().is_inside_tree()).is_true()
