@tool
class_name HullOpening
extends Node3D
## A round hole through the ship's hull, for a porthole (#196). The hull
## ([HullShell]) doesn't draw itself inside the hole, so you can see through:
## into a lit room from outside, out to sea from inside. Lamplight from the
## room shines out through it too, since the hole is cut in the shadows as well.
##
## The hole runs along this node's local Z axis, [member depth] long and
## centred on it. Put it where the porthole is, facing out of the ship, long
## enough to reach from the room's wall to the outside of the hull. Move it and
## the hole moves with it, so a room decides where its portholes are.

## Every opening joins this group, so the hull can find them.
const GROUP: StringName = &"hull_openings"

## The hole's radius, in metres.
@export var radius: float = 0.3:
	set(value):
		radius = value
		_build_sleeve()
## How far the hole reaches along local Z, in metres (centred on this node).
@export var depth: float = 1.2:
	set(value):
		depth = value
		_build_sleeve()
## Line the hole with a short dark tube, so you don't see into the hollow
## between the room's wall and the hull.
@export var sleeve: bool = true:
	set(value):
		sleeve = value
		_build_sleeve()

var _sleeve: MeshInstance3D = null


func _ready() -> void:
	add_to_group(GROUP)
	_build_sleeve()


## Maps a point in [param space]'s local coordinates into the hole's own,
## where the hole is the cylinder x² + y² < 1, -1 < z < 1.
func to_unit(space: Node3D) -> Transform3D:
	var unit: Transform3D = global_transform.scaled_local(
			Vector3(radius, radius, depth / 2.0))
	return unit.affine_inverse() * space.global_transform


## True if [param point] (in global space) is inside the hole.
func contains(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	return Vector2(local.x, local.y).length() < radius and absf(local.z) < depth / 2.0


func _build_sleeve() -> void:
	if not is_inside_tree():
		return
	if _sleeve != null:
		_sleeve.queue_free()
		_sleeve = null
	if not sleeve:
		return
	var tube: CylinderMesh = CylinderMesh.new()
	tube.top_radius = radius
	tube.bottom_radius = radius
	tube.height = depth
	tube.cap_top = false
	tube.cap_bottom = false
	tube.radial_segments = 24
	tube.rings = 1
	var lining: StandardMaterial3D = StandardMaterial3D.new()
	lining.albedo_color = Color(0.16, 0.1, 0.07)
	lining.roughness = 0.9
	lining.cull_mode = BaseMaterial3D.CULL_DISABLED
	tube.material = lining
	_sleeve = MeshInstance3D.new()
	_sleeve.name = "Sleeve"
	_sleeve.mesh = tube
	_sleeve.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(_sleeve, false, Node.INTERNAL_MODE_BACK)
