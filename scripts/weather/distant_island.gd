class_name DistantIsland
extends Node3D
## An island far off in the fog, seen only as a silhouette: nearly nothing at
## night (just its light), a ghostly shape at dawn. [TimeOfDay] tells it how
## much shows. Its meshes share one silhouette material.

## How much shows at night, and at dawn.
@export var night_reveal: float = 0.05
@export var dawn_reveal: float = 0.55
## The silhouette material its meshes use.
@export var silhouette: ShaderMaterial

## How much shows now, 0 to 1.
var reveal: float:
	get:
		return _reveal

var _reveal: float = 0.0


func _ready() -> void:
	add_to_group(&"distant")
	set_dawn(0.0)


## How far night has turned to dawn, 0 to 1: shows that much of it.
func set_dawn(dawn: float) -> void:
	_reveal = lerpf(night_reveal, dawn_reveal, clampf(dawn, 0.0, 1.0))
	if silhouette != null:
		silhouette.set_shader_parameter("reveal", _reveal)
