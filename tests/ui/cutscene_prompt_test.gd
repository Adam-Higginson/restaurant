extends GameTestSuite
## Tests for CutscenePrompt, the words shown while a cutscene waits for the
## player: they come in after a moment, say which button, and go away.

const PROMPT_SCENE: String = "res://ui/cutscene_prompt.tscn"


func test_it_starts_with_nothing_shown() -> void:
	var prompt: CutscenePrompt = _new_prompt()

	assert_bool(prompt.is_prompting).is_false()
	assert_bool(prompt.visible).is_false()
	assert_str(prompt.shown_text()).is_empty()


func test_the_words_come_in_after_a_moment() -> void:
	var prompt: CutscenePrompt = _new_prompt()
	var words: Label = prompt.get_node("%Words") as Label

	prompt.show_prompt("Press any button")
	assert_bool(prompt.is_prompting).is_true()
	assert_bool(prompt.visible).is_true()
	assert_float(words.modulate.a).is_equal(0.0)

	await get_tree().create_timer(0.5).timeout
	assert_float(words.modulate.a).is_greater(0.9)
	assert_str(prompt.shown_text()).is_equal("Press any button")


func test_hiding_fades_them_away_and_says_nothing() -> void:
	var prompt: CutscenePrompt = _new_prompt()
	prompt.show_prompt("Press any button")
	await get_tree().create_timer(0.5).timeout

	prompt.hide_prompt()
	assert_bool(prompt.is_prompting).is_false()
	assert_str(prompt.shown_text()).is_empty()

	await get_tree().create_timer(0.4).timeout
	assert_bool(prompt.visible).is_false()


func test_a_prompt_can_name_the_interact_button_for_each_device() -> void:
	var keys: String = CutscenePrompt.prompt_text("Take his hand", true,
			ActionPrompt.Device.KEYBOARD_MOUSE)
	var pad: String = CutscenePrompt.prompt_text("Take his hand", true, ActionPrompt.Device.PAD)

	assert_str(keys).is_equal("[%s] Take his hand" % ActionPrompt.button_name(&"interact",
			ActionPrompt.Device.KEYBOARD_MOUSE))
	assert_str(pad).is_equal("[%s] Take his hand" % ActionPrompt.button_name(&"interact",
			ActionPrompt.Device.PAD))
	assert_str(keys).is_not_equal(pad)
	assert_str(CutscenePrompt.prompt_text("Press any button", false,
			ActionPrompt.Device.PAD)).is_equal("Press any button")


# A prompt with a short delay and fade, so tests don't wait long.
func _new_prompt() -> CutscenePrompt:
	var prompt: CutscenePrompt = (load(PROMPT_SCENE) as PackedScene).instantiate() \
			as CutscenePrompt
	auto_free(prompt)
	prompt.delay_seconds = 0.1
	prompt.fade_seconds = 0.2
	add_child(prompt)
	return prompt
