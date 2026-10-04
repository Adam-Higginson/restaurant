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
	_state.phase_changed.connect(
		func(value: GameState.Phase) -> void: _events.append([&"phase", value])
	)


# --- Starting state -------------------------------------------------------------

func test_starts_with_design_doc_values() -> void:
	assert_int(_state.money).is_equal(50)
	assert_int(_state.day).is_equal(1)
	assert_int(_state.phase).is_equal(GameState.Phase.PREP)
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


# --- Day and phase --------------------------------------------------------------

func test_full_day_cycle() -> void:
	assert_bool(_state.start_service()).is_true()
	assert_int(_state.phase).is_equal(GameState.Phase.SERVICE)
	assert_bool(_state.end_service()).is_true()
	assert_int(_state.phase).is_equal(GameState.Phase.SUMMARY)
	assert_bool(_state.start_next_day()).is_true()
	assert_int(_state.phase).is_equal(GameState.Phase.PREP)
	assert_int(_state.day).is_equal(2)
	assert_array(_events).is_equal([
		[&"phase", GameState.Phase.SERVICE],
		[&"phase", GameState.Phase.SUMMARY],
		[&"day", 2],
		[&"phase", GameState.Phase.PREP],
	])


func test_new_day_is_set_before_listeners_hear_the_phase_change() -> void:
	var day_seen: Array[int] = []
	_state.start_service()
	_state.end_service()
	_state.phase_changed.connect(func(_phase: GameState.Phase) -> void: day_seen.append(_state.day))
	_state.start_next_day()
	assert_array(day_seen).is_equal([2])


func test_transitions_from_the_wrong_phase_fail() -> void:
	# In prep.
	assert_bool(_state.end_service()).is_false()
	assert_bool(_state.start_next_day()).is_false()
	_state.start_service()
	assert_bool(_state.start_service()).is_false()
	assert_bool(_state.start_next_day()).is_false()
	_state.end_service()
	assert_bool(_state.start_service()).is_false()
	assert_bool(_state.end_service()).is_false()
	assert_int(_state.phase).is_equal(GameState.Phase.SUMMARY)
	assert_int(_state.day).is_equal(1)


# --- New game -----------------------------------------------------------------

func test_new_game_resets_everything() -> void:
	var tomato: Ingredient = Ingredient.new()
	var pantry: Pantry = _state.pantry
	_state.pantry.add(tomato, 3)
	_state.spend(10)
	_state.start_service()
	_state.end_service()
	_state.start_next_day()
	_state.start_service()

	_state.new_game()

	assert_int(_state.money).is_equal(50)
	assert_int(_state.day).is_equal(1)
	assert_int(_state.phase).is_equal(GameState.Phase.PREP)
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


func test_assigning_day_or_phase_directly_is_an_error() -> void:
	await assert_error(func() -> void: _state.day = 5).is_push_error(
		"GameState: day is read-only, use start_next_day()"
	)
	await assert_error(func() -> void: _state.phase = GameState.Phase.SUMMARY).is_push_error(
		"GameState: phase is read-only, use the phase methods"
	)
	assert_int(_state.day).is_equal(1)
	assert_int(_state.phase).is_equal(GameState.Phase.PREP)


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
