@tool
class_name CharacterStyle
extends Resource
## The stylised look for characters (#168): soft cel shading with warm
## shadows, a rim of light and a dark outline. One of these is shared by every
## character drawn with it (data/art/styles/character.tres), so the whole cast
## is tuned in one place, and changes show at once, in the editor and in game.
##
## A [ThirdPartyModel] with a [member ThirdPartyModel.style] gives each of its
## surfaces a material made by [method make_material]: the stylised shader with
## that surface's own texture and colour, and the outline as its next pass.
## docs/look.md says what each setting does to the picture.

const SHADER: Shader = preload("res://shaders/stylised_character.gdshader")
const OUTLINE_SHADER: Shader = preload("res://shaders/outline.gdshader")

@export_group("Colour")
## Multiplies every character's own colours.
@export var base_tint: Color = Color.WHITE:
	set(value):
		base_tint = value
		emit_changed()
## The colour the shadow side is lit with, as a share of the light. A cool
## lavender keeps shadows rich and lets the warm sun read against them.
@export var shadow_color: Color = Color(0.46, 0.44, 0.58):
	set(value):
		shadow_color = value
		emit_changed()
## How much of the world's ambient light reaches the character, 0 to 1. Lower
## leans on the lamps and the sun, for stronger shapes.
@export_range(0.0, 1.0) var ambient_strength: float = 0.75:
	set(value):
		ambient_strength = value
		emit_changed()

@export_group("Shading")
## Where light turns to shadow: 0 is side-on to the light, higher puts more of
## the body in shadow.
@export_range(-1.0, 1.0) var shadow_threshold: float = 0.05:
	set(value):
		shadow_threshold = value
		emit_changed()
## How soft the light/shadow edge is: 0 is a hard cut.
@export_range(0.0, 0.5) var shadow_softness: float = 0.04:
	set(value):
		shadow_softness = value
		emit_changed()
## How much the lit side still dims as it turns from the light: 0 is flat cel
## colour, higher keeps some roundness inside the light.
@export_range(0.0, 1.0) var lit_falloff: float = 0.35:
	set(value):
		lit_falloff = value
		emit_changed()
## Steps from shadow to full light: 1 is two-tone, 3 or 4 is Wind Waker-ish.
@export_range(1, 4) var bands: int = 1:
	set(value):
		bands = value
		emit_changed()

@export_group("Brush")
## How far the edge between light and shadow is broken up into painted
## strokes, as hand-painted anime shading is (0 is a clean line).
@export_range(0.0, 1.0) var brush_strength: float = 0.0:
	set(value):
		brush_strength = value
		emit_changed()
## How many strokes fit across the texture: more is finer.
@export_range(1.0, 400.0) var brush_scale: float = 80.0:
	set(value):
		brush_scale = value
		emit_changed()
## How much longer a stroke is than it is wide.
@export_range(1.0, 8.0) var brush_stretch: float = 4.0:
	set(value):
		brush_stretch = value
		emit_changed()

@export_group("Highlight")
## How bright the small hard highlight is (0 turns it off).
@export_range(0.0, 2.0) var specular_strength: float = 0.25:
	set(value):
		specular_strength = value
		emit_changed()
## How big the highlight is.
@export_range(0.0, 0.5) var specular_size: float = 0.05:
	set(value):
		specular_size = value
		emit_changed()

@export_group("Rim")
## How bright the rim of light on the lit edge is (0 turns it off).
@export_range(0.0, 2.0) var rim_strength: float = 0.3:
	set(value):
		rim_strength = value
		emit_changed()
## How far in from the silhouette the rim reaches, 0 to 1.
@export_range(0.0, 1.0) var rim_width: float = 0.28:
	set(value):
		rim_width = value
		emit_changed()
@export var rim_color: Color = Color(1.0, 0.86, 0.66):
	set(value):
		rim_color = value
		emit_changed()

@export_group("Outline")
## Whether characters get a dark outline.
@export var outline: bool = true:
	set(value):
		outline = value
		emit_changed()
## Its width in pixels (at 1080p), the same near and far...
@export_range(0.0, 8.0) var outline_thickness: float = 2.0:
	set(value):
		outline_thickness = value
		emit_changed()
## ...up to this many metres, so small details close up stay thin.
@export_range(0.0, 0.05) var outline_max_width: float = 0.008:
	set(value):
		outline_max_width = value
		emit_changed()
## Dark brown rather than black, so it reads as a painted line.
@export var outline_color: Color = Color(0.14, 0.1, 0.09):
	set(value):
		outline_color = value
		emit_changed()

## The one outline material every surface shares, made on first use.
var _outline_material: ShaderMaterial = null


## A stylised material for a surface that was painted with [param source]:
## its texture and colour, this style's shading, and the outline after it.
func make_material(source: BaseMaterial3D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	if source != null:
		material.set_shader_parameter(&"albedo_color", source.albedo_color)
		if source.albedo_texture != null:
			material.set_shader_parameter(&"albedo_texture", source.albedo_texture)
	apply(material)
	return material


## Writes this style's settings into a material made by [method make_material].
func apply(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"base_tint", base_tint)
	material.set_shader_parameter(&"shadow_color", shadow_color)
	material.set_shader_parameter(&"ambient_strength", ambient_strength)
	material.set_shader_parameter(&"shadow_threshold", shadow_threshold)
	material.set_shader_parameter(&"shadow_softness", shadow_softness)
	material.set_shader_parameter(&"lit_falloff", lit_falloff)
	material.set_shader_parameter(&"bands", bands)
	material.set_shader_parameter(&"brush_strength", brush_strength)
	material.set_shader_parameter(&"brush_scale", brush_scale)
	material.set_shader_parameter(&"brush_stretch", brush_stretch)
	material.set_shader_parameter(&"specular_strength", specular_strength)
	material.set_shader_parameter(&"specular_size", specular_size)
	material.set_shader_parameter(&"rim_strength", rim_strength)
	material.set_shader_parameter(&"rim_width", rim_width)
	material.set_shader_parameter(&"rim_color", rim_color)
	material.next_pass = outline_material() if outline else null


## The outline drawn after every stylised surface, with this style's settings.
func outline_material() -> ShaderMaterial:
	if _outline_material == null:
		_outline_material = ShaderMaterial.new()
		_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter(&"outline_color", outline_color)
	_outline_material.set_shader_parameter(&"thickness", outline_thickness)
	_outline_material.set_shader_parameter(&"max_width", outline_max_width)
	return _outline_material
