extends GameTestSuite
## Tests for DebugKeys: the testing shortcuts that skip time, fast forward and
## bring a customer in.

const MAIN_SCENE: String = "res://scenes/main.tscn"

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)


func after_test() -> void:
	# The scene tests use the real Game autoload, so put it back afterwards.
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


# --- Time ------------------------------------------------------------------------

func test_skip_hour_moves_the_clock_on_an_hour() -> void:
	var keys: DebugKeys = _new_keys()
	keys.skip_hour()
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES + 60)


func test_skip_hour_goes_through_every_step() -> void:
	var keys: DebugKeys = _new_keys()
	var steps: Array[int] = []
	_state.clock.time_changed.connect(func(minutes: int) -> void: steps.append(minutes))
	keys.skip_hour()
	assert_int(steps.size()).is_equal(6)


func test_skip_hour_does_nothing_while_the_clock_is_paused() -> void:
	var keys: DebugKeys = _new_keys()
	_state.clock.pause(self)
	keys.skip_hour()
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES)


func test_skip_hour_also_works_while_fast_forwarding() -> void:
	var keys: DebugKeys = _new_keys()
	keys.toggle_fast_forward()
	keys.skip_hour()
	assert_int(_state.clock.minutes).is_equal(GameClock.START_MINUTES + 60)


func test_fast_forward_speeds_the_clock_up() -> void:
	var keys: DebugKeys = _new_keys()
	keys.toggle_fast_forward()
	assert_bool(keys.is_fast_forward()).is_true()
	assert_float(_state.clock.seconds_per_step).is_equal(
		GameClock.DEFAULT_SECONDS_PER_STEP / DebugKeys.FAST_FORWARD_FACTOR)


func test_fast_forward_again_goes_back_to_normal() -> void:
	var keys: DebugKeys = _new_keys()
	keys.toggle_fast_forward()
	keys.toggle_fast_forward()
	assert_bool(keys.is_fast_forward()).is_false()
	assert_float(_state.clock.seconds_per_step).is_equal(GameClock.DEFAULT_SECONDS_PER_STEP)


# --- In the game ----------------------------------------------------------------------

func test_main_scene_has_debug_keys_wired_to_the_spawner() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var keys: DebugKeys = runner.find_child("DebugKeys") as DebugKeys
	assert_object(keys).is_not_null()
	assert_object(keys.spawner).is_same(runner.find_child("CustomerSpawner"))


func test_pressing_the_skip_key_skips_an_hour() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	await press(runner, "debug_skip_hour")
	assert_int(Game.clock.minutes).is_equal(GameClock.START_MINUTES + 60)


func test_pressing_the_spawn_key_brings_a_customer_in() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var spawner: CustomerSpawner = runner.find_child("CustomerSpawner") as CustomerSpawner
	await press(runner, "debug_spawn_customer")
	assert_int(spawner.customers().size()).is_equal(1)


func test_pressing_the_fast_forward_key_toggles_it() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	await press(runner, "debug_fast_forward")
	assert_float(Game.clock.seconds_per_step).is_less(GameClock.DEFAULT_SECONDS_PER_STEP)


func _new_keys() -> DebugKeys:
	var keys: DebugKeys = DebugKeys.new()
	# Before add_child, so _ready keeps it instead of using the Game autoload.
	keys.game_state = _state
	add_child(keys)
	auto_free(keys)
	return keys
