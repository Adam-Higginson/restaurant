extends GameTestSuite
## Tests for DayCycle, the node that moves the game's clock on with real time.

const MAIN_SCENE: String = "res://scenes/main.tscn"

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_state.clock.seconds_per_step = 1.0


func after_test() -> void:
	# The scene test uses the real Game autoload, so put it back afterwards.
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


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


func test_time_moves_in_the_running_game() -> void:
	Game.clock.seconds_per_step = 0.05
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object(runner.find_child("DayCycle")).is_instanceof(DayCycle)
	# Wall-clock time, not physics ticks: the clock follows real seconds.
	await await_millis(300)
	assert_int(Game.clock.minutes).is_greater(GameClock.START_MINUTES)


func _new_cycle() -> DayCycle:
	var cycle: DayCycle = DayCycle.new()
	auto_free(cycle)
	cycle.game_state = _state
	add_child(cycle)
	return cycle
