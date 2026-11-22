class_name CarvedName
extends MeshInstance3D
## The ship's name, chiselled into a plank at her stern
## (shaders/carved_name.gdshader). The plank is this mesh; the letters are
## cut into it by the shader, which needs a picture of the name to know
## where to cut. That picture is drawn here: the [code]Mask[/code] child is a
## small off-screen screen with the name written on it in white on black.
## Change [member text] and the carving changes.
##
## The shader is told where the lantern on the hook is, and lights the cuts
## from there: the wall of each letter facing him is bright, the far wall
## dark, with its shadow across the floor of the cut, all swinging round as
## he passes. So the name isn't quite lost when he swings away, the grooves
## hold a faint ember glow; when he's gone from the hook only that is left,
## and the dull light of the sky from above.

## What's carved. Capitals suit the font.
@export var text: String = "SALT AND EMBER":
	set(value):
		text = value
		_write()
## The lamp whose warmth the grooves take up: the lantern on the hook.
## While it's hidden, they don't.
@export var lamp: Node3D
## The lamp's face, if it has one: a weaker flame warms the grooves less.
@export var lamp_face: LanternFace
## How far the lamp's light reaches along the letters, in metres.
@export var reach: float = 1.3

var _flash: float = 0.0

@onready var _mask: SubViewport = $Mask
@onready var _words: Label = $Mask/Words


func _ready() -> void:
	add_to_group(Lightning.LIT_GROUP)
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter("mask", _mask.get_texture())
	_write()


func _process(_delta: float) -> void:
	var material: ShaderMaterial = material_override as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("lamp_glow", lamp_glow())
	material.set_shader_parameter("reach", reach)
	material.set_shader_parameter("flash", _flash)
	if is_instance_valid(lamp):
		# In the plank's own space, so it works whichever way the ship faces.
		material.set_shader_parameter("lamp", to_local(lamp.global_position))


## How strongly the lamp warms the grooves now, 0 to 1: nothing with no
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


## What's written on the mask the carving is cut from.
func written() -> String:
	return _words.text if is_node_ready() else text


# Writes the name on the mask and has it drawn once: it only needs
# drawing again when the words change.
func _write() -> void:
	if not is_node_ready():
		return
	_words.text = text
	_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
