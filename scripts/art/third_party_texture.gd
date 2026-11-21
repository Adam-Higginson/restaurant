class_name ThirdPartyTexture
extends Node
## Puts a third-party texture on a shader material when the scene starts, if
## the file is there.
##
## Third-party art lives in the gitignored assets/third_party/, so a scene
## can't point at it directly: on a fresh clone (or in CI) the file is missing
## and the scene would fail to load. Instead the material keeps our own
## placeholder texture, and this swaps the real one in when it exists.

## The material to dress. Usually shared by many meshes, so they all change.
@export var material: ShaderMaterial
## The texture file, under res://assets/third_party/.
@export_file("*.png", "*.jpg") var path: String = ""
## The shader parameter that takes the texture.
@export var parameter: StringName = &"albedo_texture"
## Shrink the texture to this many pixels across (and down) as it loads, for
## the chunky N64 look; 0 keeps it as it is.
@export var pixels: int = 0


func _ready() -> void:
	apply()


## Swaps the texture in. Returns whether it was there to swap in.
func apply() -> bool:
	if material == null or path.is_empty() or not ResourceLoader.exists(path):
		return false
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return false
	if pixels > 0:
		texture = shrunk(texture, pixels)
	material.set_shader_parameter(parameter, texture)
	return true


## A copy of [param texture] shrunk to [param size] pixels square. It's
## shrunk smoothly, so the grain keeps its shape, then each colour is snapped
## to a few shades: crisp, deliberate steps of colour like an N64 texture's
## small palette, rather than a blur.
static func shrunk(texture: Texture2D, size: int, shades: int = 7) -> ImageTexture:
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	image.resize(size, size, Image.INTERPOLATE_BILINEAR)
	for y: int in size:
		for x: int in size:
			var colour: Color = image.get_pixel(x, y)
			image.set_pixel(x, y, Color(
				roundf(colour.r * shades) / shades,
				roundf(colour.g * shades) / shades,
				roundf(colour.b * shades) / shades,
				colour.a))
	return ImageTexture.create_from_image(image)
