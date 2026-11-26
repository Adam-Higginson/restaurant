extends GameTestSuite
## Tests for CounterSlot: one item on a counter, swapped with the arms, with
## vessels taking food and the knife cutting on a board. Ported from the 2D
## Counter's tests when the rules moved out of the node.

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

var _arms: Arms


func before_test() -> void:
	_arms = Arms.new()


# --- Placing and taking -------------------------------------------------------

func test_starts_empty_without_a_start_item() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	assert_bool(counter.is_empty()).is_true()


func test_start_item_is_on_the_counter() -> void:
	var counter: CounterSlot = CounterSlot.new(TOMATO)
	assert_object(counter.get_item().item).is_same(TOMATO)
	assert_int(counter.get_item().quality).is_equal(ItemInstance.MIN_QUALITY)


func test_holds_only_one_item() -> void:
	var counter: CounterSlot = CounterSlot.new(TOMATO)
	assert_bool(counter.place(ItemInstance.new(LETTUCE))).is_false()
	assert_object(counter.get_item().item).is_same(TOMATO)


func test_take_from_empty_counter_returns_null() -> void:
	assert_object(CounterSlot.new(null).take()).is_null()


# --- Exchanging with the arms ----------------------------------------------------

func test_pick_up_takes_the_item_onto_the_top_of_the_stack() -> void:
	var counter: CounterSlot = CounterSlot.new(TOMATO)
	var on_counter: ItemInstance = counter.get_item()
	_arms.add(ItemInstance.new(PLATE))

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(on_counter)
	assert_int(_arms.size()).is_equal(2)
	assert_bool(counter.is_empty()).is_true()


func test_put_down_moves_the_top_item_to_an_empty_counter() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	var tomato: ItemInstance = ItemInstance.new(TOMATO, 3)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	_arms.add(tomato)
	_arms.add(plate)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(counter.get_item()).is_same(plate)
	assert_array(_arms.get_items()).contains_exactly([tomato])


func test_pick_up_with_full_arms_does_nothing() -> void:
	var counter: CounterSlot = CounterSlot.new(TOMATO)
	for i: int in Arms.CAPACITY:
		_arms.add(ItemInstance.new(PLATE))

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(counter.get_item().item).is_same(TOMATO)
	assert_int(_arms.size()).is_equal(Arms.CAPACITY)


func test_empty_counter_and_empty_arms_does_nothing() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	assert_bool(counter.exchange_with(_arms)).is_false()
	assert_bool(counter.is_empty()).is_true()


func test_item_keeps_its_quality_when_moved() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	var diced: ItemInstance = ItemInstance.new(TOMATO, 3)
	_arms.add(diced)
	counter.exchange_with(_arms)
	counter.exchange_with(_arms)
	assert_object(_arms.top()).is_same(diced)
	assert_int(_arms.top().quality).is_equal(3)


func test_item_changed_is_emitted_on_place_and_take() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	var changes: Array[ItemInstance] = []
	counter.item_changed.connect(func(item: ItemInstance) -> void: changes.append(item))
	var tomato: ItemInstance = ItemInstance.new(TOMATO)

	counter.place(tomato)
	counter.take()

	assert_array(changes).contains_exactly([tomato, null])


# --- Vessels on the counter -----------------------------------------------------

func test_food_on_top_of_the_stack_goes_onto_the_board() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	_arms.add(lettuce)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([lettuce])
	assert_bool(_arms.is_empty()).is_true()


func test_board_holds_one_food_item() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	_arms.add(ItemInstance.new(LETTUCE))
	counter.exchange_with(_arms)
	_arms.add(tomato)

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(_arms.top()).is_same(tomato)
	assert_int(counter.get_item().contents.get_contents().size()).is_equal(1)


func test_pick_up_takes_the_food_off_the_board_and_leaves_the_board() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var board: ItemInstance = counter.get_item()
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	board.contents.add_item(lettuce)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(lettuce)
	assert_object(counter.get_item()).is_same(board)
	assert_array(board.contents.get_contents()).is_empty()


func test_pick_up_takes_an_empty_board() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var board: ItemInstance = counter.get_item()

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(board)
	assert_bool(counter.is_empty()).is_true()


func test_taking_food_off_the_board_loses_its_chopping_progress() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	_arms.add(ItemInstance.new(LETTUCE))
	counter.exchange_with(_arms)
	counter.use_tool(KNIFE)

	counter.exchange_with(_arms)
	counter.exchange_with(_arms)

	var active: Array[ActiveReaction] = counter.get_item().contents.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_float(active[0].progress).is_equal(0.0)


func test_food_on_a_carried_board_stays_with_it() -> void:
	var counter: CounterSlot = CounterSlot.new(null)
	var board: ItemInstance = ItemInstance.new(BOARD)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	board.contents.add_item(tomato)
	_arms.add(board)

	counter.exchange_with(_arms)

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([tomato])


func test_plate_is_picked_up_whole_with_its_food() -> void:
	var counter: CounterSlot = CounterSlot.new(PLATE)
	var plate: ItemInstance = counter.get_item()
	var onion: ItemInstance = ItemInstance.new(ONION)
	plate.contents.add_item(onion)

	assert_bool(counter.exchange_with(_arms)).is_true()

	assert_object(_arms.top()).is_same(plate)
	assert_array(plate.contents.get_contents()).contains_exactly([onion])
	assert_bool(counter.is_empty()).is_true()


func test_plate_holds_three_food_items() -> void:
	var counter: CounterSlot = CounterSlot.new(PLATE)
	for i: int in 3:
		_arms.add(ItemInstance.new(ONION))
		assert_bool(counter.exchange_with(_arms)).is_true()
	var fourth: ItemInstance = ItemInstance.new(ONION)
	_arms.add(fourth)

	assert_bool(counter.exchange_with(_arms)).is_false()

	assert_object(_arms.top()).is_same(fourth)


func test_food_that_matches_nothing_just_sits_on_the_plate() -> void:
	var counter: CounterSlot = CounterSlot.new(PLATE)
	var lettuce: ItemInstance = ItemInstance.new(CHOPPED_LETTUCE)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	_arms.add(tomato)
	_arms.add(lettuce)

	counter.exchange_with(_arms)
	counter.exchange_with(_arms)

	assert_array(counter.get_item().contents.get_contents()).contains_exactly([lettuce, tomato])


func test_a_vessel_never_goes_into_another() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var board: ItemInstance = counter.get_item()
	var plate: ItemInstance = ItemInstance.new(PLATE)
	_arms.add(plate)

	# With room in the arms, pick up takes the empty board instead.
	counter.exchange_with(_arms)

	assert_array(_arms.get_items()).contains_exactly([plate, board])
	assert_array(plate.contents.get_contents()).is_empty()
	assert_array(board.contents.get_contents()).is_empty()


func test_use_tool_cuts_food_on_the_board() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(LETTUCE))

	for i: int in 2:
		assert_bool(counter.use_tool(KNIFE)).is_true()
	_assert_board_holds(counter, LETTUCE)
	counter.use_tool(KNIFE)

	_assert_board_holds(counter, CHOPPED_LETTUCE)
	assert_bool(counter.use_tool(KNIFE)).is_false()


func test_use_tool_slices_then_dices_a_tomato() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(TOMATO))

	for i: int in 2:
		counter.use_tool(KNIFE)
	_assert_board_holds(counter, SLICED_TOMATO)
	for i: int in 3:
		counter.use_tool(KNIFE)

	_assert_board_holds(counter, DICED_TOMATO)


func test_use_tool_does_nothing_without_a_board() -> void:
	var on_plate: CounterSlot = CounterSlot.new(PLATE)
	on_plate.get_item().contents.add_item(ItemInstance.new(TOMATO))
	assert_bool(on_plate.use_tool(KNIFE)).is_false()
	assert_bool(CounterSlot.new(TOMATO).use_tool(KNIFE)).is_false()
	assert_bool(CounterSlot.new(null).use_tool(KNIFE)).is_false()
	assert_object(on_plate.get_item().contents.get_contents()[0].item).is_same(TOMATO)


func test_counter_stops_listening_to_a_board_that_leaves() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var board: ItemInstance = counter.get_item()
	assert_int(board.contents.contents_changed.get_connections().size()).is_equal(1)

	counter.exchange_with(_arms)

	assert_int(board.contents.contents_changed.get_connections().size()).is_equal(0)
	assert_int(board.contents.reaction_progressed.get_connections().size()).is_equal(0)


# --- With the 3D toolbar --------------------------------------------------------

func test_holding_food_at_a_counter_with_other_food_picks_that_up_too() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(TOMATO)
	var lettuce: ItemInstance = ItemInstance.new(LETTUCE)
	hand.add(lettuce)

	assert_int(counter.interact_action(hand)).is_equal(CounterSlot.Action.PICK_UP)
	assert_bool(counter.exchange_with(hand)).is_true()

	assert_object(hand.top().item).is_same(TOMATO)
	assert_array(hand.get_items()).contains([lettuce])
	assert_bool(counter.is_empty()).is_true()


func test_a_full_toolbar_at_an_occupied_counter_does_nothing() -> void:
	var hand: Toolbar = Toolbar.new()
	while not hand.is_full():
		hand.add(ItemInstance.new(LETTUCE))
	var counter: CounterSlot = CounterSlot.new(TOMATO)

	assert_int(counter.interact_action(hand)).is_equal(CounterSlot.Action.NONE)
	assert_bool(counter.exchange_with(hand)).is_false()
	assert_object(counter.get_item().item).is_same(TOMATO)


func test_a_held_plate_takes_the_food_off_the_board() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var lettuce: ItemInstance = ItemInstance.new(CHOPPED_LETTUCE)
	counter.get_item().contents.add_item(lettuce)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	hand.add(plate)

	assert_int(counter.interact_action(hand)).is_equal(CounterSlot.Action.MOVE_ONTO_PLATE)
	assert_bool(counter.exchange_with(hand)).is_true()

	assert_object(hand.top()).is_same(plate)
	assert_array(plate.contents.get_contents()).contains_exactly([lettuce])
	assert_array(counter.get_item().contents.get_contents()).is_empty()
	assert_object(counter.get_item().item).is_same(BOARD)


func test_moving_food_onto_a_plate_makes_a_salad() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(SLICED_TOMATO, 2))
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(CHOPPED_LETTUCE, 2))
	hand.add(plate)

	counter.exchange_with(hand)

	var food: Array[ItemInstance] = plate.contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(GARDEN_SALAD)
	assert_int(food[0].quality).is_equal(3)


func test_moving_food_half_chopped_loses_its_progress() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(LETTUCE))
	counter.use_tool(KNIFE)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	hand.add(plate)

	counter.exchange_with(hand)

	assert_object(plate.contents.get_contents()[0].item).is_same(LETTUCE)
	assert_array(counter.get_item().contents.get_active_reactions()).is_empty()


func test_a_full_plate_leaves_the_food_so_it_is_taken_instead() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var lettuce: ItemInstance = ItemInstance.new(CHOPPED_LETTUCE)
	counter.get_item().contents.add_item(lettuce)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	for i: int in PLATE.capacity:
		plate.contents.add_item(ItemInstance.new(ONION))
	hand.add(plate)

	assert_int(counter.interact_action(hand)).is_equal(CounterSlot.Action.TAKE_FOOD)
	counter.exchange_with(hand)

	assert_object(hand.top()).is_same(lettuce)
	assert_int(plate.contents.get_contents().size()).is_equal(PLATE.capacity)


func test_a_held_plate_at_an_empty_board_picks_up_the_board() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	hand.add(ItemInstance.new(PLATE))
	assert_int(counter.interact_action(hand)).is_equal(CounterSlot.Action.PICK_UP)


# --- What Interact would do ----------------------------------------------------

func test_interact_action_matches_each_case() -> void:
	var hand: Toolbar = Toolbar.new()
	assert_int(CounterSlot.new(null).interact_action(hand)).is_equal(CounterSlot.Action.NONE)
	assert_int(CounterSlot.new(TOMATO).interact_action(hand)) \
			.is_equal(CounterSlot.Action.PICK_UP)
	var board: CounterSlot = CounterSlot.new(BOARD)
	assert_int(board.interact_action(hand)).is_equal(CounterSlot.Action.PICK_UP)
	board.get_item().contents.add_item(ItemInstance.new(LETTUCE))
	assert_int(board.interact_action(hand)).is_equal(CounterSlot.Action.TAKE_FOOD)

	hand.add(ItemInstance.new(TOMATO))
	assert_int(CounterSlot.new(null).interact_action(hand)) \
			.is_equal(CounterSlot.Action.PUT_DOWN)
	assert_int(CounterSlot.new(PLATE).interact_action(hand)) \
			.is_equal(CounterSlot.Action.ADD_TO_VESSEL)
	# The board already holds its one piece of food.
	assert_int(board.interact_action(hand)).is_equal(CounterSlot.Action.NONE)


func test_interact_prompts() -> void:
	var hand: Toolbar = Toolbar.new()
	var board: CounterSlot = CounterSlot.new(BOARD)
	assert_str(board.interact_prompt(hand)).is_equal("Pick up Chopping Board")
	assert_str(CounterSlot.new(null).interact_prompt(hand)).is_empty()

	hand.add(ItemInstance.new(LETTUCE))
	assert_str(CounterSlot.new(null).interact_prompt(hand)).is_equal("Put down Lettuce")
	assert_str(board.interact_prompt(hand)).is_equal("Put Lettuce on Chopping Board")

	board.exchange_with(hand)
	assert_str(board.interact_prompt(hand)).is_equal("Take Lettuce")

	hand.add(ItemInstance.new(PLATE))
	assert_str(board.interact_prompt(hand)).is_equal("Put Lettuce on Plate")
	assert_str(CounterSlot.new(TOMATO).interact_prompt(hand)).is_equal("Pick up Tomato")


func test_can_use_tool_only_while_there_is_something_to_cut() -> void:
	var board: CounterSlot = CounterSlot.new(BOARD)
	assert_bool(board.can_use_tool(KNIFE)).is_false()
	board.get_item().contents.add_item(ItemInstance.new(LETTUCE))
	assert_bool(board.can_use_tool(KNIFE)).is_true()
	for i: int in 3:
		board.use_tool(KNIFE)
	# Chopped lettuce can't be cut any further.
	assert_bool(board.can_use_tool(KNIFE)).is_false()
	assert_bool(CounterSlot.new(TOMATO).can_use_tool(KNIFE)).is_false()
	assert_bool(CounterSlot.new(null).can_use_tool(KNIFE)).is_false()


# --- Garden Salad, end to end -----------------------------------------------------

func test_proper_garden_salad_is_three_stars() -> void:
	var board: CounterSlot = CounterSlot.new(BOARD)
	var plate: CounterSlot = CounterSlot.new(PLATE)
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
	var plate: CounterSlot = CounterSlot.new(PLATE)
	_arms.add(ItemInstance.new(TOMATO))
	_arms.add(ItemInstance.new(LETTUCE))
	plate.exchange_with(_arms)
	plate.exchange_with(_arms)

	var food: Array[ItemInstance] = plate.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(GARDEN_SALAD)
	assert_int(food[0].quality).is_equal(1)


func test_changed_is_emitted_as_a_board_is_used() -> void:
	var counter: CounterSlot = CounterSlot.new(BOARD)
	var count: Array[int] = [0]
	counter.changed.connect(func() -> void: count[0] += 1)
	_arms.add(ItemInstance.new(LETTUCE))

	counter.exchange_with(_arms)
	var after_adding: int = count[0]
	counter.use_tool(KNIFE)

	assert_int(after_adding).is_greater(0)
	assert_int(count[0]).is_greater(after_adding)


func _assert_board_holds(counter: CounterSlot, item: Item) -> void:
	var food: Array[ItemInstance] = counter.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(item)


# Puts a fresh [param item] on the board, cuts it [param cuts] times, and moves
# the result onto the plate, all through the arms.
func _chop_onto(board: CounterSlot, plate: CounterSlot, item: Item, cuts: int) -> void:
	_arms.add(ItemInstance.new(item))
	board.exchange_with(_arms)
	for i: int in cuts:
		board.use_tool(KNIFE)
	board.exchange_with(_arms)
	plate.exchange_with(_arms)


# --- Use and Interact, apart (#207) ----------------------------------------------

func test_use_puts_the_held_item_down() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(null)
	var tomato: ItemInstance = ItemInstance.new(TOMATO)
	hand.add(tomato)

	assert_str(counter.use_prompt(hand)).is_equal("Put down Tomato")
	assert_str(counter.take_prompt(hand)).is_empty()
	assert_bool(counter.use_with(hand)).is_true()

	assert_object(counter.get_item()).is_same(tomato)
	assert_bool(hand.is_empty()).is_true()


func test_use_puts_food_on_the_board_and_interact_takes_it_off() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	hand.add(ItemInstance.new(LETTUCE))

	assert_int(counter.use_action(hand)).is_equal(CounterSlot.Action.ADD_TO_VESSEL)
	counter.use_with(hand)
	assert_int(counter.take_action(hand)).is_equal(CounterSlot.Action.TAKE_FOOD)
	assert_bool(counter.take_into(hand)).is_true()

	assert_object(hand.top().item).is_same(LETTUCE)
	assert_array(counter.get_item().contents.get_contents()).is_empty()


func test_with_nothing_held_use_does_nothing() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(TOMATO)

	assert_int(counter.use_action(hand)).is_equal(CounterSlot.Action.NONE)
	assert_bool(counter.use_with(hand)).is_false()
	assert_str(counter.take_prompt(hand)).is_equal("Pick up Tomato")


func test_interact_picks_up_whatever_you_hold() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(BOARD)
	counter.get_item().contents.add_item(ItemInstance.new(TOMATO))
	hand.add(ItemInstance.new(LETTUCE))

	# Holding lettuce, Use would put it on the board, but Interact takes the
	# tomato off it into a free slot.
	assert_int(counter.take_action(hand)).is_equal(CounterSlot.Action.TAKE_FOOD)
	counter.take_into(hand)

	assert_object(hand.top().item).is_same(TOMATO)
	assert_int(hand.get_items().size()).is_equal(2)


# --- The pot (#207 follow-up) ----------------------------------------------------

func test_water_in_a_pot_cant_be_taken_by_hand() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(preload("res://data/items/saucepan.tres"))
	counter.get_item().contents.add_item(ItemInstance.new(preload("res://data/items/rainwater.tres")))

	# Interact picks up the whole pot, water and all, rather than the water.
	assert_int(counter.take_action(hand)).is_equal(CounterSlot.Action.PICK_UP)
	assert_str(counter.take_prompt(hand)).is_equal("Pick up Cooking Pot")


func test_once_food_is_in_the_water_it_stays_in() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(preload("res://data/items/saucepan.tres"))
	counter.get_item().contents.add_item(ItemInstance.new(preload("res://data/items/rainwater.tres")))
	counter.get_item().contents.add_item(ItemInstance.new(TOMATO))

	assert_str(counter.take_prompt(hand)).is_equal("Pick up Cooking Pot")


func test_food_comes_out_of_a_dry_pan() -> void:
	var hand: Toolbar = Toolbar.new()
	var counter: CounterSlot = CounterSlot.new(preload("res://data/items/frying_pan.tres"))
	counter.get_item().contents.add_item(ItemInstance.new(TOMATO))

	assert_str(counter.take_prompt(hand)).is_equal("Take Tomato")


func test_food_goes_in_a_pot_and_on_a_board() -> void:
	var hand: Toolbar = Toolbar.new()
	hand.add(ItemInstance.new(DICED_TOMATO))

	assert_str(CounterSlot.new(preload("res://data/items/saucepan.tres")).use_prompt(hand)) \
			.is_equal("Put Diced Tomato in Cooking Pot")
	assert_str(CounterSlot.new(BOARD).use_prompt(hand)).is_equal("Put Diced Tomato on Chopping Board")

func test_soup_requires_a_bowl_and_a_plain_batch_can_go_back() -> void:
	var pot: Item = load("res://data/items/saucepan.tres") as Item
	var soup: Item = load("res://data/items/tomato_soup.tres") as Item
	var bowl: Item = load("res://data/items/bowl.tres") as Item
	var plate: Item = load("res://data/items/plate.tres") as Item
	var slot: CounterSlot = CounterSlot.new(pot)
	var original: ItemInstance = ItemInstance.new(soup)
	slot.get_item().contents.add_item(original)
	var arms: Toolbar = Toolbar.new()
	arms.add(ItemInstance.new(plate))
	assert_bool(slot.use_with(arms)).is_false()
	assert_str(slot.use_prompt(arms)).is_equal("Use a bowl for soup")
	arms.add(ItemInstance.new(bowl))
	assert_bool(slot.use_with(arms)).is_true()
	assert_object(arms.top().contents.get_contents()[0]).is_same(original)
	assert_bool(slot.use_with(arms)).is_true()
	assert_object(slot.get_item().contents.get_contents()[0]).is_same(original)
