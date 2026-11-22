class_name SurfaceGlow
extends MeshInstance3D
## The light of the sea's surface overhead in the underwater set (drawn by
## shaders/sea_underside.gdshader). It dims as you sink ([member glow], which
## a clip moves) and flares whenever the storm's lightning strikes, because
## it joins the group [Lightning] tells about every flash.

## How bright the surface is: 1 near it, less the deeper you are.
@export_range(0.0, 2.0) var glow: float = 1.0:
	set(value):
		glow = value
		_apply()

var _flash: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	_apply()


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
	_apply()


func _apply() -> void:
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("glow", glow)
	material.set_shader_parameter("flash", _flash)
