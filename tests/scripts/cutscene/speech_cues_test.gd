extends GameTestSuite
## Tests for things said in a cutscene without waiting for a button: @say
## puts a line in the dialogue box and the script carries on, @say_in does
## it after a delay, the box puts itself away when the line's time is up
## and stays up while a cue holds the script, and answering (pressing
## Interact), skipping or ending the cutscene drops whatever was to come.

const BOX: PackedScene = preload("res://ui/dialogue_box.tscn")
const PROMPT: PackedScene = preload("res://ui/cutscene_prompt.tscn")

var _player: Player3D
var _conversation: Conversation
var _speech: SpeechCues
var _box: DialogueBox


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_say_puts_the_line_in_the_dialogue_box_and_the_script_carries_straight_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player,
			"@say lantern 2.0 Someone in the water!\nset done\n@wait 9")

	assert_bool(_box.visible).is_true()
	assert_str(_box.line_text()).is_equal("Someone in the water!")
	assert_str(_box.speaker_name()).is_equal("Lantern")
	assert_bool(_conversation.is_aside_up()).is_true()
	assert_bool(Game.dialogue.is_set(&"done")).is_true()


func test_the_box_stays_up_while_the_script_is_held_and_goes_when_time_is_up() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@say lantern 0.5 Hold on.\n@wait 9")

	await physics_ticks(runner, 15)
	assert_bool(_box.visible).is_true()
	assert_str(_box.line_text()).is_equal("Hold on.")

	await physics_ticks(runner, 25)
	assert_bool(_box.visible).is_false()
	assert_bool(_conversation.is_aside_up()).is_false()
	assert_float(_speech.seconds_left()).is_equal(0.0)


func test_say_in_waits_its_moment_then_says_it() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@say_in 0.5 lantern 2.0 Come on. Come on.\n@wait 9")

	await physics_ticks(runner, 15)
	assert_bool(_box.visible).is_false()
	assert_int(_speech.waiting_count()).is_equal(1)

	await physics_ticks(runner, 25)
	assert_bool(_box.visible).is_true()
	assert_str(_box.line_text()).is_equal("Come on. Come on.")
	assert_int(_speech.waiting_count()).is_equal(0)


func test_a_new_line_takes_the_place_of_the_one_before() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player,
			"@say lantern 5 Grab my hand!\n@say lantern 5 Please.\n@wait 9")

	assert_str(_box.line_text()).is_equal("Please.")


func test_once_youve_answered_nothing_more_is_said() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@say lantern 5 Grab my hand!\n"
			+ "@say_in 0.5 lantern 5 Please.\n@wait_for interact\n@wait 9")
	await physics_ticks(runner, 5)
	assert_str(_box.line_text()).is_equal("Grab my hand!")
	assert_bool(_box.visible).is_true()

	_conversation.press()
	await physics_ticks(runner, 60)

	assert_bool(_box.visible).is_false()
	assert_int(_speech.waiting_count()).is_equal(0)


func test_skipped_nothing_is_said_at_all() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n@say lantern 5 Hold on.\n"
			+ "@say_in 1 lantern 5 Don't look down.\nset done")

	_conversation.skip()
	await physics_ticks(runner, 90)

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(_box.visible).is_false()
	assert_int(_speech.waiting_count()).is_equal(0)


func test_when_the_cutscene_ends_whats_up_is_put_away() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"@say lantern 5 Hold on.\n@say_in 2 lantern 5 Later.\n@wait 9")
	assert_bool(_box.visible).is_true()

	_conversation.stop()

	assert_bool(_box.visible).is_false()
	assert_int(_speech.waiting_count()).is_equal(0)


func test_a_line_thats_read_the_usual_way_still_waits_and_shows_its_arrow() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@say lantern 5 In passing.\nheron: To be read.")

	# The ordinary line has taken the box, and it's no longer an aside.
	assert_str(_box.line_text()).is_equal("To be read.")
	assert_bool(_conversation.is_aside_up()).is_false()


func test_the_prompt_moves_up_out_of_the_way_while_a_line_is_up() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var prompt: CutscenePrompt = PROMPT.instantiate() as CutscenePrompt
	_player.get_parent().add_child(prompt)
	_speech.prompt = prompt
	var words: Label = prompt.get_node("%Words") as Label
	var usual: float = words.offset_top

	play_cutscene(_conversation, _player, "@say lantern 0.5 Grab my hand!\n@wait 9")
	assert_bool(prompt.raised).is_true()
	assert_float(words.offset_top).is_equal_approx(usual - prompt.raise_by, 0.001)

	# When the line's gone, it comes back down.
	await physics_ticks(runner, 40)
	assert_bool(prompt.raised).is_false()
	assert_float(words.offset_top).is_equal_approx(usual, 0.001)


func test_with_no_box_nothing_goes_wrong() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_conversation.box = null

	play_cutscene(_conversation, _player,
			"@say lantern 1 Hello.\n@say_in 0.1 lantern 1 Again.\nset done\n@wait 9")
	await physics_ticks(runner, 20)

	assert_bool(Game.dialogue.is_set(&"done")).is_true()


# The player, a conversation with a dialogue box, and the speech cues.
func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_box = BOX.instantiate() as DialogueBox
	world.add_child(_box)
	_conversation.box = _box
	_speech = SpeechCues.new()
	world.add_child(_speech)
	world.add_child(WaitCues.new())
