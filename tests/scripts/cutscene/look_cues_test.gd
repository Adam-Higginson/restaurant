extends GameTestSuite
## Tests for directing the lantern's face in a cutscene: @look gives a named
## lantern a look, the lantern is given back when the cutscene ends, and a
## lantern or a look that isn't there is warned about.

const BODY: String = "res://scenes/prototype/lantern_body.tscn"

var _player: Player3D
var _conversation: Conversation
var _cues: LookCues
var _face: LanternFace
var _other: LanternFace


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_look_gives_the_named_lantern_that_look_and_no_other() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@look hook_lantern determined\nheron: Hm.")

	assert_int(_face.expression).is_equal(LanternFace.Look.DETERMINED)
	assert_bool(_face.directed).is_true()
	assert_int(_other.expression).is_equal(LanternFace.Look.CALM)
	assert_bool(_other.directed).is_false()


func test_look_can_change_his_glass() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player,
			"@look hook_lantern cracked\nheron: Oh.\n@look hook_lantern mended\nheron: Good.")
	assert_bool(_face.cracked).is_true()

	_conversation.press()
	assert_bool(_face.cracked).is_false()


func test_every_lantern_is_given_back_when_the_cutscene_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@look hook_lantern pleading\nheron: Hm.")
	assert_bool(_face.directed).is_true()

	_conversation.stop()

	assert_bool(_face.directed).is_false()


func test_skipping_puts_the_look_on_at_once() -> void:
	_build()
	_face.blend_speed = 0.5
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"heron: One.\n@look hook_lantern surprised\n- Stay. -> END")

	_conversation.skip()

	assert_float(_face.eye_shape().y).is_equal_approx(1.35, 0.001)


func test_a_lantern_that_isnt_there_is_warned_about() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_cues.handle(&"look", PackedStringArray(["nobody", "calm"]))) \
			.is_push_warning(any_string())

	assert_object(_cues.find_face("hook_lantern")).is_same(_face)
	assert_object(_cues.find_face("nobody")).is_null()


func test_a_look_that_isnt_one_is_a_mistake_in_the_script() -> void:
	var tree: DialogueTree = DialogueScript.parse("@look hook_lantern grumpy")

	assert_int(tree.errors.size()).is_equal(1)
	assert_str(tree.errors[0]).contains("line 1").contains("@look")


func _new_face(world: Node, look_name: String) -> LanternFace:
	var face: LanternFace = (load(BODY) as PackedScene).instantiate() as LanternFace
	face.look_name = look_name
	face.blink_min = 999.0
	face.blink_max = 999.0
	world.add_child(face)
	return face


# The player, a conversation, the look cues and two lanterns. Called at the
# start of each test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_cues = LookCues.new()
	world.add_child(_cues)
	_face = _new_face(world, "hook_lantern")
	_other = _new_face(world, "sinking_lantern")
