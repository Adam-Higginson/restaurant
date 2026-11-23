class_name FishShoal
extends MultiMeshInstance3D
## A shoal of small fish in the shallows, cruising a lazy figure of eight
## over the drop-off. Come too close and they dart away. Looks only: they
## can't be caught (yet).
##
## The fish are one [MultiMesh] (a little low-poly fish, made here in code,
## drawn many times). Every frame each fish is put at its place on the
## shoal's path, a little behind the one in front, so they follow one
## another round like a real school.

## Emitted when something comes too close and the shoal darts off.
signal startled

## How long a startled shoal keeps darting, in seconds.
const DART_SECONDS: float = 1.6
## How many times faster a darting shoal swims.
const DART_SPEED: float = 3.6

## The lie of the land (and the seabed) they swim over.
@export var shape: IslandShape
## Where along the beach the shoal lives (its X).
@export var home_x: float = 0.0
## How far out from the waterline it lives, in metres.
@export var out_by: float = 7.5
## How far it roams from home: along the beach, and in and out.
@export var roam: Vector2 = Vector2(7.0, 2.2)
## How many fish.
@export var count: int = 26
## Which shoal you get: where each fish swims in it.
@export var shoal_seed: int = 1
## How fast it cruises, in metres a second.
@export var speed: float = 0.9
## How long a fish is, in metres.
@export var fish_length: float = 0.3
## How far below the surface they swim, where the water's deep enough.
@export var swim_depth: float = 0.7
## Who they dart away from (the player).
@export var wary_of: Node3D
## How close that may come before they dart, in metres.
@export var startle_within: float = 3.5

var _phase: float = 0.0
var _dart_left: float = 0.0
# For each fish: how far behind the leader it swims (as phase), and its own
# place in the shoal (sideways, up and down).
var _lags: PackedFloat32Array = PackedFloat32Array()
var _places: PackedVector3Array = PackedVector3Array()


func _ready() -> void:
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = shoal_seed
	_phase = random.randf_range(0.0, TAU)
	_lags.resize(count)
	_places.resize(count)
	for index: int in count:
		_lags[index] = random.randf_range(0.0, 0.5)
		_places[index] = Vector3(
			random.randf_range(-0.7, 0.7),
			random.randf_range(-0.22, 0.22),
			random.randf_range(-0.7, 0.7)
		)
	var many: MultiMesh = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _fish_mesh()
	many.instance_count = count
	multimesh = many
	# The fish wander well away from this node's own spot.
	custom_aabb = AABB(Vector3(-200.0, -20.0, -200.0), Vector3(400.0, 40.0, 400.0))
	_place_fish()


func _process(delta: float) -> void:
	if shape == null:
		return
	if _dart_left > 0.0:
		_dart_left = maxf(0.0, _dart_left - delta)
	elif _too_close():
		startle()
	var swimming: float = speed * (DART_SPEED if is_darting() else 1.0)
	_phase = fmod(_phase + swimming / maxf(roam.x, 0.1) * delta, TAU)
	_place_fish()


## Whether the shoal is darting away from something right now.
func is_darting() -> bool:
	return _dart_left > 0.0


## Makes the shoal dart off, as if something had come too close.
func startle() -> void:
	_dart_left = DART_SECONDS
	startled.emit()


## Where the middle of the shoal is at [param phase] of its round (0 to TAU):
## a figure of eight about its home, in the water.
func centre_at(phase: float) -> Vector3:
	var x: float = home_x + sin(phase) * roam.x
	var z: float = shape.shore_line(x) + out_by + sin(phase * 2.0) * roam.y
	return Vector3(x, _swim_height(x, z, 0.0), z)


## Where the middle of the shoal is now.
func centre() -> Vector3:
	return centre_at(_phase)


## Where fish number [param index] is now.
func fish_position(index: int) -> Vector3:
	return _fish_transform(index).origin


func _place_fish() -> void:
	if shape == null or multimesh == null:
		return
	for index: int in count:
		multimesh.set_instance_transform(index, _fish_transform(index))


func _fish_transform(index: int) -> Transform3D:
	var phase: float = _phase - _lags[index]
	var here: Vector3 = centre_at(phase)
	var ahead: Vector3 = centre_at(phase + 0.05)
	var heading: Vector3 = ahead - here
	heading.y = 0.0
	if heading.length() < 0.0001:
		heading = Vector3.RIGHT
	heading = heading.normalized()
	var side: Vector3 = Vector3(-heading.z, 0.0, heading.x)
	var place: Vector3 = _places[index]
	# A darting shoal strings out along its path.
	var spread: float = 1.6 if is_darting() else 1.0
	var spot: Vector3 = here + side * place.x + heading * place.z * spread
	spot.y = _swim_height(spot.x, spot.z, place.y)
	var facing: Basis = Basis.looking_at(heading, Vector3.UP).scaled(Vector3.ONE * fish_length)
	return Transform3D(facing, spot)


# The height a fish swims at over a spot: [member swim_depth] down, but never
# closer to the seabed than a hand's width, and never out of the water.
func _swim_height(x: float, z: float, offset: float) -> float:
	var seabed: float = shape.height_at(x, z)
	return minf(maxf(-swim_depth + offset, seabed + 0.12), -0.06)


func _too_close() -> bool:
	if wary_of == null or not is_instance_valid(wary_of):
		return false
	var away: Vector3 = wary_of.global_position - centre()
	away.y = 0.0
	return away.length() < startle_within


# One fish, one unit long, its nose towards -Z (the way looking_at faces):
# a body of eight triangles and a tail of one. UV.x runs from nose (0) to
# tail (1); the shader wags it more the further back.
func _fish_mesh() -> ArrayMesh:
	var nose: Vector3 = Vector3(0.0, 0.0, -0.5)
	var top: Vector3 = Vector3(0.0, 0.15, -0.12)
	var bottom: Vector3 = Vector3(0.0, -0.13, -0.12)
	var left: Vector3 = Vector3(-0.07, 0.0, -0.12)
	var right: Vector3 = Vector3(0.07, 0.0, -0.12)
	var waist: Vector3 = Vector3(0.0, 0.0, 0.3)
	var fin_top: Vector3 = Vector3(0.0, 0.15, 0.5)
	var fin_bottom: Vector3 = Vector3(0.0, -0.15, 0.5)
	var faces: Array[Vector3] = [
		nose, top, right, nose, right, bottom, nose, bottom, left, nose, left, top,
		waist, right, top, waist, bottom, right, waist, left, bottom, waist, top, left,
		waist, fin_top, fin_bottom,
	]
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for corner: int in range(0, faces.size(), 3):
		var a: Vector3 = faces[corner]
		var b: Vector3 = faces[corner + 1]
		var c: Vector3 = faces[corner + 2]
		var facing: Vector3 = (c - a).cross(b - a).normalized()
		# Whichever way round the corners were listed, face outwards.
		if facing.dot((a + b + c) / 3.0 - Vector3(0.0, 0.0, -0.1)) < 0.0:
			facing = -facing
		for point: Vector3 in [a, b, c]:
			points.append(point)
			normals.append(facing)
			uvs.append(Vector2(point.z + 0.5, 0.5))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
