@tool
class_name GrassPatch
extends MultiMeshInstance3D
## Tufts of grass over a stretch of an island, drawn as one
## [MultiMesh]: a single mesh (one tuft of a few blades, made here in code)
## drawn thousands of times in one go, each copy with its own place, turn
## and size. That's what makes thousands of tufts cost almost nothing.
##
## Like [IslandScatter], the tufts go by rule and by seed, and are made when
## the scene starts, never saved.

## The lie of the land they grow on.
@export var shape: IslandShape:
	set(value):
		shape = value
		_refresh()
## How many tufts.
@export var count: int = 2000:
	set(value):
		count = value
		_refresh()
## Which arrangement you get.
@export var grass_seed: int = 3:
	set(value):
		grass_seed = value
		_refresh()
## The stretch of beach they grow along: from this X to that X.
@export var along: Vector2 = Vector2(-70.0, 70.0):
	set(value):
		along = value
		_refresh()
## How far inland of the waterline they grow: from so many metres to so many.
@export var inland: Vector2 = Vector2(13.0, 45.0):
	set(value):
		inland = value
		_refresh()
## Tufts thin out towards the near edge of the band over this many metres,
## so the grass frays into the sand instead of stopping at a line.
@export var fray: float = 5.0:
	set(value):
		fray = value
		_refresh()
## How tall a tuft is, in metres, before each one's own scaling.
@export var blade_height: float = 0.55:
	set(value):
		blade_height = value
		_refresh()
## How wide a blade is at its root, in metres. Wide blades make leafy
## undergrowth rather than grass.
@export var blade_width: float = 0.022:
	set(value):
		blade_width = value
		_refresh()
## How far a blade reaches outwards, as a part of its height: from so far
## to so far. More makes a low spreading plant.
@export var reach: Vector2 = Vector2(0.25, 0.6):
	set(value):
		reach = value
		_refresh()
## Blades in a tuft.
@export var blades: int = 7:
	set(value):
		blades = value
		_refresh()


func _ready() -> void:
	grow()


## Where the tufts go, each with its size in the fourth number. Worked out
## from the shape and the seed alone.
func tufts() -> Array[Vector4]:
	var found: Array[Vector4] = []
	if shape == null:
		return found
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = grass_seed
	for attempt: int in count * 4:
		if found.size() >= count:
			break
		var x: float = random.randf_range(along.x, along.y)
		var back: float = random.randf_range(inland.x, inland.y)
		# Fewer near the sand: keep a tuft less often the nearer the edge.
		var keep: float = clampf((back - inland.x) / maxf(fray, 0.01), 0.08, 1.0)
		if random.randf() > keep:
			continue
		var z: float = shape.shore_line(x) - back
		if not shape.covers(x, z):
			continue
		var size: float = random.randf_range(0.6, 1.35) * lerpf(0.6, 1.0, keep)
		found.append(Vector4(x, shape.height_at(x, z), z, size))
	return found


## Makes the tufts afresh.
func grow() -> void:
	var places: Array[Vector4] = tufts()
	var many: MultiMesh = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _tuft_mesh()
	many.instance_count = places.size()
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = grass_seed + 1000
	for index: int in places.size():
		var place: Vector4 = places[index]
		var turned: Basis = Basis(Vector3.UP, random.randf_range(0.0, TAU))
		turned = turned.scaled(Vector3(place.w, place.w * random.randf_range(0.8, 1.3), place.w))
		many.set_instance_transform(index, Transform3D(turned, Vector3(place.x, place.y, place.z)))
	multimesh = many


# One tuft: a few thin blades fanning out from a point, each a tapering
# strip of three triangles that bends over towards its tip. UV.y runs from
# the root (0) to the tip (1): the shader colours and sways by it.
func _tuft_mesh() -> ArrayMesh:
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = 11
	for blade: int in blades:
		var turn: float = TAU * float(blade) / float(blades) + random.randf_range(-0.3, 0.3)
		var out: Vector3 = Vector3(cos(turn), 0.0, sin(turn))
		var side: Vector3 = Vector3(-out.z, 0.0, out.x)
		var tall: float = blade_height * random.randf_range(0.6, 1.0)
		var out_by: float = tall * random.randf_range(reach.x, reach.y)
		var width: float = blade_width
		var root: Vector3 = out * 0.04
		var middle: Vector3 = root + out * out_by * 0.35 + Vector3.UP * tall * 0.6
		var tip: Vector3 = root + out * out_by + Vector3.UP * tall
		var corners: Array[Vector3] = [
			root - side * width, root + side * width,
			middle - side * width * 0.8, middle + side * width * 0.8,
			tip,
		]
		var heights: Array[float] = [0.0, 0.0, 0.6, 0.6, 1.0]
		for corner: int in [0, 1, 2, 1, 3, 2, 2, 3, 4]:
			points.append(corners[corner])
			# Lit as if it were the ground it grows from: soft, never black.
			normals.append(Vector3.UP)
			uvs.append(Vector2(0.5, heights[corner]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _refresh() -> void:
	if is_inside_tree():
		grow()
