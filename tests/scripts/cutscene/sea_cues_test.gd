extends GameTestSuite
## Tests for the sea on cue (@grave): the Grave of the Lanterns' faint lights
## fade up under the open sea and away again, at once when skipped, and are
## never left showing when a cutscene ends.

const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"

var _player: Player3D
var _conversation: Conversation
var _sea: Sea
var _cues: SeaCues


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_grave_on_fades_the_lights_up_and_off_fades_them_away() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	assert_float(_sea.grave).is_equal(0.0)

	play_cutscene(_conversation, _player, "@grave on\nheron: Below.\n@grave off\nheron: Gone.")
	await physics_ticks(runner, 15)
	assert_float(_sea.grave).is_between(0.05, 0.95)
	await physics_ticks(runner, 40)
	assert_float(_sea.grave).is_equal_approx(1.0, 0.001)

	_conversation.press()
	await physics_ticks(runner, 15)
	assert_float(_sea.grave).is_between(0.05, 0.95)
	await physics_ticks(runner, 40)
	assert_float(_sea.grave).is_equal_approx(0.0, 0.001)


func test_skipped_the_lights_get_where_they_were_going_at_once() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n@grave on\nheron: Two.\nset done")

	_conversation.skip()

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	# The cutscene's over, and it never leaves them showing.
	assert_float(_sea.grave).is_equal(0.0)


func test_the_lights_are_never_left_showing_when_a_cutscene_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@grave on\nheron: Below.")
	await physics_ticks(runner, 60)
	assert_float(_sea.grave).is_equal_approx(1.0, 0.001)

	_conversation.stop()

	assert_float(_sea.grave).is_equal(0.0)


func test_leaping_fish_leap_on_cue_and_stop_when_the_cutscene_ends() -> void:
	_build()
	var fish: LeapingFish = LeapingFish.new()
	_player.get_parent().add_child(fish)
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@leaping_fish on\nheron: Look at them go.")
	assert_bool(fish.leaping).is_true()
	_conversation.press()
	await physics_ticks(runner, 3)

	assert_bool(_conversation.is_active()).is_false()
	assert_bool(fish.leaping).is_false()


func test_the_sea_keeps_how_much_shows_between_zero_and_one() -> void:
	_build()
	_sea.grave = 4.0
	assert_float(_sea.grave).is_equal(1.0)
	_sea.grave = -2.0
	assert_float(_sea.grave).is_equal(0.0)


# The player, a conversation, a sea and the cues that work it. The fade is
# made short so the tests needn't wait long. Called at the start of each
# test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	world.add_child(_sea)
	_cues = SeaCues.new()
	_cues.sea = _sea
	_cues.fade_seconds = 0.6
	world.add_child(_cues)
