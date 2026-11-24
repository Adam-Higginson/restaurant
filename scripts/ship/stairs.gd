@tool
class_name Stairs
extends Node3D
## A flight of solid wooden steps, built from boxes as it loads (#204: the
## hatch's ramp became stairs). It's only a look: you walk on a smooth
## slope (a ramp's collision shape) laid along the same line, which the
## treads straddle, so your feet never catch on a step edge.
##
## The flight starts at this node, at the foot of the bottom step, and climbs
## towards -z: [member rise] up over [member run] along. Each tread's middle
## sits on the slope, so the nose of each step stands a little above it and
## its back a little below.

## How high the flight climbs, in metres.
@export var rise: float = 4.3:
	set(value):
		rise = value
		_rebuild()
## How far along it runs (its length on the floor plan).
@export var run: float = 7.45:
	set(value):
		run = value
		_rebuild()
## How wide the steps are (across x).
@export var width: float = 2.0:
	set(value):
		width = value
		_rebuild()
## How many steps there are.
@export_range(1, 60) var steps: int = 24:
	set(value):
		steps = value
		_rebuild()
## How deep each step's block is below the one under it, so the flight is
## solid seen from beneath.
@export var thickness: float = 0.3:
	set(value):
		thickness = value
		_rebuild()
## What the steps are made of.
@export var material: Material:
	set(value):
		material = value
		_rebuild()


func _ready() -> void:
	_rebuild()


## How high each step is.
func step_rise() -> float:
	return rise / steps


## How deep each tread is.
func tread() -> float:
	return run / steps


## The box of step [param index] (0 at the bottom), in this node's space.
func step_box(index: int) -> AABB:
	var top: float = (index + 0.5) * step_rise()
	var bottom: float = maxf(0.0, top - step_rise() - thickness)
	var front: float = -index * tread()
	return AABB(Vector3(-width / 2.0, bottom, front - tread()),
			Vector3(width, top - bottom, tread()))


## How high the slope you walk on is, [param along] metres up the flight.
func slope_height(along: float) -> float:
	return along / run * rise


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for child: Node in get_children(true):
		if child.has_meta(&"step"):
			child.free()
	for index: int in steps:
		var box: AABB = step_box(index)
		var mesh: BoxMesh = BoxMesh.new()
		mesh.size = box.size
		var piece: MeshInstance3D = MeshInstance3D.new()
		piece.name = "Step%d" % (index + 1)
		piece.set_meta(&"step", true)
		piece.mesh = mesh
		piece.material_override = material
		piece.position = box.get_center()
		add_child(piece, false, Node.INTERNAL_MODE_BACK)
