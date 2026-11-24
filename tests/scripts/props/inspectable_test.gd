extends GameTestSuite
## Tests for Inspectable, something you can look at (#185): Interact says
## "Look at" it, and plays its lines from look.dlg, unless you're already
## talking.

var _player: Player3D
var _conversation: Conversation
var _thing: Inspectable


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_its_prompt_says_what_you_look_at() -> void:
	_build("the chart", &"grave_chart")

	assert_str(_thing.prompt()).is_equal("Look at the chart")


func test_looking_plays_its_lines() -> void:
	_build("the chart", &"grave_chart")
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)
	var lines: Array[int] = [0]
	_conversation.line_said.connect(func(_speaker: Person) -> void: lines[0] += 1)

	assert_bool(_thing.look(_player)).is_true()

	assert_bool(_conversation.is_active()).is_true()
	assert_str(String(_conversation.section())).is_equal("grave_chart")
	assert_int(lines[0]).is_equal(1)


func test_it_waits_while_youre_already_talking() -> void:
	_build("the chart", &"grave_chart")
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 2)
	play_cutscene(_conversation, _player, "heron: Hm.")

	assert_bool(_thing.look(_player)).is_false()


func test_every_thing_you_can_look_at_has_lines_to_say() -> void:
	var tree: DialogueTree = DialogueLibrary.reread(Inspectable.CUTSCENE)
	assert_object(tree).is_not_null()
	assert_bool(tree.has_section(&"grave_chart")).is_true()


# The player, a conversation, and something to look at beside them.
func _build(what: String, lines: StringName) -> void:
	_player = new_player_3d_on_floor()
	_conversation = new_conversation(_player)
	_thing = Inspectable.new()
	_thing.what = what
	_thing.lines = lines
	var reach: Interactable3D = Interactable3D.new()
	reach.name = "Reach"
	_thing.add_child(reach)
	_player.get_parent().add_child(_thing)
