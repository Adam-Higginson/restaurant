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
## Small blocky textures, N64 style, instead of smooth filtering.
@export var nearest_filter: bool = true

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
	if nearest_filter:
		_use_nearest(model)
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


func _use_nearest(node: Node) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if material != null:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	for child: Node in node.get_children():
		_use_nearest(child)


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
