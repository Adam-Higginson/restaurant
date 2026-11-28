class_name RecipeBook
extends Node3D
## The recipe book, a small battered thing lying on the lantern's table by
## your bunk when you wake (#184; the lantern tells you it's there, #206).
## Pick it up (Interact) and it plays the cutscene [constant CUTSCENE]
## ([code]data/dialogue/recipe_book.dlg[/code]): you hold it up, it's yours
## (the saved flag [code]has_recipe_book[/code] unlocks the Journal action).
## The journal opens after the conversation and can be reopened during play.
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
	conversation.ended.connect(func(_id: StringName) -> void:
		if is_instance_valid(player) and is_taken():
			RecipeBook.open_journal.call_deferred(player), CONNECT_ONE_SHOT)
	return conversation.play(CUTSCENE, player)


## Opens the player's Voyage and Recipes pages without using a toolbar slot.
static func open_journal(player: Player3D) -> void:
	var view: BookView = BookView.find(player)
	if view != null and player.controls_enabled:
		view.open(make_journal(), player)


## Builds today's pages from the milestones already recorded by the voyage.
static func make_journal() -> Book:
	var state: DialogueState = Game.dialogue
	var next: String = "Find the captain at the wheel."
	var entries: PackedStringArray = [
		"The soup recipe is in my handwriting. Lantern asked if I was a cook. "
		+ "I wish I'd said yes. It would be nice to know I could do something for him."
	]
	if state.is_set(&"has_saucepan"):
		next = "Read the old cookbook by the galley stove."
		entries.append("The captain gave me a pot and told me where to look. Then he asked "
				+ "if Lantern had managed to get off the table yet. I said he'd tried.")
	if state.is_set(&"read_fire_spirits"):
		next = "Find fresh water for the soup."
		entries.append("The cookbook says a little fire. I've put chilli in stranger things. "
				+ "Or at least whoever wrote these recipes has.")
		if state.is_set(&"asked_fresh_water"):
			next = "Fill the pot at the rain barrel on deck."
		if state.is_set(&"fetched_water"):
			next = "Make spicy tomato soup in the galley."
		if state.is_set(&"served_plain_soup"):
			next = "Heat the plain soup again with chopped chilli."
		if state.is_set(&"cooked_remedy"):
			next = "Set a bowl at Lantern's place and ring the galley bell."
	if state.is_set(&"warmed_lantern"):
		next = "Lantern is warm again."
		entries.append("I was looking at the captain when the light came back. "
				+ "I saw it on his face first.")
	if not state.is_set(&"has_saucepan") and not state.is_set(&"warmed_lantern"):
		next = "Find the captain at the wheel."
	var book: Book = Book.new()
	book.title = "Journal"
	book.pages.append(BookPage.make("Voyage · A Little Warmth", PackedStringArray(["Next · " + next, entries[0]])))
	var recent: PackedStringArray = entries.slice(1)
	book.pages.append(BookPage.make("Voyage", recent))
	book.pages.append(BookPage.make("Recipes", PackedStringArray([
		"Some of these are mine. Some I've picked up since I came aboard."
	])))
	var recipes: Array[Recipe] = Catalog.load_default().recipes
	for recipe: Recipe in recipes:
		if recipe.id == &"spicy_tomato_soup" and not state.is_set(&"read_fire_spirits"):
			continue
		var steps: PackedStringArray = recipe.steps.duplicate()
		if recipe.id == &"tomato_soup":
			steps.insert(0, "If I'm in a hurry, everything can go in cold. I always think I'll "
					+ "get away with it. I can always taste it.")
		book.pages.append(BookPage.make(recipe.title, steps))
	return book


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
