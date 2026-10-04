extends GameTestSuite
## Tests for Pantry, using throwaway ingredients so they don't depend on the
## catalog's data.

var _pantry: Pantry
var _tomato: Ingredient
var _onion: Ingredient
# Each count_changed emission as [ingredient, count].
var _changes: Array[Array] = []


func before_test() -> void:
	_pantry = Pantry.new()
	_tomato = _make_ingredient(&"tomato")
	_onion = _make_ingredient(&"onion")
	_changes = []
	_pantry.count_changed.connect(
		func(ingredient: Ingredient, count: int) -> void: _changes.append([ingredient, count])
	)


# --- Adding and removing -------------------------------------------------------

func test_starts_empty() -> void:
	assert_int(_pantry.count(_tomato)).is_equal(0)
	assert_dict(_pantry.get_counts()).is_empty()


func test_add_increases_count() -> void:
	_pantry.add(_tomato, 2)
	_pantry.add(_tomato, 3)
	assert_int(_pantry.count(_tomato)).is_equal(5)
	assert_int(_pantry.count(_onion)).is_equal(0)


func test_remove_decreases_count() -> void:
	_pantry.add(_tomato, 5)
	assert_bool(_pantry.remove(_tomato, 2)).is_true()
	assert_int(_pantry.count(_tomato)).is_equal(3)


func test_remove_more_than_stocked_fails_and_changes_nothing() -> void:
	_pantry.add(_tomato, 1)
	_changes.clear()
	assert_bool(_pantry.remove(_tomato, 2)).is_false()
	assert_bool(_pantry.remove(_onion, 1)).is_false()
	assert_int(_pantry.count(_tomato)).is_equal(1)
	assert_array(_changes).is_empty()


func test_emptied_ingredient_is_no_longer_listed() -> void:
	_pantry.add(_tomato, 2)
	_pantry.add(_onion, 1)
	_pantry.remove(_tomato, 2)
	assert_dict(_pantry.get_counts()).is_equal({_onion: 1})


func test_get_counts_is_a_copy() -> void:
	_pantry.add(_tomato, 1)
	var counts: Dictionary[Ingredient, int] = _pantry.get_counts()
	counts[_tomato] = 99
	assert_int(_pantry.count(_tomato)).is_equal(1)


func test_rejects_non_positive_amounts() -> void:
	_pantry.add(_tomato, 2)
	_changes.clear()
	_pantry.add(_tomato, 0)
	_pantry.add(_tomato, -1)
	assert_bool(_pantry.remove(_tomato, 0)).is_false()
	assert_bool(_pantry.remove(_tomato, -1)).is_false()
	assert_int(_pantry.count(_tomato)).is_equal(2)
	assert_array(_changes).is_empty()


func test_clear_empties_the_pantry() -> void:
	_pantry.add(_tomato, 2)
	_pantry.add(_onion, 1)
	_changes.clear()
	_pantry.clear()
	assert_dict(_pantry.get_counts()).is_empty()
	assert_array(_changes).contains_exactly_in_any_order([[_tomato, 0], [_onion, 0]])


# --- Recipes ------------------------------------------------------------------

func test_has_all_checks_every_ingredient() -> void:
	var recipe: Dictionary[Ingredient, int] = {_tomato: 2, _onion: 1}
	_pantry.add(_tomato, 2)
	assert_bool(_pantry.has_all(recipe)).is_false()
	_pantry.add(_onion, 1)
	assert_bool(_pantry.has_all(recipe)).is_true()


func test_remove_all_takes_the_whole_recipe() -> void:
	_pantry.add(_tomato, 3)
	_pantry.add(_onion, 1)
	assert_bool(_pantry.remove_all({_tomato: 2, _onion: 1})).is_true()
	assert_dict(_pantry.get_counts()).is_equal({_tomato: 1})


func test_remove_all_takes_nothing_if_anything_is_short() -> void:
	_pantry.add(_tomato, 3)
	_changes.clear()
	assert_bool(_pantry.remove_all({_tomato: 2, _onion: 1})).is_false()
	assert_int(_pantry.count(_tomato)).is_equal(3)
	assert_array(_changes).is_empty()


func test_remove_all_works_with_a_catalog_dish() -> void:
	var catalog: Catalog = Catalog.load_default()
	var soup: Dish = catalog.dishes.filter(
		func(dish: Dish) -> bool: return dish.id == &"tomato_soup"
	)[0]
	for ingredient: Ingredient in catalog.ingredients:
		_pantry.add(ingredient, 1)
	assert_bool(_pantry.remove_all(soup.ingredients)).is_true()
	assert_bool(_pantry.has_all(soup.ingredients)).is_false()


# --- Signals ------------------------------------------------------------------

func test_count_changed_reports_new_counts() -> void:
	_pantry.add(_tomato, 2)
	_pantry.remove(_tomato, 1)
	_pantry.remove(_tomato, 1)
	assert_array(_changes).is_equal([[_tomato, 2], [_tomato, 1], [_tomato, 0]])


# --- Helpers -------------------------------------------------------------------

func _make_ingredient(id: StringName) -> Ingredient:
	var ingredient: Ingredient = Ingredient.new()
	ingredient.id = id
	return ingredient
