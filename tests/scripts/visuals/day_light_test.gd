extends GameTestSuite
## Tests for DayLight, which tints the world with the time of day and turns
## the lamps up as it gets dark.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const LAMP_SCENE: String = "res://scenes/props/lamp.tscn"
const NOON: int = 12 * 60
## 4:00 pm, halfway through the day.
const HALFWAY: int = 16 * 60
const ELEVEN_PM: int = 23 * 60
## Real seconds of ticking (at one second per step) from 6:00 am to 11:00 pm.
const SECONDS_TO_ELEVEN_PM: float = 102.0

var _state: GameState
## Black at 6:00 am to white at 2:00 am (Godot's default gradient).
var _gradient: Gradient
## Lamps off at 6:00 am to fully on at 2:00 am, in a straight line.
var _curve: Curve


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_state.clock.seconds_per_step = 1.0
	_gradient = Gradient.new()
	_curve = Curve.new()
	_curve.add_point(Vector2(0, 0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
	_curve.add_point(Vector2(1, 1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)


func after_test() -> void:
	# The scene tests use the real Game autoload, so put it back afterwards.
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


# --- Time to fraction ---------------------------------------------------------

func test_the_day_runs_from_zero_at_six_to_one_at_two() -> void:
	assert_float(DayLight.day_fraction(GameClock.START_MINUTES)).is_equal(0.0)
	assert_float(DayLight.day_fraction(GameClock.END_MINUTES)).is_equal(1.0)
	assert_float(DayLight.day_fraction(HALFWAY)).is_equal_approx(0.5, 0.001)


func test_times_outside_the_day_are_clamped() -> void:
	assert_float(DayLight.day_fraction(0)).is_equal(0.0)
	assert_float(DayLight.day_fraction(GameClock.END_MINUTES + 60)).is_equal(1.0)


# --- Colour and lamp level ----------------------------------------------------

func test_colour_follows_the_gradient() -> void:
	assert_object(DayLight.colour_at(_gradient, GameClock.START_MINUTES)) \
			.is_equal(_gradient.get_color(0))
	assert_object(DayLight.colour_at(_gradient, GameClock.END_MINUTES)) \
			.is_equal(_gradient.get_color(1))
	assert_object(DayLight.colour_at(_gradient, HALFWAY)).is_equal(_gradient.sample(0.5))


func test_no_gradient_means_no_tint() -> void:
	assert_object(DayLight.colour_at(null, NOON)).is_equal(Color.WHITE)


func test_lamp_level_follows_the_curve() -> void:
	assert_float(DayLight.lamp_level_at(_curve, GameClock.START_MINUTES)).is_equal(0.0)
	assert_float(DayLight.lamp_level_at(_curve, HALFWAY)).is_equal_approx(0.5, 0.01)
	assert_float(DayLight.lamp_level_at(_curve, GameClock.END_MINUTES)) \
			.is_equal_approx(1.0, 0.01)


func test_no_curve_means_lamps_off() -> void:
	assert_float(DayLight.lamp_level_at(null, ELEVEN_PM)).is_equal(0.0)


# --- Following the clock ------------------------------------------------------

func test_starts_with_the_light_for_the_current_time() -> void:
	var day_light: DayLight = _new_day_light()
	assert_object(day_light.color).is_equal(_gradient.get_color(0))


func test_drifts_to_each_new_time_rather_than_jumping() -> void:
	var day_light: DayLight = _new_day_light()
	day_light.tween_seconds = 0.3
	_state.clock.tick(SECONDS_TO_ELEVEN_PM)
	assert_object(day_light.color).is_equal(_gradient.get_color(0))
	await get_tree().create_timer(0.5).timeout
	assert_object(day_light.color).is_equal(DayLight.colour_at(_gradient, ELEVEN_PM))


func test_turns_the_lamps_up_with_the_curve() -> void:
	var lamp: Lamp = _new_lamp()
	_new_day_light()
	_state.clock.tick(SECONDS_TO_ELEVEN_PM)
	await get_tree().create_timer(0.2).timeout
	assert_float(lamp.level).is_equal_approx(DayLight.lamp_level_at(_curve, ELEVEN_PM), 0.001)


func test_a_new_day_snaps_straight_to_the_morning() -> void:
	var lamp: Lamp = _new_lamp()
	var day_light: DayLight = _new_day_light()
	_state.clock.tick(SECONDS_TO_ELEVEN_PM)
	await get_tree().create_timer(0.2).timeout
	day_light.tween_seconds = 5.0
	_state.end_day()
	_state.start_next_day()
	assert_object(day_light.color).is_equal(_gradient.get_color(0))
	assert_float(lamp.level).is_equal(0.0)
	# And no drift left over pulls it back towards the night.
	await get_tree().create_timer(0.2).timeout
	assert_object(day_light.color).is_equal(_gradient.get_color(0))


# --- In the game --------------------------------------------------------------

func test_the_game_has_a_day_light_with_a_gradient_and_lamp_curve() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var day_light: DayLight = runner.find_child("DayLight") as DayLight
	assert_object(day_light).is_not_null()
	if day_light == null:
		return
	assert_object(day_light.gradient).is_not_null()
	assert_object(day_light.lamp_curve).is_not_null()


func test_the_game_is_untinted_at_noon_with_the_lamps_off() -> void:
	assert_object(DayLight.colour_at(_main_gradient(), NOON)).is_equal(Color.WHITE)
	assert_float(DayLight.lamp_level_at(_main_curve(), NOON)).is_equal(0.0)


func test_the_game_is_dark_at_eleven_with_the_lamps_on() -> void:
	assert_float(DayLight.colour_at(_main_gradient(), ELEVEN_PM).get_luminance()).is_less(0.4)
	assert_float(DayLight.lamp_level_at(_main_curve(), ELEVEN_PM)).is_equal_approx(1.0, 0.01)


# --- Helpers ------------------------------------------------------------------

# A day light for _state with the test gradient and curve, drifting quickly.
func _new_day_light() -> DayLight:
	var day_light: DayLight = DayLight.new()
	auto_free(day_light)
	day_light.game_state = _state
	day_light.gradient = _gradient
	day_light.lamp_curve = _curve
	day_light.tween_seconds = 0.01
	add_child(day_light)
	return day_light


func _new_lamp() -> Lamp:
	var lamp: Lamp = (load(LAMP_SCENE) as PackedScene).instantiate() as Lamp
	auto_free(lamp)
	add_child(lamp)
	return lamp


func _main_day_light() -> DayLight:
	var main: Node = (load(MAIN_SCENE) as PackedScene).instantiate()
	auto_free(main)
	return main.get_node("DayLight") as DayLight


func _main_gradient() -> Gradient:
	return _main_day_light().gradient


func _main_curve() -> Curve:
	return _main_day_light().lamp_curve
