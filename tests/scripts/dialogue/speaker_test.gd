extends GameTestSuite
## Tests for somebody speaking in bubbles: lines wait their turn and fade,
## hushing cuts them off, tags become bubble styles, and a wall between you
## hides the bubble.
##
## The player stands at the origin; the speaker floats 4 m ahead at head height.

const AHEAD: Vector3 = Vector3(0, 1.6, -4)

var _player: Player3D
var _speaker: Speaker


func test_lines_wait_their_turn_then_they_go_quiet() -> void:
	var runner: GdUnitSceneRunner = _build()
	var heard: PackedStringArray = PackedStringArray()
	_speaker.said.connect(func(line: String) -> void: heard.append(line))
	await physics_ticks(runner, 2)

	_speaker.say("One.")
	_speaker.say("Two.")
	assert_str(_speaker.saying).is_equal("One.")
	assert_str(_speaker.bubble.text).is_equal("One.")
	await physics_ticks(runner, 15)
	assert_str(_speaker.saying).is_equal("Two.")
	await physics_ticks(runner, 15)

	assert_str(_speaker.saying).is_empty()
	assert_bool(_speaker.is_busy()).is_false()
	assert_array(Array(heard)).is_equal(["One.", "Two."])


func test_hushing_cuts_them_off_and_forgets_whats_waiting() -> void:
	var runner: GdUnitSceneRunner = _build()
	var hushed: Array[bool] = [false]
	_speaker.hushed.connect(func() -> void: hushed[0] = true)
	await physics_ticks(runner, 2)
	_speaker.say("One.")
	_speaker.say("Two.")

	_speaker.hush()
	await physics_ticks(runner, 30)

	assert_bool(hushed[0]).is_true()
	assert_str(_speaker.saying).is_empty()


func test_saying_something_now_replaces_what_they_were_saying() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 2)
	_speaker.say("One.")
	_speaker.say("Two.")

	_speaker.say_now("Oi!", SpeechBubble.Style.EXCLAIM)
	assert_str(_speaker.saying).is_equal("Oi!")
	await physics_ticks(runner, 15)

	assert_str(_speaker.saying).is_empty()


func test_a_lines_tag_is_its_bubble_style() -> void:
	assert_int(Speaker.style_for(&"")).is_equal(SpeechBubble.Style.SPEECH)
	assert_int(Speaker.style_for(&"thought")).is_equal(SpeechBubble.Style.THOUGHT)
	assert_int(Speaker.style_for(&"shout")).is_equal(SpeechBubble.Style.EXCLAIM)
	assert_int(Speaker.style_for(&"sound")).is_equal(SpeechBubble.Style.SOUND)


func test_you_can_see_them_with_nothing_in_the_way() -> void:
	var runner: GdUnitSceneRunner = _build()
	await physics_ticks(runner, 3)

	assert_bool(_speaker.is_seen()).is_true()


func test_a_wall_between_you_hides_their_bubble() -> void:
	var runner: GdUnitSceneRunner = _build(true)
	await physics_ticks(runner, 3)

	_speaker.say("Behind the wall.")
	await physics_ticks(runner, 10)

	assert_bool(_speaker.is_seen()).is_false()
	assert_float(_speaker.bubble.sight).is_equal(0.0)


func test_the_bubble_comes_back_when_the_wall_is_gone() -> void:
	var runner: GdUnitSceneRunner = _build(true)
	await physics_ticks(runner, 3)
	_speaker.base_seconds = 5.0
	_speaker.say("Behind the wall.")
	await physics_ticks(runner, 3)

	place_player_3d(runner, Vector3(5, 0, 0))
	await physics_ticks(runner, 30)

	assert_float(_speaker.bubble.sight).is_equal(1.0)


# The player on a floor and a quick-talking speaker ahead, with a wall
# between them if [param walled].
func _build(walled: bool = false) -> GdUnitSceneRunner:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_speaker = Speaker.new()
	_speaker.who = &"heron"
	_speaker.position = AHEAD
	_speaker.base_seconds = 0.1
	_speaker.seconds_per_letter = 0.0
	_speaker.pause_seconds = 0.0
	world.add_child(_speaker)
	_speaker.bubble.fade_seconds = 0.02
	if walled:
		world.add_child(static_box(Vector3(3, 4, 0.3), Vector3(0, 2, -2)))
	return scene_runner(world)
