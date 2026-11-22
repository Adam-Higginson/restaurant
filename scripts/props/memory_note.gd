class_name MemoryNote
extends Node3D
## The folded note by your pillow, in your own hand. Read it (Interact) and
## the memories of home you've got back so far come back again, one after
## another, on the memory card. Before any have, it says only what you wrote
## the night you came aboard.

## What it says before you've remembered anything.
const BLANK_TITLE: String = "A note in your own hand"
const BLANK_LINES: PackedStringArray = [
	"Don't forget.",
	"Cook something. Catch something. It comes back.",
]

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(_player: Player3D) -> void: read())
	_reach.describe_interact = func(_player: Player3D) -> String: return "Read your note"


## Reads the note: shows every memory got back so far, in order, or the
## blank note's words if there are none yet. Returns how many cards it showed.
func read() -> int:
	var card: MemoryCard = get_tree().get_first_node_in_group(&"memory_card") as MemoryCard
	if card == null:
		return 0
	var memories: Array[Memory] = Game.memories.remembered_memories()
	if memories.is_empty():
		var blank: Memory = Memory.new()
		blank.title = BLANK_TITLE
		blank.lines = BLANK_LINES
		memories = [blank]
	for memory: Memory in memories:
		card.show_memory(memory)
	return memories.size()
