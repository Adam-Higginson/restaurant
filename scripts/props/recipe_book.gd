class_name RecipeBook
extends Node3D
## The galley's recipe book, open on the crew table. Read it (Interact) and it
## opens in the [BookView]: a page for each dish the galley knows, and how to
## make it.

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: read(player))
	_reach.describe_interact = func(_player: Player3D) -> String: return "Read the recipe book"


## Opens the book for [param player]. Returns how many pages it has, or 0 if
## it couldn't be opened (no book view, or a book already open).
func read(player: Player3D = null) -> int:
	var view: BookView = BookView.find(self)
	if view == null:
		return 0
	var book: Book = make_book(Catalog.load_default().recipes)
	return book.pages.size() if view.open(book, player) else 0


## The recipe book's pages: one for each of [param recipes], headed with its
## title, with its steps beneath.
static func make_book(recipes: Array[Recipe]) -> Book:
	var book: Book = Book.new()
	book.title = "Recipes"
	for recipe: Recipe in recipes:
		book.pages.append(BookPage.make(recipe.title, recipe.steps))
	return book
