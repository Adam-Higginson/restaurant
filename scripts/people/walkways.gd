class_name Walkways
extends Node3D
## The open ways about the ship that crew walk along (#157): a network of
## [Waypoint]s, its children, joined by their links. [method route] finds the
## shortest way from one place to another over them, with Godot's A* search
## ([AStar3D]).
##
## Everything is in this node's own space. It's a child of the ship, so the
## ways move with her as she sails and rolls, and a walker following them is
## carried along too.

## The group the walkways are in, so a walker can find them.
const GROUP: StringName = &"walkways"

var _astar: AStar3D = AStar3D.new()
var _ids: Dictionary[StringName, int] = {}


func _ready() -> void:
	add_to_group(GROUP)
	rebuild()


## The ship's walkways, looked for from [param from], or null.
static func find(from: Node) -> Walkways:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as Walkways


## Reads the waypoints and their links again (after they've been changed).
func rebuild() -> void:
	_astar.clear()
	_ids.clear()
	for point: Waypoint in waypoints():
		var id: int = _ids.size()
		_ids[point.name] = id
		_astar.add_point(id, point.position)
	for point: Waypoint in waypoints():
		for other: StringName in point.links:
			if not _ids.has(other):
				push_error("Walkways: %s links to '%s', which isn't a waypoint" % [point.name, other])
				continue
			_astar.connect_points(_ids[point.name], _ids[other])


## The waypoints, in the order they're in the tree.
func waypoints() -> Array[Waypoint]:
	var found: Array[Waypoint] = []
	for child: Node in get_children():
		if child is Waypoint:
			found.append(child as Waypoint)
	return found


## Every link as its two ends, in this node's space: [code][a, b, a, b...][/code].
func link_ends() -> PackedVector3Array:
	var ends: PackedVector3Array = PackedVector3Array()
	for point: Waypoint in waypoints():
		for other: StringName in point.links:
			var far: Waypoint = get_node_or_null(NodePath(String(other))) as Waypoint
			if far != null:
				ends.append(point.position)
				ends.append(far.position)
	return ends


## The way from [param from] to [param to] (both in this node's space): the
## waypoints in between, nearest first, ending at [param to]. Empty if
## there's no way there along the links.
func route(from: Vector3, to: Vector3) -> PackedVector3Array:
	var path: PackedVector3Array = PackedVector3Array()
	if _astar.get_point_count() == 0:
		return path
	var start: int = _astar.get_closest_point(from)
	var end: int = _astar.get_closest_point(to)
	var ids: PackedInt64Array = _astar.get_id_path(start, end)
	if ids.is_empty():
		return path
	for id: int in ids:
		path.append(_astar.get_point_position(id))
	if path[path.size() - 1].distance_to(to) > 0.01:
		path.append(to)
	return path
