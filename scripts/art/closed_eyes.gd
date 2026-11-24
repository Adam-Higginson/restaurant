class_name ClosedEyes
extends Resource
## Where a whole character's eyes are, so the stylised shader can draw them
## closed (#172). A Meshy face is one painted texture with no eyelids, so
## shut eyes are drawn: while [member CharacterModel.eyes_shut] is on, each
## eye's oval is covered in [member lid_color] and a lash line is drawn
## across it, sagging a little in the middle, the way a sleeping eye looks.
## Measured in the head bone's own space, in its units (centimetres for a
## Meshy model): +x is the character's left, +y up, +z out of its face.
## Without one, shut eyes fall back to painting over whatever is
## eye-coloured, which only works on a face with a heavy upper lash.

## Each eye's oval: its middle (x, y) and half its width and height, along
## and across the eye. Its right eye (at -x) and its left (at +x).
@export var right_eye: Vector4 = Vector4.ZERO
@export var left_eye: Vector4 = Vector4.ZERO
## How far each eye is turned, in radians (right eye, left eye): the line
## through its corners against level.
@export var tilt: Vector2 = Vector2.ZERO
## Only points further out of the face than this are drawn on, so the hair
## behind and the back of the head are left alone.
@export var front: float = 0.0
## The lid's colour: the skin round the eyes.
@export var lid_color: Color = Color(0.85, 0.56, 0.34)
## The lash line: its colour, how thick it is, and how far its middle sags
## below its ends, as a share of the eye's half height.
@export var lash_color: Color = Color(0.2, 0.12, 0.07)
@export var lash_thickness: float = 0.14
@export_range(0.0, 1.0) var lash_sag: float = 0.3


## Writes the eyes into a stylised material.
func apply(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"lid_right", right_eye)
	material.set_shader_parameter(&"lid_left", left_eye)
	material.set_shader_parameter(&"lid_tilt", tilt)
	material.set_shader_parameter(&"lid_front", front)
	material.set_shader_parameter(&"eyelid_color", lid_color)
	material.set_shader_parameter(&"lash_color", lash_color)
	material.set_shader_parameter(&"lash_thickness", lash_thickness)
	material.set_shader_parameter(&"lash_sag", lash_sag)
