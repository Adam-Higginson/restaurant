extends GameTestSuite
## Tests for BookView, the open book you read in: it shows the open pages,
## turns them with left and right, closes with Interact or Cancel, holds the
## player still while it's open, and sets a page's words smaller when they
## wouldn't fit.

const VIEW_SCENE: String = "res://ui/book_view.tscn"


func test_it_starts_closed() -> void:
	var view: BookView = _new_view()

	assert_bool(view.is_open()).is_false()
	assert_bool(view.visible).is_false()
	assert_array(view.shown_text()).is_empty()


func test_opening_shows_the_first_two_pages() -> void:
	var view: BookView = _new_view()

	assert_bool(view.open(_book(3))).is_true()

	assert_bool(view.is_open()).is_true()
	assert_bool(view.visible).is_true()
	assert_array(view.shown_text()).contains_exactly(
			["Page 1", "Words of page 1.", "Page 2", "Words of page 2."])
	assert_str((view.get_node("%LeftNumber") as Label).text).is_equal("1")
	assert_str((view.get_node("%RightNumber") as Label).text).is_equal("2")


func test_turning_shows_the_next_pages_and_a_blank_one_after_the_last() -> void:
	var view: BookView = _new_view()
	view.open(_book(3))
	var turned: Array[int] = [0]
	view.page_turned.connect(func() -> void: turned[0] += 1)

	assert_bool(view.turn_forward()).is_true()
	assert_array(view.shown_text()).contains_exactly(["Page 3", "Words of page 3."])
	assert_str((view.get_node("%RightNumber") as Label).text).is_empty()
	assert_bool(view.turn_forward()).is_false()
	assert_int(turned[0]).is_equal(1)

	assert_bool(view.turn_back()).is_true()
	assert_array(view.shown_text()).contains(["Page 1"])
	assert_int(turned[0]).is_equal(2)


func test_another_book_cannot_open_over_an_open_one() -> void:
	var view: BookView = _new_view()
	view.open(_book(2))

	assert_bool(view.open(_book(4))).is_false()
	assert_int(view.reading.page_count()).is_equal(2)


func test_the_player_is_held_still_while_reading() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var view: BookView = _new_view(player.get_parent())
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	view.open(_book(2), player)
	assert_bool(player.controls_enabled).is_false()

	view.close()
	assert_bool(player.controls_enabled).is_true()
	assert_bool(view.is_open()).is_false()


func test_left_and_right_turn_and_interact_closes() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var view: BookView = _new_view(player.get_parent())
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	view.open(_book(4), player)
	await physics_ticks(runner, 2)

	await press(runner, "move_right")
	assert_int(view.reading.left_index).is_equal(2)
	await press(runner, "move_left")
	assert_int(view.reading.left_index).is_equal(0)

	await press(runner, "interact")
	assert_bool(view.is_open()).is_false()
	assert_bool(player.controls_enabled).is_true()


func test_cancel_closes_it_too() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var view: BookView = _new_view(player.get_parent())
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	view.open(_book(2), player)
	await physics_ticks(runner, 2)

	await press(runner, "ui_cancel")

	assert_bool(view.is_open()).is_false()


func test_it_fades_away_after_closing() -> void:
	var view: BookView = _new_view()
	view.open(_book(2))
	view.close()

	assert_bool(await wait_for_signal(view.visibility_changed, 1.0)).is_true()
	assert_bool(view.visible).is_false()


func test_a_full_page_is_set_smaller() -> void:
	var short: BookPage = BookPage.make("Short", PackedStringArray(["One line."]))
	var lines: PackedStringArray = PackedStringArray()
	for i: int in 6:
		lines.append("A longer line of words that runs over two lines of the page.")
	var full: BookPage = BookPage.make("Full", lines)

	assert_int(BookView.body_size_for(short)).is_equal(BookView.BODY_SIZES[0])
	assert_int(BookView.body_size_for(full)).is_less(BookView.BODY_SIZES[0])


func test_a_page_far_too_long_does_not_fit() -> void:
	var lines: PackedStringArray = PackedStringArray()
	for i: int in 30:
		lines.append("A line.")

	assert_bool(BookView.fits(BookPage.make("Too long", lines))).is_false()


# A book view added to [param parent] (the test suite if none): freed with it,
# or after the test.
func _new_view(parent: Node = null) -> BookView:
	var view: BookView = (load(VIEW_SCENE) as PackedScene).instantiate() as BookView
	if parent == null:
		add_child(view)
		auto_free(view)
	else:
		parent.add_child(view)
	return view


func _book(pages: int) -> Book:
	var book: Book = Book.new()
	for i: int in pages:
		book.pages.append(BookPage.make("Page %d" % (i + 1),
				PackedStringArray(["Words of page %d." % (i + 1)])))
	return book
