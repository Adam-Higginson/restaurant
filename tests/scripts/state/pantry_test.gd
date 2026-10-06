extends GameTestSuite
## Tests for Pantry, using throwaway ingredients so they don't depend on the
## catalog's data.

var _pantry: Pantry
var _tomato: Item
var _onion: Item
# Each count_changed emission as [ingredient, count].
var _changes: Array[Array] = []


func before_test() -> void:
	_pantry = Pantry.new()
	_tomato = _make_ingredient(&"tomato")
	_onion = _make_ingredient(&"onion")
	_changes = []
	_pantry.count_changed.connect(
		func(ingredient: Item, count: int) -> void: _changes.append([ingredient, count])
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
	var counts: Dictionary[Item, int] = _pantry.get_counts()
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
	# Exact comparison, because contains_exactly_in_any_order ignores duplicates.
	assert_array(_changes).is_equal([[_tomato, 0], [_onion, 0]])


# --- Recipes ------------------------------------------------------------------

func test_has_all_checks_every_ingredient() -> void:
	var recipe: Dictionary[Item, int] = {_tomato: 2, _onion: 1}
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


func test_has_all_rejects_bad_amounts_like_remove_all() -> void:
	# Otherwise a station could offer a dish that remove_all then refuses.
	_pantry.add(_tomato, 1)
	var zero: Dictionary[Item, int] = {_tomato: 0}
	var negative: Dictionary[Item, int] = {_tomato: -1}
	var missing: Dictionary[Item, int] = {null: 1}
	_assert_recipe_rejected(zero)
	_assert_recipe_rejected(negative)
	_assert_recipe_rejected(missing)


func test_remove_all_is_safe_from_listeners_that_change_the_pantry() -> void:
	# A listener that takes an onion when the tomato count changes must not be
	# able to push the onion count below zero mid-recipe.
	_pantry.add(_tomato, 1)
	_pantry.add(_onion, 1)
	var listener_removed: Array[bool] = []
	_pantry.count_changed.connect(
		func(ingredient: Item, _count: int) -> void:
			if ingredient == _tomato and listener_removed.is_empty():
				listener_removed.append(_pantry.remove(_onion, 1))
	)
	assert_bool(_pantry.remove_all({_tomato: 1, _onion: 1})).is_true()
	assert_int(_pantry.count(_onion)).is_equal(0)
	assert_array(listener_removed).is_equal([false])


func test_remove_all_emits_after_every_count_is_updated() -> void:
	_pantry.add(_tomato, 1)
	_pantry.add(_onion, 1)
	var seen: Array[Array] = []
	_pantry.count_changed.connect(
		func(_ingredient: Item, _count: int) -> void:
			seen.append([_pantry.count(_tomato), _pantry.count(_onion)])
	)
	_pantry.remove_all({_tomato: 1, _onion: 1})
	assert_array(seen).is_equal([[0, 0], [0, 0]])


# --- Signals ------------------------------------------------------------------

func test_count_changed_reports_new_counts() -> void:
	_pantry.add(_tomato, 2)
	_pantry.remove(_tomato, 1)
	_pantry.remove(_tomato, 1)
	assert_array(_changes).is_equal([[_tomato, 2], [_tomato, 1], [_tomato, 0]])


# --- Helpers -------------------------------------------------------------------

func _make_ingredient(id: StringName) -> Item:
	var ingredient: Item = Item.new()
	ingredient.id = id
	return ingredient


func _assert_recipe_rejected(recipe: Dictionary[Item, int]) -> void:
	assert_bool(_pantry.has_all(recipe)).override_failure_message(
		"has_all accepted %s" % [recipe]
	).is_false()
	assert_bool(_pantry.remove_all(recipe)).override_failure_message(
		"remove_all accepted %s" % [recipe]
	).is_false()
