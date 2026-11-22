class_name LightningShafts
extends Node3D
## Shafts of lightning coming down through the water in the underwater set.
## Its children are the shafts: tall tubes that all share one material
## (shaders/light_shaft.gdshader). It joins the group [Lightning] tells
## about every flash and makes them as bright as the flash is, so between
## flashes there's nothing there.

## How bright the lightning is right now, 0 to 1.
var flash: float:
	get:
		return _flash

var _flash: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	set_lightning(0.0)


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
	visible = _flash > 0.001
	for child: Node in get_children():
		var shaft: GeometryInstance3D = child as GeometryInstance3D
		if shaft == null:
			continue
		var material: ShaderMaterial = shaft.material_override as ShaderMaterial
		if material != null:
			material.set_shader_parameter("flash", _flash)
