extends GameTestSuite
## Tests for ItemModel's structure and sizes, which the counters and the
## carried stack rely on to lay models out. Not how they look.

const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")


func test_food_is_one_cube() -> void:
	var model: Node3D = ItemModel.build(ItemInstance.new(TOMATO))
	auto_free(model)

	assert_int(model.get_child_count()).is_equal(1)


func test_a_plate_shows_each_piece_of_food_on_it() -> void:
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(TOMATO))
	plate.contents.add_item(ItemInstance.new(TOMATO))

	var model: Node3D = ItemModel.build(plate)
	auto_free(model)

	assert_object(model.find_child("Food0", false, false)).is_not_null()
	assert_object(model.find_child("Food1", false, false)).is_not_null()
	assert_object(model.find_child("Food2", false, false)).is_null()


func test_a_board_shows_progress_while_chopping() -> void:
	var board: ItemInstance = ItemInstance.new(BOARD)
	board.contents.add_item(ItemInstance.new(LETTUCE))
	board.contents.add_element(KNIFE.element)

	var model: Node3D = ItemModel.build(board)
	auto_free(model)

	var bar: Node3D = model.find_child("ProgressBar", false, false) as Node3D
	assert_object(bar).is_not_null()
	var fill: MeshInstance3D = bar.find_child("Fill", false, false) as MeshInstance3D
	# One cut of three: a third of the bar.
	var length: float = (fill.mesh as BoxMesh).size.x
	assert_float(length).is_equal_approx(ItemModel.BAR_LENGTH / 3.0, 0.001)


func test_an_empty_board_has_no_progress_bar() -> void:
	var model: Node3D = ItemModel.build(ItemInstance.new(BOARD))
	auto_free(model)

	assert_object(model.find_child("ProgressBar", false, false)).is_null()


func test_pans_pots_and_bowls_look_like_themselves() -> void:
	var catalog: Catalog = Catalog.load_default()
	var pan: Node3D = auto_free(ItemModel.build(ItemInstance.new(catalog.find_item(&"frying_pan"))))
	var pot: Node3D = auto_free(ItemModel.build(ItemInstance.new(catalog.find_item(&"saucepan"))))
	var bowl: Node3D = auto_free(ItemModel.build(ItemInstance.new(catalog.find_item(&"bowl"))))

	assert_object(pan.get_node_or_null("Handle")).is_not_null()
	assert_object(pot.get_node_or_null("Pot")).is_not_null()
	assert_object(bowl.get_node_or_null("Bowl")).is_not_null()
