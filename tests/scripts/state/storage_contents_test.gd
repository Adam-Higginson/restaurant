extends GameTestSuite
## Tests for StorageContents, using throwaway items so they don't depend on the
## catalog.

var _fridge: StorageContents
var _changes: int = 0
var _tomato: Item
var _onion: Item
var _soup: Item
var _plate: Item


func before_test() -> void:
	_tomato = _item(&"tomato", Item.StorageKind.FRIDGE)
	_onion = _item(&"onion", Item.StorageKind.CUPBOARD)
	_soup = _item(&"soup", Item.StorageKind.NONE)
	_plate = _item(&"plate", Item.StorageKind.NONE)
	_plate.capacity = 1
	_fridge = _watch(StorageContents.new(Item.StorageKind.FRIDGE, 3))


# --- Putting away -------------------------------------------------------------

func test_starts_empty() -> void:
	assert_bool(_fridge.is_empty()).is_true()
	assert_bool(_fridge.is_full()).is_false()
	assert_array(_fridge.get_items()).is_empty()


func test_puts_away_food_of_its_kind() -> void:
	var tomato: ItemInstance = ItemInstance.new(_tomato)
	assert_bool(_fridge.put_away(tomato)).is_true()
	assert_array(_fridge.get_items()).contains_exactly([tomato])
	assert_int(_changes).is_equal(1)


func test_refuses_food_of_another_kind() -> void:
	assert_bool(_fridge.put_away(ItemInstance.new(_onion))).is_false()
	assert_bool(_fridge.is_empty()).is_true()
	assert_int(_changes).is_equal(0)


func test_refuses_things_that_cant_be_stored() -> void:
	assert_bool(_fridge.accepts(ItemInstance.new(_soup))).is_false()
	assert_bool(_fridge.accepts(ItemInstance.new(_plate))).is_false()
	assert_bool(_fridge.accepts(null)).is_false()


func test_refuses_vessels_even_of_its_kind() -> void:
	var tray: Item = _item(&"tray", Item.StorageKind.FRIDGE)
	tray.capacity = 1
	assert_bool(_fridge.put_away(ItemInstance.new(tray))).is_false()


func test_holds_up_to_its_capacity() -> void:
	for i: int in 3:
		assert_bool(_fridge.put_away(ItemInstance.new(_tomato))).is_true()
	assert_bool(_fridge.is_full()).is_true()
	assert_bool(_fridge.put_away(ItemInstance.new(_tomato))).is_false()
	assert_bool(_fridge.add(ItemInstance.new(_tomato))).is_false()
	assert_int(_fridge.size()).is_equal(3)
	assert_int(_changes).is_equal(3)


func test_no_capacity_means_no_limit() -> void:
	var crate: StorageContents = StorageContents.new(Item.StorageKind.NONE, 0, true)
	for i: int in 50:
		assert_bool(crate.add(ItemInstance.new(_tomato))).is_true()
	assert_bool(crate.is_full()).is_false()
	assert_int(crate.size()).is_equal(50)


func test_take_only_refuses_putting_away_but_takes_deliveries() -> void:
	var crate: StorageContents = _watch(StorageContents.new(Item.StorageKind.FRIDGE, 0, true))
	assert_bool(crate.put_away(ItemInstance.new(_tomato))).is_false()
	assert_bool(crate.add(ItemInstance.new(_tomato))).is_true()
	assert_bool(crate.add(ItemInstance.new(_onion))).is_true()
	assert_int(crate.size()).is_equal(2)
	assert_int(_changes).is_equal(2)


func test_add_ignores_kind() -> void:
	assert_bool(_fridge.add(ItemInstance.new(_onion))).is_true()
	assert_int(_fridge.count(_onion, 1)).is_equal(1)


func test_adding_null_is_an_error() -> void:
	await assert_error(func() -> void: _fridge.add(null)).is_push_error(
		"StorageContents: instance is null"
	)
	assert_bool(_fridge.is_empty()).is_true()


func test_negative_capacity_means_no_limit() -> void:
	assert_int(StorageContents.new(Item.StorageKind.FRIDGE, -4).capacity).is_equal(0)


# --- Taking out ---------------------------------------------------------------

func test_counts_by_item_and_quality() -> void:
	_fridge.add(ItemInstance.new(_tomato, 1))
	_fridge.add(ItemInstance.new(_tomato, 2))
	_fridge.add(ItemInstance.new(_tomato, 1))
	assert_int(_fridge.count(_tomato, 1)).is_equal(2)
	assert_int(_fridge.count(_tomato, 2)).is_equal(1)
	assert_int(_fridge.count(_tomato, 3)).is_equal(0)
	assert_int(_fridge.count(_onion, 1)).is_equal(0)


func test_take_returns_the_oldest_matching_piece() -> void:
	var first: ItemInstance = ItemInstance.new(_tomato, 2)
	var good: ItemInstance = ItemInstance.new(_tomato, 3)
	var second: ItemInstance = ItemInstance.new(_tomato, 2)
	_fridge.add(first)
	_fridge.add(good)
	_fridge.add(second)
	_changes = 0

	assert_object(_fridge.take(_tomato, 2)).is_same(first)
	assert_array(_fridge.get_items()).contains_exactly([good, second])
	assert_int(_changes).is_equal(1)


func test_take_returns_null_when_there_is_none() -> void:
	_fridge.add(ItemInstance.new(_tomato, 1))
	_changes = 0
	assert_object(_fridge.take(_tomato, 2)).is_null()
	assert_object(_fridge.take(_onion, 1)).is_null()
	assert_int(_fridge.size()).is_equal(1)
	assert_int(_changes).is_equal(0)


func test_take_into_moves_one_piece_onto_the_arms() -> void:
	var tomato: ItemInstance = ItemInstance.new(_tomato, 2)
	_fridge.add(tomato)
	var arms: Arms = Arms.new()
	assert_bool(_fridge.take_into(arms, _tomato, 2)).is_true()
	assert_object(arms.top()).is_same(tomato)
	assert_bool(_fridge.is_empty()).is_true()


func test_take_into_full_arms_changes_nothing() -> void:
	_fridge.add(ItemInstance.new(_tomato))
	var arms: Arms = Arms.new()
	for i: int in Arms.CAPACITY:
		arms.add(ItemInstance.new(_onion))
	_changes = 0
	assert_bool(_fridge.take_into(arms, _tomato, 1)).is_false()
	assert_int(_fridge.size()).is_equal(1)
	assert_int(_changes).is_equal(0)


func test_take_into_with_none_inside_changes_nothing() -> void:
	var arms: Arms = Arms.new()
	assert_bool(_fridge.take_into(arms, _tomato, 1)).is_false()
	assert_bool(arms.is_empty()).is_true()


func test_get_items_is_a_copy() -> void:
	_fridge.add(ItemInstance.new(_tomato))
	_fridge.get_items().clear()
	assert_int(_fridge.size()).is_equal(1)


func test_settings_are_read_only() -> void:
	await assert_error(func() -> void: _fridge.capacity = 99).is_push_error(
		"StorageContents: capacity is read-only"
	)
	assert_int(_fridge.capacity).is_equal(3)


func _item(id: StringName, storage: Item.StorageKind) -> Item:
	var item: Item = Item.new()
	item.id = id
	item.storage = storage
	return item


func _watch(contents: StorageContents) -> StorageContents:
	_changes = 0
	contents.changed.connect(func() -> void: _changes += 1)
	return contents
