extends GameTestSuite
## Tests for DayCycle, the node that moves the game's clock on with real time,
## nudges the player at midnight and plays the night when the day ends.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const SCREEN_FADE_SCENE: String = "res://ui/screen_fade.tscn"
const NOTICE_SCENE: String = "res://ui/notice.tscn"
## Real seconds of ticking (at one second per step) from 6:00 am to midnight.
const SECONDS_TO_MIDNIGHT: float = 108.0
const WAKE_POSITION: Vector2 = Vector2(56, 216)

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_state.clock.seconds_per_step = 1.0


func after_test() -> void:
	# A night that's still playing (or a failing test) could leave the game
	# paused, which would stall later suites.
	get_tree().paused = false
	# The scene test uses the real Game autoload, so put it back afterwards.
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


# --- The clock ----------------------------------------------------------------

func test_each_frame_moves_the_clock_on() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(0.5)
	cycle._process(0.5)
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES + 10)


func test_running_until_two_am_ends_the_day() -> void:
	var cycle: DayCycle = _new_cycle()
	_state.set_open(true)
	cycle._process(1000.0)
	assert_bool(_state.is_day_over).is_true()
	assert_bool(_state.is_open).is_false()


func test_uses_the_game_autoload_by_default() -> void:
	var cycle: DayCycle = DayCycle.new()
	auto_free(cycle)
	add_child(cycle)
	assert_object(cycle.game_state).is_same(Game)


# --- The night ----------------------------------------------------------------

func test_the_night_moves_on_to_the_next_day() -> void:
	var cycle: DayCycle = _new_cycle()
	assert_bool(await _sleep_through_night(cycle)).is_true()
	assert_int(_state.day).is_equal(2)
	assert_bool(_state.is_day_over).is_false()


func test_the_new_day_starts_while_the_screen_is_black() -> void:
	var cycle: DayCycle = _new_cycle()
	var seen: Dictionary[String, bool] = {"covering": false}
	_state.day_changed.connect(func(_day: int) -> void:
		seen["covering"] = cycle.screen_fade.is_covering())
	await _sleep_through_night(cycle)
	assert_bool(seen["covering"]).override_failure_message(
		"The day changed before the screen had faded to black").is_true()


func test_the_screen_is_clear_again_in_the_morning() -> void:
	var cycle: DayCycle = _new_cycle()
	await _sleep_through_night(cycle)
	assert_bool(cycle.screen_fade.is_covering()).is_false()
	assert_bool(cycle.screen_fade.visible).is_false()


func test_wakes_the_player_at_the_wake_spot() -> void:
	var cycle: DayCycle = _new_cycle()
	var player: Node2D = Node2D.new()
	auto_free(player)
	add_child(player)
	cycle.player = player
	await _sleep_through_night(cycle)
	assert_vector(player.global_position).is_equal(WAKE_POSITION)


func test_the_title_shows_the_new_date() -> void:
	var cycle: DayCycle = _new_cycle()
	await _sleep_through_night(cycle)
	var title: Label = cycle.screen_fade.find_child("Title") as Label
	assert_str(title.text).is_equal("Spring 2, Tuesday")


func test_the_game_is_paused_through_the_night() -> void:
	var cycle: DayCycle = _new_cycle()
	_state.end_day()
	assert_bool(get_tree().paused).is_true()
	assert_bool(cycle.is_night()).is_true()
	assert_bool(await wait_for_signal(cycle.morning_started)).is_true()
	assert_bool(get_tree().paused).is_false()
	assert_bool(cycle.is_night()).is_false()


func test_the_clock_runs_from_six_in_the_morning() -> void:
	var cycle: DayCycle = _new_cycle()
	await _sleep_through_night(cycle)
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)
	assert_bool(_state.clock.is_paused()).is_false()


func test_the_night_plays_without_a_player() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle.player = null
	assert_bool(await _sleep_through_night(cycle)).is_true()
	assert_int(_state.day).is_equal(2)


func test_falling_asleep_at_two_am_plays_the_night_too() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(1000.0)
	assert_bool(await wait_for_signal(cycle.morning_started)).is_true()
	assert_int(_state.day).is_equal(2)


# --- Midnight -----------------------------------------------------------------

func test_midnight_shows_getting_late() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(SECONDS_TO_MIDNIGHT)
	assert_bool(cycle.notice.is_showing()).is_true()
	assert_str(cycle.notice.text).is_equal(DayCycle.LATE_MESSAGE)


func test_no_note_before_midnight() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(SECONDS_TO_MIDNIGHT - 1.0)
	assert_bool(cycle.notice.is_showing()).is_false()


func test_no_note_again_after_midnight() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(SECONDS_TO_MIDNIGHT)
	cycle.notice.dismiss()
	cycle._process(5.0)
	assert_bool(cycle.notice.is_showing()).is_false()


func test_going_to_bed_hides_the_note() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(SECONDS_TO_MIDNIGHT)
	_state.end_day()
	assert_bool(cycle.notice.is_showing()).is_false()


func test_the_note_shows_again_the_next_night() -> void:
	var cycle: DayCycle = _new_cycle()
	cycle._process(SECONDS_TO_MIDNIGHT)
	await _sleep_through_night(cycle)
	cycle._process(SECONDS_TO_MIDNIGHT)
	assert_bool(cycle.notice.is_showing()).is_true()


# --- In the game --------------------------------------------------------------

func test_time_moves_in_the_running_game() -> void:
	Game.clock.seconds_per_step = 0.05
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object(runner.find_child("DayCycle")).is_instanceof(DayCycle)
	# Wall-clock time, not physics ticks: the clock follows real seconds.
	await await_millis(300)
	assert_int(Game.clock.minutes).is_greater(GameClock.START_MINUTES)


func test_the_game_wires_up_the_night() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var cycle: DayCycle = runner.find_child("DayCycle") as DayCycle
	assert_object(cycle.player).is_same(runner.find_child("Player"))
	assert_object(cycle.wake_spot).is_same(runner.find_child("WakeSpot"))
	assert_object(cycle.screen_fade).is_not_null()
	assert_object(cycle.notice).is_not_null()


func test_going_to_bed_in_the_game_wakes_the_player_in_the_back_room() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var cycle: DayCycle = runner.find_child("DayCycle") as DayCycle
	cycle.screen_fade.fade_seconds = 0.01
	cycle.title_seconds = 0.01
	var player: Player = place_player(runner, Vector2(200, 100))
	Game.end_day()
	assert_bool(await wait_for_signal(cycle.morning_started)).is_true()
	assert_int(Game.day).is_equal(2)
	assert_vector(player.global_position).is_equal(cycle.wake_spot.global_position)


# --- Helpers ------------------------------------------------------------------

# A day cycle for _state with a fast screen fade, a notice and a wake spot at
# WAKE_POSITION, but no player.
func _new_cycle() -> DayCycle:
	var fade: ScreenFade = (load(SCREEN_FADE_SCENE) as PackedScene).instantiate() as ScreenFade
	auto_free(fade)
	fade.fade_seconds = 0.01
	add_child(fade)

	var notice: Notice = (load(NOTICE_SCENE) as PackedScene).instantiate() as Notice
	auto_free(notice)
	add_child(notice)

	var wake_spot: Marker2D = Marker2D.new()
	auto_free(wake_spot)
	wake_spot.position = WAKE_POSITION
	add_child(wake_spot)

	var cycle: DayCycle = DayCycle.new()
	auto_free(cycle)
	cycle.game_state = _state
	cycle.title_seconds = 0.01
	cycle.screen_fade = fade
	cycle.notice = notice
	cycle.wake_spot = wake_spot
	add_child(cycle)
	return cycle


# Ends the day and waits for morning. Returns whether morning came.
func _sleep_through_night(cycle: DayCycle) -> bool:
	_state.end_day()
	return await wait_for_signal(cycle.morning_started)
