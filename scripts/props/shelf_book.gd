@tool
class_name ShelfBook
extends Node3D
## One book standing on a shelf, made from the one Meshy book (#196): any cover
## colour, any height, thicker or thinner. Its spine faces +Z (out of a shelf),
## its bottom sits on this node, and it's centred on it.
##
## The model is gitignored art: without it a plain box of the same size and
## colour stands in.

const MODEL: String = "res://assets/third_party/meshy/book/model/model.glb"
const COVER: Shader = preload("res://shaders/book_cover.gdshader")
## The model's own size: its height and its thickness (its cover faces z, its
## spine -x, so on a shelf it's turned a quarter round).
const MODEL_HEIGHT: float = 0.953
const MODEL_THICKNESS: float = 0.239
const MODEL_WIDTH: float = 0.676

## The cover's colour.
@export var cover: Color = Color(0.55, 0.14, 0.12):
	set(value):
		cover = value
		_paint()
## The book's height, in metres.
@export var height: float = 0.24:
	set(value):
		height = value
		_build()
## How much thicker (above 1) or thinner than usual the book is.
@export var thickness: float = 1.0:
	set(value):
		thickness = value
		_build()

## One material for every book (each book sets its own cover colour on it).
static var _shared: ShaderMaterial = null
## The book model, kept loaded once it's been used.
static var _model: PackedScene = null

var _look: Node3D = null


func _ready() -> void:
	_build()


## How thick the book is, in metres (its width along a shelf).
func depth() -> float:
	return height / MODEL_HEIGHT * MODEL_THICKNESS * thickness


func _build() -> void:
	if not is_inside_tree():
		return
	if _look != null:
		_look.queue_free()
		_look = null
	var size: float = height / MODEL_HEIGHT
	if ResourceLoader.exists(MODEL):
		if _model == null:
			_model = load(MODEL) as PackedScene
		_look = _model.instantiate() as Node3D
		# Spine (-x) round to face +Z, then sized and stood on the floor.
		# (Its thickness is along its own z, which the turn lays along +X.)
		_look.transform = Transform3D(Basis(Vector3.UP, PI / 2.0) * Basis.from_scale(
				Vector3(size, size, size * thickness)), Vector3(0.0, MODEL_HEIGHT * size / 2.0, 0.0))
	else:
		var box: BoxMesh = BoxMesh.new()
		box.size = Vector3(depth(), height, MODEL_WIDTH * size)
		var stand_in: MeshInstance3D = MeshInstance3D.new()
		stand_in.mesh = box
		stand_in.position = Vector3(0.0, height / 2.0, 0.0)
		_look = stand_in
	add_child(_look, false, Node.INTERNAL_MODE_BACK)
	_paint()


func _paint() -> void:
	if _look == null:
		return
	var meshes: Array[Node] = _look.find_children("*", "MeshInstance3D", true, false)
	meshes.append(_look)
	for node: Node in meshes:
		var mesh: MeshInstance3D = node as MeshInstance3D
		if mesh == null:
			continue
		if mesh.mesh is BoxMesh:
			var plain: StandardMaterial3D = StandardMaterial3D.new()
			plain.albedo_color = cover
			mesh.material_override = plain
			continue
		if _shared == null:
			var source: BaseMaterial3D = mesh.mesh.surface_get_material(0) as BaseMaterial3D
			_shared = ShaderMaterial.new()
			_shared.shader = COVER
			if source != null:
				_shared.set_shader_parameter("albedo_texture", source.albedo_texture)
		mesh.material_override = _shared
		mesh.set_instance_shader_parameter(&"cover", cover)
