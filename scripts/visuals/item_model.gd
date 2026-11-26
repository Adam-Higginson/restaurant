class_name ItemModel
extends RefCounted
## Builds 3D models for items: food is its real model ([member Item.model_path],
## #152) or, without one, a small cube in the item's colour; a chopping board
## is a flat slab, and a plate is a flat disc. A vessel shows its food on
## top. (How far it's cooked shows in a bubble over the pan, [PanFeel].)
##
## Display only. Counters and the carried stack throw the old model away and
## build a new one whenever what they hold changes.

## A food item's edge, in metres.
const FOOD_SIZE: float = 0.2
## Food sitting on a vessel is smaller, so up to three fit.
const FOOD_ON_VESSEL_SIZE: float = 0.13
## How much of a piece of food is under the surface of water or soup.
const SUNK_SHARE: float = 0.35
## A chopping board (a vessel taken apart, not whole).
const BOARD_SIZE: Vector3 = Vector3(0.5, 0.06, 0.34)
## A plate or bowl (a vessel carried whole).
const PLATE_RADIUS: float = 0.21
const PLATE_HEIGHT: float = 0.03

## How a liquid's surface is drawn: glossy, gently rippling.
const LIQUID_SHADER: Shader = preload("res://shaders/liquid_surface.gdshader")

## One material per colour, shared by every model.
static var _materials: Dictionary[Color, StandardMaterial3D] = {}


## A new model of [param instance], standing on its base at the origin.
static func build(instance: ItemInstance) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Item"
	if not instance.is_vessel():
		var whole: Node3D = food(instance.item, FOOD_SIZE)
		whole.name = "Food"
		root.add_child(whole)
		return root
	var base: float = vessel_height(instance.item)
	_add_vessel(root, instance.item)
	var pieces: Array[ItemInstance] = []
	var liquid: Item = null
	for piece: ItemInstance in instance.contents.get_contents():
		if piece.item.liquid and can_hold_liquid(instance.item):
			liquid = piece.item
		else:
			pieces.append(piece)
	if liquid != null:
		root.add_child(liquid_surface(instance.item, liquid))
		_tint_liquid(root, instance)
		# Food in water or soup sits down in it, just its top showing.
		base = liquid_level(instance.item) - FOOD_ON_VESSEL_SIZE * SUNK_SHARE
	for i: int in pieces.size():
		var spot: Vector2 = _food_spot(i, pieces.size())
		var piece: Node3D = food(pieces[i].item, FOOD_ON_VESSEL_SIZE)
		piece.position = Vector3(spot.x, maxf(base, floor_height(instance.item)), spot.y)
		piece.name = "Food%d" % i
		piece.scale = Vector3.ONE * VesselLook.piece_scale(instance.contents, pieces[i])
		root.add_child(piece)
	return root


## Updates a model [method build] made of [param instance] as it cooks,
## without building it again: the liquid's colour and how far each piece has
## melted (see [VesselLook]). Only right while the same pieces are inside;
## when food goes in or out, build a new model.
static func refresh(root: Node3D, instance: ItemInstance) -> void:
	if not instance.is_vessel():
		return
	_tint_liquid(root, instance)
	var i: int = 0
	for piece: ItemInstance in solids_in(instance):
		var node: Node3D = root.get_node_or_null("Food%d" % i) as Node3D
		if node != null:
			node.scale = Vector3.ONE * VesselLook.piece_scale(instance.contents, piece)
		i += 1


## The pieces of food in [param vessel] drawn as pieces, in the order
## [method build] places them: everything but a liquid it can hold.
static func solids_in(vessel: ItemInstance) -> Array[ItemInstance]:
	var pieces: Array[ItemInstance] = []
	for piece: ItemInstance in vessel.contents.get_contents():
		if not (piece.item.liquid and can_hold_liquid(vessel.item)):
			pieces.append(piece)
	return pieces


# Colours the liquid's surface by what it's becoming.
static func _tint_liquid(root: Node3D, instance: ItemInstance) -> void:
	var surface: MeshInstance3D = root.get_node_or_null("Liquid") as MeshInstance3D
	if surface == null:
		return
	var material: ShaderMaterial = surface.material_override as ShaderMaterial
	if material != null:
		material.set_shader_parameter(&"colour", VesselLook.liquid_colour(instance.contents))


## Whether [param vessel] holds liquid as liquid, filling it: a pot, a pan or
## a bowl. On a board or plate, water or soup is drawn as a piece of food.
static func can_hold_liquid(vessel: Item) -> bool:
	return vessel.vessel_shape != Item.VesselShape.FLAT


## How high the surface of a liquid stands in [param vessel], in metres.
static func liquid_level(vessel: Item) -> float:
	match vessel.vessel_shape:
		Item.VesselShape.POT:
			return 0.12
		Item.VesselShape.BOWL:
			return 0.075
		Item.VesselShape.PAN:
			return 0.035
	return 0.0


## The surface of [param liquid] filling [param vessel] (#207): a rippling
## disc in the liquid's colour, glossy, and see-through for water.
static func liquid_surface(vessel: Item, liquid: Item) -> MeshInstance3D:
	var mesh: CylinderMesh = CylinderMesh.new()
	var radius: float = 0.14
	match vessel.vessel_shape:
		Item.VesselShape.BOWL:
			radius = 0.13
		Item.VesselShape.PAN:
			radius = 0.17
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.004
	mesh.radial_segments = 20
	mesh.rings = 1
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = LIQUID_SHADER
	material.set_shader_parameter(&"colour", liquid.color)
	var surface: MeshInstance3D = MeshInstance3D.new()
	surface.name = "Liquid"
	surface.mesh = mesh
	surface.material_override = material
	surface.position = Vector3.UP * liquid_level(vessel)
	return surface


## A model of [param tool] standing on its base at the origin (the recipe book
## in your hand, #207): its own model fitted into its
## [member HandTool.model_size], over a greybox block in its colour.
static func tool_model(tool: HandTool) -> Node3D:
	var root: Node3D = Node3D.new()
	root.name = "Tool"
	var block: MeshInstance3D = _box(tool.model_size, tool.color, Vector3.UP * tool.model_size.y / 2.0)
	block.name = "Greybox"
	root.add_child(block)
	if tool.model_path.is_empty() or not ResourceLoader.exists(tool.model_path):
		return root
	var model: ThirdPartyModel = ThirdPartyModel.new()
	model.name = "Model"
	model.fit_size = tool.model_size
	model.stand_ins = [block]
	model.opaque = true
	model.path = tool.model_path
	root.add_child(model)
	return root


## A piece of [param item] about [param size] metres across, standing on its
## base at the origin: its real model, with a greybox cube in its colour in
## its place whenever the model isn't there (a fresh clone, CI).
static func food(item: Item, size: float) -> Node3D:
	var piece: Node3D = Node3D.new()
	var cube: MeshInstance3D = _box(Vector3.ONE * size, item.color, Vector3.UP * size / 2.0)
	cube.name = "Greybox"
	piece.add_child(cube)
	# Fitted to its own size, then shrunk on a vessel
	# as the cubes are, so up to three fit.
	if item.model_pieces <= 1:
		_add_model(piece, item, [cube], size / FOOD_SIZE)
		return piece
	# In bits: small copies in a ring, each turned its own way.
	for i: int in item.model_pieces:
		var bit: Node3D = Node3D.new()
		bit.name = "Bit%d" % i
		var angle: float = TAU * float(i) / float(item.model_pieces)
		bit.position = Vector3(cos(angle), 0.0, sin(angle)) * size * 0.25
		bit.rotation.y = angle * 1.7 + 0.6
		piece.add_child(bit)
		_add_model(bit, item, [cube], size / FOOD_SIZE * 0.5)
	return piece


# Adds [param item]'s real model to [param parent], scaled by [param scale],
# hiding [param stand_ins] while it shows. Nothing if it has no model file.
static func _add_model(parent: Node3D, item: Item, stand_ins: Array[VisualInstance3D],
		scale: float) -> void:
	if item.model_path.is_empty() or not ResourceLoader.exists(item.model_path):
		return
	var model: ThirdPartyModel = ThirdPartyModel.new()
	model.name = "Model"
	model.fit_size = item.model_size
	model.stand_ins = stand_ins
	model.opaque = true
	model.tint = item.model_tint
	model.scale = Vector3.ONE * scale
	model.position = item.model_offset * scale
	model.rotation_degrees = Vector3(0.0, item.model_yaw_degrees, item.model_roll_degrees)
	model.path = item.model_path
	parent.add_child(model)


## How high food sits in or on the vessel [param item]: on the floor of the
## open Meshy pot and pan (#207), on top of the greybox bowl, board or plate.
static func vessel_height(item: Item) -> float:
	match item.vessel_shape:
		Item.VesselShape.BOWL:
			return 0.09
		Item.VesselShape.PAN:
			return 0.025
		Item.VesselShape.POT:
			return 0.03
	return PLATE_HEIGHT if item.carried_whole else BOARD_SIZE.y


## The lowest food can sit in [param item]: its floor.
static func floor_height(item: Item) -> float:
	return vessel_height(item)


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
			# The real pan (the one you parry with), when it's there, its
			# handle pointing the way the greybox's does (+X).
			_add_model(root, item, [pan, handle], 1.0)
		Item.VesselShape.POT:
			var pot: MeshInstance3D = _cup(0.17, 0.16, 0.18, colour)
			pot.name = "Pot"
			root.add_child(pot)
			for side: float in [-1.0, 1.0]:
				var ear: MeshInstance3D = _box(Vector3(0.06, 0.03, 0.08), colour.darkened(0.3),
						Vector3(side * 0.2, 0.15, 0.0))
				ear.name = "Handle%d" % int(side)
				root.add_child(ear)
			_add_model(root, item, [pot, root.get_node("Handle-1") as MeshInstance3D,
					root.get_node("Handle1") as MeshInstance3D], 1.0)
		_:
			if item.carried_whole:
				root.add_child(_disc(PLATE_RADIUS, PLATE_HEIGHT, colour))
			else:
				var board: MeshInstance3D = _box(BOARD_SIZE, colour,
						Vector3.UP * BOARD_SIZE.y / 2.0)
				board.name = "Board"
				root.add_child(board)
				_add_model(root, item, [board], 1.0)


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
