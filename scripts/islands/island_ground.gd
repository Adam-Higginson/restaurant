@tool
class_name IslandGround
extends StaticBody3D
## The ground of an island: builds its mesh and its collision from an
## [IslandShape] when the scene starts (and in the editor, so you see it).
##
## Both are made in code and never saved into the scene: a mesh of twenty
## thousand points would bloat the scene file, and the shape's numbers are
## the truth. Change the shape's numbers in the Inspector and the ground
## rebuilds.
##
## The mesh has a point every metre. The collision is a
## [HeightMapShape3D]: a grid of heights, which is what Godot has for
## terrain. Under the sea it stops at [member wade_depth], so you can wade
## in to your knees and no deeper.

## Emitted each time the ground has been (re)built.
signal built

## Metres between the points of the mesh and of the collision grid.
const CELL: float = 1.0

## The lie of the land.
@export var shape: IslandShape:
	set(value):
		if shape != null and shape.changed.is_connected(build):
			shape.changed.disconnect(build)
		shape = value
		if shape != null:
			shape.changed.connect(build)
		if is_inside_tree():
			build()
## What the ground is painted with.
@export var material: Material:
	set(value):
		material = value
		if _mesh != null:
			_mesh.material_override = material
## The deepest the sea floor's collision goes: how far in you can wade.
@export var wade_depth: float = 0.55

var _mesh: MeshInstance3D = null
var _collision: CollisionShape3D = null
var _heights: ImageTexture = null


func _ready() -> void:
	build()


## Builds the mesh, the collision and the height picture from [member shape].
func build() -> void:
	if _mesh != null:
		_mesh.queue_free()
		_mesh = null
	if _collision != null:
		_collision.queue_free()
		_collision = null
	_heights = null
	if shape == null:
		return
	var across: int = int(shape.size.x / CELL) + 1
	var deep: int = int(shape.size.y / CELL) + 1
	var corner: Vector2 = -Vector2(across - 1, deep - 1) * CELL / 2.0

	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var floor_heights: PackedFloat32Array = PackedFloat32Array()
	var picture: Image = Image.create_empty(across, deep, false, Image.FORMAT_RGF)
	points.resize(across * deep)
	normals.resize(across * deep)
	uvs.resize(across * deep)
	floor_heights.resize(across * deep)
	for row: int in deep:
		for column: int in across:
			var x: float = corner.x + column * CELL
			var z: float = corner.y + row * CELL
			var height: float = shape.height_at(x, z)
			var index: int = row * across + column
			points[index] = Vector3(x, height, z)
			normals[index] = shape.normal_at(x, z)
			uvs[index] = Vector2(x, z)
			floor_heights[index] = maxf(height, -wade_depth)
			picture.set_pixel(column, row, Color(height, shape.inland(x, z), 0.0))

	var indices: PackedInt32Array = PackedInt32Array()
	indices.resize((across - 1) * (deep - 1) * 6)
	var next: int = 0
	for row: int in deep - 1:
		for column: int in across - 1:
			var a: int = row * across + column
			var b: int = a + 1
			var c: int = a + across
			var d: int = c + 1
			for corner_index: int in [a, b, c, b, d, c]:
				indices[next] = corner_index
				next += 1

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_mesh = MeshInstance3D.new()
	_mesh.name = "Mesh"
	_mesh.mesh = mesh
	_mesh.material_override = material
	add_child(_mesh)

	var grid: HeightMapShape3D = HeightMapShape3D.new()
	grid.map_width = across
	grid.map_depth = deep
	grid.map_data = floor_heights
	_collision = CollisionShape3D.new()
	_collision.name = "Shape"
	_collision.shape = grid
	add_child(_collision)

	_heights = ImageTexture.create_from_image(picture)
	built.emit()


## The ground as a picture, one pixel a metre, for shaders: red is the
## height and green is how far inland of the waterline the spot is
## (negative out at sea). The shore water reads how deep it is, and how
## far out, from this. Null before it's built.
func height_texture() -> ImageTexture:
	return _heights


## The patch of the world the height picture covers: its corner (x, z) and
## its size (x, z), in metres.
func height_rect() -> Rect2:
	if shape == null:
		return Rect2()
	var across: int = int(shape.size.x / CELL) + 1
	var deep: int = int(shape.size.y / CELL) + 1
	# A pixel's colour sits at its centre, so the picture reaches half a
	# cell past the first and last points.
	var span: Vector2 = Vector2(across, deep) * CELL
	return Rect2(-span / 2.0, span)
