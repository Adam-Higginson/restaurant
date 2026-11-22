class_name ThingEye
extends MeshInstance3D
## The eye of the thing that passes beneath you in the underwater set
## (drawn by shaders/thing_eye.gdshader on a sheet lying on its head). It
## gives no light of its own. A clip opens it ([member open]); it shows
## only while lightning is on it, and for a moment after as the flash dies,
## so the last thing the flash leaves you with is that it was looking.

## How far its lids are open: 0 shut, 1 wide. A clip moves it.
@export_range(0.0, 1.0) var open: float = 0.0:
	set(value):
		open = clampf(value, 0.0, 1.0)
		_apply()
## How long it stays visible after a flash is over, in seconds.
@export var linger_seconds: float = 0.5

## How bright the lightning is right now, 0 to 1.
var _flash: float = 0.0
## The light still on it: follows the flash up at once, and dies away after.
var _shine: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	_apply()


func _process(delta: float) -> void:
	fade(delta)


## How much light is on it right now, 0 to 1.
func shine() -> float:
	return _shine


## Whether there's anything of it to see: open, and with light on it.
func is_showing() -> bool:
	return open > 0.001 and _shine > 0.001


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
	_shine = maxf(_shine, _flash)
	_apply()


## Lets the light on it die away for [param delta] seconds: never below
## what the lightning is giving it right now.
func fade(delta: float) -> void:
	var gone: float = delta / linger_seconds if linger_seconds > 0.0 else 1.0
	_shine = maxf(_shine - gone, _flash)
	_apply()


func _apply() -> void:
	visible = is_showing()
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("open", open)
	material.set_shader_parameter("shine", _shine)
