extends GameTestSuite
## Tests for stages (things shown over the game for part of a cutscene) and
## the cue that brings them up: one at a time, never left up when a
## cutscene ends, and the game's own 3D not drawn behind one that covers it.

var _player: Player3D
var _conversation: Conversation
var _cues: StageCues
var _title: Stage
var _underwater: Stage


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()
	get_viewport().disable_3d = false


func test_a_stage_starts_away_and_not_running() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	assert_bool(_title.is_open).is_false()
	assert_bool(_title.visible).is_false()
	assert_int(_title.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)


func test_the_cue_brings_a_stage_up_and_off_puts_it_away() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@stage title\nheron: Up.\n@stage off\nheron: Away.")
	assert_bool(_title.is_open).is_true()
	assert_bool(_title.visible).is_true()
	assert_int(_title.process_mode).is_equal(Node.PROCESS_MODE_INHERIT)
	assert_object(_cues.open_stage()).is_same(_title)

	_conversation.press()
	assert_bool(_title.is_open).is_false()
	assert_bool(_title.visible).is_false()
	assert_object(_cues.open_stage()).is_null()


func test_bringing_one_up_puts_the_other_away() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player, "@stage title\n@stage underwater\nheron: Under.")

	assert_bool(_title.is_open).is_false()
	assert_bool(_underwater.is_open).is_true()


func test_a_stage_that_covers_the_world_stops_it_being_drawn_behind() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(_conversation, _player,
			"@stage title\nheron: Title.\n@stage underwater\nheron: Under.\n@stage off\nheron: Up.")
	assert_bool(get_viewport().disable_3d).is_false()

	_conversation.press()
	assert_bool(get_viewport().disable_3d).is_true()

	_conversation.press()
	assert_bool(get_viewport().disable_3d).is_false()


func test_a_covering_stage_that_fades_keeps_the_world_drawn_until_its_up() -> void:
	_build()
	_underwater.fade_seconds = 0.5
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	_underwater.open()
	await physics_ticks(runner, 12)
	assert_bool(get_viewport().disable_3d).is_false()
	await physics_ticks(runner, 30)
	assert_bool(get_viewport().disable_3d).is_true()

	_underwater.close()
	assert_bool(get_viewport().disable_3d).is_false()


func test_a_stage_fades_up_and_away_over_its_seconds() -> void:
	_build()
	_title.fade_seconds = 0.5
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var content: Control = _title.get_child(0) as Control

	_title.open()
	await physics_ticks(runner, 12)
	assert_float(content.modulate.a).is_between(0.1, 0.9)
	await physics_ticks(runner, 30)
	assert_float(content.modulate.a).is_equal_approx(1.0, 0.01)

	_title.close()
	assert_bool(_title.is_open).is_false()
	assert_bool(_title.visible).is_true()
	await physics_ticks(runner, 40)
	assert_bool(_title.visible).is_false()


func test_cut_brings_a_stage_up_and_away_at_once_whatever_its_fade() -> void:
	# For changing over under a fade to black (#203).
	_build()
	_title.fade_seconds = 5.0
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var content: Control = _title.get_child(0) as Control

	play_cutscene(_conversation, _player, "@stage title cut\nheron: Up.\n@stage off cut\nheron: Away.")
	assert_float(content.modulate.a).is_equal_approx(1.0, 0.01)

	_conversation.press()
	assert_bool(_title.is_open).is_false()
	assert_bool(_title.visible).is_false()


func test_a_cutscene_never_leaves_a_stage_up_when_it_ends() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "@stage underwater\nheron: Under.")
	assert_bool(_underwater.is_open).is_true()

	_conversation.stop()

	assert_bool(_underwater.is_open).is_false()
	assert_bool(_underwater.visible).is_false()
	assert_bool(get_viewport().disable_3d).is_false()


func test_skipping_puts_stages_away_at_once_whatever_their_fade() -> void:
	_build()
	_title.fade_seconds = 5.0
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	play_cutscene(_conversation, _player, "heron: One.\n@stage title\nheron: Two.\nset done")

	_conversation.skip()

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(_title.is_open).is_false()
	assert_bool(_title.visible).is_false()


func test_a_stage_that_isnt_there_is_warned_about_and_nothing_changes() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	_title.open()

	await assert_error(func() -> void:
		_cues.handle(&"stage", PackedStringArray(["nowhere"]))) \
			.is_push_warning(any_string())

	assert_bool(_title.is_open).is_true()


func test_it_finds_a_stage_by_its_name_in_snake_case() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	assert_object(_cues.find_stage("title")).is_same(_title)
	assert_object(_cues.find_stage("underwater")).is_same(_underwater)
	assert_object(_cues.find_stage("galley")).is_null()


# A stage called [param stage_name] holding one empty Control, added to
# [param world].
func _new_stage(world: Node, stage_name: String, covers_world: bool) -> Stage:
	var stage: Stage = Stage.new()
	stage.name = stage_name
	stage.covers_world = covers_world
	stage.add_child(Control.new())
	world.add_child(stage)
	return stage


# The player, a conversation, the stage cues and two stages: a title, and
# an underwater set that covers the world. Called at the start of each
# test, so everything is made (and freed) inside it.
func _build() -> void:
	_player = new_player_3d_on_floor()
	var world: Node = _player.get_parent()
	_conversation = new_conversation(_player)
	_cues = StageCues.new()
	world.add_child(_cues)
	_title = _new_stage(world, "Title", false)
	_underwater = _new_stage(world, "Underwater", true)
