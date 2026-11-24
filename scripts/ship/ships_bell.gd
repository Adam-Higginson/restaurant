class_name ShipsBell
extends Node3D
## The ship's bell in its belfry over the forecastle stairs. Pull its rope
## (Interact) and it rings: the bell swings hard and clangs. It used to heave
## the ship to; that went in #207 (the jolly boat will take you ashore
## instead, later), so for now it's just a bell to ring.

## Emitted each time the bell is rung.
signal rung

## How wide the bell swings when it's rung, in degrees.
@export var ring_degrees: float = 28.0

@onready var _bell: Swinging = $Bell
@onready var _rope: Interactable3D = $Rope
@onready var _sound: SoundSpot = $RingSound


func _ready() -> void:
	_rope.interacted.connect(func(_player: Player3D) -> void: ring())
	_rope.describe_interact = func(_player: Player3D) -> String: return prompt()


## Rings the bell: it swings hard and clangs.
func ring() -> void:
	_bell.kick(ring_degrees)
	_sound.play_now()
	rung.emit()


## What pulling the rope does, for the HUD.
func prompt() -> String:
	return "Ring the bell"
