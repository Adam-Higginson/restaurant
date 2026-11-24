@tool
class_name HullOpening
extends Node3D
## A round hole through the ship's hull, for a porthole (#196). The hull
## ([HullShell]) doesn't draw itself inside the hole, so you can see through:
## into a lit room from outside, out to sea from inside. Lamplight from the
## room shines out through it too, since the hole is cut in the shadows as well.
##
## The hole runs along this node's Z axis, from here out to the hull's outside:
## whichever way (+Z or -Z) leaves the hull sooner, found by stepping out
## through the hull's saved [member outline]. The porthole scene carries one,
## so wherever a room puts a porthole against its wall, the hull opens behind
## it; move the porthole and the hole moves with it.

## Every opening joins this group, so the hull can find them.
const GROUP: StringName = &"hull_openings"
## The brass ring round the hole on the outside of the hull.
const RIM_MATERIAL: Material = preload("res://assets/placeholder/materials/brass.tres")
## How far to look for the hull's outside, in metres.
const FARTHEST: float = 4.0
## How finely to step while looking.
const STEP: float = 0.05

## The hole's radius, in metres.
@export var radius: float = 0.3:
	set(value):
		radius = value
		_build_sleeve()
## The hull's shape, to find how far the hole has to reach.
@export var outline: HullOutline
## Line the hole with a short dark tube, so you don't see into the hollow
## between the room's wall and the hull, and ring it in brass outside.
@export var sleeve: bool = true:
	set(value):
		sleeve = value
		_build_sleeve()

## How far the hole reaches along this node's Z (in its own units, which a
## scaled porthole stretches), and which way (+1 or -1).
var depth: float = 0.0
var direction: float = -1.0

var _sleeve: MeshInstance3D = null
var _rim: MeshInstance3D = null


func _ready() -> void:
	add_to_group(GROUP)
	fit()
	# The hull may have been ready first: tell it there's a new hole.
	get_tree().call_group_flags(SceneTree.GROUP_CALL_DEFERRED, HullShell.GROUP,
			&"refresh_openings")


## Finds how far the hole must reach to get out through the hull, and which
## way, then lines it. Zero depth (no hole) if there's no hull around it.
func fit() -> void:
	depth = 0.0
	var ship: Node3D = _ship()
	if outline != null and ship != null:
		var start: Vector3 = ship.to_local(global_position)
		var along_z: Vector3 = ship.global_basis.inverse() * global_basis.z
		var axis: Vector3 = along_z.normalized()
		var forward: float = reach(start, axis)
		var backward: float = reach(start, -axis)
		if minf(forward, backward) < FARTHEST:
			direction = 1.0 if forward < backward else -1.0
			# Out to wherever the hull stands farthest round the hole (a wale
			# may cross it), so the brass rim sits on top of everything.
			var out: Vector3 = axis * direction
			var across: Vector3 = (ship.global_basis.inverse() * global_basis.x).normalized()
			var up: Vector3 = out.cross(across).normalized()
			var ring: float = radius * along_z.length() + 0.1
			var farthest: float = minf(forward, backward)
			var around_hole: Array[Vector3] = [across * ring, -across * ring, up * ring, -up * ring]
			for offset: Vector3 in around_hole:
				var around: float = reach(start + offset, out)
				if around < FARTHEST:
					farthest = maxf(farthest, around)
			depth = (farthest + 0.08) / along_z.length()
	_build_sleeve()


## How far from [param start] (ship space) along [param axis] it is to the
## hull's outside, or [constant FARTHEST] if it never gets out.
func reach(start: Vector3, axis: Vector3) -> float:
	var along: float = 0.0
	while along < FARTHEST:
		var point: Vector3 = start + axis * along
		if not outline.covers(point.z) or absf(point.x) > outline.half_width_at(point.z, point.y):
			return along
		along += STEP
	return FARTHEST


## Maps a point in [param space]'s local coordinates into the hole's own,
## where the hole is the cylinder x² + y² < 1, -1 < z < 1.
func to_unit(space: Node3D) -> Transform3D:
	var middle: Transform3D = global_transform.translated_local(
			Vector3(0.0, 0.0, direction * depth / 2.0))
	var unit: Transform3D = middle.scaled_local(Vector3(radius, radius, maxf(depth, 0.001) / 2.0))
	return unit.affine_inverse() * space.global_transform


## True if [param point] (in global space) is inside the hole.
func contains(point: Vector3) -> bool:
	var local: Vector3 = to_local(point)
	var along: float = local.z * direction
	return Vector2(local.x, local.y).length() < radius and along > 0.0 and along < depth


func _ship() -> Node3D:
	var at: Node = get_parent()
	while at != null:
		if at is Ship:
			return at as Node3D
		at = at.get_parent()
	return null


func _build_sleeve() -> void:
	if not is_inside_tree():
		return
	for old: MeshInstance3D in [_sleeve, _rim]:
		if old != null:
			old.queue_free()
	_sleeve = null
	_rim = null
	if not sleeve or depth <= 0.0:
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
	_sleeve.position = Vector3(0.0, 0.0, direction * depth / 2.0)
	add_child(_sleeve, false, Node.INTERNAL_MODE_BACK)
	var ring: TorusMesh = TorusMesh.new()
	ring.inner_radius = radius
	ring.outer_radius = radius + 0.09
	ring.material = RIM_MATERIAL
	_rim = MeshInstance3D.new()
	_rim.name = "Rim"
	_rim.mesh = ring
	_rim.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	_rim.position = Vector3(0.0, 0.0, direction * (depth - 0.06))
	add_child(_rim, false, Node.INTERNAL_MODE_BACK)
