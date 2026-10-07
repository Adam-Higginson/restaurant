extends GameTestSuite
## Tests for the text HeldItemLabel shows for the player's top carried item.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const ONION: Item = preload("res://data/items/onion.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")


func test_food_shows_its_name_and_stars() -> void:
	assert_str(HeldItemLabel.describe(ItemInstance.new(TOMATO, 2))).is_equal("Tomato ★★")


func test_empty_vessel_shows_just_its_name() -> void:
	assert_str(HeldItemLabel.describe(ItemInstance.new(BOARD))).is_equal("Chopping Board")


func test_plate_shows_its_food() -> void:
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(LETTUCE))
	plate.contents.add_item(ItemInstance.new(TOMATO))
	assert_str(HeldItemLabel.describe(plate)).is_equal("Plate: Garden Salad ★")

	var mixed: ItemInstance = ItemInstance.new(PLATE)
	mixed.contents.add_item(ItemInstance.new(ONION, 3))
	mixed.contents.add_item(ItemInstance.new(ONION))
	assert_str(HeldItemLabel.describe(mixed)).is_equal("Plate: Onion ★★★, Onion ★")


func test_label_follows_the_top_of_the_stack() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = runner.find_child("Player") as Player
	var label: HeldItemLabel = runner.find_child("HeldItemLabel") as HeldItemLabel
	assert_str(label.text).is_empty()

	player.arms.add(ItemInstance.new(TOMATO))
	assert_str(label.text).is_equal("Tomato ★")

	player.arms.take_top()
	assert_str(label.text).is_empty()
