class_name BookCues
extends CueHandler
## Books in cutscenes (#184). [code]@read recipe_book[/code] opens the recipe
## book in the book view and holds the script until it's closed, so what
## comes next waits until you've had your look. Skipped, it isn't opened.

## The books a script can open, by the name it uses.
const BOOKS: Array[String] = ["recipe_book"]

## Who's reading.
@export var player: Player3D


func cues() -> Array[StringName]:
	return [&"read"]


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	if not BOOKS.has(args[0]):
		warn("no book called '%s' (the books: %s)" % [args[0], ", ".join(BOOKS)])
		return
	if is_skipping():
		return
	var view: BookView = BookView.find(self)
	if view == null:
		return
	var held: int = hold()
	if RecipeBook.open_book(self, player) == 0:
		release(held)
		return
	while is_holding(held) and is_instance_valid(view) and view.is_open():
		await get_tree().process_frame
	release(held)


func _on_skip_started() -> void:
	var view: BookView = BookView.find(self)
	if view != null and view.is_open():
		view.close()
