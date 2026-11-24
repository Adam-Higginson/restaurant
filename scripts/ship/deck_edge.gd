@tool
class_name DeckEdge
extends Node3D
## The decks' edges, made to fit the hull (#196). The hull ([HullShell]) is
## ship-shaped, wider than our old square decks amidships and narrower at the
## bow, so the decks follow its shape here, read from a saved [HullOutline]
## (never from the art, so walking is the same on every computer):
## - [member pieces]: whole stretches of deck, reaching from side to side of
##   the hull (the forecastle and bow, the main deck forward, the after end of
##   the quarterdeck), standing in for the old square ones in [member retired];
## - [member strips]: where the old decks stay (they have the hatch and the
##   stairwells cut out of them), a strip from their edge out to the hull;
## - [member sides]: along each side, a wall you can't walk through at the
##   hull's inside, and where the hull's top edge is lower than a rail would
##   be, a rail on top of it.
##
## Each is built when the scene loads. The walls are the [Ship]'s collision
## (a physics body only feels shapes it owns, so they're given to it through
## its shape owners rather than added as children).

## How thick the hull's side is: the decks stop this far inside its outside.
const HULL_THICKNESS: float = 0.12
## How high a rail stands above its deck.
const RAIL_HEIGHT: float = 1.0
## How high the walls along the sides reach above their deck.
const WALL_HEIGHT: float = 1.6
## Metres between rail posts.
const POST_SPACING: float = 0.9
## A side is built only where the hull is wider than this (the stem is narrow).
const NARROWEST: float = 0.45

## The hull's shape.
@export var outline: HullOutline
## The decks' material.
@export var deck_material: Material
## The rails' material.
@export var rail_material: Material
## Whole stretches of deck: (height, from z, to z), bow first.
@export var pieces: PackedVector3Array = PackedVector3Array()
## Strips from an old deck's edge to the hull: (height, from z, to z, from x).
@export var strips: PackedVector4Array = PackedVector4Array()
## Sides to wall in and rail where the hull is low: (height, from z, to z).
@export var sides: PackedVector3Array = PackedVector3Array()
## Panels across the gap between an old deck's edge and the hull, so you
## can't walk into it: (height, z, how tall, from x).
@export var bulkheads: PackedVector4Array = PackedVector4Array()
## Close the after end of the last side across the stern.
@export var close_stern: bool = true
## Old greybox decks and rails the pieces stand in for: hidden.
@export var retired: Array[Node3D] = []

var _owner_id: int = -1


func _ready() -> void:
	build()


## Builds the decks, rails and walls (again, clearing the last ones).
func build() -> void:
	for child: Node in get_children(true):
		if child.get_meta(&"deck_edge", false):
			child.free()
	var body: CollisionObject3D = get_parent() as CollisionObject3D
	if body != null and _owner_id >= 0:
		body.remove_shape_owner(_owner_id)
		_owner_id = -1
	for node: Node3D in retired:
		if node != null:
			node.visible = false
	if outline == null or outline.samples() == 0:
		return
	var decks: SurfaceTool = _start()
	var floors: PackedVector3Array = PackedVector3Array()
	for piece: Vector3 in pieces:
		_add_deck(decks, floors, piece.x, piece.y, piece.z, -1.0)
	for strip: Vector4 in strips:
		_add_deck(decks, floors, strip.x, strip.y, strip.z, strip.w)
	_add_mesh("Decks", decks, deck_material)
	var rails: SurfaceTool = _start()
	var walls: PackedVector3Array = PackedVector3Array()
	for side: Vector3 in sides:
		for sign: float in PackedFloat32Array([-1.0, 1.0]):
			_add_side(rails, walls, side.x, side.y, side.z, sign)
	for bulkhead: Vector4 in bulkheads:
		for sign: float in PackedFloat32Array([-1.0, 1.0]):
			_add_bulkhead(rails, walls, bulkhead, sign)
	if close_stern and not sides.is_empty():
		_add_stern(walls, sides[sides.size() - 1].x)
	_add_mesh("Rails", rails, rail_material)
	if body != null and not Engine.is_editor_hint():
		_owner_id = body.create_shape_owner(self)
		body.shape_owner_set_transform(_owner_id, transform)
		body.shape_owner_add_shape(_owner_id, _trimesh(floors))
		body.shape_owner_add_shape(_owner_id, _trimesh(walls))


## How far the hull's inside is from the centreline at [param z], at
## [param y] high (zero where the hull isn't).
func inside_at(z: float, y: float) -> float:
	var outside: float = outline.half_width_at(z, y)
	return maxf(outside - HULL_THICKNESS, 0.0) if outside > 0.0 else 0.0


## How far the hull's inside is from the centreline at [param z], a little
## above a deck at [param y] (but under the hull's top edge, where it's low).
func wall_at(z: float, y: float) -> float:
	return inside_at(z, minf(y + 0.6, outline.rim_at(z) - 0.05))


## Where along the ship the hull is at least [constant NARROWEST] wide at
## [param y], between [param from_z] and [param to_z].
func span_at(y: float, from_z: float, to_z: float) -> Vector2:
	var first: float = maxf(from_z, outline.start_z)
	var last: float = minf(to_z, outline.end_z())
	while first < last and inside_at(first, y) < NARROWEST:
		first += outline.step / 4.0
	while last > first and inside_at(last, y) < NARROWEST:
		last -= outline.step / 4.0
	return Vector2(first, last)


func _add_deck(tool: SurfaceTool, floors: PackedVector3Array, y: float, from_z: float,
		to_z: float, from_x: float) -> void:
	var span: Vector2 = span_at(y + 0.05, from_z, to_z)
	var zs: PackedFloat32Array = _steps(span.x, span.y)
	for sign: float in PackedFloat32Array([-1.0, 1.0]):
		for at: int in zs.size() - 1:
			var near_z: float = zs[at]
			var far_z: float = zs[at + 1]
			var near_out: float = inside_at(near_z, y + 0.05)
			var far_out: float = inside_at(far_z, y + 0.05)
			var near_in: float = 0.0 if from_x < 0.0 else minf(from_x, near_out)
			var far_in: float = 0.0 if from_x < 0.0 else minf(from_x, far_out)
			var quad: PackedVector3Array = PackedVector3Array([
				Vector3(sign * near_in, y, near_z), Vector3(sign * near_out, y, near_z),
				Vector3(sign * far_out, y, far_z), Vector3(sign * far_in, y, far_z)])
			_quad(tool, floors, quad, Vector3.UP, sign < 0.0)


func _add_side(tool: SurfaceTool, walls: PackedVector3Array, y: float, from_z: float,
		to_z: float, sign: float) -> void:
	var span: Vector2 = span_at(y + 0.05, from_z, to_z)
	var zs: PackedFloat32Array = _steps(span.x, span.y)
	for at: int in zs.size() - 1:
		var near: Vector3 = Vector3(sign * wall_at(zs[at], y), y, zs[at])
		var far: Vector3 = Vector3(sign * wall_at(zs[at + 1], y), y, zs[at + 1])
		walls.append_array(PackedVector3Array([near, far, far + Vector3.UP * WALL_HEIGHT,
			near, far + Vector3.UP * WALL_HEIGHT, near + Vector3.UP * WALL_HEIGHT]))
	# A rail on the hull's top edge, wherever that's lower than a rail would be.
	var along: float = span.x
	var last_top: Vector3 = Vector3.INF
	while along <= span.y:
		var rim: float = outline.rim_at(along)
		var rail_top: float = y + RAIL_HEIGHT
		if rim < rail_top - 0.1:
			var x: float = sign * maxf(outline.half_width_at(along, rim - 0.05) - 0.08, 0.0)
			var foot: Vector3 = Vector3(x, rim - 0.05, along)
			var head: Vector3 = Vector3(x, rail_top, along)
			_box(tool, foot.lerp(head, 0.5), Vector3(0.09, head.y - foot.y, 0.09), 0.0)
			if last_top != Vector3.INF:
				_beam(tool, last_top, head + Vector3.UP * 0.03, Vector2(0.14, 0.07))
			last_top = head + Vector3.UP * 0.03
		else:
			last_top = Vector3.INF
		along += POST_SPACING


func _add_bulkhead(tool: SurfaceTool, walls: PackedVector3Array, bulkhead: Vector4,
		sign: float) -> void:
	var y: float = bulkhead.x
	var z: float = bulkhead.y
	var tall: float = bulkhead.z
	var inner: float = bulkhead.w
	var outer: float = wall_at(z, y) + HULL_THICKNESS
	if outer <= inner:
		return
	var centre: Vector3 = Vector3(sign * (inner + outer) / 2.0, y + tall / 2.0, z)
	_box(tool, centre, Vector3(outer - inner, tall, 0.1), 0.0)
	var near: Vector3 = Vector3(sign * inner, y, z)
	var far: Vector3 = Vector3(sign * outer, y, z)
	walls.append_array(PackedVector3Array([near, far, far + Vector3.UP * tall,
		near, far + Vector3.UP * tall, near + Vector3.UP * tall]))


func _add_stern(walls: PackedVector3Array, y: float) -> void:
	var z: float = outline.end_z() - HULL_THICKNESS - 0.15
	var half: float = wall_at(z, y)
	var left: Vector3 = Vector3(-half, y, z)
	var right: Vector3 = Vector3(half, y, z)
	walls.append_array(PackedVector3Array([left, right, right + Vector3.UP * WALL_HEIGHT,
		left, right + Vector3.UP * WALL_HEIGHT, left + Vector3.UP * WALL_HEIGHT]))


func _steps(from_z: float, to_z: float) -> PackedFloat32Array:
	var zs: PackedFloat32Array = PackedFloat32Array([from_z])
	var next: float = ceilf(from_z / outline.step) * outline.step
	while next < to_z:
		if next > from_z + 0.01:
			zs.append(next)
		next += outline.step
	zs.append(to_z)
	return zs


func _start() -> SurfaceTool:
	var tool: SurfaceTool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	return tool


func _add_mesh(called: String, tool: SurfaceTool, material: Material) -> void:
	tool.generate_tangents()
	var mesh: ArrayMesh = tool.commit()
	if mesh.get_surface_count() == 0:
		return
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = called
	instance.mesh = mesh
	instance.material_override = material
	instance.set_meta(&"deck_edge", true)
	add_child(instance, false, Node.INTERNAL_MODE_BACK)


## A flat four-cornered piece facing [param normal], given corner by corner
## round its edge; [param flip] turns the winding for the mirrored side.
func _quad(tool: SurfaceTool, floors: PackedVector3Array, corners: PackedVector3Array,
		normal: Vector3, flip: bool) -> void:
	# Godot draws a triangle's front where its corners run clockwise.
	var order: PackedInt32Array = PackedInt32Array([0, 1, 2, 0, 2, 3]) if not flip \
			else PackedInt32Array([0, 2, 1, 0, 3, 2])
	for pick: int in order:
		var point: Vector3 = corners[pick]
		tool.set_normal(normal)
		tool.set_uv(Vector2(point.x, point.z))
		tool.add_vertex(point)
		floors.append(point)


## A box centred at [param centre], [param size] big, turned [param turn]
## about the vertical.
func _box(tool: SurfaceTool, centre: Vector3, size: Vector3, turn: float) -> void:
	var box: BoxMesh = BoxMesh.new()
	box.size = size
	var placed: Transform3D = Transform3D(Basis(Vector3.UP, turn), centre)
	tool.append_from(box, 0, placed)


## A beam from [param from] to [param to], [param section] wide and deep.
func _beam(tool: SurfaceTool, from: Vector3, to: Vector3, section: Vector2) -> void:
	var length: float = from.distance_to(to)
	if length < 0.01:
		return
	var box: BoxMesh = BoxMesh.new()
	box.size = Vector3(section.x, section.y, length)
	var placed: Transform3D = Transform3D(Basis(), from.lerp(to, 0.5)).looking_at(to, Vector3.UP)
	tool.append_from(box, 0, Transform3D(placed.basis, from.lerp(to, 0.5)))


func _trimesh(faces: PackedVector3Array) -> ConcavePolygonShape3D:
	var shape: ConcavePolygonShape3D = ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	return shape
