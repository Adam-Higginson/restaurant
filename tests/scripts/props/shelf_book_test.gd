extends GameTestSuite
## Tests for one book on a shelf (#196): its size, and that it's drawn whether
## or not the Meshy book is on this computer.


func test_a_taller_or_thicker_book_takes_more_shelf() -> void:
	var book: ShelfBook = ShelfBook.new()
	auto_free(book)
	book.height = 0.24
	var usual: float = book.depth()
	book.height = 0.3
	assert_float(book.depth()).is_greater(usual)
	book.height = 0.24
	book.thickness = 1.5
	assert_float(book.depth()).is_equal_approx(usual * 1.5, 0.0001)


func test_its_drawn_with_or_without_the_art() -> void:
	var book: ShelfBook = ShelfBook.new()
	add_child(book)
	auto_free(book)
	assert_int(book.get_child_count(true)).is_equal(1)
