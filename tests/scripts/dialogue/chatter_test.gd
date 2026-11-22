extends GameTestSuite
## Tests for the ship's chatter: an exchange plays one bubble at a time, only
## within earshot and sight, never during a proper conversation, and the
## lantern cuts in when something happens. It never stops you walking.
##
## The player stands at the origin with the lantern at their shoulder and
## the heron 3 m ahead.

const HERON: PackedScene = preload("res://scenes/prototype/people/heron.tscn")
const AHEAD: Vector3 = Vector3(0, 0, -3)

const EXCHANGE: String = "~ hello\nheron: One.\nlantern: Two.\nheron: Three."
const HERON_ALONE: String = "~ hm\nheron: Hm."

var _player: Player3D
var _heron: Crewmate
var _heron_voice: Speaker
var _lantern: Speaker
var _chatter: Chatter
var _conversation: Conversation


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_an_exchange_plays_one_bubble_at_a_time_in_order() -> void:
	var runner: GdUnitSceneRunner = _build(EXCHANGE)
	var heard: PackedStringArray = PackedStringArray()
	_heron_voice.said.connect(func(line: String) -> void: heard.append(line))
	_lantern.said.connect(func(line: String) -> void: heard.append(line))
	await physics_ticks(runner, 3)

	assert_bool(_chatter.chat()).is_true()
	assert_str(_heron_voice.saying).is_equal("One.")
	assert_str(_lantern.saying).is_empty()
	await physics_ticks(runner, 12)
	assert_str(_heron_voice.saying).is_empty()
	assert_str(_lantern.saying).is_equal("Two.")
	await physics_ticks(runner, 30)

	assert_array(Array(heard)).is_equal(["One.", "Two.", "Three."])
	assert_object(_chatter.playing).is_null()
	assert_float(_chatter.wait_left).is_between(_chatter.gap_min, _chatter.gap_max)


func test_it_chats_on_its_own_after_a_wait() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE, 0.1)
	_heron_voice.base_seconds = 5.0
	var started: Array[Remark] = []
	_chatter.remark_started.connect(func(remark: Remark) -> void: started.append(remark))

	await physics_ticks(runner, 12)

	assert_int(started.size()).is_equal(1)
	assert_str(_heron_voice.saying).is_equal("Hm.")


func test_nobody_chats_out_of_earshot() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	await physics_ticks(runner, 3)

	place_player_3d(runner, Vector3(0, 0, 12))
	await physics_ticks(runner, 3)

	assert_bool(_chatter.chat()).is_false()


func test_nobody_chats_through_a_wall() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	_player.get_parent().add_child(static_box(Vector3(4, 5, 0.3), Vector3(0, 2.5, -1.5)))
	await physics_ticks(runner, 3)

	assert_bool(_chatter.chat()).is_false()


func test_an_exchange_needs_everyone_in_it_nearby() -> void:
	var runner: GdUnitSceneRunner = _build(EXCHANGE)
	_lantern.who = &"somebody_else"
	await physics_ticks(runner, 3)

	assert_bool(_chatter.chat()).is_false()


func test_nobody_chats_during_a_conversation() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	await physics_ticks(runner, 3)

	_begin_conversation()

	assert_bool(_chatter.chat()).is_false()


func test_a_conversation_starting_cuts_the_chatter_off() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	_heron_voice.base_seconds = 5.0
	await physics_ticks(runner, 3)
	assert_bool(_chatter.chat()).is_true()

	_begin_conversation()
	await physics_ticks(runner, 2)

	assert_object(_chatter.playing).is_null()
	assert_str(_heron_voice.saying).is_empty()


func test_the_lantern_cuts_in_when_something_happens() -> void:
	var runner: GdUnitSceneRunner = _build(EXCHANGE)
	_heron_voice.base_seconds = 5.0
	await physics_ticks(runner, 3)
	assert_bool(_chatter.chat()).is_true()

	var spirit: LanternSpirit = _player.get_node("LanternSpirit") as LanternSpirit
	assert_bool(spirit.tell(&"caught")).is_true()

	assert_object(_chatter.playing).is_null()
	assert_str(_heron_voice.saying).is_empty()
	assert_bool(spirit.saying() in moment_lines(&"caught")).is_true()


func test_it_waits_while_somebody_nearby_is_already_talking() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	await physics_ticks(runner, 3)

	_lantern.say("I'm talking.")

	assert_bool(_chatter.chat()).is_false()


func test_chatter_never_stops_you_walking() -> void:
	var runner: GdUnitSceneRunner = _build(EXCHANGE)
	_heron_voice.base_seconds = 5.0
	await physics_ticks(runner, 3)
	assert_bool(_chatter.chat()).is_true()

	await walk(runner, "move_right", 20)

	assert_bool(_player.controls_enabled).is_true()
	assert_float(_player.global_position.x).is_greater(0.5)


func test_nobody_chats_while_you_cant_move() -> void:
	var runner: GdUnitSceneRunner = _build(HERON_ALONE)
	await physics_ticks(runner, 3)

	_player.controls_enabled = false

	assert_bool(_chatter.chat()).is_false()


# The player, the heron ahead, a conversation and a chatter with
# [param script] as its only remarks, first chatting after
# [param first_wait] seconds. Everyone talks quickly.
func _build(script: String, first_wait: float = 1000.0) -> GdUnitSceneRunner:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_heron = HERON.instantiate() as Crewmate
	_heron.position = AHEAD
	world.add_child(_heron)
	_heron_voice = _heron.get_node("Head") as Speaker
	_conversation = Conversation.new()
	world.add_child(_conversation)
	_chatter = Chatter.new()
	_chatter.player = _player
	_chatter.first_wait_min = first_wait
	_chatter.first_wait_max = first_wait
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 94
	_chatter.rng = rng
	var tree: DialogueTree = DialogueScript.parse(script, &"test", true)
	assert_array(tree.errors).is_empty()
	_chatter.remarks = Remark.all_in(tree)
	world.add_child(_chatter)
	_lantern = _player.get_node("LanternSpirit/Voice") as Speaker
	for speaker: Speaker in [_heron_voice, _lantern]:
		speaker.base_seconds = 0.1
		speaker.seconds_per_letter = 0.0
		speaker.pause_seconds = 0.0
		speaker.bubble.fade_seconds = 0.02
	return scene_runner(world)


func _begin_conversation() -> void:
	var tree: DialogueTree = DialogueScript.parse("heron: Well?", &"test")
	assert_bool(_conversation.begin_tree(tree, _player, _heron)).is_true()

