@tool
class_name FaceRepaint
extends Resource
## A calmer face painted over the one a character was made with (#172):
## a plain, level mouth and new brows.
##
## A Meshy face is made with whatever expression its picture had (the boy's
## grins, and his brows read as a scowl from above), painted into its texture
## and sculpted into its mesh, with no bones or shapes to move it. The
## stylised shader covers the old mouth and brows with skin and draws new
## ones. Over the mouth it also lights the face as a smooth dome, so the
## sculpted lips stop showing. Everything is measured in the head bone's own
## space, in its units (centimetres for a Meshy model): +x is the
## character's left, +y up and +z out of its face. [CharacterModel] applies
## it to a whole character's body (not its clothes) from
## [member CharacterParts.whole_face].

@export_group("Mouth")
## The middle of the patch that's covered over the old mouth (x, y).
@export var mouth_centre: Vector2 = Vector2.ZERO
## Half the patch's width and height. It's a box with well-rounded corners.
@export var mouth_size: Vector2 = Vector2(3.0, 1.0)
## How far in from the patch's edge it fades, as a share of the way (0 to 1).
@export_range(0.0, 1.0) var mouth_feather: float = 0.35
## Only points further out of the face than this (z) are covered, so the
## patch doesn't reach round to the cheeks or the inside of the mouth.
@export var mouth_front: float = 0.0
## The skin colour the patch is painted.
@export var mouth_skin: Color = Color(0.9, 0.6, 0.4)
## The middle of the dome the patch is lit as, behind the face.
@export var dome_centre: Vector3 = Vector3(0.0, 0.0, -10.0)
## How much of the way the patch's light follows the dome, not the mesh
## (0 to 1): 1 smooths away the sculpted lips.
@export_range(0.0, 1.0) var smoothing: float = 1.0
## The new mouth's middle (x, y).
@export var line_centre: Vector2 = Vector2.ZERO
## Half the new mouth's width.
@export var line_half_width: float = 1.5
## How thick the new mouth's line is.
@export var line_thickness: float = 0.2
## How far the line's ends sit above its middle: 0 is level, negative a
## little down-turned, positive a smile.
@export var line_curve: float = 0.0
## The new mouth's colour.
@export var line_color: Color = Color(0.6, 0.3, 0.2)

@export_group("Brows")
## Whether the brows are repainted too.
@export var brows: bool = false
## The face's middle line (x): each brow is the other mirrored across it.
## The numbers below are for the left brow (+x).
@export var brow_mirror: float = 0.0
## The middle of the patch covered over the old left brow (x, y), and half
## its width and height. Only paint darker than [member brow_skin] is
## covered, so the skin's own shading stays.
@export var brow_area_centre: Vector2 = Vector2(3.0, 14.0)
@export var brow_area_size: Vector2 = Vector2(2.5, 1.0)
## Hair hangs in front of the brows. Only points nearer the face than a dome
## are painted: [code]x[/code] is how far out of the face it is in the
## middle, [code]y[/code] how fast it falls away to the sides (per x
## squared), so the hair in front is left alone.
@export var brow_skin_depth: Vector2 = Vector2(7.0, 0.06)
## The forehead's colour, painted over the old brows.
@export var brow_skin: Color = Color(0.9, 0.6, 0.4)
## The new brow's inner end (nearer the nose) and outer end (x, y).
@export var brow_inner: Vector2 = Vector2(1.5, 13.6)
@export var brow_outer: Vector2 = Vector2(5.2, 13.6)
## How far the new brow's middle rises above the line between its ends.
@export var brow_arch: float = 0.2
## How thick the new brow is at its inner and outer ends.
@export var brow_thickness: Vector2 = Vector2(0.5, 0.15)
## The new brows' colour.
@export var brow_color: Color = Color(0.33, 0.21, 0.1)


## Writes the face into a stylised material.
func apply(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"mouth_paint", 1.0)
	material.set_shader_parameter(&"mouth_area",
			Vector4(mouth_centre.x, mouth_centre.y, mouth_size.x, mouth_size.y))
	material.set_shader_parameter(&"mouth_feather", mouth_feather)
	material.set_shader_parameter(&"mouth_front", mouth_front)
	material.set_shader_parameter(&"mouth_skin", mouth_skin)
	material.set_shader_parameter(&"mouth_dome", dome_centre)
	material.set_shader_parameter(&"mouth_smoothing", smoothing)
	material.set_shader_parameter(&"mouth_line",
			Vector3(line_centre.x, line_centre.y, line_half_width))
	material.set_shader_parameter(&"mouth_thickness", line_thickness)
	material.set_shader_parameter(&"mouth_curve", line_curve)
	material.set_shader_parameter(&"mouth_color", line_color)
	material.set_shader_parameter(&"brow_paint", 1.0 if brows else 0.0)
	material.set_shader_parameter(&"brow_mirror", brow_mirror)
	material.set_shader_parameter(&"brow_area", Vector4(brow_area_centre.x,
			brow_area_centre.y, brow_area_size.x, brow_area_size.y))
	material.set_shader_parameter(&"brow_skin_depth", brow_skin_depth)
	material.set_shader_parameter(&"brow_skin", brow_skin)
	material.set_shader_parameter(&"brow_line",
			Vector4(brow_inner.x, brow_inner.y, brow_outer.x, brow_outer.y))
	material.set_shader_parameter(&"brow_arch", brow_arch)
	material.set_shader_parameter(&"brow_thickness", brow_thickness)
	material.set_shader_parameter(&"brow_color", brow_color)


## Takes the repainting off a stylised material: the face's own shows again.
static func clear(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"mouth_paint", 0.0)
	material.set_shader_parameter(&"brow_paint", 0.0)
