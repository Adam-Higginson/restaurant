class_name SplashRing
extends MeshInstance3D
## The ring of foam that spreads across the water where something has gone
## in (drawn by shaders/splash_ring.gdshader on a sheet lying on the
## surface). A clip moves [member spread] from 0 to 1; nothing shows before
## it begins or once it's spent.

## How far the ring has spread: 0 not begun, 1 spent.
@export_range(0.0, 1.0) var spread: float = 0.0:
	set(value):
		spread = clampf(value, 0.0, 1.0)
		_apply()


func _ready() -> void:
	_apply()


## Whether there's any foam to see.
func is_showing() -> bool:
	return spread > 0.0 and spread < 1.0


func _apply() -> void:
	visible = is_showing()
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("spread", spread)
