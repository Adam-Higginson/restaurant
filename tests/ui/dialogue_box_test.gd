extends GameTestSuite
## Tests for the dialogue box: words typing out, the name plate, highlighted
## words, and a list of replies that grows to four and then scrolls.

const BOX: PackedScene = preload("res://ui/dialogue_box.tscn")


func test_it_starts_hidden_and_shows_with_a_line() -> void:
	var box: DialogueBox = _new_box()
	assert_bool(box.visible).is_false()

	box.show_line(_captain(), "Hm.")

	assert_bool(box.visible).is_true()
	assert_str(box.speaker_name()).is_equal("Captain")


func test_a_narrator_has_no_name_plate() -> void:
	var box: DialogueBox = _new_box()

	box.show_line(null, "The stove ticks.")

	assert_str(box.speaker_name()).is_empty()


func test_words_type_out_over_time() -> void:
	var box: DialogueBox = _new_box()
	box.letters_per_second = 20.0

	box.show_line(_captain(), "Bit of a rough night out there.")
	await _ticks(15)
	var some: int = box.shown_text().length()
	assert_bool(box.is_typing()).is_true()
	assert_int(some).is_between(1, 20)

	await _ticks(120)
	assert_bool(box.is_typing()).is_false()
	assert_str(box.shown_text()).is_equal("Bit of a rough night out there.")


func test_finishing_shows_the_rest_at_once_and_says_so() -> void:
	var box: DialogueBox = _new_box()
	box.letters_per_second = 1.0
	var typed: Array[int] = [0]
	box.typed.connect(func() -> void: typed[0] += 1)
	box.show_line(_captain(), "Hm. Go on, then.")

	box.finish_typing()
	box.finish_typing()

	assert_str(box.shown_text()).is_equal("Hm. Go on, then.")
	assert_int(typed[0]).is_equal(1)


func test_each_letter_is_announced_as_it_appears() -> void:
	var box: DialogueBox = _new_box()
	box.letters_per_second = 30.0
	var letters: PackedStringArray = PackedStringArray()
	box.letter_typed.connect(func(letter: String) -> void: letters.append(letter))

	box.show_line(_captain(), "Hm ok")
	await _ticks(40)

	assert_str("".join(letters)).is_equal("Hm ok")


func test_starred_words_are_highlighted_and_brackets_survive() -> void:
	var marked: String = DialogueBox.to_bbcode("Mind the *wet planks* [by the hatch].")

	assert_str(marked).contains("[color=#").contains("wet planks[/color]")
	assert_str(marked).contains("[lb]by the hatch]")
	assert_str(marked).not_contains("*")


func test_pause_after_is_never_negative() -> void:
	for letter: String in ["a", " ", ",", ".", "!", "?", "…", ""]:
		assert_float(DialogueBox.pause_after(letter)).is_greater_equal(0.0)


func test_up_to_four_choices_all_show_and_the_box_grows_for_the_fourth() -> void:
	var box: DialogueBox = _new_box()
	box.show_line(_captain(), "Well?")
	var short: float = box.size.y

	box.show_choices(PackedStringArray(["One", "Two", "Three", "Four"]))

	assert_int(box.shown_count()).is_equal(4)
	assert_array(box.shown_choices()).contains_exactly(["One", "Two", "Three", "Four"])
	assert_float(box.size.y).is_greater(short)

	box.show_line(_captain(), "Hm.")
	assert_float(box.size.y).is_equal_approx(short, 0.01)


func test_a_longer_list_scrolls_to_keep_the_cursor_in_view() -> void:
	var box: DialogueBox = _new_box()
	box.show_choices(PackedStringArray(["One", "Two", "Three", "Four", "Five", "Six"]))
	assert_array(box.shown_choices()).contains_exactly(["One", "Two", "Three", "Four"])

	box.select(4)
	assert_array(box.shown_choices()).contains_exactly(["Two", "Three", "Four", "Five"])

	box.select(5)
	box.select(2)
	assert_array(box.shown_choices()).contains_exactly(["Three", "Four", "Five", "Six"])

	box.select(0)
	assert_array(box.shown_choices()).contains_exactly(["One", "Two", "Three", "Four"])


func test_select_wraps_round_at_either_end() -> void:
	var box: DialogueBox = _new_box()
	box.show_choices(PackedStringArray(["One", "Two", "Three"]))

	box.select(-1)
	assert_int(box.selected).is_equal(2)
	box.select(3)
	assert_int(box.selected).is_equal(0)


func test_first_shown_for_moves_only_as_far_as_it_must(chosen: int, first: int, expected: int,
		test_parameters: Array = [
			[0, 0, 0],
			[3, 0, 0],
			[4, 0, 1],
			[5, 1, 2],
			[2, 2, 2],
			[1, 2, 1],
		]) -> void:
	assert_int(DialogueBox.first_shown_for(chosen, first, 4)).is_equal(expected)


func test_close_puts_it_away() -> void:
	var box: DialogueBox = _new_box()
	box.show_line(_captain(), "Hm.")

	box.close()

	assert_bool(box.visible).is_false()
	assert_bool(box.is_typing()).is_false()


func _ticks(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _new_box() -> DialogueBox:
	var layer: CanvasLayer = CanvasLayer.new()
	auto_free(layer)
	var box: DialogueBox = BOX.instantiate() as DialogueBox
	layer.add_child(box)
	add_child(layer)
	return box


func _captain() -> Person:
	return Catalog.load_default().find_person(&"heron")
