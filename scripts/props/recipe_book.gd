class_name RecipeBook
extends Node3D
## The recipe book, a small battered thing lying on the lantern's table by
## your bunk when you wake (#184; the lantern tells you it's there, #206).
## Pick it up (Interact) and it plays the cutscene [constant CUTSCENE]
## ([code]data/dialogue/recipe_book.dlg[/code]): you hold it up, it's yours
## (the flag [code]has_recipe_book[/code] puts it on your toolbar), and the
## lantern asks if you're a cook. It doesn't open there: you read it later.
## After that it's gone from the table: you carry it, and select it on the
## toolbar and Use it to read it wherever you are.
##
## [method open_book] opens it in the [BookView]: a page for each dish the
## galley knows, and how to make it.

## The cutscene picking it up plays.
const CUTSCENE: StringName = &"recipe_book"
## The flag that says it's yours (see [member HandTool.owned_flag]).
const OWNED_FLAG: StringName = &"has_recipe_book"

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: pick_up(player))
	_reach.describe_interact = func(_player: Player3D) -> String: return "Pick up the book"
	Game.dialogue.flag_changed.connect(func(flag: StringName, _value: int) -> void:
		if flag == OWNED_FLAG:
			_show_if_left())
	_show_if_left()


## Picks it up for [param player]: plays its cutscene. Returns whether it
## started (not if it's already yours, or a conversation is on).
func pick_up(player: Player3D) -> bool:
	if is_taken():
		return false
	var conversation: Conversation = Conversation.find(self)
	if conversation == null or conversation.is_active():
		return false
	return conversation.play(CUTSCENE, player)


## Whether you've picked it up: it's yours, and no longer on the table.
func is_taken() -> bool:
	return Game.dialogue.is_set(OWNED_FLAG)


## Opens the recipe book in the book view nearest [param from], for
## [param player]. Returns how many pages it has, or 0 if it couldn't be
## opened (no book view, or a book already open).
static func open_book(from: Node, player: Player3D = null) -> int:
	var view: BookView = BookView.find(from)
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


# On the table until it's yours.
func _show_if_left() -> void:
	visible = not is_taken()
	_reach.enabled = not is_taken()
