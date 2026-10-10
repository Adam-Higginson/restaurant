extends GameTestSuite
## Tests for GameState. Each test uses its own instance rather than the Game
## autoload, so tests can't leak money or stock into each other.

var _state: GameState
# Each signal emission as [signal name, value].
var _events: Array[Array] = []


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_events = []
	_state.money_changed.connect(func(value: int) -> void: _events.append([&"money", value]))
	_state.day_changed.connect(func(value: int) -> void: _events.append([&"day", value]))
	_state.open_changed.connect(func(value: bool) -> void: _events.append([&"open", value]))
	_state.day_ended.connect(func(value: int) -> void: _events.append([&"day_ended", value]))


# --- Starting state -------------------------------------------------------------

func test_starts_with_design_doc_values() -> void:
	assert_int(_state.money).is_equal(50)
	assert_int(_state.day).is_equal(1)
	assert_bool(_state.is_open).is_false()
	assert_bool(_state.is_day_over).is_false()
	assert_dict(_state.pantry.get_counts()).is_empty()


# --- Money --------------------------------------------------------------------

func test_earn_adds_money() -> void:
	_state.earn(12)
	assert_int(_state.money).is_equal(62)
	assert_array(_events).is_equal([[&"money", 62]])


func test_spend_takes_money() -> void:
	assert_bool(_state.spend(20)).is_true()
	assert_int(_state.money).is_equal(30)
	assert_array(_events).is_equal([[&"money", 30]])


func test_can_spend_exactly_everything() -> void:
	assert_bool(_state.can_afford(50)).is_true()
	assert_bool(_state.spend(50)).is_true()
	assert_int(_state.money).is_equal(0)


func test_spend_fails_when_unaffordable() -> void:
	assert_bool(_state.can_afford(51)).is_false()
	assert_bool(_state.spend(51)).is_false()
	assert_int(_state.money).is_equal(50)
	assert_array(_events).is_empty()


func test_rejects_non_positive_amounts() -> void:
	_state.earn(0)
	_state.earn(-5)
	assert_bool(_state.spend(0)).is_false()
	assert_bool(_state.spend(-5)).is_false()
	assert_int(_state.money).is_equal(50)
	assert_array(_events).is_empty()


# --- Open and closed ------------------------------------------------------------

func test_set_open_opens_the_restaurant() -> void:
	_state.set_open(true)
	assert_bool(_state.is_open).is_true()
	assert_array(_events).is_equal([[&"open", true]])


func test_set_open_closes_the_restaurant() -> void:
	_state.set_open(true)
	_state.set_open(false)
	assert_bool(_state.is_open).is_false()
	assert_array(_events).is_equal([[&"open", true], [&"open", false]])


func test_setting_the_same_open_state_emits_nothing() -> void:
	_state.set_open(false)
	_state.set_open(true)
	_state.set_open(true)
	assert_array(_events).is_equal([[&"open", true]])


# --- Ending the day -----------------------------------------------------------

func test_end_day_announces_which_day_ended() -> void:
	_state.end_day()
	assert_bool(_state.is_day_over).is_true()
	assert_array(_events).is_equal([[&"day_ended", 1]])


func test_end_day_closes_the_restaurant_first() -> void:
	# Customers (#9) listen to day_ended, and should already see it closed.
	_state.set_open(true)
	_events.clear()
	_state.end_day()
	assert_bool(_state.is_open).is_false()
	assert_array(_events).is_equal([[&"open", false], [&"day_ended", 1]])


func test_ending_the_day_twice_does_nothing_the_second_time() -> void:
	# E.g. going to bed in the same moment the clock reaches 2:00.
	_state.end_day()
	_state.end_day()
	assert_array(_events).is_equal([[&"day_ended", 1]])


func test_cannot_open_once_the_day_is_over() -> void:
	_state.end_day()
	_state.set_open(true)
	assert_bool(_state.is_open).is_false()


# --- Starting the next day -----------------------------------------------------

func test_start_next_day_advances_the_day() -> void:
	_state.end_day()
	_events.clear()
	assert_bool(_state.start_next_day()).is_true()
	assert_int(_state.day).is_equal(2)
	assert_bool(_state.is_day_over).is_false()
	assert_array(_events).is_equal([[&"day", 2]])


func test_start_next_day_fails_until_the_day_is_over() -> void:
	assert_bool(_state.start_next_day()).is_false()
	assert_int(_state.day).is_equal(1)
	assert_array(_events).is_empty()


func test_each_day_starts_closed_and_can_open() -> void:
	_state.set_open(true)
	_state.end_day()
	_state.start_next_day()
	assert_bool(_state.is_open).is_false()
	_state.set_open(true)
	assert_bool(_state.is_open).is_true()


# --- New game -----------------------------------------------------------------

func test_new_game_resets_everything() -> void:
	var tomato: Item = Item.new()
	var pantry: Pantry = _state.pantry
	_state.pantry.add(tomato, 3)
	_state.spend(10)
	_state.end_day()
	_state.start_next_day()
	_state.set_open(true)
	_state.end_day()

	_state.new_game()

	assert_int(_state.money).is_equal(50)
	assert_int(_state.day).is_equal(1)
	assert_bool(_state.is_open).is_false()
	assert_bool(_state.is_day_over).is_false()
	assert_dict(_state.pantry.get_counts()).is_empty()
	# Same instance, so anything connected to the pantry's signals still hears it.
	assert_object(_state.pantry).is_same(pantry)


# --- Read-only values -----------------------------------------------------------

func test_assigning_money_directly_is_an_error_and_changes_nothing() -> void:
	await assert_error(func() -> void: _state.money = 999).is_push_error(
		"GameState: money is read-only, use earn() or spend()"
	)
	assert_int(_state.money).is_equal(50)
	assert_array(_events).is_empty()


func test_assigning_day_or_open_state_directly_is_an_error() -> void:
	await assert_error(func() -> void: _state.day = 5).is_push_error(
		"GameState: day is read-only, use start_next_day()"
	)
	await assert_error(func() -> void: _state.is_open = true).is_push_error(
		"GameState: is_open is read-only, use set_open()"
	)
	await assert_error(func() -> void: _state.is_day_over = true).is_push_error(
		"GameState: is_day_over is read-only, use end_day()"
	)
	assert_int(_state.day).is_equal(1)
	assert_bool(_state.is_open).is_false()


func test_pantry_cannot_be_replaced() -> void:
	var pantry: Pantry = _state.pantry
	await assert_error(func() -> void: _state.pantry = Pantry.new()).is_push_error(
		"GameState: pantry can't be replaced, use pantry.clear()"
	)
	assert_object(_state.pantry).is_same(pantry)


# --- Autoload -----------------------------------------------------------------

func test_game_autoload_is_a_game_state() -> void:
	var game: Node = get_tree().root.get_node_or_null(^"Game")
	assert_object(game).is_not_null()
	assert_bool(game is GameState).is_true()
