class_name Inspectable
extends Node3D
## Something you can look at, and nothing more (#185): Interact says
## "Look at the chart" and plays a few lines about it, from the section
## [member lines] of [code]data/dialogue/look.dlg[/code]. The first is the
## navigation room's chart; the galley's stove and shelves can follow.
##
## Its first child of its own called [code]Reach[/code] (an [Interactable3D])
## is where you stand to look.

## The file of things to look at.
const CUTSCENE: StringName = &"look"

## What it is, after "Look at": [code]the chart[/code].
@export var what: String = "the chart"
## The section of look.dlg it plays.
@export var lines: StringName = &""

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	_reach.interacted.connect(func(player: Player3D) -> void: look(player))
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


## What Interact says: "Look at the chart".
func prompt() -> String:
	return "Look at %s" % what


## Plays its lines for [param player]. Returns whether they started (not if
## a conversation is already on).
func look(player: Player3D) -> bool:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null or conversation.is_active():
		return false
	return conversation.play(CUTSCENE, player, lines)
