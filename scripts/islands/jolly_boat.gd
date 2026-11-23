class_name JollyBoat
extends Node3D
## The ship's rowing boat: how you get between the ship at anchor and the
## shore. Interact with it and the screen fades, and you step out at the
## other end. There are two in an island scene, one on the ship's deck and
## one pulled up on the sand, each sending you to the other.
##
## The crossing itself isn't shown yet: the fade stands in for the row.

## Emitted when someone has made the crossing and stepped out.
signal crossed(player: Player3D)

## Where you step out at the other end, facing the way this node faces.
@export var destination: Node3D
## The fade that covers the crossing. Without one, you're there at once.
@export var fade: ScreenFade
## What the prompt says.
@export var prompt: String = "Row ashore"
## Seconds the screen takes to fade out, and to fade back in.
@export var fade_seconds: float = 0.7
## When set, the boat settles onto this island's ground at its spot when the
## scene starts (for the one on the beach), sunk this far into the sand.
@export var settle_on: IslandShape
@export var settle_sink: float = 0.1

var _crossing: bool = false

@onready var _reach: Interactable3D = $Reach


func _ready() -> void:
	if settle_on != null:
		global_position.y = settle_on.height_at(global_position.x, global_position.z) - settle_sink
	_reach.interacted.connect(func(player: Player3D) -> void: cross(player))
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt


## Whether someone is in the middle of a crossing.
func is_crossing() -> bool:
	return _crossing


## Takes [param player] across: fades out, puts them at the
## [member destination], fades back in. Call it with [code]await[/code] to
## wait for the whole crossing.
func cross(player: Player3D) -> void:
	if _crossing or destination == null:
		return
	_crossing = true
	player.controls_enabled = false
	if fade != null:
		await fade.fade_out(fade_seconds)
	Island.stand_at(player, destination)
	if fade != null:
		await fade.fade_in(fade_seconds)
	player.controls_enabled = true
	_crossing = false
	crossed.emit(player)
