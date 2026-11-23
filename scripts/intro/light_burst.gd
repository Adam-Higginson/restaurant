class_name LightBurst
extends MeshInstance3D
## A burst of light spreading out through the water from where it stands:
## the lantern flaring back alight (drawn by shaders/light_burst.gdshader
## on a ball). A clip moves [member spread] from 0 to 1 and this grows the
## ball and fades it, quick at first and slowing, the way a flash goes.
##
## It's always drawn, at no brightness until it begins, so the game
## doesn't stop for a moment to prepare it when the flash comes.

## How far the burst has spread: 0 not begun (nothing shows), 1 spent.
@export_range(0.0, 1.0) var spread: float = 0.0:
	set(value):
		spread = clampf(value, 0.0, 1.0)
		_apply()
## How big the ball is when the burst is spent, in metres across.
@export var reach: float = 40.0
## How bright it is at its start.
@export var brightness: float = 1.6

var _material: ShaderMaterial = null


func _ready() -> void:
	_material = material_override as ShaderMaterial
	_apply()


## How big the ball is right now, in metres across: it shoots out and
## then slows.
func size_now() -> float:
	return reach * (1.0 - pow(1.0 - spread, 2.5))


## How bright it is right now: brightest as it starts, gone when it's spent.
func brightness_now() -> float:
	if spread <= 0.0:
		return 0.0
	return brightness * pow(1.0 - spread, 1.6)


## Whether there's any light to see: begun, and not yet spent.
func is_showing() -> bool:
	return spread > 0.0 and spread < 1.0


func _apply() -> void:
	scale = Vector3.ONE * maxf(size_now(), 0.01)
	if _material != null:
		_material.set_shader_parameter("brightness", brightness_now())
