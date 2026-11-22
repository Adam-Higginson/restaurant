class_name NameGilt
extends MeshInstance3D
## The ship's name on her stern, in worn gilt that only shows where light
## catches it (shaders/nameboard_gilt.gdshader). The lantern swinging on the
## hook lights a few letters at a time as it passes; lightning shows the
## whole name for an instant; and when the lantern's gone, her name is dark.

## The lamp that lights the letters: the lantern on the hook. While it's
## hidden, nothing lights them.
@export var lamp: Node3D
## The lamp's face, if it has one: a weaker flame lights the letters less.
@export var lamp_face: LanternFace
## How far the lamp's light reaches along the letters, in metres.
@export var reach: float = 1.15

var _flash: float = 0.0


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)


func _process(_delta: float) -> void:
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("lamp_glow", lamp_glow())
	material.set_shader_parameter("reach", reach)
	material.set_shader_parameter("flash", _flash)
	if is_instance_valid(lamp):
		material.set_shader_parameter("lamp", lamp.global_position)


## How brightly the lamp lights the letters now, 0 to 1: nothing with no
## lamp or a hidden one, and less as its flame weakens.
func lamp_glow() -> float:
	if not is_instance_valid(lamp) or not lamp.is_visible_in_tree():
		return 0.0
	if is_instance_valid(lamp_face):
		return lerpf(0.2, 1.0, lamp_face.strength)
	return 1.0


## How bright the lightning is now: 0 dark, 1 the brightest moment.
func set_lightning(brightness: float) -> void:
	_flash = clampf(brightness, 0.0, 1.0)
