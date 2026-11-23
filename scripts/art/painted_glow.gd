@tool
class_name PaintedGlow
extends Node
## Makes the bright painted parts of a [ThirdPartyModel] glow, like the glass
## of a Meshy lantern, whose flame is painted into its texture (#168). Each
## time the model is dressed, its surfaces get the painted-glow material with
## their own texture. Put a light beside it for the glow to light the room.

const SHADER: Shader = preload("res://shaders/painted_glow.gdshader")

## The model whose paint glows.
@export var model: ThirdPartyModel:
	set(value):
		if model != null and model.dressed.is_connected(_on_dressed):
			model.dressed.disconnect(_on_dressed)
		model = value
		if model != null:
			model.dressed.connect(_on_dressed)
			if model.model != null:
				_on_dressed(true)
## How bright the paint must be (0 to 1) before it glows.
@export_range(0.0, 1.0) var threshold: float = 0.6
## How strongly it glows: above 1 it blooms.
@export_range(0.0, 16.0) var energy: float = 3.0


## The glowing material for a surface painted with [param source].
func material_for(source: BaseMaterial3D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"albedo_color", source.albedo_color)
	if source.albedo_texture != null:
		material.set_shader_parameter(&"albedo_texture", source.albedo_texture)
	material.set_shader_parameter(&"threshold", threshold)
	material.set_shader_parameter(&"energy", energy)
	return material


func _on_dressed(shown: bool) -> void:
	if shown and model.model != null:
		_glow(model.model)


func _glow(node: Node) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	var whole: BaseMaterial3D = null
	if mesh_node != null:
		whole = mesh_node.material_override as BaseMaterial3D
		# A lamp's own body doesn't shadow the light that sits inside it.
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if whole != null:
		# One material over the whole mesh: that's the paint.
		mesh_node.material_override = material_for(whole)
	elif mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if source != null:
				mesh_node.set_surface_override_material(surface, material_for(source))
	for child: Node in node.get_children():
		_glow(child)
