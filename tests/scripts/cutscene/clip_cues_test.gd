extends GameTestSuite
## Tests for clips (movements made on the animation timeline) in a cutscene:
## @play holds the script until the clip ends, @start doesn't, and skipping
## leaves whatever a clip moves where the clip leaves it.
##
## The clip "slide" moves a thing from x = 0 to x = 2 in half a second;
## "bob" loops, between x = 5 and x = 6.

var _player: Player3D
var _conversation: Conversation
var _cues: ClipCues
var _thing: Node3D
var _clips: AnimationPlayer
## How many lines have been said.
var _lines: int


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_play_holds_the_script_until_the_clip_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@play slide\nheron: After.")
	await physics_ticks(runner, 15)
	assert_int(_lines).is_equal(0)
	assert_float(_thing.position.x).is_between(0.2, 1.8)

	await physics_ticks(runner, 25)
	assert_int(_lines).is_equal(1)
	assert_float(_thing.position.x).is_equal_approx(2.0, 0.001)


func test_start_plays_a_clip_and_carries_straight_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@start bob\nheron: Meanwhile.")
	assert_int(_lines).is_equal(1)

	await physics_ticks(runner, 20)
	assert_bool(_clips.is_playing()).is_true()
	assert_float(_thing.position.x).is_between(5.0, 6.0)


func test_a_looping_clip_keeps_going_however_long_the_script_waits() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@start bob\nheron: Meanwhile.")

	await physics_ticks(runner, 200)

	assert_bool(_clips.is_playing()).is_true()
	assert_str(String(_clips.current_animation)).is_equal("bob")


func test_skipping_past_a_clip_leaves_things_where_it_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: Before.\n@play slide\nset done")

	_conversation.skip()

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_float(_thing.position.x).is_equal_approx(2.0, 0.001)
	assert_bool(_clips.is_playing()).is_false()


func test_skipping_in_the_middle_of_a_clip_jumps_it_to_its_end() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@play slide\nset done")
	await physics_ticks(runner, 10)
	assert_float(_thing.position.x).is_less(1.5)

	_conversation.skip()

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_float(_thing.position.x).is_equal_approx(2.0, 0.001)


func test_a_clip_that_isnt_there_is_warned_about_and_the_script_goes_on() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_cues.handle(&"play", PackedStringArray(["nothing"]))) \
			.is_push_warning(any_string())

	assert_bool(_clips.is_playing()).is_false()


func test_it_finds_whichever_player_has_the_clip() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	assert_object(_cues.find_player(&"slide")).is_same(_clips)
	assert_object(_cues.find_player(&"nothing")).is_null()


# A clip [param length] seconds long that moves the thing's x through
# [param xs], evenly spaced.
func _clip(length: float, xs: Array[float], loops: bool) -> Animation:
	var clip: Animation = Animation.new()
	clip.length = length
	if loops:
		clip.loop_mode = Animation.LOOP_LINEAR
	var track: int = clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(track, NodePath("Thing:position:x"))
	for i: int in xs.size():
		clip.track_insert_key(track, length * i / (xs.size() - 1), xs[i])
	return clip


# The player, a conversation, the clip cues, a thing to move and an
# AnimationPlayer with two clips. Called at the start of each test, so
# everything is made (and freed) inside it.
func _build() -> void:
	_lines = 0
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void: _lines += 1)
	_cues = ClipCues.new()
	world.add_child(_cues)
	_thing = Node3D.new()
	_thing.name = "Thing"
	world.add_child(_thing)
	_clips = AnimationPlayer.new()
	_clips.name = "Clips"
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"slide", _clip(0.5, [0.0, 2.0], false))
	library.add_animation(&"bob", _clip(1.0, [5.0, 6.0, 5.0], true))
	_clips.add_animation_library(&"", library)
	_clips.add_to_group(ClipCues.GROUP)
	world.add_child(_clips)
