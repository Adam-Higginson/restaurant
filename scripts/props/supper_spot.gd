class_name SupperSpot
extends Node3D
## The little round table by the bunk room's stove, where the lantern lives:
## its [code]Perch[/code] is his home. Interact talks to him. Supper isn't
## shared here any more: it's set on the galley's long table and the bell is
## rung ([SupperTable], [DinnerBell], #207).

## The conversation Interact starts: a file in [code]data/dialogue[/code].
@export var talk: StringName = &"lantern"

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
