extends GameTestSuite
## Tests for fades and titles in a cutscene: each holds the script until it's
## done, a title makes the screen black, a skipped cutscene is black until
## it's over, and a cutscene never ends on a black screen.

const SCREEN_FADE: PackedScene = preload("res://ui/screen_fade.tscn")

var _player: Player3D
var _conversation: Conversation
var _fade: ScreenFade
## How many lines have been said.
var _lines: int


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_fade_out_holds_the_script_until_the_screen_is_black() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@fade out 0.5\nheron: In the dark.")
	await physics_ticks(runner, 15)
	assert_int(_lines).is_equal(0)
	assert_bool(_fade.is_covering()).is_false()

	await physics_ticks(runner, 25)
	assert_int(_lines).is_equal(1)
	assert_bool(_fade.is_covering()).is_true()


func test_fade_in_holds_the_script_until_the_screen_is_clear() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_fade.cover_now()

	play_cutscene(_conversation, _player, "@fade in 0.5\nheron: There you are.")
	await physics_ticks(runner, 15)
	assert_int(_lines).is_equal(0)

	await physics_ticks(runner, 25)
	assert_int(_lines).is_equal(1)
	assert_bool(_fade.visible).is_false()


func test_a_fade_with_no_seconds_takes_the_usual_time() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@fade out\nheron: In the dark.")
	await physics_ticks(runner, 20)

	assert_int(_lines).is_equal(1)
	assert_bool(_fade.is_covering()).is_true()


func test_a_title_shows_its_words_over_black() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@title Somewhere at sea\nheron: Hm.")
	assert_bool(_fade.is_covering()).is_true()
	assert_int(_lines).is_equal(0)

	await physics_ticks(runner, 15)
	var title: Label = _fade.find_child("Title") as Label
	assert_str(title.text).is_equal("Somewhere at sea")
	assert_float(title.modulate.a).is_equal_approx(1.0, 0.01)
	assert_int(_lines).is_equal(1)


func test_a_cutscene_never_ends_on_a_black_screen() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@fade out 0.1")
	await physics_ticks(runner, 12)
	assert_bool(_conversation.is_active()).is_false()

	await physics_ticks(runner, 20)
	assert_bool(_fade.visible).is_false()


func test_skipping_blacks_the_screen_at_once_and_clears_it_after() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n- Stay. -> END")

	_conversation.skip()
	# It stopped at the choice: the screen clears so you can read it.
	assert_bool(_conversation.is_active()).is_true()
	await physics_ticks(runner, 20)
	assert_bool(_fade.visible).is_false()


func test_a_skip_leaves_the_screen_black_if_the_script_last_asked_for_black() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"heron: One.\n@fade out 5\nheron: Two.\n- Stay. -> END")

	_conversation.skip()
	await physics_ticks(runner, 20)

	assert_bool(_conversation.is_active()).is_true()
	assert_bool(_fade.is_covering()).is_true()


func test_a_skipped_cutscene_ends_with_the_screen_clear() -> void:
	_build()
	_fade.fade_seconds = 0.2
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player,
			"@title Somewhere at sea\n@wait 30\n@fade in 30\nheron: One.\n@fade out 30")
	await physics_ticks(runner, 20)

	_conversation.skip()
	assert_bool(_conversation.is_active()).is_false()
	assert_bool(_fade.is_covering()).is_true()

	await physics_ticks(runner, 20)
	assert_bool(_fade.visible).is_false()


# The player, a conversation, a screen fade and the fade cues (with wait
# cues, for scripts that pause). Called at the start of each test, so
# everything is made (and freed) inside it.
func _build() -> void:
	_lines = 0
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void: _lines += 1)
	_fade = SCREEN_FADE.instantiate() as ScreenFade
	world.add_child(_fade)
	var fades: FadeCues = FadeCues.new()
	fades.fade = _fade
	world.add_child(fades)
	world.add_child(WaitCues.new())
