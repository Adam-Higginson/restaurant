extends GameTestSuite
## Tests for TimeLabel, the temporary date, time, open-state and money readout
## (until the HUD in #13).

const TIME_LABEL_SCENE: String = "res://ui/time_label.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_state.clock.seconds_per_step = 1.0


# --- The text -----------------------------------------------------------------

func test_describe_the_first_morning() -> void:
	assert_str(TimeLabel.describe(1, 6 * 60, false, 50)).is_equal(
		"Spring 1, Monday · 6:00 am · Closed · 50G"
	)


func test_describe_an_open_evening() -> void:
	assert_str(TimeLabel.describe(3, 18 * 60 + 40, true, 62)).is_equal(
		"Spring 3, Wednesday · 6:40 pm · Open · 62G"
	)


# --- Following the game state -------------------------------------------------

func test_shows_the_state_straight_away() -> void:
	var label: TimeLabel = _new_label()
	assert_str(label.text).is_equal("Spring 1, Monday · 6:00 am · Closed · 50G")


func test_updates_when_the_restaurant_opens() -> void:
	var label: TimeLabel = _new_label()
	_state.set_open(true)
	assert_str(label.text).is_equal("Spring 1, Monday · 6:00 am · Open · 50G")


func test_updates_as_the_clock_ticks() -> void:
	var label: TimeLabel = _new_label()
	_state.clock.tick(2.0)
	assert_str(label.text).is_equal("Spring 1, Monday · 6:20 am · Closed · 50G")


func test_updates_for_a_new_day() -> void:
	var label: TimeLabel = _new_label()
	_state.clock.tick(3.0)
	_state.end_day()
	_state.start_next_day()
	assert_str(label.text).is_equal("Spring 2, Tuesday · 6:00 am · Closed · 50G")


func test_updates_when_money_comes_in() -> void:
	var label: TimeLabel = _new_label()
	_state.earn(12)
	assert_str(label.text).is_equal("Spring 1, Monday · 6:00 am · Closed · 62G")


func test_uses_the_game_autoload_by_default() -> void:
	var label: TimeLabel = (load(TIME_LABEL_SCENE) as PackedScene).instantiate() as TimeLabel
	add_child(label)
	auto_free(label)
	assert_object(label.game_state).is_same(Game)


# --- In the game --------------------------------------------------------------

func test_main_scene_shows_a_time_label() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var label: TimeLabel = runner.find_child("TimeLabel") as TimeLabel
	assert_object(label).is_not_null()
	assert_str(label.text).starts_with("Spring 1, Monday")


func _new_label() -> TimeLabel:
	var label: TimeLabel = (load(TIME_LABEL_SCENE) as PackedScene).instantiate() as TimeLabel
	label.game_state = _state
	add_child(label)
	auto_free(label)
	return label
