extends GameTestSuite
## Tests for ScreenFade, the black fade and title card played at night.

const SCREEN_FADE_SCENE: String = "res://ui/screen_fade.tscn"
const DATE: String = "Spring 2, Tuesday"


func after_test() -> void:
	get_tree().paused = false


func test_starts_hidden_and_not_covering() -> void:
	var fade: ScreenFade = _new_fade()
	assert_bool(fade.visible).is_false()
	assert_bool(fade.is_covering()).is_false()


func test_fade_out_covers_the_screen() -> void:
	var fade: ScreenFade = _new_fade()
	assert_bool(await finishes_within(fade.fade_out)).is_true()
	assert_bool(fade.visible).is_true()
	assert_bool(fade.is_covering()).is_true()


func test_fade_to_white_covers_the_screen_in_white() -> void:
	var fade: ScreenFade = _new_fade()
	assert_bool(await finishes_within(fade.fade_to_white)).is_true()
	assert_bool(fade.is_covering()).is_true()
	assert_bool(fade.is_white()).is_true()


func test_from_white_fade_out_goes_to_black_and_fade_in_leaves_black_for_next_time() -> void:
	var fade: ScreenFade = _new_fade()
	await finishes_within(fade.fade_to_white)
	assert_bool(await finishes_within(fade.fade_out)).is_true()
	assert_bool(fade.is_covering()).is_true()
	assert_bool(fade.is_white()).is_false()

	await finishes_within(fade.fade_to_white)
	await finishes_within(fade.fade_in)
	# The next plain fade out is black again.
	await finishes_within(fade.fade_out)
	assert_bool(fade.is_white()).is_false()


func test_covering_at_once_is_always_black() -> void:
	var fade: ScreenFade = _new_fade()
	await finishes_within(fade.fade_to_white)
	fade.cover_now()
	assert_bool(fade.is_covering()).is_true()
	assert_bool(fade.is_white()).is_false()


func test_show_title_shows_the_text() -> void:
	var fade: ScreenFade = _new_fade()
	await finishes_within(fade.fade_out)
	# Several frames long, so returning before the title is in can't pass by luck.
	fade.fade_seconds = 0.2
	assert_bool(await finishes_within(fade.show_title.bind(DATE))).is_true()
	assert_str(_title(fade).text).is_equal(DATE)
	assert_float(_title(fade).modulate.a).is_equal_approx(1.0, 0.01)


func test_fade_in_uncovers_and_hides() -> void:
	var fade: ScreenFade = _new_fade()
	await finishes_within(fade.fade_out)
	await finishes_within(fade.show_title.bind(DATE))
	assert_bool(await finishes_within(fade.fade_in)).is_true()
	assert_bool(fade.is_covering()).is_false()
	assert_bool(fade.visible).is_false()
	assert_float(_title(fade).modulate.a).is_equal_approx(0.0, 0.01)


func test_fades_while_the_game_is_paused() -> void:
	var fade: ScreenFade = _new_fade()
	get_tree().paused = true
	assert_bool(await finishes_within(fade.fade_out)).is_true()
	assert_bool(fade.is_covering()).is_true()


func test_draws_above_the_question_panel() -> void:
	var fade: ScreenFade = _new_fade()
	var panel: CanvasLayer = (load("res://ui/confirm_panel.tscn") as PackedScene).instantiate() as CanvasLayer
	auto_free(panel)
	assert_int(fade.layer).is_greater(panel.layer)


func test_cover_now_blacks_the_screen_at_once_and_uncover_now_clears_it() -> void:
	var fade: ScreenFade = _new_fade()

	fade.cover_now()
	assert_bool(fade.is_covering()).is_true()

	fade.uncover_now()
	assert_bool(fade.is_covering()).is_false()
	assert_bool(fade.visible).is_false()
	assert_float(_title(fade).modulate.a).is_equal(0.0)


func test_a_fade_can_be_given_its_own_time() -> void:
	var fade: ScreenFade = _new_fade()
	# The usual time is far longer than the test waits.
	fade.fade_seconds = 60.0

	var out: bool = await finishes_within(func() -> void: await fade.fade_out(0.05))
	assert_bool(out).is_true()
	assert_bool(fade.is_covering()).is_true()

	var back: bool = await finishes_within(func() -> void: await fade.fade_in(0.05))
	assert_bool(back).is_true()
	assert_bool(fade.visible).is_false()


func _new_fade() -> ScreenFade:
	var fade: ScreenFade = (load(SCREEN_FADE_SCENE) as PackedScene).instantiate() as ScreenFade
	auto_free(fade)
	fade.fade_seconds = 0.01
	add_child(fade)
	return fade


func _title(fade: ScreenFade) -> Label:
	return fade.find_child("Title") as Label
