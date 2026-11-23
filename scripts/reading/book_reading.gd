class_name BookReading
extends RefCounted
## Which pages of a [Book] are open. Like a real book it lies open at two
## pages: the left one is always the 1st, 3rd, 5th... and turning the page
## moves on (or back) by two. With an odd number of pages, the last right-hand
## page is blank.
##
## Pure logic: the [BookView] shows what this says and plays the sounds.

## The book being read.
var book: Book:
	get:
		return _book

## The index in [member Book.pages] of the open left-hand page.
var left_index: int:
	get:
		return _left_index

var _book: Book = null
var _left_index: int = 0


func _init(open_book: Book) -> void:
	_book = open_book


## How many pages the book has.
func page_count() -> int:
	return _book.pages.size() if _book != null else 0


## The open left-hand page, or null if the book has no pages.
func left_page() -> BookPage:
	return _page_at(_left_index)


## The open right-hand page, or null if it's blank.
func right_page() -> BookPage:
	return _page_at(_left_index + 1)


## Which pair of pages is open, counting from 0.
func spread() -> int:
	@warning_ignore("integer_division")
	return _left_index / 2


## How many pairs of pages the book opens at: at least one, even if empty.
func spread_count() -> int:
	@warning_ignore("integer_division")
	return maxi(1, (page_count() + 1) / 2)


func can_turn_forward() -> bool:
	return _left_index + 2 < page_count()


func can_turn_back() -> bool:
	return _left_index > 0


## Turns to the next two pages. Returns whether it turned: not at the end.
func turn_forward() -> bool:
	if not can_turn_forward():
		return false
	_left_index += 2
	return true


## Turns back to the two pages before. Returns whether it turned: not at the
## start.
func turn_back() -> bool:
	if not can_turn_back():
		return false
	_left_index -= 2
	return true


func _page_at(index: int) -> BookPage:
	if index < 0 or index >= page_count():
		return null
	return _book.pages[index]
