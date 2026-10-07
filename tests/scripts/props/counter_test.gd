extends GameTestSuite
## Tests for Counter, on its own and in the restaurant with the player.

const COUNTER_SCENE: String = "res://scenes/props/counter.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const ONION: Item = preload("res://data/items/onion.tres")
const CHOPPED_LETTUCE: Item = preload("res://data/items/chopped_lettuce.tres")
const SLICED_TOMATO: Item = preload("res://data/items/sliced_tomato.tres")
const DICED_TOMATO: Item = preload("res://data/items/diced_tomato.tres")
const GARDEN_SALAD: Item = preload("res://data/items/garden_salad.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
## Just below Counter1 (centred at 72, 24), which starts empty.
const BELOW_COUNTER_1: Vector2 = Vector2(72, 44)
## Just below BoardCounter (centred at 104, 24), which starts with the board.
const BELOW_BOARD: Vector2 = Vector2(104, 44)
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


# --- Vessels on the counter -----------------------------------------------------

func test_food_on_top_of_the_stack_goes_onto_the_board() -> void:
	var counter: Counter = _new_counter(BOARD)
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	_arms.add(lettuce)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([lettuce])
	assert_bool(_arms.is_empty()).is_true()


func test_board_holds_one_food_item() -> void:
	var counter: Counter = _new_counter(BOARD)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	_arms.add(ItemInstance.new(LETTUCE))
	counter.exchange_with(_arms)
	_arms.add(tomato)

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(_arms.top()).is_same(tomato)
	assert_int(counter.get_item().contents.get_contents().size()).is_equal(1)


func test_pick_up_takes_the_food_off_the_board_and_leaves_the_board() -> void:
	var counter: Counter = _new_counter(BOARD)
	var board: ItemInstance = counter.get_item()
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	board.contents.add_item(lettuce)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(lettuce)
	assert_object(counter.get_item()).is_same(board)
	assert_array(board.contents.get_contents()).is_empty()


func test_pick_up_takes_an_empty_board() -> void:
	var counter: Counter = _new_counter(BOARD)
	var board: ItemInstance = counter.get_item()

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(board)
	assert_bool(counter.is_empty()).is_true()


func test_taking_food_off_the_board_loses_its_chopping_progress() -> void:
	var counter: Counter = _new_counter(BOARD)
	_arms.add(ItemInstance.new(LETTUCE))
	counter.exchange_with(_arms)
	counter.use_tool(KNIFE)

	counter.exchange_with(_arms)
	counter.exchange_with(_arms)

	var active: Array[ActiveReaction] = counter.get_item().contents.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_float(active[0].progress).is_equal(0.0)


func test_food_on_a_carried_board_stays_with_it() -> void:
	var counter: Counter = _new_counter(null)
	var board: ItemInstance = ItemInstance.new(BOARD)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	board.contents.add_item(tomato)
	_arms.add(board)

	counter.exchange_with(_arms)

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([tomato])


func test_plate_is_picked_up_whole_with_its_food() -> void:
	var counter: Counter = _new_counter(PLATE)
	var plate: ItemInstance = counter.get_item()
	var onion: ItemInstance = ItemInstance.new(ONION)
	plate.contents.add_item(onion)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(plate)
	assert_array(plate.contents.get_contents()).contains_exactly([onion])
	assert_bool(counter.is_empty()).is_true()


func test_plate_holds_three_food_items() -> void:
	var counter: Counter = _new_counter(PLATE)
	for i: int in 3:
		_arms.add(ItemInstance.new(ONION))
		assert_bool(counter.exchange_with(_arms)).is_true()
	var fourth: ItemInstance = ItemInstance.new(ONION)
	_arms.add(fourth)

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(_arms.top()).is_same(fourth)


func test_food_that_matches_nothing_just_sits_on_the_plate() -> void:
	var counter: Counter = _new_counter(PLATE)
	var lettuce: ItemInstance = ItemInstance.new(CHOPPED_LETTUCE)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	_arms.add(tomato)
	_arms.add(lettuce)

	counter.exchange_with(_arms)
	counter.exchange_with(_arms)

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([lettuce, tomato])


func test_a_vessel_never_goes_into_another() -> void:
	var counter: Counter = _new_counter(BOARD)
	var board: ItemInstance = counter.get_item()
	var plate: ItemInstance = ItemInstance.new(PLATE)
	_arms.add(plate)

	# With room in the arms, pick up takes the empty board instead.
	counter.exchange_with(_arms)

	assert_array(_arms.get_items()).contains_exactly([plate, board])
	assert_array(plate.contents.get_contents()).is_empty()
	assert_array(board.contents.get_contents()).is_empty()


func test_use_tool_cuts_food_on_the_board() -> void:
	var counter: Counter = _new_counter(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(LETTUCE))

	for i: int in 2:
		assert_bool(counter.use_tool(KNIFE)).is_true()
	_assert_board_holds(counter, LETTUCE)
	counter.use_tool(KNIFE)

	_assert_board_holds(counter, CHOPPED_LETTUCE)
	assert_bool(counter.use_tool(KNIFE)).is_false()


func test_use_tool_slices_then_dices_a_tomato() -> void:
	var counter: Counter = _new_counter(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(TOMATO))

	for i: int in 2:
		counter.use_tool(KNIFE)
	_assert_board_holds(counter, SLICED_TOMATO)
	for i: int in 3:
		counter.use_tool(KNIFE)

	_assert_board_holds(counter, DICED_TOMATO)


func test_use_tool_does_nothing_without_a_board() -> void:
	var on_plate: Counter = _new_counter(PLATE)
	on_plate.get_item().contents.add_item(ItemInstance.new(TOMATO))
	assert_bool(on_plate.use_tool(KNIFE)).is_false()
	assert_bool(_new_counter(TOMATO).use_tool(KNIFE)).is_false()
	assert_bool(_new_counter(null).use_tool(KNIFE)).is_false()
	assert_object(on_plate.get_item().contents.get_contents()[0].item).is_same(TOMATO)


func test_counter_stops_listening_to_a_board_that_leaves() -> void:
	var counter: Counter = _new_counter(BOARD)
	var board: ItemInstance = counter.get_item()
	assert_int(board.contents.contents_changed.get_connections().size()).is_equal(1)

	counter.exchange_with(_arms)

	assert_int(board.contents.contents_changed.get_connections().size()).is_equal(0)
	assert_int(board.contents.reaction_progressed.get_connections().size()).is_equal(0)


# --- Garden Salad, end to end -----------------------------------------------------

func test_proper_garden_salad_is_three_stars() -> void:
	var board: Counter = _new_counter(BOARD)
	var plate: Counter = _new_counter(PLATE)
	_chop_onto(board, plate, LETTUCE, 3)
	_chop_onto(board, plate, TOMATO, 2)

	var food: Array[ItemInstance] = plate.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(GARDEN_SALAD)
	assert_int(food[0].quality).is_equal(3)
	# Carried away whole.
	plate.exchange_with(_arms)
	assert_object(_arms.top().contents.get_contents()[0]).is_same(food[0])


func test_shortcut_garden_salad_is_one_star() -> void:
	var plate: Counter = _new_counter(PLATE)
	_arms.add(ItemInstance.new(TOMATO))
	_arms.add(ItemInstance.new(LETTUCE))
	plate.exchange_with(_arms)
	plate.exchange_with(_arms)

	var food: Array[ItemInstance] = plate.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(GARDEN_SALAD)
	assert_int(food[0].quality).is_equal(1)


# --- In the restaurant -----------------------------------------------------------

func test_restaurant_has_five_counters_with_only_the_board_on_one() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var items: Array[Item] = []
	for node: Node in runner.scene().get_tree().get_nodes_in_group("counters"):
		var counter: Counter = node as Counter
		if not counter.is_empty():
			items.append(counter.get_item().item)
	assert_int(runner.scene().get_tree().get_nodes_in_group("counters").size()).is_equal(5)
	assert_array(items).contains_exactly([BOARD])


func test_pressing_pick_up_at_a_counter_takes_and_puts_back() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_COUNTER_1)
	var counter: Counter = runner.find_child("Counter1") as Counter
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	counter.place(tomato)

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


func test_use_tool_at_the_board_chops_the_lettuce() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_BOARD)
	var board: ItemInstance = (runner.find_child("BoardCounter") as Counter).get_item()
	player.arms.add(ItemInstance.new(LETTUCE))

	await walk(runner, "move_up", 20)
	await press(runner, "pick_up")
	for i: int in 3:
		await press(runner, "use_tool")

	assert_object(board.contents.get_contents()[0].item).is_same(CHOPPED_LETTUCE)
	assert_bool(player.arms.is_empty()).is_true()


func _new_counter(start_item: Item) -> Counter:
	var counter: Counter = (load(COUNTER_SCENE) as PackedScene).instantiate() as Counter
	counter.start_item = start_item
	add_child(counter)
	auto_free(counter)
	return counter


func _assert_board_holds(counter: Counter, item: Item) -> void:
	var food: Array[ItemInstance] = counter.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(item)


# Puts a fresh [param item] on the board, cuts it [param cuts] times, and moves
# the result onto the plate, all through the arms.
func _chop_onto(board: Counter, plate: Counter, item: Item, cuts: int) -> void:
	_arms.add(ItemInstance.new(item))
	board.exchange_with(_arms)
	for i: int in cuts:
		board.use_tool(KNIFE)
	board.exchange_with(_arms)
	plate.exchange_with(_arms)
