extends GameTestSuite
## Tests for Toolbar: tools and items sharing twelve slots, the selected slot
## being what the player holds, and the Arms rules it keeps.

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")

var _toolbar: Toolbar
var _changes: int = 0


func before_test() -> void:
	_toolbar = Toolbar.new()
	_toolbar.set_tool(0, KNIFE)
	_changes = 0
	_toolbar.changed.connect(func() -> void: _changes += 1)


func test_starts_with_the_first_slot_selected_and_nothing_held() -> void:
	assert_int(_toolbar.selected_index).is_equal(0)
	assert_object(_toolbar.selected_tool()).is_same(KNIFE)
	assert_object(_toolbar.top()).is_null()
	assert_bool(_toolbar.is_empty()).is_true()
	assert_bool(_toolbar.is_full()).is_false()


func test_picking_up_fills_the_first_free_slot_and_selects_it() -> void:
	var tomato: ItemInstance = ItemInstance.new(TOMATO)

	assert_bool(_toolbar.add(tomato)).is_true()

	# Slot 0 holds the knife, so the tomato goes in slot 1.
	assert_object(_toolbar.get_item(1)).is_same(tomato)
	assert_int(_toolbar.selected_index).is_equal(1)
	assert_object(_toolbar.top()).is_same(tomato)
	assert_int(_changes).is_equal(1)


func test_carries_several_items_and_holds_the_selected_one() -> void:
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	_toolbar.add(tomato)
	_toolbar.add(lettuce)

	assert_int(_toolbar.size()).is_equal(2)
	assert_array(_toolbar.get_items()).contains_exactly([tomato, lettuce])
	assert_object(_toolbar.top()).is_same(lettuce)

	_toolbar.select(1)

	assert_object(_toolbar.top()).is_same(tomato)


func test_take_top_empties_the_selected_slot_and_keeps_it_selected() -> void:
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	_toolbar.add(tomato)

	assert_object(_toolbar.take_top()).is_same(tomato)

	assert_object(_toolbar.get_item(1)).is_null()
	assert_int(_toolbar.selected_index).is_equal(1)
	assert_object(_toolbar.take_top()).is_null()


func test_take_top_never_takes_a_tool() -> void:
	_toolbar.select(0)
	assert_object(_toolbar.take_top()).is_null()
	assert_object(_toolbar.get_tool(0)).is_same(KNIFE)


func test_a_freed_slot_is_filled_first() -> void:
	_toolbar.add(ItemInstance.new(TOMATO))
	_toolbar.add(ItemInstance.new(TOMATO))
	_toolbar.select(1)
	_toolbar.take_top()
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)

	_toolbar.add(lettuce)

	assert_object(_toolbar.get_item(1)).is_same(lettuce)


func test_full_when_every_slot_holds_something() -> void:
	for i: int in Toolbar.SLOT_COUNT - 1:
		assert_bool(_toolbar.add(ItemInstance.new(TOMATO))).is_true()
	assert_bool(_toolbar.is_full()).is_true()

	var extra: ItemInstance = ItemInstance.new(LETTUCE)
	assert_bool(_toolbar.add(extra)).is_false()
	assert_array(_toolbar.get_items()).not_contains([extra])


func test_adding_null_is_an_error() -> void:
	await assert_error(func() -> void: _toolbar.add(null)).is_push_error(
		"Toolbar: item is null"
	)
	assert_bool(_toolbar.is_empty()).is_true()


func test_a_tool_cant_replace_an_item() -> void:
	_toolbar.add(ItemInstance.new(TOMATO))
	await assert_error(func() -> void: _toolbar.set_tool(1, KNIFE)).is_push_error(
		"Toolbar: slot 1 holds an item"
	)
	assert_object(_toolbar.get_tool(1)).is_null()


func test_selection_wraps_both_ways() -> void:
	_toolbar.select_previous()
	assert_int(_toolbar.selected_index).is_equal(Toolbar.SLOT_COUNT - 1)
	_toolbar.select_next()
	assert_int(_toolbar.selected_index).is_equal(0)


func test_selecting_emits_changed_and_ignores_bad_slots() -> void:
	_toolbar.select(5)
	_toolbar.select(5)
	_toolbar.select(-1)
	_toolbar.select(Toolbar.SLOT_COUNT)
	assert_int(_toolbar.selected_index).is_equal(5)
	assert_int(_changes).is_equal(1)


func test_lists_its_tools() -> void:
	assert_array(_toolbar.get_tools()).contains_exactly([KNIFE])


func test_rotate_does_nothing() -> void:
	_toolbar.add(ItemInstance.new(TOMATO))
	_toolbar.add(ItemInstance.new(LETTUCE))
	_toolbar.rotate()
	assert_object(_toolbar.top().item).is_same(LETTUCE)


func test_take_item_empties_any_slot_whatever_is_selected() -> void:
	_toolbar.add(ItemInstance.new(TOMATO))
	_toolbar.add(ItemInstance.new(LETTUCE))
	_toolbar.select(0)
	_changes = 0

	var taken: ItemInstance = _toolbar.take_item(1)

	assert_object(taken.item).is_same(TOMATO)
	assert_object(_toolbar.get_item(1)).is_null()
	assert_object(_toolbar.get_item(2).item).is_same(LETTUCE)
	assert_int(_toolbar.selected_index).is_equal(0)
	assert_int(_changes).is_equal(1)


func test_take_item_from_an_empty_or_tool_slot_takes_nothing() -> void:
	assert_object(_toolbar.take_item(0)).is_null()
	assert_object(_toolbar.take_item(5)).is_null()
	assert_object(_toolbar.take_item(-1)).is_null()
	assert_object(_toolbar.get_tool(0)).is_same(KNIFE)
	assert_int(_changes).is_equal(0)


func test_has_item_finds_a_kind_of_item_in_any_slot() -> void:
	_toolbar.add(ItemInstance.new(TOMATO))
	_toolbar.add(ItemInstance.new(LETTUCE))
	_toolbar.select(0)

	assert_bool(_toolbar.has_item(&"tomato")).is_true()
	assert_bool(_toolbar.has_item(&"lettuce")).is_true()
	assert_bool(_toolbar.has_item(&"frying_pan")).is_false()
