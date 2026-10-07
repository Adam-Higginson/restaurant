extends GameTestSuite
## Tests for ItemInstance.

const TOMATO: Item = preload("res://data/items/tomato.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const PLATE: Item = preload("res://data/items/plate.tres")


func test_quality_is_kept_within_one_to_three() -> void:
	assert_int(ItemInstance.new(TOMATO, 0).quality).is_equal(1)
	assert_int(ItemInstance.new(TOMATO, 5).quality).is_equal(3)
	assert_int(ItemInstance.new(TOMATO).quality).is_equal(ItemInstance.MIN_QUALITY)


func test_food_has_no_contents() -> void:
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	assert_bool(tomato.is_vessel()).is_false()
	assert_object(tomato.contents).is_null()


func test_board_holds_one_food_item() -> void:
	var board: ItemInstance = ItemInstance.new(BOARD)
	assert_bool(board.is_vessel()).is_true()
	assert_bool(board.contents.add_item(ItemInstance.new(TOMATO))).is_true()
	assert_bool(board.contents.add_item(ItemInstance.new(TOMATO))).is_false()


func test_plate_holds_three_food_items() -> void:
	var plate: ItemInstance = ItemInstance.new(PLATE)
	for i: int in 3:
		assert_bool(plate.contents.add_item(ItemInstance.new(TOMATO))).is_true()
	assert_bool(plate.contents.add_item(ItemInstance.new(TOMATO))).is_false()


func test_each_vessel_has_its_own_contents() -> void:
	var first: ItemInstance = ItemInstance.new(PLATE)
	var second: ItemInstance = ItemInstance.new(PLATE)
	first.contents.add_item(ItemInstance.new(TOMATO))
	assert_array(second.contents.get_contents()).is_empty()


func test_plate_is_carried_whole_and_board_is_not() -> void:
	assert_bool(PLATE.carried_whole).is_true()
	assert_bool(BOARD.carried_whole).is_false()
