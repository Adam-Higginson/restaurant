@tool
class_name FiredModel
extends RefCounted
## Draws a model fired in the Kiln: every mesh gets the N64 surface shader
## with the model's own small texture. Shared by [ThirdPartyModel] and
## [CharacterModel], so every fired model is drawn the same way.

const SHADER: Shader = preload("res://shaders/n64_surface.gdshader")

## Materials already made, by texture and look, so every copy of a model
## shares one.
static var _made: Dictionary = {}


## The material for a fired model with the texture at [param texture_path],
## drawn as [param look] says, times [param tint].
static func material(texture_path: String, look: ArtLook,
		tint: Color = Color.WHITE) -> ShaderMaterial:
	var key: String = "%s|%d|%s" % [texture_path, look.get_instance_id(), tint.to_html()]
	var known: ShaderMaterial = _made.get(key, null)
	if known != null:
		return known
	var made: ShaderMaterial = ShaderMaterial.new()
	made.shader = SHADER
	made.set_shader_parameter(&"albedo_texture", load(texture_path) as Texture2D)
	made.set_shader_parameter(&"albedo_color", tint)
	made.set_shader_parameter(&"roughness", look.roughness)
	made.set_shader_parameter(&"specular", look.specular)
	made.set_shader_parameter(&"faceted", look.faceted)
	_made[key] = made
	return made


## Draws every mesh under [param node] with [param job]'s fired texture, at
## full detail: the Kiln already made it as simple as it should be.
static func paint(node: Node, job: KilnJob, tint: Color = Color.WHITE) -> void:
	var drawn: ShaderMaterial = material(job.texture_path(), job.look, tint)
	for found: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = found as MeshInstance3D
		mesh.material_override = drawn
		mesh.lod_bias = 1.0
	var own: MeshInstance3D = node as MeshInstance3D
	if own != null:
		own.material_override = drawn
		own.lod_bias = 1.0


## Forgets the materials made so far, so the next ones read the looks and
## textures afresh (after firing again).
static func forget() -> void:
	_made.clear()
