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


func _ready() -> void:
	apply()


## Swaps the texture in. Returns whether it was there to swap in.
func apply() -> bool:
	if material == null or path.is_empty() or not ResourceLoader.exists(path):
		return false
	var texture: Texture2D = load(path) as Texture2D
	if texture == null:
		return false
	material.set_shader_parameter(parameter, texture)
	return true
