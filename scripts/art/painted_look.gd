class_name PaintedLook
extends Node
## PROTOTYPE (#168): the painted cartoon look from the look-dev cabin, put on
## a whole scene. Add one of these to a scene and it:
## - keeps colours rich where the light lands (Filmic tone mapping, more
##   saturation, light that bounces between nearby surfaces);
## - paints the picture: a painterly filter and ink lines over everything
##   (shaders/painted_filter.gdshader), on whichever camera is in use;
## - draws rigged Meshy characters with the stylised look, so they keep a
##   fine brush and crisp faces, and no one light burns them out.
## F8 switches it on and off while the game runs (debug builds only), to
## compare. It leaves the scene's own time of day, weather and fog alone.

const FILTER: Shader = preload("res://shaders/painted_filter.gdshader")
const STYLE: CharacterStyle = preload("res://data/art/styles/character.tres")
const TOGGLE_KEY: Key = KEY_F8

## Whether the look is on.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if is_node_ready():
			_apply()
## The scene's environment. Left empty, the first WorldEnvironment in the
## scene is used.
@export var world: WorldEnvironment
@export_group("Picture")
## How much richer colours are than the scene's own grade.
@export_range(0.5, 2.0) var saturation: float = 1.12
## Brush widths in pixels at 1080p: the scenery's, and the characters'.
@export_range(0.0, 8.0) var brush: float = 3.0
@export_range(0.0, 8.0) var character_brush: float = 0.9
## Ink line width in pixels at 1080p, and how dark the line is.
@export_range(0.0, 4.0) var line_width: float = 1.2
@export_range(0.0, 1.0) var line_strength: float = 0.7
@export_group("Characters")
## The brightest any one light may be on a stylised character.
@export_range(0.0, 4.0) var light_cap: float = 0.85

var _filter: MeshInstance3D
var _style: CharacterStyle
var _was: Dictionary[StringName, Variant] = {}
var _styled: Array[ThirdPartyModel] = []


func _ready() -> void:
	_style = STYLE.duplicate() as CharacterStyle
	_style.specular_strength = 0.0
	if world == null:
		var found: Array[Node] = get_tree().root.find_children("*", "WorldEnvironment", true, false)
		if not found.is_empty():
			world = found[0] as WorldEnvironment
	get_tree().node_added.connect(_on_node_added)
	_apply()


func _process(_delta: float) -> void:
	# The filter rides on whichever camera is in use (cutscenes change it).
	var camera: Camera3D = get_viewport().get_camera_3d()
	if _filter != null and camera != null and _filter.get_parent() != camera:
		if _filter.get_parent() != null:
			_filter.get_parent().remove_child(_filter)
		camera.add_child(_filter)


func _unhandled_key_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if OS.is_debug_build() and key != null and key.pressed and not key.echo \
			and key.keycode == TOGGLE_KEY:
		enabled = not enabled


## A quad over the whole screen that paints the picture. [param compare] is
## the stencil test it's drawn under: "compare_equal" covers stylised
## characters only, "compare_not_equal" everything else.
static func make_filter(compare: String, brush_size: float) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var shader: Shader = Shader.new()
	shader.code = FILTER.code.replace("// STENCIL", "stencil_mode read, %s, 1;" % compare)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"brush_size", brush_size)
	# Before everything see-through (rain, glass, light shafts), which the
	# filter can't see and would otherwise paint over.
	material.render_priority = -100
	quad.material = material
	var screen: MeshInstance3D = MeshInstance3D.new()
	screen.name = "PaintedFilter"
	screen.mesh = quad
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Never culled: the shader puts it over the whole screen.
	screen.extra_cull_margin = 16384.0
	return screen


func _apply() -> void:
	_apply_environment()
	if enabled and _filter == null:
		_filter = make_filter("compare_not_equal", brush)
		_filter.add_child(make_filter("compare_equal", character_brush))
		var screens: Array[MeshInstance3D] = [_filter, _filter.get_child(0) as MeshInstance3D]
		for screen: MeshInstance3D in screens:
			var material: ShaderMaterial = screen.mesh.surface_get_material(0) as ShaderMaterial
			material.set_shader_parameter(&"line_width", line_width)
			material.set_shader_parameter(&"line_strength", line_strength)
	if _filter != null:
		_filter.visible = enabled
	if enabled:
		for found: Node in get_tree().root.find_children("*", "ThirdPartyModel", true, false):
			_on_node_added(found)
	else:
		for model: ThirdPartyModel in _styled:
			if is_instance_valid(model):
				model.style = null
		_styled.clear()


func _apply_environment() -> void:
	if world == null or world.environment == null:
		return
	var env: Environment = world.environment
	if not enabled:
		for property: StringName in _was:
			env.set(property, _was[property])
		_was.clear()
		return
	# Filmic keeps bright colours saturated; AgX fades them towards white.
	_override(env, &"tonemap_mode", Environment.TONE_MAPPER_FILMIC)
	_override(env, &"tonemap_white", 5.0)
	_override(env, &"adjustment_enabled", true)
	_override(env, &"adjustment_saturation", env.adjustment_saturation * saturation)
	# Light bounces between nearby surfaces: lantern light warms the wood
	# around it. (SDFGI would do more, but it can't follow a moving ship.)
	_override(env, &"ssil_enabled", true)
	_override(env, &"ssil_radius", 2.5)
	_override(env, &"ssil_intensity", 1.2)
	_override(env, &"ssao_light_affect", 0.0)


func _override(env: Environment, property: StringName, value: Variant) -> void:
	if not _was.has(property):
		_was[property] = env.get(property)
	env.set(property, value)


# Rigged Meshy models are characters: draw them stylised.
func _on_node_added(node: Node) -> void:
	var model: ThirdPartyModel = node as ThirdPartyModel
	if model == null or not enabled or _styled.has(model):
		return
	_styled.append(model)
	if not model.dressed.is_connected(_on_dressed):
		model.dressed.connect(_on_dressed.bind(model))
	_on_dressed.call_deferred(model.model != null, model)


func _on_dressed(shown: bool, model: ThirdPartyModel) -> void:
	if not shown or not enabled or model.model == null:
		return
	if model.model.find_children("*", "Skeleton3D", true, false).is_empty():
		return
	if model.style == null:
		model.style = _style
		return
	for found: Node in model.model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		mesh_node.set_instance_shader_parameter(&"light_cap", light_cap)
		if model.outfit != null:
			mesh_node.set_instance_shader_parameter(&"round_form", 0.75)
