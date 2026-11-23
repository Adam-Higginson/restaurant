@tool
class_name ClothRecolour
extends Resource
## Repaints a stylised character's near-white cloth in two colours, one above
## a height (a shirt or vest) and one below it (shorts or trousers), without
## touching the model (#168). Only paint that is bright and nearly colourless
## changes, so skin, hair and eyes keep their own colours.
##
## It's a stand-in until characters have real outfits (#173): the boy's
## base-body vest and shorts read as a white mannequin otherwise. Put it in
## the [member ThirdPartyModel.recolour] slot of one character; it only works
## on a model drawn with a [CharacterStyle].

## The colour for cloth above [member split_height] (the top).
@export var upper_color: Color = Color(0.46, 0.6, 0.74):
	set(value):
		upper_color = value
		emit_changed()
## The colour for cloth below [member split_height] (the bottoms).
@export var lower_color: Color = Color(0.5, 0.38, 0.28):
	set(value):
		lower_color = value
		emit_changed()
## Where the top ends and the bottoms start, in metres above the model's feet.
@export_range(0.0, 3.0) var split_height: float = 0.93:
	set(value):
		split_height = value
		emit_changed()
## How bright the paint must be (0 to 1) to count as white cloth.
@export_range(0.0, 1.0) var min_brightness: float = 0.62:
	set(value):
		min_brightness = value
		emit_changed()
## How colourless it must be (0 to 1): skin is about 0.35, white cloth under 0.15.
@export_range(0.0, 1.0) var max_saturation: float = 0.2:
	set(value):
		max_saturation = value
		emit_changed()


## Writes the recolour into a stylised material.
func apply(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"recolour_strength", 1.0)
	material.set_shader_parameter(&"recolour_upper", upper_color)
	material.set_shader_parameter(&"recolour_lower", lower_color)
	material.set_shader_parameter(&"recolour_split", split_height)
	material.set_shader_parameter(&"recolour_min_brightness", min_brightness)
	material.set_shader_parameter(&"recolour_max_saturation", max_saturation)


## Takes the recolour off a stylised material.
static func clear(material: ShaderMaterial) -> void:
	material.set_shader_parameter(&"recolour_strength", 0.0)
