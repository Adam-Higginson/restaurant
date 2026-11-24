@tool
class_name HangingChain
extends MultiMeshInstance3D
## One of the enormous chains in the Grave of the Lanterns: iron links
## strung from [member top] down to [member bottom] (both in this node's own
## space), sagging a little between them, each link turned a quarter turn
## from the one before as real chain is. It runs in the editor too, so move
## its ends in the Inspector and the chain follows.
##
## All the links are one [MultiMesh] (many copies of one mesh drawn in a
## single go), which is how a long chain stays cheap.

## Where the chain starts and ends, in metres in this node's own space.
@export var top: Vector3 = Vector3.ZERO:
	set(value):
		top = value
		_rebuild_if_ready()
@export var bottom: Vector3 = Vector3(0.0, -20.0, 0.0):
	set(value):
		bottom = value
		_rebuild_if_ready()
## How far the middle hangs below the straight line between the ends, in metres.
@export var sag: float = 1.5:
	set(value):
		sag = value
		_rebuild_if_ready()
## How long one link is, in metres.
@export var link_length: float = 0.7:
	set(value):
		link_length = maxf(value, 0.05)
		_rebuild_if_ready()
## How thick the iron of a link is, in metres.
@export var thickness: float = 0.08:
	set(value):
		thickness = maxf(value, 0.01)
		_rebuild_if_ready()
## The iron.
@export var iron: Material:
	set(value):
		iron = value
		_rebuild_if_ready()


func _ready() -> void:
	rebuild()


## How many links the chain has.
func link_count() -> int:
	return multimesh.instance_count if multimesh != null else 0


## Where along the chain [param share] of the way down is (0 the top, 1 the
## bottom), in this node's own space: a gentle curve sagging below the line.
func point_at(share: float) -> Vector3:
	var middle: Vector3 = (top + bottom) * 0.5 + Vector3.DOWN * sag * 2.0
	var a: Vector3 = top.lerp(middle, share)
	var b: Vector3 = middle.lerp(bottom, share)
	return a.lerp(b, share)


## Builds the links again.
func rebuild() -> void:
	var span: float = 0.0
	var steps: int = 64
	for index: int in steps:
		span += point_at(float(index) / steps).distance_to(point_at(float(index + 1) / steps))
	# Links overlap where they hook through each other.
	var pitch: float = link_length * 0.78
	var count: int = maxi(int(span / pitch), 1)
	var torus: TorusMesh = TorusMesh.new()
	torus.outer_radius = 0.5
	torus.inner_radius = 0.5 - thickness / link_length * 1.4
	torus.rings = 10
	torus.ring_segments = 6
	torus.material = iron
	var links: MultiMesh = MultiMesh.new()
	links.transform_format = MultiMesh.TRANSFORM_3D
	links.mesh = torus
	links.instance_count = count
	for index: int in count:
		var share: float = (float(index) + 0.5) / count
		var here: Vector3 = point_at(share)
		var along: Vector3 = (point_at(minf(share + 0.01, 1.0)) - point_at(maxf(share - 0.01, 0.0))) \
				.normalized()
		var side: Vector3 = along.cross(Vector3.FORWARD)
		if side.length() < 0.01:
			side = along.cross(Vector3.RIGHT)
		side = side.normalized()
		# Every other link is turned a quarter turn about the chain.
		if index % 2 == 1:
			side = along.cross(side).normalized()
		var axis: Vector3 = side.cross(along).normalized()
		# A torus lies flat in its own XZ plane: X across the link, Z along
		# the chain (stretched, as a link is longer than it's wide).
		var basis: Basis = Basis(side * link_length * 0.62, axis * link_length * 0.62,
				along * link_length)
		links.set_instance_transform(index, Transform3D(basis, here))
	multimesh = links


func _rebuild_if_ready() -> void:
	if is_node_ready():
		rebuild()
