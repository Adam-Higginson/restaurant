extends GameTestSuite
## Tests for books in cutscenes (#184): @read opens the recipe book and the
## script waits until it's closed; skipped, it's never opened; a book with no
## name it knows is warned about.

var _player: Player3D
var _conversation: Conversation
var _hud: Hud3D
var _cues: BookCues
var _lines: int


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_read_opens_the_book_and_waits_until_its_closed() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var view: BookView = _hud.get_node("%BookView") as BookView

	play_cutscene(_conversation, _player, "@read recipe_book\nheron: After.")
	await physics_ticks(runner, 10)
	assert_bool(view.is_open()).is_true()
	assert_int(_lines).is_equal(0)

	view.close()
	await physics_ticks(runner, 5)
	assert_int(_lines).is_equal(1)


func test_skipped_the_book_is_never_opened() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)
	var view: BookView = _hud.get_node("%BookView") as BookView
	play_cutscene(_conversation, _player, "heron: One.\n@read recipe_book\nheron: Two.\nset done")

	_conversation.skip()
	await physics_ticks(runner, 3)

	assert_bool(Game.dialogue.is_set(&"done")).is_true()
	assert_bool(view.is_open()).is_false()


func test_a_book_it_doesnt_know_is_warned_about() -> void:
	_build()
	var runner: GdUnitSceneRunner = scene_runner(_player.get_parent())
	await physics_ticks(runner, 3)

	await assert_error(func() -> void:
		_cues.handle(&"read", PackedStringArray(["the_old_book"]))) \
			.is_push_warning(any_string())


# The player, the HUD (with its book view), a conversation and the book
# cues. Called at the start of each test, so everything is made (and freed)
# inside it.
func _build() -> void:
	_lines = 0
	_player = new_player_3d_on_floor()
	_hud = new_hud_3d(_player)
	_conversation = new_conversation(_player)
	_conversation.line_said.connect(func(_speaker: Person) -> void: _lines += 1)
	_cues = BookCues.new()
	_cues.player = _player
	_player.get_parent().add_child(_cues)
