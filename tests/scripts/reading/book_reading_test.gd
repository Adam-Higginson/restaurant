extends GameTestSuite
## Tests for BookReading, which pages of a book lie open: two at a time,
## turning forward and back, and stopping at both covers.


func test_it_opens_at_the_first_two_pages() -> void:
	var reading: BookReading = BookReading.new(_book(4))

	assert_int(reading.left_index).is_equal(0)
	assert_str(reading.left_page().heading).is_equal("Page 1")
	assert_str(reading.right_page().heading).is_equal("Page 2")
	assert_int(reading.spread()).is_equal(0)
	assert_int(reading.spread_count()).is_equal(2)


func test_turning_forward_and_back_moves_two_pages() -> void:
	var reading: BookReading = BookReading.new(_book(4))

	assert_bool(reading.turn_forward()).is_true()
	assert_str(reading.left_page().heading).is_equal("Page 3")
	assert_str(reading.right_page().heading).is_equal("Page 4")
	assert_int(reading.spread()).is_equal(1)

	assert_bool(reading.turn_back()).is_true()
	assert_str(reading.left_page().heading).is_equal("Page 1")


func test_it_stops_at_both_covers() -> void:
	var reading: BookReading = BookReading.new(_book(4))

	assert_bool(reading.can_turn_back()).is_false()
	assert_bool(reading.turn_back()).is_false()
	assert_int(reading.left_index).is_equal(0)

	reading.turn_forward()
	assert_bool(reading.can_turn_forward()).is_false()
	assert_bool(reading.turn_forward()).is_false()
	assert_int(reading.left_index).is_equal(2)


func test_an_odd_last_page_has_a_blank_one_beside_it() -> void:
	var reading: BookReading = BookReading.new(_book(3))

	assert_int(reading.spread_count()).is_equal(2)
	assert_bool(reading.turn_forward()).is_true()
	assert_str(reading.left_page().heading).is_equal("Page 3")
	assert_object(reading.right_page()).is_null()
	assert_bool(reading.can_turn_forward()).is_false()


func test_a_single_page_book_cannot_turn_at_all() -> void:
	var reading: BookReading = BookReading.new(_book(1))

	assert_object(reading.right_page()).is_null()
	assert_bool(reading.can_turn_forward()).is_false()
	assert_bool(reading.can_turn_back()).is_false()


func test_an_empty_book_opens_on_blank_pages() -> void:
	var reading: BookReading = BookReading.new(_book(0))

	assert_object(reading.left_page()).is_null()
	assert_object(reading.right_page()).is_null()
	assert_int(reading.spread_count()).is_equal(1)
	assert_bool(reading.turn_forward()).is_false()


func test_a_marked_book_falls_open_at_the_pair_holding_its_page() -> void:
	var book: Book = _book(6)
	book.opens_at = 3

	var reading: BookReading = BookReading.new(book)

	assert_int(reading.left_index).is_equal(2)
	assert_str(reading.right_page().heading).is_equal("Page 4")


func test_a_mark_past_the_end_opens_at_the_start() -> void:
	var book: Book = _book(2)
	book.opens_at = 9

	assert_int(BookReading.new(book).left_index).is_equal(0)


func _book(pages: int) -> Book:
	var book: Book = Book.new()
	for i: int in pages:
		book.pages.append(BookPage.make("Page %d" % (i + 1), PackedStringArray(["Words."])))
	return book
