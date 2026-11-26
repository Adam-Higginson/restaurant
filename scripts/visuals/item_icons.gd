class_name ItemIcons
extends Node
## Pictures of the real models, for the toolbar (#206): each item or tool is
## photographed once, in a little studio of its own (a [SubViewport] with its
## own world, a camera and a lamp), and the picture is kept for next time.
##
## Asking for one that hasn't been taken yet returns null and queues it;
## [signal icon_made] says when it's ready, so whoever asked can draw it.
## Where nothing is drawn (headless tests, CI), no picture comes out and the
## asker keeps its placeholder.

## Emitted when a picture has been taken, with its key (see [method key_of]).
signal icon_made(key: String)

## How many pixels square each picture is taken at.
const SIZE: int = 96
## Which way the camera looks at the model from: in front, a little above
## and to one side, as a shop window shows a thing.
const VIEW_FROM: Vector3 = Vector3(0.55, 0.75, 1.0)
## How much room is left round the model, as a share of its size.
const MARGIN: float = 1.15
## How far a tool is turned, lying across its picture, in degrees.
const TOOL_TILT: float = -45.0
## How many frames a picture is drawn for before it is kept.
const SETTLE_FRAMES: int = 4

## The pictures taken, by key.
var _icons: Dictionary[String, Texture2D] = {}
## What's waiting to be photographed, in turn, and what each key is of.
var _queue: Array[String] = []
var _items: Dictionary[String, ItemInstance] = {}
var _tools: Dictionary[String, HandTool] = {}
## Keys whose picture came out empty (nothing is drawn here): not tried again.
var _blank: Dictionary[String, bool] = {}
var _busy: bool = false

var _studio: SubViewport
var _camera: Camera3D
var _stage: Node3D


func _ready() -> void:
	_studio = SubViewport.new()
	_studio.name = "Studio"
	_studio.own_world_3d = true
	_studio.transparent_bg = true
	_studio.size = Vector2i(SIZE, SIZE)
	_studio.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_studio.msaa_3d = Viewport.MSAA_4X
	add_child(_studio)
	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.85, 0.8, 0.75)
	environment.ambient_light_energy = 0.7
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = environment
	_studio.add_child(world)
	var lamp: DirectionalLight3D = DirectionalLight3D.new()
	lamp.light_color = Color(1.0, 0.93, 0.82)
	lamp.light_energy = 1.1
	lamp.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	_studio.add_child(lamp)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.current = true
	_studio.add_child(_camera)
	_stage = Node3D.new()
	_studio.add_child(_stage)


## The picture of [param instance] (a dish shows what's in it), or null if
## it hasn't been taken yet: then it's queued.
func icon_for_item(instance: ItemInstance) -> Texture2D:
	var key: String = key_of(instance)
	if not _icons.has(key) and not _items.has(key):
		_items[key] = instance
	return _icon(key)


## The picture of [param tool], or null if it hasn't been taken yet.
func icon_for_tool(tool: HandTool) -> Texture2D:
	var key: String = key_of_tool(tool)
	if not _icons.has(key) and not _tools.has(key):
		_tools[key] = tool
	return _icon(key)


## What a picture of [param instance] is kept under: the item, and for a
## plate or bowl what's on it. Two tomatoes share one picture.
static func key_of(instance: ItemInstance) -> String:
	var key: String = "item:" + String(instance.item.id)
	if instance.is_vessel():
		for food: ItemInstance in instance.contents.get_contents():
			key += "+" + String(food.item.id)
	return key


## What a picture of [param tool] is kept under.
static func key_of_tool(tool: HandTool) -> String:
	return "tool:" + String(tool.id)


## How many pictures are waiting to be taken.
func waiting() -> int:
	return _queue.size()


func _icon(key: String) -> Texture2D:
	if _icons.has(key):
		return _icons[key]
	if not _blank.has(key) and not _queue.has(key):
		_queue.append(key)
		_take_next.call_deferred()
	return null


# Photographs the next thing waiting, one at a time.
func _take_next() -> void:
	if _busy or _queue.is_empty() or not is_inside_tree():
		return
	_busy = true
	var key: String = _queue[0]
	var model: Node3D = ItemModel.build(_items[key]) if _items.has(key) \
			else _tool_model(_tools[key])
	_stage.add_child(model)
	_frame(model)
	# A few frames, not one: a material drawn for the first time can take a
	# frame or two to be ready, and would be missing from the picture.
	_studio.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for i: int in SETTLE_FRAMES:
		await RenderingServer.frame_post_draw
	if not is_inside_tree():
		return
	_studio.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var image: Image = _studio.get_texture().get_image()
	model.queue_free()
	_queue.erase(key)
	_items.erase(key)
	_tools.erase(key)
	if image == null or image.is_empty():
		_blank[key] = true
	else:
		image.generate_mipmaps()
		_icons[key] = ImageTexture.create_from_image(image)
		icon_made.emit(key)
	_busy = false
	_take_next.call_deferred()


# A tool's own model to photograph (a bar in its colour without one), lying
# across the picture.
func _tool_model(tool: HandTool) -> Node3D:
	var root: Node3D = Node3D.new()
	var bar: MeshInstance3D = MeshInstance3D.new()
	var box: BoxMesh = BoxMesh.new()
	box.size = tool.model_size
	bar.mesh = box
	var colour: StandardMaterial3D = StandardMaterial3D.new()
	colour.albedo_color = tool.color
	bar.material_override = colour
	root.add_child(bar)
	if not tool.model_path.is_empty() and ResourceLoader.exists(tool.model_path):
		var model: ThirdPartyModel = ThirdPartyModel.new()
		model.fit_size = tool.model_size
		model.stand_ins = [bar]
		model.path = tool.model_path
		root.add_child(model)
	root.rotation_degrees.z = TOOL_TILT
	return root


# Points the camera at [param model] so it fills the picture.
func _frame(model: Node3D) -> void:
	var bounds: AABB = _bounds_of(model)
	if bounds.size == Vector3.ZERO:
		bounds = AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 0.2, 0.2))
	var centre: Vector3 = bounds.get_center()
	var reach: float = bounds.size.length()
	_camera.size = reach * MARGIN * 0.8
	_camera.near = 0.01
	_camera.far = reach * 4.0 + 1.0
	_camera.position = centre + VIEW_FROM.normalized() * (reach * 2.0 + 0.5)
	_camera.look_at(centre)


# The box round everything drawn under [param node], in the stage's space.
func _bounds_of(node: Node3D) -> AABB:
	var bounds: AABB = AABB()
	var found: bool = false
	for child: Node in node.find_children("*", "VisualInstance3D", true, false):
		var visual: VisualInstance3D = child as VisualInstance3D
		if not visual.is_visible_in_tree():
			continue
		var box: AABB = _stage.global_transform.affine_inverse() * visual.global_transform \
				* visual.get_aabb()
		bounds = box if not found else bounds.merge(box)
		found = true
	return bounds
