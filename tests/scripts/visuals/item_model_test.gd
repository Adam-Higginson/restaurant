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


func test_a_chopped_chilli_is_in_bits() -> void:
	var chopped: Item = preload("res://data/items/chopped_chilli.tres")
	var model: Node3D = ItemModel.food(chopped, ItemModel.FOOD_SIZE)
	auto_free(model)

	assert_int(model.find_children("Bit*", "", false, false).size()).is_equal(chopped.model_pieces)
	assert_int(chopped.model_pieces).is_greater(1)


func test_food_uses_its_source_model_and_hides_the_cube() -> void:
	var item: Item = Item.new()
	item.model_path = "res://tests/fixtures/box_model.tscn"
	item.model_size = Vector3(0.22, 0.18, 0.12)
	item.model_tint = Color(0.5, 0.75, 1.0)
	var food: Node3D = ItemModel.food(item, ItemModel.FOOD_SIZE)
	auto_free(food)
	add_child(food)

	var cube: MeshInstance3D = food.get_node("Greybox") as MeshInstance3D
	var dresser: ThirdPartyModel = food.get_node("Model") as ThirdPartyModel
	assert_bool(cube.visible).is_false()
	assert_object(dresser.model).is_not_null()
	assert_float(dresser.model.scale.x).is_equal_approx(0.2, 0.0001)
	var mesh: MeshInstance3D = dresser.model.get_node("Mesh") as MeshInstance3D
	var material: BaseMaterial3D = mesh.material_override as BaseMaterial3D
	assert_that(material.albedo_color).is_equal(Color(0.6, 0.4, 0.2) * item.model_tint)


func test_a_tool_with_a_missing_model_keeps_its_greybox() -> void:
	var tool: HandTool = HandTool.new()
	tool.model_path = "res://assets/third_party/no_such_tool.glb"
	var model: Node3D = ItemModel.tool_model(tool)
	auto_free(model)
	add_child(model)

	var greybox: MeshInstance3D = model.get_node("Greybox") as MeshInstance3D
	assert_bool(greybox.visible).is_true()
	assert_object(model.get_node_or_null("Model")).is_null()
