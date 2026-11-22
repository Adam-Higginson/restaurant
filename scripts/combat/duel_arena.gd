class_name DuelArena
extends Node3D
## The greybox duel arena: a patch of island with a landing, two fog-crabs
## and nothing else, for trying duels until an island can be sailed to
## (#67). Open [code]scenes/prototype/islands/duel_arena.tscn[/code] and
## press F6.
##
## It hands the player what they'd have brought ashore (a frying pan to
## parry with, and some food to lose), and gives the pan back after a defeat
## that took it, so there's always a way to parry here.

const PAN: Item = preload("res://data/items/frying_pan.tres")

## The player duelling here. Set in the scene.
@export var player: Player3D
## What the player carries at the start, besides their tools.
@export var start_items: Array[Item] = []

@onready var _duellist: Duellist = player.get_node("Duellist") as Duellist


func _ready() -> void:
	for item: Item in start_items:
		player.toolbar.add(ItemInstance.new(item))
	# Picking things up selects them: go back to the knife in the first slot.
	player.toolbar.select(0)
	_duellist.defeated.connect(_on_defeated)


func _on_defeated(_lost: Array[ItemInstance]) -> void:
	if not _duellist.has_pan():
		var selected: int = player.toolbar.selected_index
		player.toolbar.add(ItemInstance.new(PAN))
		player.toolbar.select(selected)
