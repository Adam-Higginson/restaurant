extends GameTestSuite
## Tests for VesselLook (#207): a pot's liquid takes its colour from the
## reaction it's in, tinted a little as soon as everything's in and the rest
## of the way as it cooks, and the food that reaction uses melts into it.

const POT: Item = preload("res://data/items/saucepan.tres")


func test_water_alone_is_its_own_colour() -> void:
	var pot: VesselContents = _pot()
	pot.add_item(ItemInstance.new(_item(&"boiling_water")))

	assert_object(VesselLook.liquid_colour(pot)).is_equal(_item(&"boiling_water").color)


func test_once_the_soup_is_all_in_the_water_is_tinted_towards_it() -> void:
	var pot: VesselContents = _soup_makings()
	var water: Color = _item(&"boiling_water").color
	var soup: Color = _item(&"tomato_soup").color

	var colour: Color = VesselLook.liquid_colour(pot)

	assert_object(colour).is_equal(water.lerp(soup, VesselLook.FIRST_TINT))


func test_as_it_cooks_it_turns_into_the_soup_and_the_food_melts() -> void:
	var pot: VesselContents = _soup_makings()
	var tomato: ItemInstance = pot.get_contents()[1]
	pot.add_element(_catalog().find_element(&"fire"))
	var before: Color = VesselLook.liquid_colour(pot)

	pot.tick(4.0)

	var soup: Color = _item(&"tomato_soup").color
	var after: Color = VesselLook.liquid_colour(pot)
	assert_float(_distance(after, soup)).is_less(_distance(before, soup))
	assert_float(VesselLook.piece_scale(pot, tomato)).is_less(1.0)
	assert_float(VesselLook.piece_scale(pot, tomato)).is_greater(1.0 - VesselLook.SHRINK)


func test_food_nothing_is_using_stays_whole() -> void:
	var pot: VesselContents = _pot()
	pot.add_item(ItemInstance.new(_item(&"boiling_water")))
	var tomato: ItemInstance = ItemInstance.new(_item(&"diced_tomato"))
	pot.add_item(tomato)

	assert_float(VesselLook.piece_scale(pot, tomato)).is_equal(1.0)


func _soup_makings() -> VesselContents:
	var pot: VesselContents = _pot()
	pot.add_item(ItemInstance.new(_item(&"boiling_water")))
	pot.add_item(ItemInstance.new(_item(&"diced_tomato")))
	pot.add_item(ItemInstance.new(_item(&"chopped_onion")))
	return pot


func _distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()


func _pot() -> VesselContents:
	return VesselContents.new(POT, _catalog().reactions, 3)


func _item(id: StringName) -> Item:
	return _catalog().find_item(id)


func _catalog() -> Catalog:
	return Catalog.load_default()
