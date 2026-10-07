extends GameTestSuite
## Tests for Arms, using throwaway items so they don't depend on the catalog.

var _arms: Arms
var _changes: int = 0


func before_test() -> void:
	_arms = Arms.new()
	_changes = 0
	_arms.changed.connect(func() -> void: _changes += 1)


func test_starts_empty() -> void:
	assert_bool(_arms.is_empty()).is_true()
	assert_bool(_arms.is_full()).is_false()
	assert_object(_arms.top()).is_null()


func test_added_item_goes_on_top() -> void:
	var tomato: ItemInstance = _make(&"tomato")
	var plate: ItemInstance = _make(&"plate")
	assert_bool(_arms.add(tomato)).is_true()
	assert_bool(_arms.add(plate)).is_true()
	assert_object(_arms.top()).is_same(plate)
	assert_array(_arms.get_items()).contains_exactly([tomato, plate])
	assert_int(_changes).is_equal(2)


func test_holds_up_to_three_items() -> void:
	for i: int in Arms.CAPACITY:
		assert_bool(_arms.add(_make(&"tomato"))).is_true()
	assert_bool(_arms.is_full()).is_true()

	var extra: ItemInstance = _make(&"lettuce")
	assert_bool(_arms.add(extra)).is_false()
	assert_int(_arms.size()).is_equal(Arms.CAPACITY)
	assert_array(_arms.get_items()).not_contains([extra])
	assert_int(_changes).is_equal(Arms.CAPACITY)


func test_rejects_null() -> void:
	assert_bool(_arms.add(null)).is_false()
	assert_bool(_arms.is_empty()).is_true()
	assert_int(_changes).is_equal(0)


func test_take_top_removes_the_top_item() -> void:
	var tomato: ItemInstance = _make(&"tomato")
	var plate: ItemInstance = _make(&"plate")
	_arms.add(tomato)
	_arms.add(plate)
	assert_object(_arms.take_top()).is_same(plate)
	assert_object(_arms.top()).is_same(tomato)
	assert_int(_changes).is_equal(3)


func test_take_top_with_empty_arms_returns_null() -> void:
	assert_object(_arms.take_top()).is_null()
	assert_int(_changes).is_equal(0)


func test_rotate_moves_the_top_item_to_the_bottom() -> void:
	var tomato: ItemInstance = _make(&"tomato")
	var lettuce: ItemInstance = _make(&"lettuce")
	var plate: ItemInstance = _make(&"plate")
	_arms.add(tomato)
	_arms.add(lettuce)
	_arms.add(plate)
	_changes = 0

	_arms.rotate()
	assert_array(_arms.get_items()).contains_exactly([plate, tomato, lettuce])
	assert_object(_arms.top()).is_same(lettuce)
	assert_int(_changes).is_equal(1)

	_arms.rotate()
	_arms.rotate()
	assert_array(_arms.get_items()).contains_exactly([tomato, lettuce, plate])


func test_rotate_with_fewer_than_two_items_does_nothing() -> void:
	_arms.rotate()
	var tomato: ItemInstance = _make(&"tomato")
	_arms.add(tomato)
	_changes = 0
	_arms.rotate()
	assert_object(_arms.top()).is_same(tomato)
	assert_int(_changes).is_equal(0)


func test_get_items_is_a_copy() -> void:
	_arms.add(_make(&"tomato"))
	_arms.get_items().clear()
	assert_int(_arms.size()).is_equal(1)


func _make(id: StringName) -> ItemInstance:
	var item: Item = Item.new()
	item.id = id
	return ItemInstance.new(item)
