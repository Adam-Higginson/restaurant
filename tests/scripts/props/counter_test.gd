extends GameTestSuite
## Tests for Counter, on its own and in the restaurant with the player.

const COUNTER_SCENE: String = "res://scenes/props/counter.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
## Just below Counter1 (centred at 72, 24), which starts with a tomato.
const BELOW_COUNTER_1: Vector2 = Vector2(72, 44)
## Just below Counter4 (centred at 136, 24), which starts empty.
const BELOW_COUNTER_4: Vector2 = Vector2(136, 44)

var _arms: Arms


func before_test() -> void:
	_arms = Arms.new()


# --- Placing and taking -------------------------------------------------------

func test_starts_empty_without_a_start_item() -> void:
	var counter: Counter = _new_counter(null)
	assert_bool(counter.is_empty()).is_true()


func test_start_item_is_on_the_counter() -> void:
	var counter: Counter = _new_counter(TOMATO)
	assert_object(counter.get_item().item).is_same(TOMATO)
	assert_int(counter.get_item().quality).is_equal(ItemInstance.MIN_QUALITY)


func test_holds_only_one_item() -> void:
	var counter: Counter = _new_counter(TOMATO)
	assert_bool(counter.place(ItemInstance.new(LETTUCE))).is_false()
	assert_object(counter.get_item().item).is_same(TOMATO)


func test_take_from_empty_counter_returns_null() -> void:
	assert_object(_new_counter(null).take()).is_null()


# --- Exchanging with the arms ----------------------------------------------------

func test_pick_up_takes_the_item_onto_the_top_of_the_stack() -> void:
	var counter: Counter = _new_counter(TOMATO)
	var on_counter: ItemInstance = counter.get_item()
	_arms.add(ItemInstance.new(PLATE))

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(on_counter)
	assert_int(_arms.size()).is_equal(2)
	assert_bool(counter.is_empty()).is_true()


func test_put_down_moves_the_top_item_to_an_empty_counter() -> void:
	var counter: Counter = _new_counter(null)
	var tomato: ItemInstance = ItemInstance.new(TOMATO, 3)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	_arms.add(tomato)
	_arms.add(plate)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(counter.get_item()).is_same(plate)
	assert_array(_arms.get_items()).contains_exactly([tomato])


func test_pick_up_with_full_arms_does_nothing() -> void:
	var counter: Counter = _new_counter(TOMATO)
	for i: int in Arms.CAPACITY:
		_arms.add(ItemInstance.new(PLATE))

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(counter.get_item().item).is_same(TOMATO)
	assert_int(_arms.size()).is_equal(Arms.CAPACITY)


func test_empty_counter_and_empty_arms_does_nothing() -> void:
	var counter: Counter = _new_counter(null)
	assert_bool(counter.exchange_with(_arms)).is_false()
	assert_bool(counter.is_empty()).is_true()


func test_item_keeps_its_quality_when_moved() -> void:
	var counter: Counter = _new_counter(null)
	var diced: ItemInstance = ItemInstance.new(TOMATO, 3)
	_arms.add(diced)
	counter.exchange_with(_arms)
	counter.exchange_with(_arms)
	assert_object(_arms.top()).is_same(diced)
	assert_int(_arms.top().quality).is_equal(3)


func test_item_changed_is_emitted_on_place_and_take() -> void:
	var counter: Counter = _new_counter(null)
	var changes: Array[ItemInstance] = []
	counter.item_changed.connect(func(item: ItemInstance) -> void: changes.append(item))
	var tomato: ItemInstance = ItemInstance.new(TOMATO)

	counter.place(tomato)
	counter.take()

	assert_array(changes).contains_exactly([tomato, null])


# --- In the restaurant -----------------------------------------------------------

func test_restaurant_has_four_counters_with_three_test_items() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var items: Array[Item] = []
	for node: Node in runner.scene().get_tree().get_nodes_in_group("counters"):
		var counter: Counter = node as Counter
		if not counter.is_empty():
			items.append(counter.get_item().item)
	assert_int(runner.scene().get_tree().get_nodes_in_group("counters").size()).is_equal(4)
	assert_array(items).contains_exactly_in_any_order([TOMATO, LETTUCE, PLATE])


func test_pressing_pick_up_at_a_counter_takes_and_puts_back() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_COUNTER_1)
	var counter: Counter = runner.find_child("Counter1") as Counter
	var tomato: ItemInstance = counter.get_item()

	await walk(runner, "move_up", 20)
	await press(runner, "pick_up")
	assert_object(player.arms.top()).is_same(tomato)
	assert_bool(counter.is_empty()).is_true()

	await press(runner, "pick_up")
	assert_bool(player.arms.is_empty()).is_true()
	assert_object(counter.get_item()).is_same(tomato)


func test_carried_item_can_be_put_on_another_counter() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_COUNTER_4)
	var counter: Counter = runner.find_child("Counter4") as Counter
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	player.arms.add(tomato)

	await walk(runner, "move_up", 20)
	await press(runner, "pick_up")

	assert_object(counter.get_item()).is_same(tomato)
	assert_bool(player.arms.is_empty()).is_true()


func test_pick_up_facing_nothing_keeps_the_stack() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	# Facing down at the start, towards open floor.
	var player: Player = place_player(runner, BELOW_COUNTER_1)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	player.arms.add(tomato)

	await physics_ticks(runner, 5)
	await press(runner, "pick_up")

	assert_object(player.arms.top()).is_same(tomato)


func _new_counter(start_item: Item) -> Counter:
	var counter: Counter = (load(COUNTER_SCENE) as PackedScene).instantiate() as Counter
	counter.start_item = start_item
	add_child(counter)
	auto_free(counter)
	return counter
