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


func test_show_title_shows_the_text() -> void:
	var fade: ScreenFade = _new_fade()
	await finishes_within(fade.fade_out)
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


func _new_fade() -> ScreenFade:
	var fade: ScreenFade = (load(SCREEN_FADE_SCENE) as PackedScene).instantiate() as ScreenFade
	auto_free(fade)
	fade.fade_seconds = 0.01
	add_child(fade)
	return fade


func _title(fade: ScreenFade) -> Label:
	return fade.find_child("Title") as Label
