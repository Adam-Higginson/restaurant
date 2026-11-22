class_name Porthole
extends Node3D
## A round brass porthole onto the storm. Cold moonlight spills in through it,
## and when [Lightning] flashes, the glass lights up and the room is lit blue
## for a moment.

## How much brighter the moonlight gets at the brightest moment of a flash.
@export var flash_energy: float = 10.0

## The moonlight's own brightness, between flashes.
var base_energy: float = 0.0

@onready var _moonlight: SpotLight3D = $Moonlight
@onready var _glass: GeometryInstance3D = $Glass


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	base_energy = _moonlight.light_energy


## Shows a flash of [param brightness], from 0 (none) to 1 (the brightest).
## Called by [Lightning].
func set_lightning(brightness: float) -> void:
	_moonlight.light_energy = base_energy + flash_energy * brightness
	_glass.set_instance_shader_parameter(&"flash", brightness)
