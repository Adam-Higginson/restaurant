class_name LanternPerch
extends Node3D
## Where the lantern lives aboard (#206): on the little table by your bunk,
## so he's beside you when you wake. Its [code]Perch[/code] marker is his
## home (it's in [constant LanternSpirit.HOME_GROUP]), and Interact by it
## talks to him. Supper is shared at the round table ([SupperSpot]), and he
## comes over to it to eat.

## The conversation Interact starts: a file in [code]data/dialogue[/code].
@export var talk: StringName = &"lantern"

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(use)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


## What Interact would do, for the HUD.
func prompt() -> String:
	return "Talk to the lantern" if can_talk() else ""


## Whether there's a conversation to have here.
func can_talk() -> bool:
	return talk != &"" and Conversation.find(self) != null


## Talks to the lantern, for [param player].
func use(player: Player3D) -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and talk != &"":
		conversation.begin(talk, player)
