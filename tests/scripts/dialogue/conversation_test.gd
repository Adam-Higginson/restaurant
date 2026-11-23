extends GameTestSuite
## Tests for a proper conversation in a running scene: you can't walk while
## you talk, Interact moves it on and picks replies, everything is put back
## at the end, the world never pauses, and the HUD steps aside.
##
## The player stands at the origin facing -Z with the heron 1.2 m ahead.

const HERON: PackedScene = preload("res://scenes/prototype/people/heron.tscn")
const AHEAD: Vector3 = Vector3(0, 0, -1.2)

const TWO_LINES: String = "heron: One.\nheron: Two."
const A_CHOICE: String = "heron: Well?\n- Weather? -> weather\n- Heading? -> heading\n" \
		+ "~ weather\nset picked = 1\nheron: Wet.\n~ heading\nset picked = 2\nheron: North."

var _player: Player3D
var _heron: Crewmate
var _conversation: Conversation
var _hud: Hud3D


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_you_cant_walk_while_you_talk_and_can_after() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_begin(TWO_LINES)

	await walk(runner, "move_right", 20)
	assert_vector(_player.global_position).is_equal_approx(Vector3.ZERO, Vector3(0.05, 0.05, 0.05))

	_conversation.stop()
	await walk(runner, "move_right", 20)
	assert_float(_player.global_position.x).is_greater(0.5)


func test_interact_finishes_the_typing_then_moves_on_then_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var box: DialogueBox = _box()
	box.letters_per_second = 2.0
	_begin(TWO_LINES)
	await physics_ticks(runner, 2)
	assert_bool(box.visible).is_true()
	assert_bool(box.is_typing()).is_true()

	await press(runner, "interact")
	assert_bool(box.is_typing()).is_false()
	assert_str(box.shown_text()).is_equal("One.")

	await press(runner, "interact")
	assert_str(box.line_text()).is_equal("Two.")

	await press(runner, "interact")
	await press(runner, "interact")
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(box.visible).is_false()
	assert_bool(_player.controls_enabled).is_true()


func test_moving_down_and_interact_picks_the_second_reply() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_box().letters_per_second = 10000.0
	_begin(A_CHOICE)
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	await press(runner, "move_down")
	assert_int(_conversation.selected_choice()).is_equal(1)
	assert_int(_box().selected).is_equal(1)
	await press(runner, "interact")

	assert_int(Game.dialogue.value(&"picked")).is_equal(2)


func test_the_choice_cursor_wraps_round() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_box().letters_per_second = 10000.0
	_begin(A_CHOICE)
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	await press(runner, "move_up")

	assert_int(_conversation.selected_choice()).is_equal(1)


func test_the_press_that_ends_a_talk_doesnt_start_it_again() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 5)
	_box().letters_per_second = 10000.0
	var started: Array[int] = [0]
	_conversation.started.connect(func(_id: StringName) -> void: started[0] += 1)

	# Facing the heron, so Interact talks to him: his own conversation.
	await press(runner, "interact")
	assert_int(started[0]).is_equal(1)
	_conversation.stop()
	_begin("heron: Only line.")
	await physics_ticks(runner, 3)
	await press(runner, "interact")

	assert_bool(_conversation.is_active()).is_false()
	assert_int(started[0]).is_equal(2)


func test_interact_talks_to_the_crewmate_you_face() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 5)

	assert_str(_heron.prompt()).is_equal("Talk to Captain")
	await press(runner, "interact")

	assert_str(String(_conversation.talking)).is_equal("heron")


func test_the_world_keeps_running_while_you_talk() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	_begin(TWO_LINES)

	assert_bool(_player.get_tree().paused).is_false()


func test_they_turn_to_face_each_other_and_he_turns_back_after() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	_heron.position = Vector3(1.2, 0, 0)
	await physics_ticks(runner, 3)
	var model: Node3D = _heron.get_node("Model") as Node3D

	_begin(TWO_LINES)
	await physics_ticks(runner, 60)
	# The heron, to the player's right (+X), has turned to look back along -X.
	assert_float(absf(angle_difference(model.rotation.y, PI / 2.0))).is_less(0.05)
	assert_float(_player.facing.x).is_greater(0.9)

	_conversation.stop()
	await physics_ticks(runner, 60)
	assert_float(absf(model.rotation.y)).is_less(0.05)


func test_the_hud_steps_aside_while_you_talk() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	assert_bool(_hud.shows_play_parts()).is_true()

	_begin(TWO_LINES)
	assert_bool(_hud.shows_play_parts()).is_false()

	_conversation.stop()
	assert_bool(_hud.shows_play_parts()).is_true()


func test_each_talk_finished_is_counted() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	_begin("heron: Hm.", &"heron")
	_conversation.stop()
	_begin("heron: Hm.", &"heron")
	_conversation.stop()

	assert_int(Game.dialogue.value(&"talked.heron")).is_equal(2)


func test_a_second_conversation_cant_start_over_the_first() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_begin(TWO_LINES)

	assert_bool(_conversation.begin(&"lantern", _player)).is_false()


func test_a_conversation_that_isnt_there_doesnt_start() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void: _conversation.begin(&"nobody", _player)) \
			.is_push_error(any_string())

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_player.controls_enabled).is_true()


func test_interact_does_nothing_to_the_world_while_controls_are_off() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 5)
	_player.controls_enabled = false

	await press(runner, "interact")

	assert_bool(_conversation.is_active()).is_false()


func test_it_knows_who_its_with_until_it_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	assert_object(_conversation.partner).is_null()
	_begin(TWO_LINES)
	assert_object(_conversation.partner).is_same(_heron)
	_conversation.stop()
	assert_object(_conversation.partner).is_null()


func test_it_says_when_replies_are_offered() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var offered: Array[int] = [0]
	_conversation.choices_offered.connect(func() -> void: offered[0] += 1)
	_box().letters_per_second = 10000.0
	_begin(A_CHOICE)
	await physics_ticks(runner, 3)
	assert_int(offered[0]).is_equal(0)
	await press(runner, "interact")
	assert_int(offered[0]).is_equal(1)


func _begin(script: String, id: StringName = &"test") -> void:
	var tree: DialogueTree = DialogueScript.parse(script, id)
	assert_array(tree.errors).is_empty()
	assert_bool(_conversation.begin_tree(tree, _player, _heron)).is_true()


func _box() -> DialogueBox:
	return _hud.get_node("%DialogueBox") as DialogueBox


# The player, the heron ahead of them, a conversation and a HUD. Called at
# the start of each test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	_heron = HERON.instantiate() as Crewmate
	_heron.position = AHEAD
	_player.get_parent().add_child(_heron)
	_conversation = Conversation.new()
	_player.get_parent().add_child(_conversation)
	_hud = new_hud_3d(_player)
