extends GameTestSuite
## Tests for HeldItemLabel3D: naming what the 3D player holds.

const TOMATO: Item = preload("res://data/items/tomato.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
const GARDEN_SALAD: Item = preload("res://data/items/garden_salad.tres")


func test_empty_with_free_hands() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var label: HeldItemLabel3D = _label(new_hud_3d(player))
	scene_runner(player.get_parent())
	assert_str(label.text).is_empty()


func test_names_the_held_item_and_its_quality() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var label: HeldItemLabel3D = _label(new_hud_3d(player))
	scene_runner(player.get_parent())

	player.arms.add(ItemInstance.new(TOMATO, 2))
	assert_str(label.text).is_equal("Tomato ★★")

	player.arms.take_top()
	assert_str(label.text).is_empty()


func test_a_plate_names_its_food() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var label: HeldItemLabel3D = _label(new_hud_3d(player))
	scene_runner(player.get_parent())
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(GARDEN_SALAD, 3))

	player.arms.add(plate)

	assert_str(label.text).is_equal("Plate: Garden Salad ★★★")


func _label(hud: Hud3D) -> HeldItemLabel3D:
	return hud.find_child("HeldItem") as HeldItemLabel3D
