extends GameTestSuite
## Tests for DefeatLoss: a defeat takes half the items, from the last slots
## first, and never a tool.

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
const PAN: Item = preload("res://data/items/frying_pan.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")


func test_half_is_rounded_down() -> void:
	assert_int(DefeatLoss.count_lost(0)).is_equal(0)
	assert_int(DefeatLoss.count_lost(1)).is_equal(0)
	assert_int(DefeatLoss.count_lost(2)).is_equal(1)
	assert_int(DefeatLoss.count_lost(5)).is_equal(2)
	assert_int(DefeatLoss.count_lost(11)).is_equal(5)


func test_half_the_items_go_from_the_last_slots() -> void:
	var toolbar: Toolbar = _toolbar_with([PAN, TOMATO, LETTUCE, TOMATO])

	var lost: Array[ItemInstance] = DefeatLoss.take_half(toolbar)

	assert_array(_ids(lost)).contains_exactly([&"tomato", &"lettuce"])
	assert_array(_ids(toolbar.get_items())).contains_exactly([&"frying_pan", &"tomato"])
	# The knife in slot 1, then the two that are left, where they were.
	assert_object(toolbar.get_item(1).item).is_same(PAN)
	assert_object(toolbar.get_item(2).item).is_same(TOMATO)
	assert_object(toolbar.get_item(3)).is_null()
	assert_object(toolbar.get_item(4)).is_null()


func test_tools_are_never_lost() -> void:
	var toolbar: Toolbar = _toolbar_with([TOMATO, LETTUCE])

	DefeatLoss.take_half(toolbar)

	assert_object(toolbar.get_tool(0)).is_same(KNIFE)
	assert_array(toolbar.get_tools()).contains_exactly([KNIFE])


func test_a_single_item_is_kept() -> void:
	var toolbar: Toolbar = _toolbar_with([PAN])

	var lost: Array[ItemInstance] = DefeatLoss.take_half(toolbar)

	assert_array(lost).is_empty()
	assert_int(toolbar.size()).is_equal(1)


func test_an_odd_number_keeps_the_extra_one() -> void:
	var toolbar: Toolbar = _toolbar_with([PAN, TOMATO, LETTUCE])

	var lost: Array[ItemInstance] = DefeatLoss.take_half(toolbar)

	assert_int(lost.size()).is_equal(1)
	assert_int(toolbar.size()).is_equal(2)


func test_nothing_carried_loses_nothing() -> void:
	var toolbar: Toolbar = _toolbar_with([])

	assert_array(DefeatLoss.take_half(toolbar)).is_empty()


func test_the_pan_can_be_lost() -> void:
	var toolbar: Toolbar = _toolbar_with([TOMATO, PAN])

	DefeatLoss.take_half(toolbar)

	assert_bool(toolbar.has_item(&"frying_pan")).is_false()


# A toolbar with the knife in the first slot and [param items] after it.
func _toolbar_with(items: Array[Item]) -> Toolbar:
	var toolbar: Toolbar = Toolbar.new()
	toolbar.set_tool(0, KNIFE)
	for item: Item in items:
		toolbar.add(ItemInstance.new(item))
	return toolbar


func _ids(items: Array[ItemInstance]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for instance: ItemInstance in items:
		ids.append(instance.item.id)
	return ids
