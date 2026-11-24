@tool
class_name HullShell
extends Node3D
## Wraps the ship in the Meshy hull (#196): the outside of the ship, drawn as
## made, around our own decks and rooms. It's only a look: walking and
## collision stay on the ship's own shapes, and the deck's edge and the rails
## follow the hull's shape as saved in a [HullOutline].
##
## Meshy made the hull as a small model (about a metre long, its length along
## X), so it's fitted to the ship as it loads, by moving its points:
## - along the ship by [member length_map], a few model-x to ship-z pairs
##   joined by straight lines, so the middle can be stretched more than the
##   bow and stern and the ends keep their shape;
## - up, with the waist's top edge ([member model_rim]) lifted to
##   [member rim_y]: [member height] times taller above it and
##   [member depth] times below, so the rooms sit where the hull is wide;
## - across by [member width], let out wherever a room below deck
##   ([member room_half_width] either side, from [member room_from_z] to
##   [member room_to_z], [member room_floor_y] to [member room_top_y] high)
##   would poke through, and eased back from there so the sides stay smooth.
##
## Holes for portholes are left undrawn wherever a [HullOpening] is (see
## shaders/hull_shell.gdshader). The model is gitignored art: without it the
## greybox [member stand_ins] stay showing.

## Emitted after [method dress]: [param shown] is true if the hull is showing.
signal dressed(shown: bool)

## Every hull joins this group, so a new opening can ask it to cut its hole.
const GROUP: StringName = &"hull_shells"
## Openings beyond this many aren't cut (the shader's array size).
const MAX_OPENINGS: int = 32
const SHADER: Shader = preload("res://shaders/hull_shell.gdshader")
## The model is measured in a grid of this many slices along its length...
const SLICES: int = 64
## ...by this many heights.
const ROWS: int = 32
## How quickly a let-out width eases back to [member width]: width units per
## metre along the ship, and per metre up or down.
const EASE_ALONG: float = 1.2
const EASE_UP: float = 2.5

## Fitted meshes already made this run, by their settings: the ship is loaded
## many times (every test does), and fitting takes a moment.
static var _fitted: Dictionary[String, ArrayMesh] = {}

## The hull model, under res://assets/third_party/.
@export_file("*.glb", "*.gltf") var path: String = "":
	set(value):
		path = value
		_redress()
## Model x (its length) to ship z, as pairs from bow to stern.
@export var length_map: PackedVector2Array = PackedVector2Array([
		Vector2(-0.476, -21.5), Vector2(-0.2, -13.5), Vector2(0.33, 13.2),
		Vector2(0.476, 16.4)]):
	set(value):
		length_map = value
		_redress()
## How much wider than the model the hull is drawn, at the least.
@export var width: float = 38.0:
	set(value):
		width = value
		_redress()
## How much taller than the model it's drawn above the waist's top edge...
@export var height: float = 30.0:
	set(value):
		height = value
		_redress()
## ...and below it.
@export var depth: float = 40.0:
	set(value):
		depth = value
		_redress()
## The model's height (y) at its waist's top edge.
@export var model_rim: float = 0.069:
	set(value):
		model_rim = value
		_redress()
## Where the waist's top edge goes, in ship y.
@export var rim_y: float = 6.4:
	set(value):
		rim_y = value
		_redress()
## The rooms below deck reach this far either side of the centreline...
@export var room_half_width: float = 6.3:
	set(value):
		room_half_width = value
		_redress()
## ...from here...
@export var room_from_z: float = -4.0:
	set(value):
		room_from_z = value
		_redress()
## ...to here, along the ship...
@export var room_to_z: float = 15.5:
	set(value):
		room_to_z = value
		_redress()
## ...from this high (ship y)...
@export var room_floor_y: float = 1.0:
	set(value):
		room_floor_y = value
		_redress()
## ...to this high.
@export var room_top_y: float = 5.3:
	set(value):
		room_top_y = value
		_redress()
## Build the hull from its starboard half and a mirror image of it. Meshy's
## hull came out with holes along its port side (most of the waist's upper
## planking is missing), and the starboard half is whole.
@export var mirror: bool = true:
	set(value):
		mirror = value
		_redress()
## Greybox to hide while the hull shows.
@export var stand_ins: Array[Node3D] = []

## The fitted hull, while it's showing.
var model: MeshInstance3D = null


func _ready() -> void:
	add_to_group(GROUP)
	dress()


func _process(_delta: float) -> void:
	# In the editor, openings get moved about: keep the holes with them.
	if Engine.is_editor_hint() and model != null:
		refresh_openings()


## Loads and fits the hull. Returns false (and shows the greybox) if the
## model isn't there.
func dress() -> bool:
	if model != null:
		model.queue_free()
		model = null
	var mesh: ArrayMesh = _fitted_mesh()
	if mesh == null:
		_show_stand_ins(true)
		dressed.emit(false)
		return false
	model = MeshInstance3D.new()
	model.name = "Hull"
	model.mesh = mesh
	for surface: int in mesh.get_surface_count():
		var material: ShaderMaterial = (mesh.surface_get_material(surface) as ShaderMaterial)
		model.set_surface_override_material(surface, material.duplicate() as ShaderMaterial)
	add_child(model, false, Node.INTERNAL_MODE_BACK)
	_show_stand_ins(false)
	refresh_openings()
	dressed.emit(true)
	return true


## The ship y a point of the model at model height [param y] goes to.
func ship_y(y: float) -> float:
	return rim_y + (y - model_rim) * (height if y >= model_rim else depth)


## The model height that goes to ship height [param y].
func model_y(y: float) -> float:
	return model_rim + (y - rim_y) / (height if y >= rim_y else depth)


## The hull's mesh moved into ship space (this node's space).
func fit_mesh(source: ArrayMesh, placed: Transform3D) -> ArrayMesh:
	var fitted: ArrayMesh = ArrayMesh.new()
	var grid: PackedFloat32Array = PackedFloat32Array()
	var bounds: AABB = AABB()
	for surface: int in source.get_surface_count():
		var arrays: Array = source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for at: int in vertices.size():
			vertices[at] = placed * vertices[at]
			normals[at] = (placed.basis * normals[at]).normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		# One triangle per three corners from here on, so each can be marked
		# as skin or inside on its own.
		arrays = mirrored(arrays) if mirror else _unshared(arrays)
		vertices = arrays[Mesh.ARRAY_VERTEX]
		normals = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if surface == 0:
			bounds = _bounds_of(vertices)
			grid = width_grid(vertices, indices, bounds)
		for at: int in vertices.size():
			var point: Vector3 = vertices[at]
			var across: float = _grid_at(grid, point, bounds)
			var along: float = stretch_at(point.x, length_map)
			var up: float = height if point.y >= model_rim else depth
			vertices[at] = Vector3(-point.z * across, ship_y(point.y),
					length_at(point.x, length_map))
			var normal: Vector3 = normals[at]
			normals[at] = Vector3(-normal.z / across, normal.y / up, normal.x / along).normalized()
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_TANGENT] = null
		arrays[Mesh.ARRAY_COLOR] = outer_skin(vertices)
		var tool: SurfaceTool = SurfaceTool.new()
		tool.create_from_arrays(arrays)
		tool.generate_tangents()
		tool.set_material(_material_for(source.surface_get_material(surface) as BaseMaterial3D))
		tool.commit(fitted)
	return fitted


## Marks each triangle of the fitted hull white if it's on its outside skin
## and black if it's inside it (the inner planking, the frames and the like),
## which the shader draws with planks of our own. The triangles come three
## corners at a time. A triangle is on the skin if its front (which way its
## corners wind, as Godot draws it, not Meshy's normals, which disagree in
## places) faces up (the top edge), or out to the side, or straight fore or aft at the
## very bow or stern ([param ends] beyond: elsewhere those are frames' sides),
## or lies on the centreline (the stem, keel and rudder).
static func outer_skin(vertices: PackedVector3Array,
		ends: Vector2 = Vector2(-14.5, 13.5)) -> PackedColorArray:
	var colours: PackedColorArray = PackedColorArray()
	colours.resize(vertices.size())
	for corner: int in range(0, vertices.size() - 2, 3):
		var a: Vector3 = vertices[corner]
		var b: Vector3 = vertices[corner + 1]
		var c: Vector3 = vertices[corner + 2]
		# Godot's front faces wind clockwise, so this points out of the front.
		var facing: Vector3 = (c - a).cross(b - a).normalized()
		var centre: Vector3 = (a + b + c) / 3.0
		var outward: bool = Vector2(facing.x, facing.z).dot(Vector2(centre.x, centre.z)) > 0.0
		var lengthways: bool = absf(facing.z) > 0.9
		var at_ends: bool = centre.z < ends.x or centre.z > ends.y
		# The stem, keel and rudder stand on the centreline, where "out" means
		# nothing: they're always outside.
		var on_centreline: bool = absf(centre.x) < 0.35
		var skin: bool = facing.y > 0.7 or on_centreline or outward and (at_ends or not lengthways)
		var colour: Color = Color.WHITE if skin else Color.BLACK
		colours[corner] = colour
		colours[corner + 1] = colour
		colours[corner + 2] = colour
	return colours


## A surface's [param arrays] with no corner shared between triangles.
static func _unshared(arrays: Array) -> Array:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		indices = PackedInt32Array(range(vertices.size()))
	var result: Array = []
	result.resize(Mesh.ARRAY_MAX)
	var out_vertices: PackedVector3Array = PackedVector3Array()
	var out_normals: PackedVector3Array = PackedVector3Array()
	var out_uvs: PackedVector2Array = PackedVector2Array()
	for index: int in indices:
		out_vertices.append(vertices[index])
		out_normals.append(normals[index])
		out_uvs.append(uvs[index])
	result[Mesh.ARRAY_VERTEX] = out_vertices
	result[Mesh.ARRAY_NORMAL] = out_normals
	result[Mesh.ARRAY_TEX_UV] = out_uvs
	result[Mesh.ARRAY_INDEX] = PackedInt32Array(range(out_vertices.size()))
	return result


## A surface's [param arrays] cut down the model's centreline (z = 0), its
## starboard half (z <= 0) kept and a mirror image of it added for port.
## Triangles crossing the centreline are cut exactly there, so the two halves
## meet without overlapping.
static func mirrored(arrays: Array) -> Array:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if indices.is_empty():
		indices = PackedInt32Array(range(vertices.size()))
	var kept_vertices: PackedVector3Array = PackedVector3Array()
	var kept_normals: PackedVector3Array = PackedVector3Array()
	var kept_uvs: PackedVector2Array = PackedVector2Array()
	for corner: int in range(0, indices.size(), 3):
		var corners: PackedInt32Array = PackedInt32Array([indices[corner], indices[corner + 1],
				indices[corner + 2]])
		# Sutherland-Hodgman against the plane z = 0, keeping z <= 0.
		var out_points: PackedVector3Array = PackedVector3Array()
		var out_normals: PackedVector3Array = PackedVector3Array()
		var out_uvs: PackedVector2Array = PackedVector2Array()
		for side: int in 3:
			var here: int = corners[side]
			var next: int = corners[(side + 1) % 3]
			var here_in: bool = vertices[here].z <= 0.0
			var next_in: bool = vertices[next].z <= 0.0
			if here_in:
				out_points.append(vertices[here])
				out_normals.append(normals[here])
				out_uvs.append(uvs[here])
			if here_in != next_in:
				var weight: float = vertices[here].z / (vertices[here].z - vertices[next].z)
				var point: Vector3 = vertices[here].lerp(vertices[next], weight)
				point.z = 0.0
				out_points.append(point)
				out_normals.append(normals[here].lerp(normals[next], weight).normalized())
				out_uvs.append(uvs[here].lerp(uvs[next], weight))
		for fan: int in range(1, out_points.size() - 1):
			for pick: int in PackedInt32Array([0, fan, fan + 1]):
				kept_vertices.append(out_points[pick])
				kept_normals.append(out_normals[pick])
				kept_uvs.append(out_uvs[pick])
	var count: int = kept_vertices.size()
	var all_vertices: PackedVector3Array = kept_vertices.duplicate()
	var all_normals: PackedVector3Array = kept_normals.duplicate()
	var all_uvs: PackedVector2Array = kept_uvs.duplicate()
	for corner: int in range(0, count, 3):
		# Mirrored, each triangle's corners go the other way round so it
		# still faces outwards.
		for pick: int in PackedInt32Array([corner, corner + 2, corner + 1]):
			var point: Vector3 = kept_vertices[pick]
			var normal: Vector3 = kept_normals[pick]
			all_vertices.append(Vector3(point.x, point.y, -point.z))
			all_normals.append(Vector3(normal.x, normal.y, -normal.z))
			all_uvs.append(kept_uvs[pick])
	var result: Array = []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = all_vertices
	result[Mesh.ARRAY_NORMAL] = all_normals
	result[Mesh.ARRAY_TEX_UV] = all_uvs
	result[Mesh.ARRAY_INDEX] = PackedInt32Array(range(all_vertices.size()))
	return result


## How much wider than the model to draw it, in a grid of [constant SLICES]
## along its length by [constant ROWS] up it ([code]slice * ROWS + row[/code]):
## [member width], let out wherever a room would poke through, then eased back
## along the ship and up and down so the sides stay smooth.
func width_grid(vertices: PackedVector3Array, indices: PackedInt32Array,
		bounds: AABB) -> PackedFloat32Array:
	var half_widths: PackedFloat32Array = _model_half_widths(vertices, indices, bounds)
	var needed: PackedFloat32Array = PackedFloat32Array()
	needed.resize(SLICES * ROWS)
	needed.fill(width)
	for slice: int in SLICES:
		var z: float = length_at(_slice_x(slice, bounds), length_map)
		if z < room_from_z or z > room_to_z:
			continue
		var floor_need: float = width
		for row: int in ROWS:
			var y: float = ship_y(_row_y(row, bounds))
			var half: float = half_widths[slice * ROWS + row]
			if y < room_floor_y or y > room_top_y or half <= 0.0:
				continue
			needed[slice * ROWS + row] = maxf(width, room_half_width / half)
			if floor_need == width:
				floor_need = needed[slice * ROWS + row]
		# Below the rooms, keep the hull as full as at their floor, so its
		# bottom isn't pinched in.
		for row: int in ROWS:
			if ship_y(_row_y(row, bounds)) < room_floor_y:
				needed[slice * ROWS + row] = floor_need
	var along: PackedFloat32Array = PackedFloat32Array()
	along.resize(SLICES * ROWS)
	for row: int in ROWS:
		for slice: int in SLICES:
			var z: float = length_at(_slice_x(slice, bounds), length_map)
			var best: float = width
			for other: int in SLICES:
				var other_z: float = length_at(_slice_x(other, bounds), length_map)
				best = maxf(best, needed[other * ROWS + row] - EASE_ALONG * absf(z - other_z))
			along[slice * ROWS + row] = best
	var grid: PackedFloat32Array = PackedFloat32Array()
	grid.resize(SLICES * ROWS)
	for slice: int in SLICES:
		for row: int in ROWS:
			var y: float = ship_y(_row_y(row, bounds))
			var best: float = width
			for other: int in ROWS:
				var other_y: float = ship_y(_row_y(other, bounds))
				best = maxf(best, along[slice * ROWS + other] - EASE_UP * absf(y - other_y))
			grid[slice * ROWS + row] = best
	return grid


## Collects every [HullOpening] on the ship and cuts its hole.
func refresh_openings() -> void:
	if model == null or not is_inside_tree():
		return
	var ship: Node = owner if owner != null else get_parent()
	var found: Array[HullOpening] = []
	for node: Node in get_tree().get_nodes_in_group(HullOpening.GROUP):
		if node is HullOpening and ship.is_ancestor_of(node) and found.size() < MAX_OPENINGS:
			found.append(node as HullOpening)
	var unit: Array[Projection] = []
	for opening: HullOpening in found:
		unit.append(Projection(opening.to_unit(model)))
	while unit.size() < MAX_OPENINGS:
		unit.append(Projection())
	for surface: int in model.mesh.get_surface_count():
		var material: ShaderMaterial = model.get_surface_override_material(surface) as ShaderMaterial
		material.set_shader_parameter("opening_count", found.size())
		material.set_shader_parameter("openings", unit)


## Measures the fitted hull every [param step] metres along the ship: its top
## edge's height, and how wide it is at heights from [param low_y] up, every
## [param height_step]. The deck and the rails follow it. Each triangle is cut
## by each sample's cross-section, so long thin triangles are measured
## properly, not only at their corners.
func measure_outline(step: float = 0.5, low_y: float = 0.0,
		height_step: float = 0.25) -> HullOutline:
	var outline: HullOutline = HullOutline.new()
	if model == null:
		return outline
	var points: PackedVector3Array = _triangles(model.mesh)
	var front: float = INF
	var back: float = -INF
	var top: float = -INF
	for point: Vector3 in points:
		front = minf(front, point.z)
		back = maxf(back, point.z)
		top = maxf(top, point.y)
	var count: int = floori((back - front) / step) + 1
	var rows: int = ceili((top - low_y) / height_step) + 1
	var rims: PackedFloat32Array = PackedFloat32Array()
	rims.resize(count)
	rims.fill(-INF)
	var widths: PackedFloat32Array = PackedFloat32Array()
	widths.resize(count * rows)
	for corner: int in range(0, points.size(), 3):
		var a: Vector3 = points[corner]
		var b: Vector3 = points[corner + 1]
		var c: Vector3 = points[corner + 2]
		var first: int = maxi(ceili((minf(a.z, minf(b.z, c.z)) - front) / step), 0)
		var last: int = mini(floori((maxf(a.z, maxf(b.z, c.z)) - front) / step), count - 1)
		for sample: int in range(first, last + 1):
			var cut: PackedVector3Array = _cut(a, b, c, Vector3.BACK, front + sample * step)
			if cut.size() < 2:
				continue
			rims[sample] = maxf(rims[sample], maxf(cut[0].y, cut[1].y))
			_widen(widths, sample, rows, cut[0], cut[1], low_y, height_step)
	for sample: int in count:
		if is_inf(rims[sample]):
			rims[sample] = rims[sample - 1] if sample > 0 else low_y
	outline.start_z = front
	outline.step = step
	outline.rims = rims
	outline.low_y = low_y
	outline.height_step = height_step
	outline.heights = rows
	outline.widths = widths
	return outline


## Ship z for model x, along the straight lines between [param map]'s pairs
## (and on past the first and last).
static func length_at(x: float, map: PackedVector2Array) -> float:
	var segment: int = _segment(x, map)
	var from: Vector2 = map[segment]
	var to: Vector2 = map[segment + 1]
	return lerpf(from.y, to.y, (x - from.x) / (to.x - from.x))


## How many metres of ship one unit of model length becomes at [param x].
static func stretch_at(x: float, map: PackedVector2Array) -> float:
	var segment: int = _segment(x, map)
	var from: Vector2 = map[segment]
	var to: Vector2 = map[segment + 1]
	return (to.y - from.y) / (to.x - from.x)


## Where a triangle crosses the plane [code]point · axis == at[/code]: the two
## ends of the line it makes there (or fewer if it only touches).
static func _cut(a: Vector3, b: Vector3, c: Vector3, axis: Vector3,
		at: float) -> PackedVector3Array:
	var cut: PackedVector3Array = PackedVector3Array()
	_cross(cut, a, b, axis, at)
	_cross(cut, b, c, axis, at)
	_cross(cut, c, a, axis, at)
	return cut


static func _cross(cut: PackedVector3Array, from: Vector3, to: Vector3, axis: Vector3,
		at: float) -> void:
	var start: float = from.dot(axis)
	var end: float = to.dot(axis)
	if cut.size() >= 2 or (start - at) * (end - at) > 0.0 or is_equal_approx(start, end):
		return
	var point: Vector3 = from.lerp(to, (at - start) / (end - start))
	# A corner lying on the plane is met by two edges: count it once.
	if cut.size() == 1 and cut[0].is_equal_approx(point):
		return
	cut.append(point)


## Records how far the line from [param from] to [param to] reaches out at
## each measured height it crosses.
static func _widen(widths: PackedFloat32Array, sample: int, rows: int, from: Vector3,
		to: Vector3, low_y: float, height_step: float) -> void:
	var lowest: int = maxi(ceili((minf(from.y, to.y) - low_y) / height_step), 0)
	var highest: int = mini(floori((maxf(from.y, to.y) - low_y) / height_step), rows - 1)
	for row: int in range(lowest, highest + 1):
		var y: float = low_y + row * height_step
		var x: float = from.x
		if not is_equal_approx(from.y, to.y):
			x = lerpf(from.x, to.x, (y - from.y) / (to.y - from.y))
		var at: int = sample * rows + row
		widths[at] = maxf(widths[at], absf(x))


static func _segment(x: float, map: PackedVector2Array) -> int:
	for at: int in map.size() - 2:
		if x < map[at + 1].x:
			return at
	return map.size() - 2


## How far the model reaches out (its z) in each cell of the grid, found by
## cutting its triangles at each row's height.
func _model_half_widths(vertices: PackedVector3Array, indices: PackedInt32Array,
		bounds: AABB) -> PackedFloat32Array:
	var half_widths: PackedFloat32Array = PackedFloat32Array()
	half_widths.resize(SLICES * ROWS)
	for corner: int in range(0, indices.size(), 3):
		var a: Vector3 = vertices[indices[corner]]
		var b: Vector3 = vertices[indices[corner + 1]]
		var c: Vector3 = vertices[indices[corner + 2]]
		for row: int in ROWS:
			var cut: PackedVector3Array = _cut(a, b, c, Vector3.UP, _row_y(row, bounds))
			if cut.size() < 2:
				continue
			for step: int in 5:
				var point: Vector3 = cut[0].lerp(cut[1], step / 4.0)
				var at: int = _slice_of(point.x, bounds) * ROWS + row
				half_widths[at] = maxf(half_widths[at], absf(point.z))
	return half_widths


func _fitted_mesh() -> ArrayMesh:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var key: String = var_to_str([path, length_map, width, height, depth, model_rim, rim_y,
			room_half_width, room_from_z, room_to_z, room_floor_y, room_top_y, mirror])
	if _fitted.has(key):
		return _fitted[key]
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return null
	var root: Node = scene.instantiate()
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	var mesh: ArrayMesh = null
	if not meshes.is_empty():
		var found: MeshInstance3D = meshes[0] as MeshInstance3D
		mesh = fit_mesh(found.mesh as ArrayMesh, _to_root(found, root))
		_fitted[key] = mesh
	root.free()
	return mesh


func _material_for(source: BaseMaterial3D) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	if source != null:
		material.set_shader_parameter("albedo_texture", source.albedo_texture)
		material.set_shader_parameter("normal_texture", source.normal_texture)
		material.set_shader_parameter("roughness_texture", source.roughness_texture)
	return material


func _show_stand_ins(show_them: bool) -> void:
	for node: Node3D in stand_ins:
		if node != null:
			node.visible = show_them


func _redress() -> void:
	if is_inside_tree():
		dress()


func _grid_at(grid: PackedFloat32Array, point: Vector3, bounds: AABB) -> float:
	var along: float = clampf((point.x - bounds.position.x) / bounds.size.x * SLICES - 0.5,
			0.0, SLICES - 1.0)
	var up: float = clampf((point.y - bounds.position.y) / bounds.size.y * ROWS - 0.5,
			0.0, ROWS - 1.0)
	var s0: int = floori(along)
	var s1: int = mini(s0 + 1, SLICES - 1)
	var r0: int = floori(up)
	var r1: int = mini(r0 + 1, ROWS - 1)
	var near: float = lerpf(grid[s0 * ROWS + r0], grid[s0 * ROWS + r1], up - r0)
	var far: float = lerpf(grid[s1 * ROWS + r0], grid[s1 * ROWS + r1], up - r0)
	return lerpf(near, far, along - s0)


static func _slice_of(x: float, bounds: AABB) -> int:
	return clampi(int((x - bounds.position.x) / bounds.size.x * SLICES), 0, SLICES - 1)


static func _slice_x(slice: int, bounds: AABB) -> float:
	return bounds.position.x + (slice + 0.5) * bounds.size.x / SLICES


static func _row_y(row: int, bounds: AABB) -> float:
	return bounds.position.y + (row + 0.5) * bounds.size.y / ROWS


static func _bounds_of(points: PackedVector3Array) -> AABB:
	var bounds: AABB = AABB(points[0], Vector3.ZERO)
	for point: Vector3 in points:
		bounds = bounds.expand(point)
	return bounds


static func _triangles(mesh: Mesh) -> PackedVector3Array:
	var points: PackedVector3Array = PackedVector3Array()
	for surface: int in mesh.get_surface_count():
		var arrays: Array = mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if indices.is_empty():
			points.append_array(vertices)
		for index: int in indices:
			points.append(vertices[index])
	return points


static func _to_root(node: Node, root: Node) -> Transform3D:
	var placed: Transform3D = Transform3D.IDENTITY
	var at: Node = node
	while at != root and at is Node3D:
		placed = (at as Node3D).transform * placed
		at = at.get_parent()
	return placed
