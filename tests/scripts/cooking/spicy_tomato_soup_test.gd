extends GameTestSuite
## Tests for Spicy Tomato Soup, the first quest's remedy (#154): chop a chilli
## on the board and stir it into a hot Tomato Soup. A whole chilli is the
## rough shortcut. The pantry keeps chillies and onions, and the recipe book
## doesn't give away where the soup's water comes from.


func test_a_chilli_chops_on_the_board_in_two_cuts() -> void:
	var board: VesselContents = _vessel(&"chopping_board", 1)
	var cut: Element = _catalog().find_element(&"cut")
	board.add_item(ItemInstance.new(_item(&"chilli")))

	board.add_element(cut)
	assert_str(String(board.get_contents()[0].item.id)).is_equal("chilli")
	board.add_element(cut)

	assert_str(String(board.get_contents()[0].item.id)).is_equal("chopped_chilli")


func test_chopped_chilli_in_hot_soup_is_three_stars() -> void:
	var pan: VesselContents = _hot_pan()
	pan.add_item(ItemInstance.new(_item(&"tomato_soup"), 3))
	pan.add_item(ItemInstance.new(_item(&"chopped_chilli"), 3))

	pan.tick(3.9)
	assert_str(String(pan.get_contents()[0].item.id)).is_equal("tomato_soup")
	pan.tick(0.2)

	var food: Array[ItemInstance] = pan.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_str(String(food[0].item.id)).is_equal("spicy_tomato_soup")
	assert_int(food[0].quality).is_equal(3)


func test_a_whole_chilli_is_the_rough_shortcut() -> void:
	var pan: VesselContents = _hot_pan()
	pan.add_item(ItemInstance.new(_item(&"tomato_soup"), 3))
	pan.add_item(ItemInstance.new(_item(&"chilli")))

	pan.tick(6.1)

	var food: Array[ItemInstance] = pan.get_contents()
	assert_str(String(food[0].item.id)).is_equal("spicy_tomato_soup")
	assert_int(food[0].quality).is_less(3)


func test_nothing_happens_off_the_fire() -> void:
	var pan: VesselContents = _vessel(&"saucepan", 3)
	pan.add_item(ItemInstance.new(_item(&"tomato_soup")))
	pan.add_item(ItemInstance.new(_item(&"chopped_chilli")))

	pan.tick(10.0)

	assert_str(String(pan.get_contents()[0].item.id)).is_equal("tomato_soup")


func test_the_whole_soup_from_water_to_spice() -> void:
	var pan: VesselContents = _hot_pan()
	pan.add_item(ItemInstance.new(_item(&"rainwater")))
	pan.tick(4.1)
	pan.add_item(ItemInstance.new(_item(&"diced_tomato")))
	pan.add_item(ItemInstance.new(_item(&"chopped_onion")))
	pan.tick(8.1)
	pan.add_item(ItemInstance.new(_item(&"chopped_chilli")))
	pan.tick(4.1)

	var food: Array[ItemInstance] = pan.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_str(String(food[0].item.id)).is_equal("spicy_tomato_soup")
	assert_int(food[0].quality).is_equal(3)


func test_the_pantry_keeps_chillies_and_onions() -> void:
	var scene: PackedScene = load("res://scenes/prototype/props/pantry.tscn") as PackedScene
	var pantry: StorageProp3D = scene.instantiate() as StorageProp3D
	auto_free(pantry)

	assert_int(pantry.start_items.get(_item(&"chilli"), 0)).is_greater(0)
	assert_int(pantry.start_items.get(_item(&"onion"), 0)).is_greater(0)


func test_the_recipe_book_does_not_give_the_water_away() -> void:
	for recipe: Recipe in _catalog().recipes:
		var text: String = " ".join(recipe.steps).to_lower()
		for giveaway: String in ["rain", "butt"]:
			assert_str(text).override_failure_message(
					"%s's page says \"%s\"" % [recipe.title, giveaway]).not_contains(giveaway)


func _hot_pan() -> VesselContents:
	var pan: VesselContents = _vessel(&"saucepan", 3)
	pan.add_element(_catalog().find_element(&"fire"))
	return pan


func _vessel(id: StringName, capacity: int) -> VesselContents:
	return VesselContents.new(_item(id), _catalog().reactions, capacity)


func _item(id: StringName) -> Item:
	return _catalog().find_item(id)


func _catalog() -> Catalog:
	return Catalog.load_default()
