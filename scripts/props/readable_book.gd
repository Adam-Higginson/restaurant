class_name ReadableBook
extends Node3D
## A book in the world you can read (Interact): it opens [member book] in the
## [BookView]. Reading it can set a flag, so the story knows you have (the
## old book on fire spirits sets [code]read_fire_spirits[/code], #159).

## The book it opens.
@export var book: Book
## What the Interact prompt says.
@export var prompt: String = "Read the book"
## A flag set in [member GameState.dialogue] when it's read, or none.
@export var read_flag: StringName = &""

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: read(player))
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt


## Opens the book for [param player]. Returns whether it opened: not with no
## book view, or a book already open.
func read(player: Player3D = null) -> bool:
	var view: BookView = BookView.find(self)
	if view == null or not view.open(book, player):
		return false
	if read_flag != &"":
		Game.dialogue.set_flag(read_flag)
	return true
