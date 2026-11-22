class_name ShipsBell
extends Node3D
## The ship's bell in its belfry over the forecastle stairs. Pull its rope
## (Interact) and it rings: the bell swings hard, and the ship answers. Under
## way, she heaves to and eases to a stop; stopped, she gets under way again.
## It's how you tell the crew you're ready to sail (see Mooring in the GDD).
##
## It finds its ship by looking up the scene tree, so it works wherever the
## belfry sits aboard.

## Emitted each time the bell is rung.
signal rung

## How wide the bell swings when it's rung, in degrees.
@export var ring_degrees: float = 28.0

var _ship: Ship = null

@onready var _bell: Swinging = $Bell
@onready var _rope: Interactable3D = $Rope
@onready var _sound: SoundSpot = $RingSound


func _ready() -> void:
	_ship = _find_ship()
	_rope.interacted.connect(func(_player: Player3D) -> void: ring())
	_rope.describe_interact = func(_player: Player3D) -> String: return prompt()


## Rings the bell, and tells the ship to heave to or get under way.
func ring() -> void:
	_bell.kick(ring_degrees)
	_sound.play_now()
	if is_instance_valid(_ship):
		if _ship.is_sailing and not _ship.is_heaving_to:
			_ship.heave_to()
		else:
			_ship.get_under_way()
	rung.emit()


## What ringing would do now, for the HUD.
func prompt() -> String:
	if not is_instance_valid(_ship):
		return "Ring the bell"
	if _ship.is_sailing and not _ship.is_heaving_to:
		return "Ring the bell: heave to"
	return "Ring the bell: set sail"


func _find_ship() -> Ship:
	var node: Node = get_parent()
	while node != null:
		if node is Ship:
			return node as Ship
		node = node.get_parent()
	return null
