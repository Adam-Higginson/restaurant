extends GameTestSuite
## Tests for Bed: Interact asks "Go to bed?", and Yes ends the day.

const BED_SCENE: String = "res://scenes/props/bed.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
## In the back room, just right of the bed (centred at 24, 200).
const BESIDE_BED: Vector2 = Vector2(56, 200)

var _state: GameState


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)


func after_test() -> void:
	# The scene tests use the real Game autoload and can pause the game.
	get_tree().paused = false
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


# --- Asking -------------------------------------------------------------------

func test_interacting_asks_to_go_to_bed() -> void:
	var bed: Bed = _new_bed()
	_interactable(bed).interact(null)
	assert_bool(_prompt(bed).is_open()).is_true()
	assert_str((_prompt(bed).find_child("Question") as Label).text).is_equal("Go to bed?")


func test_warns_that_an_open_restaurant_will_close() -> void:
	var bed: Bed = _new_bed()
	_state.set_open(true)
	bed.ask_to_sleep()
	assert_str((_prompt(bed).find_child("Detail") as Label).text).is_equal(Bed.CLOSING_NOTE)


func test_no_warning_when_already_closed() -> void:
	var bed: Bed = _new_bed()
	bed.ask_to_sleep()
	assert_bool((_prompt(bed).find_child("Detail") as Label).visible).is_false()


# --- Answering ----------------------------------------------------------------

func test_yes_ends_the_day() -> void:
	var bed: Bed = _new_bed()
	_state.set_open(true)
	bed.ask_to_sleep()
	(_prompt(bed).find_child("YesButton") as Button).pressed.emit()
	assert_bool(_state.is_day_over).is_true()
	assert_bool(_state.is_open).is_false()


func test_no_carries_on_with_the_day() -> void:
	var bed: Bed = _new_bed()
	_state.set_open(true)
	bed.ask_to_sleep()
	(_prompt(bed).find_child("NoButton") as Button).pressed.emit()
	assert_bool(_state.is_day_over).is_false()
	assert_bool(_state.is_open).is_true()


func test_uses_the_game_autoload_by_default() -> void:
	var bed: Bed = (load(BED_SCENE) as PackedScene).instantiate() as Bed
	add_child(bed)
	auto_free(bed)
	assert_object(bed.game_state).is_same(Game)


# --- In the restaurant --------------------------------------------------------

func test_bed_is_in_the_back_room() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var bed: Bed = runner.find_child("Bed") as Bed
	assert_object(bed).is_not_null()
	if bed == null:
		return
	assert_bool(Rect2(16, 176, 64, 64).has_point(bed.global_position)).is_true()


func test_going_to_bed_in_the_game() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, BESIDE_BED)
	await walk(runner, "move_left", 20)

	await press(runner, "interact")
	assert_bool(get_tree().paused).is_true()

	runner.simulate_action_pressed("ui_accept")
	await runner.await_input_processed()
	var panel: ConfirmPanel = runner.find_child("ConfirmPanel") as ConfirmPanel
	assert_bool(panel.is_open()).is_false()
	# The game stays paused, but now for the night: DayCycle's tests cover that.
	assert_bool(Game.is_day_over).is_true()


func test_the_clock_stops_while_asking() -> void:
	Game.clock.seconds_per_step = 0.05
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, BESIDE_BED)
	await walk(runner, "move_left", 20)
	await press(runner, "interact")

	var asked_at: int = Game.clock.minutes
	# gdUnit's await_millis would wait forever: its timer pauses with the game.
	await get_tree().create_timer(0.3, true).timeout
	assert_int(Game.clock.minutes).is_equal(asked_at)


func _new_bed() -> Bed:
	var bed: Bed = (load(BED_SCENE) as PackedScene).instantiate() as Bed
	# Before add_child, so _ready sees it instead of using the Game autoload.
	bed.game_state = _state
	add_child(bed)
	auto_free(bed)
	return bed


func _interactable(bed: Bed) -> Interactable:
	return bed.get_node("Interactable") as Interactable


func _prompt(bed: Bed) -> ConfirmPanel:
	return bed.get_node("ConfirmPanel") as ConfirmPanel
