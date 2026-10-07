extends GameTestSuite
## Tests for the reaction engine, using throwaway items, elements and reactions
## so they don't depend on the catalog's data.

var _board: Item
var _plate: Item
var _pan: Item
var _tomato: Item
var _sliced: Item
var _diced: Item
var _lettuce: Item
var _salad: Item
var _water: Item
var _boiling: Item
var _onion: Item
var _soup: Item
var _potato: Item
var _boiled_potato: Item

var _cut: Element
var _fire: Element
var _cold: Element

var _slice: Reaction
var _dice: Reaction
var _make_salad: Reaction
var _boil_water: Reaction
var _rushed_soup: Reaction
var _boil_potato: Reaction


func before_test() -> void:
	_board = _item(&"board")
	_plate = _item(&"plate")
	_pan = _item(&"pan")
	_tomato = _item(&"tomato")
	_sliced = _item(&"sliced_tomato")
	_diced = _item(&"diced_tomato")
	_lettuce = _item(&"lettuce")
	_salad = _item(&"salad")
	_water = _item(&"water")
	_boiling = _item(&"boiling_water")
	_onion = _item(&"onion")
	_soup = _item(&"soup")
	_potato = _item(&"potato")
	_boiled_potato = _item(&"boiled_potato")

	_cut = _element(&"cut", Element.Kind.INSTANT)
	_fire = _element(&"fire", Element.Kind.TIMED)
	_cold = _element(&"cold", Element.Kind.TIMED)

	_slice = _reaction([_tomato], [_board], [_cut], 2, _sliced, 3)
	_dice = _reaction([_sliced], [_board], [_cut], 3, _diced, 3)
	_make_salad = _reaction([_lettuce, _sliced], [_plate], [], 0, _salad, 3)
	_boil_water = _reaction([_water], [_pan], [_fire], 4, _boiling, 3)
	_rushed_soup = _reaction([_water, _tomato, _onion], [_pan], [_fire], 6, _soup, 1)
	_boil_potato = _reaction([_potato], [_pan, _boiling], [_fire], 5, _boiled_potato, 3)


# --- Adding and removing items ------------------------------------------------

func test_add_item_respects_capacity() -> void:
	var board: VesselContents = _vessel(_board, 1)
	assert_bool(board.add_item(_piece(_tomato))).is_true()
	assert_bool(board.add_item(_piece(_lettuce))).is_false()
	assert_int(board.get_contents().size()).is_equal(1)


func test_add_item_rejects_the_same_piece_twice() -> void:
	var plate: VesselContents = _vessel(_plate, 3)
	var tomato: ItemInstance = _piece(_tomato)
	plate.add_item(tomato)
	assert_bool(plate.add_item(tomato)).is_false()
	assert_int(plate.get_contents().size()).is_equal(1)


func test_remove_item_reports_whether_it_was_there() -> void:
	var plate: VesselContents = _vessel(_plate, 3)
	var tomato: ItemInstance = _piece(_tomato)
	assert_bool(plate.remove_item(tomato)).is_false()
	plate.add_item(tomato)
	assert_bool(plate.remove_item(tomato)).is_true()
	assert_array(plate.get_contents()).is_empty()


func test_get_contents_returns_a_copy() -> void:
	var plate: VesselContents = _vessel(_plate, 3)
	plate.add_item(_piece(_tomato))
	plate.get_contents().clear()
	assert_int(plate.get_contents().size()).is_equal(1)


# --- Matching -----------------------------------------------------------------

func test_matching_items_start_a_reaction() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_tomato))
	var active: Array[ActiveReaction] = board.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_object(active[0].reaction).is_same(_slice)
	assert_float(active[0].get_fraction()).is_equal(0.0)


func test_items_that_match_nothing_just_sit_there() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_lettuce))
	assert_array(board.get_active_reactions()).is_empty()
	assert_bool(board.add_element(_cut)).is_false()
	assert_object(board.get_contents()[0].item).is_same(_lettuce)


func test_only_reactions_that_require_the_vessel_happen_in_it() -> void:
	# Slicing needs a board, so a tomato on a plate stays whole.
	var plate: VesselContents = _vessel(_plate, 3)
	plate.add_item(_piece(_tomato))
	assert_array(plate.get_active_reactions()).is_empty()


func test_immediate_reaction_finishes_when_the_last_item_arrives() -> void:
	var plate: VesselContents = _vessel(_plate, 3)
	plate.add_item(_piece(_lettuce, 2))
	assert_array(plate.get_active_reactions()).is_empty()
	plate.add_item(_piece(_sliced, 2))
	_assert_items(plate, [_salad])
	assert_array(plate.get_active_reactions()).is_empty()


func test_bigger_reaction_takes_over_from_a_smaller_one() -> void:
	# Water starts boiling, then tomato and onion go in: the rushed soup uses
	# more items, so it takes the water and boiling it is cancelled.
	var pan: VesselContents = _vessel(_pan, 3)
	var cancelled: Array[Reaction] = []
	pan.reaction_cancelled.connect(
		func(active: ActiveReaction) -> void: cancelled.append(active.reaction)
	)
	pan.add_element(_fire)
	pan.add_item(_piece(_water))
	pan.tick(2.0)
	pan.add_item(_piece(_tomato))
	pan.add_item(_piece(_onion))
	assert_array(cancelled).contains_exactly([_boil_water])
	var active: Array[ActiveReaction] = pan.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_object(active[0].reaction).is_same(_rushed_soup)
	pan.tick(6.0)
	_assert_items(pan, [_soup])


func test_dumping_everything_in_at_once_also_picks_the_bigger_reaction() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_water))
	pan.add_item(_piece(_tomato))
	pan.add_item(_piece(_onion))
	var active: Array[ActiveReaction] = pan.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_object(active[0].reaction).is_same(_rushed_soup)


func test_equal_sized_reactions_go_in_catalog_order() -> void:
	var squash: Item = _item(&"squashed_tomato")
	var squash_tomato: Reaction = _reaction([_tomato], [_board], [_cut], 2, squash, 1)
	var first: VesselContents = VesselContents.new(_board, [squash_tomato, _slice], 1)
	first.add_item(_piece(_tomato))
	assert_object(first.get_active_reactions()[0].reaction).is_same(squash_tomato)
	var second: VesselContents = VesselContents.new(_board, [_slice, squash_tomato], 1)
	second.add_item(_piece(_tomato))
	assert_object(second.get_active_reactions()[0].reaction).is_same(_slice)


func test_same_reaction_runs_once_per_set_of_items() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_water))
	pan.add_item(_piece(_water))
	assert_int(pan.get_active_reactions().size()).is_equal(2)


# --- Instant elements ---------------------------------------------------------

func test_each_cut_is_one_step() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_tomato))
	assert_bool(board.add_element(_cut)).is_true()
	assert_float(board.get_active_reactions()[0].get_fraction()).is_equal(0.5)
	_assert_items(board, [_tomato])
	board.add_element(_cut)
	_assert_items(board, [_sliced])


func test_finished_reaction_chains_into_the_next() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_tomato))
	_cuts(board, 2)
	var active: Array[ActiveReaction] = board.get_active_reactions()
	assert_int(active.size()).is_equal(1)
	assert_object(active[0].reaction).is_same(_dice)
	_cuts(board, 3)
	_assert_items(board, [_diced])


func test_extra_cuts_after_the_last_reaction_do_nothing() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_tomato))
	_cuts(board, 5)
	assert_bool(board.add_element(_cut)).is_false()
	_assert_items(board, [_diced])


func test_instant_element_does_not_stay() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_element(_cut)
	assert_bool(board.has_element(_cut)).is_false()
	# A cut before the tomato arrives doesn't count towards slicing it.
	board.add_item(_piece(_tomato))
	assert_float(board.get_active_reactions()[0].progress).is_equal(0.0)


# --- Timed elements -----------------------------------------------------------

func test_timed_reaction_only_progresses_while_its_element_is_present() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_water))
	pan.tick(10.0)
	_assert_items(pan, [_water])
	assert_bool(pan.add_element(_fire)).is_true()
	pan.tick(3.0)
	_assert_items(pan, [_water])
	pan.tick(1.0)
	_assert_items(pan, [_boiling])


func test_removing_a_timed_element_pauses_and_keeps_progress() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_water))
	pan.add_element(_fire)
	pan.tick(3.0)
	assert_bool(pan.remove_element(_fire)).is_true()
	pan.tick(10.0)
	assert_float(pan.get_active_reactions()[0].progress).is_equal(3.0)
	pan.add_element(_fire)
	pan.tick(1.0)
	_assert_items(pan, [_boiling])


func test_timed_element_is_only_added_and_removed_once() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	assert_bool(pan.add_element(_fire)).is_true()
	assert_bool(pan.add_element(_fire)).is_false()
	assert_bool(pan.has_element(_fire)).is_true()
	assert_bool(pan.remove_element(_fire)).is_true()
	assert_bool(pan.remove_element(_fire)).is_false()


func test_every_element_listed_must_be_present() -> void:
	# Fire drives it, but it also needs cold, so it waits until both are there.
	var odd: Reaction = _reaction([_tomato], [_pan], [_fire, _cold], 2, _soup, 3)
	var pan: VesselContents = VesselContents.new(_pan, [odd], 3)
	pan.add_item(_piece(_tomato))
	pan.add_element(_fire)
	pan.tick(5.0)
	_assert_items(pan, [_tomato])
	pan.add_element(_cold)
	pan.tick(2.0)
	_assert_items(pan, [_soup])


# --- Required items -----------------------------------------------------------

func test_required_items_are_shared_and_kept() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_boiling))
	pan.add_item(_piece(_potato))
	pan.add_item(_piece(_potato))
	assert_int(pan.get_active_reactions().size()).is_equal(2)
	pan.add_element(_fire)
	pan.tick(5.0)
	_assert_items(pan, [_boiling, _boiled_potato, _boiled_potato])


func test_removing_a_required_item_cancels_the_reaction() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	var water: ItemInstance = _piece(_boiling)
	pan.add_item(water)
	pan.add_item(_piece(_potato))
	pan.remove_item(water)
	assert_array(pan.get_active_reactions()).is_empty()


# --- Removing mid-reaction ----------------------------------------------------

func test_removing_an_item_cancels_its_reaction_and_loses_progress() -> void:
	var board: VesselContents = _vessel(_board, 1)
	var tomato: ItemInstance = _piece(_tomato)
	board.add_item(tomato)
	board.add_element(_cut)
	board.remove_item(tomato)
	assert_array(board.get_active_reactions()).is_empty()
	board.add_item(tomato)
	assert_float(board.get_active_reactions()[0].progress).is_equal(0.0)


# --- Results ------------------------------------------------------------------

func test_result_takes_the_slot_of_the_first_consumed_item() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_onion))
	pan.add_item(_piece(_water))
	pan.add_item(_piece(_potato))
	pan.add_element(_fire)
	pan.tick(4.0)
	_assert_items(pan, [_onion, _boiling, _potato])


func test_result_quality_averages_inputs_and_reaction() -> void:
	var board: VesselContents = _vessel(_board, 1)
	board.add_item(_piece(_tomato, 1))
	_cuts(board, 2)
	# (1 + 3) / 2 = 2
	assert_int(board.get_contents()[0].quality).is_equal(2)
	_cuts(board, 3)
	# (2 + 3) / 2 = 2.5, rounded up
	assert_int(board.get_contents()[0].quality).is_equal(3)


func test_required_items_count_towards_quality() -> void:
	# Potato 1 and boiling water 3 average 2; with a proper reaction (3): 2.5 → 3.
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_boiling, 3))
	pan.add_item(_piece(_potato, 1))
	pan.add_element(_fire)
	pan.tick(5.0)
	assert_int(pan.get_contents()[1].quality).is_equal(3)


func test_shortcut_reaction_gives_lower_quality() -> void:
	var pan: VesselContents = _vessel(_pan, 3)
	pan.add_item(_piece(_water, 1))
	pan.add_item(_piece(_tomato, 1))
	pan.add_item(_piece(_onion, 1))
	pan.add_element(_fire)
	pan.tick(6.0)
	_assert_items(pan, [_soup])
	assert_int(pan.get_contents()[0].quality).is_equal(1)


# --- Signals ------------------------------------------------------------------

func test_signals_follow_a_reaction_from_start_to_finish() -> void:
	var board: VesselContents = _vessel(_board, 1)
	var events: Array[String] = []
	board.contents_changed.connect(func() -> void: events.append("changed"))
	board.reaction_started.connect(
		func(active: ActiveReaction) -> void: events.append("started %s" % active.reaction.id)
	)
	board.reaction_progressed.connect(
		func(active: ActiveReaction) -> void: events.append("progressed %d" % active.progress)
	)
	board.reaction_finished.connect(
		func(_active: ActiveReaction, result: ItemInstance) -> void:
			events.append("finished %s" % result.item.id)
	)
	board.add_item(_piece(_tomato))
	_cuts(board, 2)
	assert_array(events).is_equal([
		"started sliced_tomato", "changed",
		"progressed 1", "progressed 2", "finished sliced_tomato", "started diced_tomato", "changed",
	])


func test_contents_changed_is_not_emitted_when_nothing_changed() -> void:
	var board: VesselContents = _vessel(_board, 1)
	var count: Array[int] = [0]
	board.add_item(_piece(_tomato))
	board.contents_changed.connect(func() -> void: count[0] += 1)
	board.add_element(_cut)
	board.add_item(_piece(_lettuce))
	assert_int(count[0]).is_equal(0)


func test_reactions_that_loop_forever_are_stopped() -> void:
	var flip: Reaction = _reaction([_tomato], [_plate], [], 0, _lettuce, 3)
	var flop: Reaction = _reaction([_lettuce], [_plate], [], 0, _tomato, 3)
	var plate: VesselContents = VesselContents.new(_plate, [flip, flop], 3)
	await assert_error(func() -> void: plate.add_item(_piece(_tomato))).is_push_error(
		"VesselContents: reactions in plate kept chaining; check the data for a loop"
	)


# --- Helpers ------------------------------------------------------------------

func _vessel(vessel: Item, capacity: int) -> VesselContents:
	var reactions: Array[Reaction] = [
		_slice, _dice, _make_salad, _boil_water, _rushed_soup, _boil_potato,
	]
	return VesselContents.new(vessel, reactions, capacity)


func _cuts(vessel: VesselContents, count: int) -> void:
	for i: int in count:
		vessel.add_element(_cut)


func _assert_items(vessel: VesselContents, expected: Array[Item]) -> void:
	var actual: Array[StringName] = []
	for instance: ItemInstance in vessel.get_contents():
		actual.append(instance.item.id)
	var wanted: Array[StringName] = []
	for item: Item in expected:
		wanted.append(item.id)
	assert_array(actual).is_equal(wanted)


func _piece(item: Item, quality: int = 1) -> ItemInstance:
	return ItemInstance.new(item, quality)


func _item(id: StringName) -> Item:
	var item: Item = Item.new()
	item.id = id
	return item


func _element(id: StringName, kind: Element.Kind) -> Element:
	var element: Element = Element.new()
	element.id = id
	element.kind = kind
	return element


func _reaction(
	consumes: Array[Item], requires: Array[Item], elements: Array[Element],
	amount: float, result: Item, quality: int
) -> Reaction:
	var reaction: Reaction = Reaction.new()
	reaction.id = result.id
	reaction.consumes = consumes
	reaction.requires = requires
	reaction.elements = elements
	reaction.amount = amount
	reaction.result = result
	reaction.quality = quality
	return reaction
