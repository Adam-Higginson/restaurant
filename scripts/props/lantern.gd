class_name Lantern
extends Swinging
## A ship's lantern hanging from its hook: an iron frame and cap around
## glowing panes, with a warm light inside. It swings like any [Swinging]
## thing. One scene (lantern.tscn) is used for every lantern aboard; each
## sets how bright and how far its light reaches.

## How bright the lantern's light is.
@export var light_energy: float = 1.4
## How far its light reaches, in metres.
@export var light_range: float = 7.0

@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	super()
	_light.light_energy = light_energy
	_light.omni_range = light_range
