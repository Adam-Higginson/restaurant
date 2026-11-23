class_name PlantSway
extends Node
## Makes a plant's model move in the wind and glow where the sun comes
## through its leaves. A Meshy model arrives with an ordinary material that
## can do neither, so once the model is showing this swaps each of its
## materials for the plant shader (shaders/plant_sway.gdshader), keeping the
## model's own painted texture.
##
## Plants that share a model share the swapped material too, so a grove of
## forty palms is still one material.

const SHADER: Shader = preload("res://shaders/plant_sway.gdshader")

## The model to move.
@export var model: ThirdPartyModel
## How far the top swings, as a part of the plant's height.
@export var sway: float = 0.035
## How far the leaves flutter, as a part of the plant's height.
@export var flutter: float = 0.012
## The part of the plant's height below which nothing moves (a trunk's foot).
@export var still_below: float = 0.1
## How much sunlight comes through the leaves from behind.
@export var glow_through: float = 0.6

# The swapped material for each of a model's own, by its settings too.
static var _made: Dictionary[String, ShaderMaterial] = {}


func _ready() -> void:
	if model == null:
		return
	model.dressed.connect(_on_dressed)
	if model.model != null:
		_swap(model.model)


func _on_dressed(shown: bool) -> void:
	if shown and model.model != null:
		_swap(model.model)


func _swap(node: Node) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if source == null:
				continue
			mesh_node.set_surface_override_material(surface, _material_for(source))
	for child: Node in node.get_children():
		_swap(child)


func _material_for(source: BaseMaterial3D) -> ShaderMaterial:
	var key: String = "%d %f %f %f %f" % [
		source.get_instance_id(), sway, flutter, still_below, glow_through,
	]
	var made: ShaderMaterial = _made.get(key, null)
	if made != null:
		return made
	made = ShaderMaterial.new()
	made.shader = SHADER
	made.set_shader_parameter(&"albedo_texture", source.albedo_texture)
	made.set_shader_parameter(&"sway", sway)
	made.set_shader_parameter(&"flutter", flutter)
	made.set_shader_parameter(&"still_below", still_below)
	made.set_shader_parameter(&"glow_through", glow_through)
	_made[key] = made
	return made
