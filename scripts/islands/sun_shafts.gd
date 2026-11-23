@tool
class_name SunShafts
extends MultiMeshInstance3D
## Shafts of sunlight slanting down through an island's trees. Each is a
## pair of crossed strips lying along the sun's rays, from a spot on the
## ground up towards the sun, drawn with shaders/sun_shaft.gdshader. They're
## looks only: the real light and shadows come from the sun itself.
##
## Like the other scatterers they go by rule and by seed, are drawn as one
## [MultiMesh], and are made when the scene starts, never saved.

## The sun they follow. Turn it and the shafts turn with it (on the next
## [method lay]).
@export var sun: DirectionalLight3D:
	set(value):
		sun = value
		_refresh()
## The lie of the land they come down on.
@export var shape: IslandShape:
	set(value):
		shape = value
		_refresh()
## How many shafts.
@export var count: int = 40:
	set(value):
		count = value
		_refresh()
## Which arrangement you get.
@export var shaft_seed: int = 2:
	set(value):
		shaft_seed = value
		_refresh()
## The stretch of beach they come down along: from this X to that X.
@export var along: Vector2 = Vector2(-60.0, 60.0):
	set(value):
		along = value
		_refresh()
## How far inland of the waterline they touch the ground: from so many
## metres to so many.
@export var inland: Vector2 = Vector2(6.0, 30.0):
	set(value):
		inland = value
		_refresh()
## How long a shaft is, in metres: from so long to so long.
@export var length: Vector2 = Vector2(12.0, 20.0):
	set(value):
		length = value
		_refresh()
## How wide a shaft is, in metres: from so wide to so wide.
@export var width: Vector2 = Vector2(0.8, 2.4):
	set(value):
		width = value
		_refresh()


func _ready() -> void:
	lay()


## The direction from the ground up towards the sun.
func to_sun() -> Vector3:
	if sun == null:
		return Vector3.UP
	# A light shines along its own -Z, so the sun is back along +Z.
	return sun.global_transform.basis.z.normalized() if sun.is_inside_tree() \
			else sun.transform.basis.z.normalized()


## Lays the shafts afresh.
func lay() -> void:
	var many: MultiMesh = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _shaft_mesh()
	if shape == null:
		many.instance_count = 0
		multimesh = many
		return
	many.instance_count = count
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = shaft_seed
	var up: Vector3 = to_sun()
	# Any two directions square to the shaft, to hang its strips on.
	var side: Vector3 = up.cross(Vector3.UP).normalized()
	if side.length() < 0.01:
		side = Vector3.RIGHT
	var front: Vector3 = side.cross(up).normalized()
	for index: int in count:
		var x: float = random.randf_range(along.x, along.y)
		var z: float = shape.shore_line(x) - random.randf_range(inland.x, inland.y)
		var foot: Vector3 = Vector3(x, shape.height_at(x, z), z)
		var wide: float = random.randf_range(width.x, width.y)
		var turn: float = random.randf_range(0.0, PI)
		var long: float = random.randf_range(length.x, length.y)
		var frame: Basis = Basis(side.rotated(up, turn) * wide, up * long, front.rotated(up, turn) * wide)
		# Start a little below the ground so the foot's fade is buried.
		many.set_instance_transform(index, Transform3D(frame, foot - up * long * 0.1))
	multimesh = many


# Two strips crossed along their length, one unit long and one wide, so a
# shaft has some body from any side.
func _shaft_mesh() -> ArrayMesh:
	var points: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for across: Vector3 in [Vector3.RIGHT, Vector3.BACK]:
		var corners: Array[Vector3] = [
			-across * 0.5, across * 0.5,
			-across * 0.5 + Vector3.UP, across * 0.5 + Vector3.UP,
		]
		var corner_uvs: Array[Vector2] = [
			Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0), Vector2(1.0, 1.0),
		]
		for corner: int in [0, 1, 2, 1, 3, 2]:
			points.append(corners[corner])
			uvs.append(corner_uvs[corner])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _refresh() -> void:
	if is_inside_tree():
		lay()
