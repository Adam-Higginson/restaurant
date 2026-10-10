extends GameTestSuite
## Tests for GameClock: 6:00 am to 2:00 am in 10-minute steps, with pause
## sources and 12-hour text.

var _clock: GameClock
# Each time_changed value, then &"end" for reached_end.
var _events: Array = []


func before_test() -> void:
	_clock = GameClock.new()
	_clock.seconds_per_step = 1.0
	_events = []
	_clock.time_changed.connect(func(value: int) -> void: _events.append(value))
	_clock.reached_end.connect(func() -> void: _events.append(&"end"))


# --- Text ---------------------------------------------------------------------

func test_format_morning() -> void:
	assert_str(GameClock.format_time(6 * 60)).is_equal("6:00 am")


func test_format_pads_minutes() -> void:
	assert_str(GameClock.format_time(6 * 60 + 5)).is_equal("6:05 am")


func test_format_noon_is_pm() -> void:
	assert_str(GameClock.format_time(12 * 60)).is_equal("12:00 pm")
	assert_str(GameClock.format_time(12 * 60 + 40)).is_equal("12:40 pm")


func test_format_evening() -> void:
	assert_str(GameClock.format_time(18 * 60 + 30)).is_equal("6:30 pm")
	assert_str(GameClock.format_time(23 * 60 + 50)).is_equal("11:50 pm")


func test_format_midnight_is_twelve_am() -> void:
	assert_str(GameClock.format_time(24 * 60)).is_equal("12:00 am")


func test_format_after_midnight() -> void:
	assert_str(GameClock.format_time(25 * 60 + 50)).is_equal("1:50 am")
	assert_str(GameClock.format_time(26 * 60)).is_equal("2:00 am")


func test_format_24_hour() -> void:
	assert_str(GameClock.format_time(6 * 60, true)).is_equal("06:00")
	assert_str(GameClock.format_time(12 * 60 + 40, true)).is_equal("12:40")
	assert_str(GameClock.format_time(18 * 60 + 30, true)).is_equal("18:30")


func test_format_24_hour_after_midnight() -> void:
	assert_str(GameClock.format_time(24 * 60, true)).is_equal("00:00")
	assert_str(GameClock.format_time(25 * 60 + 50, true)).is_equal("01:50")


# --- Ticking ------------------------------------------------------------------

func test_starts_at_six_am() -> void:
	assert_int(_clock.minutes).is_equal(6 * 60)
	assert_bool(_clock.has_ended()).is_false()
	assert_bool(_clock.is_paused()).is_false()


func test_nothing_happens_before_a_full_step() -> void:
	_clock.tick(0.9)
	assert_int(_clock.minutes).is_equal(360)
	assert_array(_events).is_empty()


func test_a_full_step_adds_ten_minutes() -> void:
	_clock.tick(1.0)
	assert_int(_clock.minutes).is_equal(370)
	assert_array(_events).is_equal([370])


func test_small_ticks_add_up() -> void:
	_clock.tick(0.5)
	_clock.tick(0.5)
	assert_int(_clock.minutes).is_equal(370)


func test_a_big_tick_moves_several_steps_and_keeps_the_rest() -> void:
	_clock.tick(2.5)
	assert_array(_events).is_equal([370, 380])
	_clock.tick(0.5)
	assert_array(_events).is_equal([370, 380, 390])


func test_uses_seconds_per_step() -> void:
	_clock.seconds_per_step = 10.0
	_clock.tick(9.0)
	assert_int(_clock.minutes).is_equal(360)
	_clock.tick(1.0)
	assert_int(_clock.minutes).is_equal(370)


# --- The end of the day -------------------------------------------------------

func test_stops_at_two_am_and_says_so_once() -> void:
	_clock.tick(1000.0)
	assert_int(_clock.minutes).is_equal(26 * 60)
	assert_bool(_clock.has_ended()).is_true()
	assert_array(_events.slice(-2)).is_equal([26 * 60, &"end"])
	assert_int(_events.count(&"end")).is_equal(1)


func test_ticking_after_the_end_does_nothing() -> void:
	_clock.tick(1000.0)
	_events.clear()
	_clock.tick(5.0)
	assert_int(_clock.minutes).is_equal(26 * 60)
	assert_array(_events).is_empty()


# --- Pausing ------------------------------------------------------------------

func test_paused_clock_does_not_move() -> void:
	var panel: RefCounted = RefCounted.new()
	_clock.pause(panel)
	_clock.tick(5.0)
	assert_bool(_clock.is_paused()).is_true()
	assert_int(_clock.minutes).is_equal(360)


func test_resuming_lets_it_run_again() -> void:
	var panel: RefCounted = RefCounted.new()
	_clock.pause(panel)
	_clock.resume(panel)
	_clock.tick(1.0)
	assert_bool(_clock.is_paused()).is_false()
	assert_int(_clock.minutes).is_equal(370)


func test_stays_paused_until_every_source_resumes() -> void:
	var shop: RefCounted = RefCounted.new()
	var bed_prompt: RefCounted = RefCounted.new()
	_clock.pause(shop)
	_clock.pause(bed_prompt)
	_clock.resume(shop)
	assert_bool(_clock.is_paused()).is_true()
	_clock.resume(bed_prompt)
	assert_bool(_clock.is_paused()).is_false()


func test_pausing_twice_for_one_source_counts_once() -> void:
	var panel: RefCounted = RefCounted.new()
	_clock.pause(panel)
	_clock.pause(panel)
	_clock.resume(panel)
	assert_bool(_clock.is_paused()).is_false()


func test_resuming_an_unknown_source_does_nothing() -> void:
	var panel: RefCounted = RefCounted.new()
	_clock.pause(panel)
	_clock.resume(RefCounted.new())
	assert_bool(_clock.is_paused()).is_true()


# --- Reset --------------------------------------------------------------------

func test_reset_goes_back_to_six_am() -> void:
	_clock.tick(1000.0)
	_events.clear()
	_clock.reset()
	assert_int(_clock.minutes).is_equal(360)
	assert_bool(_clock.has_ended()).is_false()
	assert_array(_events).is_equal([360])


func test_reset_forgets_part_of_a_step() -> void:
	_clock.tick(0.9)
	_clock.reset()
	_clock.tick(0.5)
	assert_int(_clock.minutes).is_equal(360)


# --- Read-only ----------------------------------------------------------------

func test_assigning_minutes_directly_is_an_error() -> void:
	await assert_error(func() -> void: _clock.minutes = 600).is_push_error(
		"GameClock: minutes is read-only, use tick() or reset()"
	)
	assert_int(_clock.minutes).is_equal(360)
