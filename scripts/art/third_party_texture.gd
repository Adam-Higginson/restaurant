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
## Make mipmaps for it as it loads: smaller copies Godot draws far away, so
## a finely detailed texture on the ground doesn't shimmer in the distance.
@export var mipmaps: bool = false


func _ready() -> void:
	apply()


## Swaps the texture in. Returns whether it was there to swap in.
func apply() -> bool:
	if material == null or path.is_empty() or not ResourceLoader.exists(path):
		return false
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return false
	if mipmaps:
		texture = with_mipmaps(texture)
	material.set_shader_parameter(parameter, texture)
	return true


## A copy of [param texture] with mipmaps: the smaller copies Godot draws
## when it's far away.
static func with_mipmaps(texture: Texture2D) -> ImageTexture:
	# A copy: get_image() can hand back the texture's own picture (it does
	# with no graphics card, as the tests run), and changing that would
	# change the texture for everything else that uses it.
	var image: Image = texture.get_image().duplicate() as Image
	if image.is_compressed():
		image.decompress()
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
