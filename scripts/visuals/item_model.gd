class_name ItemModel
extends RefCounted
## Builds greybox 3D models for items: food is a small cube in the item's
## colour, a chopping board is a flat slab, and a plate is a flat disc. A
## vessel shows its food on top, and a bar above it fills as a reaction runs
## (the cuts towards the next chop).
##
## Display only. Counters and the carried stack throw the old model away and
## build a new one whenever what they hold changes.

## A food item's edge, in metres.
const FOOD_SIZE: float = 0.2
## Food sitting on a vessel is smaller, so up to three fit.
const FOOD_ON_VESSEL_SIZE: float = 0.13
## A chopping board (a vessel taken apart, not whole).
const BOARD_SIZE: Vector3 = Vector3(0.5, 0.04, 0.34)
## A plate or bowl (a vessel carried whole).
const PLATE_RADIUS: float = 0.21
const PLATE_HEIGHT: float = 0.03
## The progress bar's full length and thickness, and how far above the vessel.
const BAR_LENGTH: float = 0.4
const BAR_THICKNESS: float = 0.03
const BAR_ABOVE: float = 0.25
const BAR_BACK_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
const BAR_COLOR: Color = Color(0.95, 0.85, 0.3, 1)

## One material per colour, shared by every model.
static var _materials: Dictionary[Color, StandardMaterial3D] = {}


## A new model of [param instance], standing on its base at the origin.
static func build(instance: ItemInstance) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Item"
	if not instance.is_vessel():
		root.add_child(_box(Vector3.ONE * FOOD_SIZE, instance.item.color,
				Vector3.UP * FOOD_SIZE / 2.0))
		return root
	var base: float = vessel_height(instance.item)
	_add_vessel(root, instance.item)
	var food: Array[ItemInstance] = instance.contents.get_contents()
	for i: int in food.size():
		var spot: Vector2 = _food_spot(i, food.size())
		var centre: Vector3 = Vector3(spot.x, base + FOOD_ON_VESSEL_SIZE / 2.0, spot.y)
		var piece: MeshInstance3D = _box(Vector3.ONE * FOOD_ON_VESSEL_SIZE,
				food[i].item.color, centre)
		piece.name = "Food%d" % i
		root.add_child(piece)
	# Heat's progress shows as a bar over the vessel. A cut's shows under the
	# chop meter instead (ChopMeterBar), so it isn't drawn twice.
	for active: ActiveReaction in instance.contents.get_active_reactions():
		var element: Element = active.reaction.driving_element()
		if element != null and element.kind == Element.Kind.TIMED:
			root.add_child(_progress_bar(active.get_fraction()))
			break
	return root


## How tall the vessel [param item] is without its food.
static func vessel_height(item: Item) -> float:
	match item.vessel_shape:
		Item.VesselShape.BOWL:
			return 0.05
		Item.VesselShape.PAN:
			return 0.04
		Item.VesselShape.POT:
			return 0.1
	return PLATE_HEIGHT if item.carried_whole else BOARD_SIZE.y


# The vessel itself, by its shape: a board or plate, a bowl, a pan with a
# long handle, or a deep pot with two side handles.
static func _add_vessel(root: Node3D, item: Item) -> void:
	var colour: Color = item.color
	match item.vessel_shape:
		Item.VesselShape.BOWL:
			var bowl: MeshInstance3D = _cup(0.15, 0.09, 0.09, colour)
			bowl.name = "Bowl"
			root.add_child(bowl)
		Item.VesselShape.PAN:
			var pan: MeshInstance3D = _cup(0.2, 0.18, 0.05, colour)
			pan.name = "Pan"
			root.add_child(pan)
			var handle: MeshInstance3D = _box(Vector3(0.3, 0.03, 0.04), colour.darkened(0.3),
					Vector3(0.33, 0.04, 0.0))
			handle.name = "Handle"
			root.add_child(handle)
		Item.VesselShape.POT:
			var pot: MeshInstance3D = _cup(0.17, 0.16, 0.18, colour)
			pot.name = "Pot"
			root.add_child(pot)
			for side: float in [-1.0, 1.0]:
				var ear: MeshInstance3D = _box(Vector3(0.06, 0.03, 0.08), colour.darkened(0.3),
						Vector3(side * 0.2, 0.15, 0.0))
				ear.name = "Handle%d" % int(side)
				root.add_child(ear)
		_:
			if item.carried_whole:
				root.add_child(_disc(PLATE_RADIUS, PLATE_HEIGHT, colour))
			else:
				root.add_child(_box(BOARD_SIZE, colour, Vector3.UP * BOARD_SIZE.y / 2.0))


# An open vessel, [param top] wide at the rim and [param bottom] at the base.
static func _cup(top: float, bottom: float, height: float, color: Color) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = top
	mesh.bottom_radius = bottom
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	return _mesh_instance(mesh, color, Vector3.UP * height / 2.0)


# Where food number [param index] of [param count] sits on a vessel, as x and
# z: one in the middle, two side by side, three in a triangle.
static func _food_spot(index: int, count: int) -> Vector2:
	var step: float = FOOD_ON_VESSEL_SIZE * 0.7
	match count:
		1:
			return Vector2.ZERO
		2:
			return Vector2(-step if index == 0 else step, 0.0)
		_:
			var spots: Array[Vector2] = [Vector2(-step, step * 0.6),
					Vector2(step, step * 0.6), Vector2(0.0, -step * 0.8)]
			return spots[index % spots.size()]


# A bar floating above the vessel, filled from the left by [param fraction].
static func _progress_bar(fraction: float) -> Node3D:
	var bar: Node3D = Node3D.new()
	bar.name = "ProgressBar"
	bar.position = Vector3.UP * BAR_ABOVE
	bar.add_child(_box(Vector3(BAR_LENGTH, BAR_THICKNESS, BAR_THICKNESS), BAR_BACK_COLOR,
			Vector3.ZERO))
	if fraction > 0.0:
		var length: float = BAR_LENGTH * fraction
		# In front of the back bar (towards +Z), so it isn't hidden inside it.
		var fill: MeshInstance3D = _box(
				Vector3(length, BAR_THICKNESS * 1.2, BAR_THICKNESS * 1.2), BAR_COLOR,
				Vector3(-BAR_LENGTH / 2.0 + length / 2.0, 0.0, 0.0))
		fill.name = "Fill"
		bar.add_child(fill)
	return bar


static func _box(size: Vector3, color: Color, centre: Vector3) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	return _mesh_instance(mesh, color, centre)


static func _disc(radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1
	return _mesh_instance(mesh, color, Vector3.UP * height / 2.0)


static func _mesh_instance(mesh: Mesh, color: Color, centre: Vector3) -> MeshInstance3D:
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(color)
	instance.position = centre
	return instance


static func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		_materials[color] = material
	return _materials[color]
