extends GameTestSuite
## Tests for ItemModel's placing of food in a vessel (#207): water and soup
## fill a pot as a surface, and food sits down in it rather than on top.

const POT: Item = preload("res://data/items/saucepan.tres")
const WATER: Item = preload("res://data/items/rainwater.tres")
const TOMATO: Item = preload("res://data/items/diced_tomato.tres")


func test_food_in_water_sits_below_the_surface() -> void:
	var pot: ItemInstance = ItemInstance.new(POT)
	pot.contents.add_item(ItemInstance.new(WATER))
	pot.contents.add_item(ItemInstance.new(TOMATO))
	var model: Node3D = ItemModel.build(pot)
	auto_free(model)

	var surface: Node3D = model.get_node("Liquid") as Node3D
	var food: Node3D = model.get_node("Food0") as Node3D
	assert_float(food.position.y).is_less(surface.position.y)
	assert_float(food.position.y).is_greater_equal(ItemModel.floor_height(POT))


func test_food_in_an_empty_pot_sits_on_its_floor() -> void:
	var pot: ItemInstance = ItemInstance.new(POT)
	pot.contents.add_item(ItemInstance.new(TOMATO))
	var model: Node3D = ItemModel.build(pot)
	auto_free(model)

	var food: Node3D = model.get_node("Food0") as Node3D
	assert_float(food.position.y).is_equal_approx(ItemModel.floor_height(POT), 0.001)
	assert_object(model.get_node_or_null("Liquid")).is_null()
