class_name SupperSpot
extends Node3D
## The little round table by the bunk room's stove. The lantern used to live
## here; he lives by your bunk now ([LanternPerch], #206) and is talked to
## there, and supper is set on the galley's long table and the bell rung
## ([SupperTable], [DinnerBell], #207). With [member talk] set, Interact
## here talks to him; it's off on the ship.

## The conversation Interact starts: a file in [code]data/dialogue[/code], or
## none.
@export var talk: StringName = &""

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(use)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


## What Interact would do, for the HUD: "Talk to the lantern", or "".
func prompt() -> String:
	return "Talk to the lantern" if can_talk() else ""


## Whether there's a conversation to have here.
func can_talk() -> bool:
	return talk != &"" and Conversation.find(self) != null


## What Interact does: talks to the lantern.
func use(player: Player3D) -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and talk != &"":
		conversation.begin(talk, player)
