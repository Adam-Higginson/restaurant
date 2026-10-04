extends GameTestSuite
## Tests for the game data: res://data/catalog.tres and the ingredient and dish
## files it lists. The expected values mirror the MVP menu in docs/GDD.md, so if
## either changes, update both deliberately.

var _catalog: Catalog


func before_test() -> void:
	_catalog = Catalog.load_default()


# --- Contents -------------------------------------------------------------

func test_catalog_has_five_ingredients_and_three_dishes() -> void:
	assert_object(_catalog).is_not_null()
	assert_int(_catalog.ingredients.size()).is_equal(5)
	assert_int(_catalog.dishes.size()).is_equal(3)


func test_ingredient_prices_match_design_doc() -> void:
	var expected: Dictionary[StringName, int] = {
		&"lettuce": 3, &"tomato": 3, &"onion": 2, &"bread": 3, &"cheese": 4,
	}
	var actual: Dictionary[StringName, int] = {}
	for ingredient: Ingredient in _catalog.ingredients:
		actual[ingredient.id] = ingredient.price
	assert_dict(actual).is_equal(expected)


func test_garden_salad_matches_design_doc() -> void:
	_assert_dish(&"garden_salad", 12, Dish.StationType.CHOPPING_BOARD, 4.0, {&"lettuce": 1, &"tomato": 1})


func test_tomato_soup_matches_design_doc() -> void:
	_assert_dish(&"tomato_soup", 18, Dish.StationType.STOVE, 8.0, {&"tomato": 1, &"onion": 1})


func test_grilled_cheese_matches_design_doc() -> void:
	_assert_dish(&"grilled_cheese", 15, Dish.StationType.STOVE, 6.0, {&"bread": 1, &"cheese": 1})


# --- Consistency -----------------------------------------------------------

func test_ids_are_unique() -> void:
	var ingredient_ids: Array[StringName] = []
	for ingredient: Ingredient in _catalog.ingredients:
		ingredient_ids.append(ingredient.id)
	var dish_ids: Array[StringName] = []
	for dish: Dish in _catalog.dishes:
		dish_ids.append(dish.id)
	assert_int(_unique(ingredient_ids).size()).override_failure_message(
		"Duplicate ingredient ids: %s" % [ingredient_ids]
	).is_equal(ingredient_ids.size())
	assert_int(_unique(dish_ids).size()).override_failure_message(
		"Duplicate dish ids: %s" % [dish_ids]
	).is_equal(dish_ids.size())


func test_recipes_only_use_catalog_ingredients() -> void:
	for dish: Dish in _catalog.dishes:
		for ingredient: Ingredient in dish.ingredients:
			# Same instance, not a copy: recipes must link to the shared ingredient files.
			assert_bool(_catalog.ingredients.has(ingredient)).override_failure_message(
				"%s uses %s, which isn't in the catalog" % [dish.id, ingredient.id]
			).is_true()


func test_every_dish_is_complete() -> void:
	for dish: Dish in _catalog.dishes:
		assert_str(dish.display_name).is_not_empty()
		assert_int(dish.price).is_greater(0)
		assert_float(dish.cook_time).is_greater(0.0)
		assert_int(dish.ingredients.size()).is_greater(0)
		for amount: int in dish.ingredients.values():
			assert_int(amount).is_greater(0)


func test_every_ingredient_is_complete() -> void:
	for ingredient: Ingredient in _catalog.ingredients:
		assert_str(String(ingredient.id)).is_not_empty()
		assert_str(ingredient.display_name).is_not_empty()
		assert_int(ingredient.price).is_greater(0)


# --- Helpers -------------------------------------------------------------------

func _assert_dish(id: StringName, price: int, station: Dish.StationType, cook_time: float, recipe: Dictionary[StringName, int]) -> void:
	var dish: Dish = _find_dish(id)
	assert_object(dish).override_failure_message("No dish with id %s" % id).is_not_null()
	if dish == null:
		return
	assert_int(dish.price).is_equal(price)
	assert_int(dish.station).is_equal(station)
	assert_float(dish.cook_time).is_equal_approx(cook_time, 0.001)
	var actual_recipe: Dictionary[StringName, int] = {}
	for ingredient: Ingredient in dish.ingredients:
		actual_recipe[ingredient.id] = dish.ingredients[ingredient]
	assert_dict(actual_recipe).is_equal(recipe)


func _find_dish(id: StringName) -> Dish:
	for dish: Dish in _catalog.dishes:
		if dish.id == id:
			return dish
	return null


func _unique(values: Array[StringName]) -> Array[StringName]:
	var result: Array[StringName] = []
	for value: StringName in values:
		if not result.has(value):
			result.append(value)
	return result
