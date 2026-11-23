class_name GullFlock
extends MultiMeshInstance3D
## Gulls wheeling over an island: each glides round and round its own wide
## circle, at its own height and pace, rising and dipping a little and
## leaning into its turn. Looks only.
##
## Like [FishShoal], the gulls are one [MultiMesh] (a little low-poly bird
## made here in code, drawn several times), and every frame each is put at
## its place on its circle. The wings flap in the shader
## (shaders/gull.gdshader).

## How many gulls.
@export var count: int = 9
## Which flock you get: each gull's circle, height and pace.
@export var flock_seed: int = 2
## The middle of the sky they wheel in.
@export var centre: Vector3 = Vector3(0.0, 0.0, 30.0)
## How far each gull's own circle's middle may be from that, along X and Z.
@export var spread: Vector2 = Vector2(70.0, 45.0)
## How wide a gull's circle is, in metres: from so wide to so wide (radius).
@export var circle: Vector2 = Vector2(9.0, 24.0)
## How high they fly, in metres: from so high to so high.
@export var height: Vector2 = Vector2(11.0, 26.0)
## How fast they fly, in metres a second: from so fast to so fast.
@export var speed: Vector2 = Vector2(5.0, 8.0)
## How long a gull is from wingtip to wingtip, in metres.
@export var wingspan: float = 1.3

var _time: float = 0.0
# For each gull: the middle of its circle (x, height, z), then its radius,
# its turns per second (negative flies the other way) and where it starts.
var _middles: PackedVector3Array = PackedVector3Array()
var _radii: PackedFloat32Array = PackedFloat32Array()
var _turns: PackedFloat32Array = PackedFloat32Array()
var _starts: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	# The gulls are placed afresh every drawn frame, so there's nothing for
	# Godot to smooth between physics ticks.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = flock_seed
	for index: int in count:
		var radius: float = random.randf_range(circle.x, circle.y)
		var pace: float = random.randf_range(speed.x, speed.y)
		_middles.append(Vector3(
			centre.x + random.randf_range(-spread.x, spread.x),
			centre.y + random.randf_range(height.x, height.y),
			centre.z + random.randf_range(-spread.y, spread.y)
		))
		_radii.append(radius)
		# Once round is the circle's length, at this gull's pace.
		var way: float = 1.0 if random.randf() < 0.5 else -1.0
		_turns.append(way * pace / (TAU * radius))
		_starts.append(random.randf_range(0.0, TAU))
	var many: MultiMesh = MultiMesh.new()
	many.transform_format = MultiMesh.TRANSFORM_3D
	many.mesh = _gull_mesh()
	many.instance_count = count
	multimesh = many
	# The gulls fly well away from this node's own spot.
	custom_aabb = AABB(Vector3(-400.0, -50.0, -400.0), Vector3(800.0, 200.0, 800.0))
	_place_gulls()


func _process(delta: float) -> void:
	_time += delta
	_place_gulls()


## Where gull number [param index] is, and which way it faces, [param time]
## seconds into the flock's flying.
func gull_at(index: int, time: float) -> Transform3D:
	var angle: float = _starts[index] + TAU * _turns[index] * time
	var middle: Vector3 = _middles[index]
	var out: Vector3 = Vector3(cos(angle), 0.0, sin(angle))
	var spot: Vector3 = middle + out * _radii[index]
	# Rising and dipping a little as it goes round.
	spot.y += sin(angle * 2.0 + _starts[index]) * 1.2
	# It flies along the circle: square to the line out from the middle.
	var way: float = signf(_turns[index])
	var heading: Vector3 = Vector3(-out.z, 0.0, out.x) * way
	var facing: Basis = Basis.looking_at(heading, Vector3.UP)
	# Leaning into the turn: the inner wing dips.
	facing = facing.rotated(heading, -way * 0.35)
	return Transform3D(facing.scaled(Vector3.ONE * wingspan), spot)


func _place_gulls() -> void:
	if multimesh == null:
		return
	for index: int in count:
		multimesh.set_instance_transform(index, gull_at(index, _time))


# One gull, one unit from wingtip to wingtip, its beak towards -Z: a body
# and two swept wings, flat. UV.x is how far out along a wing a point is
# (0 at the body, 1 at a tip): the shader flaps by it.
func _gull_mesh() -> ArrayMesh:
	var beak: Vector3 = Vector3(0.0, 0.0, -0.22)
	var tail: Vector3 = Vector3(0.0, 0.0, 0.2)
	var shoulder_front: Vector3 = Vector3(0.0, 0.02, -0.1)
	var shoulder_back: Vector3 = Vector3(0.0, 0.02, 0.06)
	var faces: Array[Vector3] = []
	var outs: Array[float] = []
	for side: float in [-1.0, 1.0]:
		var elbow_front: Vector3 = Vector3(0.24 * side, 0.03, -0.12)
		var elbow_back: Vector3 = Vector3(0.22 * side, 0.03, 0.04)
		var tip: Vector3 = Vector3(0.5 * side, 0.0, 0.05)
		var flank: Vector3 = Vector3(0.05 * side, 0.0, 0.0)
		faces.append_array([shoulder_front, elbow_front, elbow_back])
		outs.append_array([0.0, 0.5, 0.5])
		faces.append_array([shoulder_front, elbow_back, shoulder_back])
		outs.append_array([0.0, 0.5, 0.0])
		faces.append_array([elbow_front, tip, elbow_back])
		outs.append_array([0.5, 1.0, 0.5])
		# The body: a slim diamond, one half each side.
		faces.append_array([beak, flank, tail])
		outs.append_array([0.0, 0.0, 0.0])
	var points: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	for corner: int in faces.size():
		points.append(faces[corner])
		normals.append(Vector3.UP)
		uvs.append(Vector2(outs[corner], 0.0))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
