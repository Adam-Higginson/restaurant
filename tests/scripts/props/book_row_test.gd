extends GameTestSuite
## Tests for a row of books on a shelf (#196): it fits its shelf, and the same
## shuffle always makes the same row.


func test_the_books_fit_the_row() -> void:
	var row: BookRow = _row(0.8, 1)
	assert_int(row.books.size()).is_greater(3)
	var last: ShelfBook = row.books[row.books.size() - 1]
	assert_float(last.position.x + last.depth() / 2.0).is_less_equal(0.8 + 0.05)
	for book: ShelfBook in row.books:
		assert_float(book.height).is_between(row.heights.x, row.heights.y)


func test_the_same_shuffle_makes_the_same_row() -> void:
	var first: BookRow = _row(0.8, 7)
	var again: BookRow = _row(0.8, 7)
	assert_int(again.books.size()).is_equal(first.books.size())
	for at: int in first.books.size():
		assert_that(again.books[at].cover).is_equal(first.books[at].cover)
		assert_float(again.books[at].height).is_equal(first.books[at].height)


func test_a_different_shuffle_makes_a_different_row() -> void:
	var first: BookRow = _row(0.8, 1)
	var other: BookRow = _row(0.8, 2)
	var same: bool = first.books.size() == other.books.size()
	if same:
		for at: int in first.books.size():
			same = same and first.books[at].height == other.books[at].height
	assert_bool(same).is_false()


func _row(length: float, shuffle: int) -> BookRow:
	var row: BookRow = BookRow.new()
	row.length = length
	row.shuffle = shuffle
	add_child(row)
	auto_free(row)
	return row
