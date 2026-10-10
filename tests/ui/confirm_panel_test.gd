extends GameTestSuite
## Tests for ConfirmPanel, a yes/no question that pauses the game while open.

const CONFIRM_PANEL_SCENE: String = "res://ui/confirm_panel.tscn"

# Each answer the panel gave, as "yes" or "no".
var _answers: Array[String] = []


func before_test() -> void:
	_answers = []


func after_test() -> void:
	# A failing test could leave the game paused, which would stall later suites.
	get_tree().paused = false


# --- Opening ------------------------------------------------------------------

func test_starts_hidden() -> void:
	var panel: ConfirmPanel = _new_panel()
	assert_bool(panel.visible).is_false()
	assert_bool(panel.is_open()).is_false()


func test_ask_shows_the_question_and_detail() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?", "The restaurant will close.")
	assert_bool(panel.is_open()).is_true()
	assert_str(_label(panel, "Question").text).is_equal("Go to bed?")
	assert_str(_label(panel, "Detail").text).is_equal("The restaurant will close.")
	assert_bool(_label(panel, "Detail").visible).is_true()


func test_detail_is_hidden_when_there_is_none() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?")
	assert_bool(_label(panel, "Detail").visible).is_false()


func test_ask_pauses_the_game() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?")
	assert_bool(get_tree().paused).is_true()


func test_keeps_working_while_the_game_is_paused() -> void:
	var panel: ConfirmPanel = _new_panel()
	assert_int(panel.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)


func test_yes_has_focus_so_a_controller_can_answer() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?")
	assert_bool(_button(panel, "YesButton").has_focus()).is_true()


# --- Answering ----------------------------------------------------------------

func test_yes_confirms_closes_and_unpauses() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?")
	_button(panel, "YesButton").pressed.emit()
	assert_array(_answers).contains_exactly(["yes"])
	assert_bool(panel.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_no_cancels_closes_and_unpauses() -> void:
	var panel: ConfirmPanel = _new_panel()
	panel.ask("Go to bed?")
	_button(panel, "NoButton").pressed.emit()
	assert_array(_answers).contains_exactly(["no"])
	assert_bool(panel.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_unpauses_before_telling_listeners() -> void:
	# So whatever happens next (like ending the day) runs in an unpaused game.
	var panel: ConfirmPanel = _new_panel()
	var paused_when_told: Array[bool] = []
	panel.confirmed.connect(func() -> void: paused_when_told.append(get_tree().paused))
	panel.ask("Go to bed?")
	_button(panel, "YesButton").pressed.emit()
	assert_array(paused_when_told).contains_exactly([false])


func test_cancel_key_answers_no() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CONFIRM_PANEL_SCENE)
	var panel: ConfirmPanel = runner.scene() as ConfirmPanel
	_listen(panel)
	panel.ask("Go to bed?")
	runner.simulate_action_pressed("ui_cancel")
	await runner.await_input_processed()
	assert_array(_answers).contains_exactly(["no"])


func test_cancel_key_does_nothing_while_closed() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CONFIRM_PANEL_SCENE)
	var panel: ConfirmPanel = runner.scene() as ConfirmPanel
	_listen(panel)
	runner.simulate_action_pressed("ui_cancel")
	await runner.await_input_processed()
	assert_array(_answers).is_empty()


func _new_panel() -> ConfirmPanel:
	var panel: ConfirmPanel = (load(CONFIRM_PANEL_SCENE) as PackedScene).instantiate() as ConfirmPanel
	add_child(panel)
	auto_free(panel)
	_listen(panel)
	return panel


func _listen(panel: ConfirmPanel) -> void:
	panel.confirmed.connect(func() -> void: _answers.append("yes"))
	panel.cancelled.connect(func() -> void: _answers.append("no"))


func _label(panel: ConfirmPanel, node_name: String) -> Label:
	return panel.find_child(node_name) as Label


func _button(panel: ConfirmPanel, node_name: String) -> Button:
	return panel.find_child(node_name) as Button
