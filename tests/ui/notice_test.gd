extends GameTestSuite
## Tests for Notice, the short note that fades away by itself.

const NOTICE_SCENE: String = "res://ui/notice.tscn"


func test_starts_hidden() -> void:
	var notice: Notice = _new_notice()
	assert_bool(notice.is_showing()).is_false()


func test_show_message_shows_the_text() -> void:
	var notice: Notice = _new_notice()
	notice.show_message("Getting late…")
	assert_bool(notice.is_showing()).is_true()
	assert_str(notice.text).is_equal("Getting late…")


func test_hides_by_itself_after_a_while() -> void:
	var notice: Notice = _new_notice()
	notice.show_message("Getting late…")
	await get_tree().create_timer(0.3).timeout
	assert_bool(notice.is_showing()).is_false()


func test_a_new_message_replaces_the_old_one() -> void:
	var notice: Notice = _new_notice()
	notice.show_seconds = 0.3
	notice.show_message("First")
	await get_tree().create_timer(0.2).timeout
	notice.show_message("Second")
	# The first note would have gone by now, but the second starts its own time.
	await get_tree().create_timer(0.2).timeout
	assert_bool(notice.is_showing()).is_true()
	assert_str(notice.text).is_equal("Second")


func test_dismiss_hides_it_straight_away() -> void:
	var notice: Notice = _new_notice()
	notice.show_message("Getting late…")
	notice.dismiss()
	assert_bool(notice.is_showing()).is_false()
	# And it doesn't pop back up when the old fade would have finished.
	await get_tree().create_timer(0.3).timeout
	assert_bool(notice.is_showing()).is_false()


func _new_notice() -> Notice:
	var notice: Notice = (load(NOTICE_SCENE) as PackedScene).instantiate() as Notice
	auto_free(notice)
	notice.fade_seconds = 0.01
	notice.show_seconds = 0.05
	add_child(notice)
	return notice
