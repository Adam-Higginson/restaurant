@tool
class_name ThirdPartyModel
extends Node3D
## Dresses the scene with a third-party model when its file is there, and
## otherwise leaves our greybox stand-in showing.
##
## Third-party art lives in the gitignored assets/third_party/, so a scene
## can't reference it directly: on a fresh clone (or in CI) the file is
## missing and the scene would fail to load. This node loads the model by
## path instead, as a child, and hides the [member stand_ins]. Gameplay
## (collision, interaction) always stays on our own scenes; models are only
## looks.
##
## It runs in the editor too ([code]@tool[/code]), so you see the real model
## while placing things. The loaded model is never saved into the scene.
##
## Models from the packs are built at their own scale, so the model is
## fitted into [member fit_size] (sitting on this node's origin, centred).
## Their smooth flat colours are given the chunky N64 grain
## (shaders/n64_prop.gdshader).

const N64_SHADER: Shader = preload("res://shaders/n64_prop.gdshader")
## The chunky grain laid over models: a 32 x 32 noise texture of our own.
const GRAIN: Texture2D = preload("res://assets/placeholder/materials/n64_grain.tres")

## The model file, under res://assets/third_party/.
@export_file("*.gltf", "*.glb") var path: String = "":
	set(value):
		path = value
		if is_inside_tree():
			dress()
## The box the model is fitted into, in metres. Zero keeps its own size.
@export var fit_size: Vector3 = Vector3.ZERO:
	set(value):
		fit_size = value
		if is_inside_tree():
			dress()
## Stretch to fill [member fit_size] exactly (for boxy furniture like
## counters). Off scales evenly to fit inside it, keeping the model's shape.
@export var stretch: bool = false:
	set(value):
		stretch = value
		if is_inside_tree():
			dress()
## Greybox meshes to hide while the model shows.
@export var stand_ins: Array[VisualInstance3D] = []
## Lay the chunky N64 grain over the model's colours.
@export var grain: bool = true
## How many metres one copy of the grain covers on this model.
@export var grain_metres: float = 0.2
## Multiplies the model's colours: above 1 in a channel makes it stronger,
## e.g. to keep greens green under warm lamplight.
@export var tint: Color = Color.WHITE
## How fine a version of the model to draw: Godot keeps simplified copies of
## every imported mesh (levels of detail), and low values pick the cruder,
## lower-poly ones, for the chunky N64 look. 1 is Godot's usual choice.
@export var detail: float = 0.05

## The loaded model, or null when its file isn't there.
var model: Node3D = null


func _ready() -> void:
	dress()


## Loads the model if its file is there, fitted and with the stand-ins hidden.
## Returns whether the model is showing.
func dress() -> bool:
	if model != null:
		model.queue_free()
		model = null
	var scene: PackedScene = null
	if not path.is_empty() and ResourceLoader.exists(path):
		scene = load(path) as PackedScene
	if scene == null:
		_show_stand_ins(true)
		return false
	model = scene.instantiate() as Node3D
	if model == null:
		_show_stand_ins(true)
		return false
	add_child(model)
	_fit(model)
	if grain:
		_use_n64(model, {})
	_set_detail(model)
	_show_stand_ins(false)
	return true


func _fit(node: Node3D) -> void:
	var box: AABB = _bounds(node, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		return
	var factor: Vector3 = Vector3.ONE
	if fit_size != Vector3.ZERO:
		factor = fit_size / box.size
		if not stretch:
			var even: float = minf(factor.x, minf(factor.y, factor.z))
			factor = Vector3(even, even, even)
	node.scale = factor
	# Sit it on the origin, centred across.
	var bottom_centre: Vector3 = box.position + Vector3(box.size.x / 2.0, 0.0, box.size.z / 2.0)
	node.position = -bottom_centre * factor


# The bounding box of every mesh under [param node], in [param node]'s parent
# space before scaling.
func _bounds(node: Node, transform_so_far: Transform3D) -> AABB:
	var here: Transform3D = transform_so_far
	if node is Node3D and node != model:
		here = transform_so_far * (node as Node3D).transform
	var box: AABB = AABB()
	var found: bool = false
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		box = here * mesh_node.mesh.get_aabb()
		found = true
	for child: Node in node.get_children():
		var inner: AABB = _bounds(child, here)
		if inner.size == Vector3.ZERO:
			continue
		box = inner if not found else box.merge(inner)
		found = true
	return box


# Gives every surface the N64 prop shader, keeping its own colour and
# texture. [param made] remembers each converted material, so surfaces that
# shared one still do.
func _use_n64(node: Node, made: Dictionary) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	var override: BaseMaterial3D = null
	if mesh_node != null:
		override = mesh_node.material_override as BaseMaterial3D
	if override != null:
		# One material over the whole mesh: convert that instead.
		var whole: ShaderMaterial = made.get(override, null)
		if whole == null:
			whole = n64_material(override, grain_metres, tint)
			made[override] = whole
		mesh_node.material_override = whole
	elif mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var converted: ShaderMaterial = made.get(source, null)
			if converted == null:
				converted = n64_material(source, grain_metres, tint)
				made[source] = converted
			mesh_node.set_surface_override_material(surface, converted)
	for child: Node in node.get_children():
		_use_n64(child, made)


## The N64 prop material for a model surface painted with [param source]:
## the same colour and texture (times [param tint]), with chunky grain every
## [param metres].
static func n64_material(source: BaseMaterial3D, metres: float,
		tint: Color = Color.WHITE) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = N64_SHADER
	material.set_shader_parameter(&"albedo_color", source.albedo_color * tint)
	if source.albedo_texture != null:
		material.set_shader_parameter(&"albedo_texture", source.albedo_texture)
	material.set_shader_parameter(&"grain", GRAIN)
	material.set_shader_parameter(&"grain_metres", metres)
	return material


# Draws every mesh in the model at the chosen level of detail.
func _set_detail(node: Node) -> void:
	var shape: GeometryInstance3D = node as GeometryInstance3D
	if shape != null:
		shape.lod_bias = detail
	for child: Node in node.get_children():
		_set_detail(child)


# Shows or hides the greybox. In the editor this is done on the renderer
# only, so hiding never gets saved into the scene.
func _show_stand_ins(show_them: bool) -> void:
	for stand_in: VisualInstance3D in stand_ins:
		if stand_in == null:
			continue
		if Engine.is_editor_hint():
			RenderingServer.instance_set_visible(stand_in.get_instance(), show_them)
		else:
			stand_in.visible = show_them
