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
	assert_int(_state.stats.served).is_equal(0)


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


# --- The clock ----------------------------------------------------------------

func test_clock_starts_at_six_am_and_running() -> void:
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)
	assert_bool(_state.clock.is_paused()).is_false()


func test_reaching_two_am_ends_the_day() -> void:
	_state.set_open(true)
	_state.clock.seconds_per_step = 1.0
	_state.clock.tick(1000.0)
	assert_bool(_state.is_day_over).is_true()
	assert_bool(_state.is_open).is_false()
	assert_array(_events.slice(-1)).is_equal([[&"day_ended", 1]])


func test_clock_stops_once_the_day_is_over() -> void:
	# E.g. after going to bed at 22:00, time stands still until morning.
	_state.clock.seconds_per_step = 1.0
	_state.end_day()
	_state.clock.tick(5.0)
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)


func test_next_day_starts_at_six_am_with_the_clock_running() -> void:
	_state.clock.seconds_per_step = 1.0
	_state.clock.tick(30.5)
	_state.end_day()
	_state.start_next_day()
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)
	assert_bool(_state.clock.is_paused()).is_false()
	_state.clock.tick(1.0)
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES + 10)


func test_next_day_starts_the_clock_before_announcing_the_day() -> void:
	# So anything that hears day_changed already reads 6:00 am.
	var minutes_seen: Array[int] = []
	_state.clock.seconds_per_step = 1.0
	_state.clock.tick(30.0)
	_state.end_day()
	_state.day_changed.connect(
		func(_day: int) -> void: minutes_seen.append(_state.clock.minutes)
	)
	_state.start_next_day()
	assert_array(minutes_seen).is_equal([GameClock.START_MINUTES])


# --- The day's tally ----------------------------------------------------------

func test_next_day_starts_a_fresh_tally() -> void:
	_state.stats.record_served(Bill.new(12, 3, false))
	_state.stats.record_lost()
	_state.end_day()
	_state.start_next_day()
	assert_int(_state.stats.served).is_equal(0)
	assert_int(_state.stats.lost).is_equal(0)
	assert_int(_state.stats.earnings).is_equal(0)


func test_ending_the_day_keeps_the_tally_for_the_summary() -> void:
	_state.stats.record_served(Bill.new(12, 3, false))
	_state.end_day()
	assert_int(_state.stats.served).is_equal(1)


func test_next_day_clears_the_tally_before_announcing_the_day() -> void:
	var served_seen: Array[int] = []
	_state.stats.record_served(Bill.new(12, 1, false))
	_state.end_day()
	_state.day_changed.connect(
		func(_day: int) -> void: served_seen.append(_state.stats.served)
	)
	_state.start_next_day()
	assert_array(served_seen).is_equal([0])


# --- New game -----------------------------------------------------------------

func test_new_game_resets_everything() -> void:
	var clock: GameClock = _state.clock
	var stats: DayStats = _state.stats
	_state.spend(10)
	_state.stats.record_lost()
	_state.end_day()
	_state.start_next_day()
	_state.set_open(true)
	_state.clock.seconds_per_step = 1.0
	_state.clock.tick(30.0)
	_state.end_day()

	_state.new_game()

	assert_int(_state.money).is_equal(50)
	assert_int(_state.day).is_equal(1)
	assert_bool(_state.is_open).is_false()
	assert_bool(_state.is_day_over).is_false()
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)
	assert_bool(_state.clock.is_paused()).is_false()
	assert_int(_state.stats.lost).is_equal(0)
	# Same instances, so anything connected to their signals still hears them.
	assert_object(_state.clock).is_same(clock)
	assert_object(_state.stats).is_same(stats)


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


func test_clock_cannot_be_replaced() -> void:
	var clock: GameClock = _state.clock
	await assert_error(func() -> void: _state.clock = GameClock.new()).is_push_error(
		"GameState: clock can't be replaced, use start_next_day()"
	)
	assert_object(_state.clock).is_same(clock)


func test_stats_cannot_be_replaced() -> void:
	var stats: DayStats = _state.stats
	await assert_error(func() -> void: _state.stats = DayStats.new()).is_push_error(
		"GameState: stats can't be replaced, use stats.reset()"
	)
	assert_object(_state.stats).is_same(stats)


# --- Autoload -----------------------------------------------------------------

func test_game_autoload_is_a_game_state() -> void:
	var game: Node = get_tree().root.get_node_or_null(^"Game")
	assert_object(game).is_not_null()
	assert_bool(game is GameState).is_true()
