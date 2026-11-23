@tool
class_name IslandScatter
extends Node3D
## Stands copies of one prop (a palm, a bush, a rock) about an island, on
## the ground, by rule: so many of them, within a band of how far inland,
## not on steep ground, no closer together than so far. The same seed always
## gives the same grove, so a number in the Inspector is all there is to
## tune.
##
## The copies are made when the scene starts (and in the editor, so you see
## them) and are never saved into the scene.

## The lie of the land they stand on.
@export var shape: IslandShape:
	set(value):
		shape = value
		_refresh()
## The prop to copy.
@export var prop: PackedScene:
	set(value):
		prop = value
		_refresh()
## How many to stand. Fewer appear if there isn't room.
@export var count: int = 10:
	set(value):
		count = value
		_refresh()
## Which arrangement you get.
@export var scatter_seed: int = 1:
	set(value):
		scatter_seed = value
		_refresh()

@export_group("Where")
## The stretch of beach they may stand along: from this X to that X.
@export var along: Vector2 = Vector2(-60.0, 60.0):
	set(value):
		along = value
		_refresh()
## How far inland of the waterline they may stand: from so many metres to so
## many. Negative is out in the water.
@export var inland: Vector2 = Vector2(14.0, 40.0):
	set(value):
		inland = value
		_refresh()
## The steepest ground one will stand on (rise over run).
@export var max_slope: float = 0.5:
	set(value):
		max_slope = value
		_refresh()
## The closest two may stand, in metres.
@export var spacing: float = 3.0:
	set(value):
		spacing = value
		_refresh()

@export_group("How")
## Each is scaled by a number between these two.
@export var size_range: Vector2 = Vector2(0.85, 1.2):
	set(value):
		size_range = value
		_refresh()
## Each is turned to face somewhere between these two, in degrees. The same
## number twice fixes which way it faces.
@export var turn_degrees: Vector2 = Vector2(0.0, 360.0):
	set(value):
		turn_degrees = value
		_refresh()
## The furthest one leans from upright, in degrees.
@export var lean_degrees: float = 4.0:
	set(value):
		lean_degrees = value
		_refresh()
## How far each is sunk into the ground, in metres (to bury a model's base).
@export var sink: float = 0.0:
	set(value):
		sink = value
		_refresh()

var _copies: Array[Node3D] = []


func _ready() -> void:
	scatter()


## Where the copies go: each spot's position and how inland-ness, slope and
## spacing allowed it. Worked out from the shape and the seed alone.
func spots() -> Array[Vector3]:
	var found: Array[Vector3] = []
	if shape == null:
		return found
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = scatter_seed
	# Try many more times than needed: most tries land somewhere not allowed.
	for attempt: int in count * 40:
		if found.size() >= count:
			break
		var x: float = random.randf_range(along.x, along.y)
		var back: float = random.randf_range(inland.x, inland.y)
		var z: float = shape.shore_line(x) - back
		if not shape.covers(x, z) or shape.slope_at(x, z) > max_slope:
			continue
		var spot: Vector3 = Vector3(x, shape.height_at(x, z), z)
		if _too_close(spot, found):
			continue
		found.append(spot)
	return found


## Clears the copies and stands them afresh.
func scatter() -> void:
	for copy: Node3D in _copies:
		if is_instance_valid(copy):
			copy.queue_free()
	_copies.clear()
	if prop == null:
		return
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = scatter_seed + 1000
	for spot: Vector3 in spots():
		var copy: Node3D = prop.instantiate() as Node3D
		if copy == null:
			continue
		add_child(copy)
		var lean: float = deg_to_rad(lean_degrees)
		copy.rotation = Vector3(
			random.randf_range(-lean, lean),
			deg_to_rad(random.randf_range(turn_degrees.x, turn_degrees.y)),
			random.randf_range(-lean, lean)
		)
		copy.scale = Vector3.ONE * random.randf_range(size_range.x, size_range.y)
		copy.position = spot - Vector3(0.0, sink, 0.0)
		_copies.append(copy)


func _too_close(spot: Vector3, others: Array[Vector3]) -> bool:
	for other: Vector3 in others:
		if Vector2(spot.x - other.x, spot.z - other.z).length() < spacing:
			return true
	return false


func _refresh() -> void:
	if is_inside_tree():
		scatter()
