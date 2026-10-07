extends GameTestSuite
## Tests for ToolBelt, using throwaway tools so they don't depend on the catalog.

var _belt: ToolBelt
var _changes: int = 0


func before_test() -> void:
	_belt = ToolBelt.new()
	_changes = 0
	_belt.changed.connect(func() -> void: _changes += 1)


func test_starts_empty_with_the_first_slot_selected() -> void:
	assert_int(_belt.selected_index).is_equal(0)
	for i: int in ToolBelt.SLOT_COUNT:
		assert_object(_belt.get_tool(i)).is_null()
	assert_object(_belt.selected_tool()).is_null()


func test_selected_tool_is_the_one_in_the_selected_slot() -> void:
	var knife: HandTool = HandTool.new()
	_belt.set_tool(2, knife)
	assert_object(_belt.selected_tool()).is_null()

	_belt.select(2)

	assert_object(_belt.selected_tool()).is_same(knife)
	assert_int(_changes).is_equal(2)


func test_set_tool_null_empties_a_slot() -> void:
	_belt.set_tool(0, HandTool.new())
	_belt.set_tool(0, null)
	assert_object(_belt.get_tool(0)).is_null()
	assert_int(_changes).is_equal(2)


func test_select_ignores_slots_outside_the_belt() -> void:
	_belt.select(1)
	_belt.select(-1)
	_belt.select(ToolBelt.SLOT_COUNT)
	assert_int(_belt.selected_index).is_equal(1)
	assert_int(_changes).is_equal(1)


func test_selecting_the_selected_slot_changes_nothing() -> void:
	_belt.select(0)
	assert_int(_changes).is_equal(0)


func test_select_next_goes_through_every_slot_and_wraps() -> void:
	# Empty slots included, so cycling matches the number keys and the bar.
	var seen: Array[int] = []
	for i: int in ToolBelt.SLOT_COUNT:
		_belt.select_next()
		seen.append(_belt.selected_index)
	assert_array(seen).contains_exactly([1, 2, 3, 0])


func test_select_previous_wraps_from_the_first_slot_to_the_last() -> void:
	_belt.select_previous()
	assert_int(_belt.selected_index).is_equal(ToolBelt.SLOT_COUNT - 1)
	_belt.select_previous()
	assert_int(_belt.selected_index).is_equal(ToolBelt.SLOT_COUNT - 2)


func test_get_tool_out_of_range_is_null() -> void:
	assert_object(_belt.get_tool(-1)).is_null()
	assert_object(_belt.get_tool(ToolBelt.SLOT_COUNT)).is_null()
