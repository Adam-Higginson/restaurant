class_name PaintedLook
extends Node
## PROTOTYPE (#168): the painted cartoon look from the look-dev cabin, put on
## a whole scene. Add one of these to a scene and it:
## - keeps colours rich where the light lands (Filmic tone mapping, more
##   saturation, light that bounces between nearby surfaces);
## - paints the picture: a painterly filter and ink lines over everything
##   (shaders/painted_filter.gdshader), on whichever camera is in use;
## - draws rigged Meshy characters with the stylised look, so they keep a
##   fine brush and crisp faces, and no one light burns them out;
## - takes the N64 look off: every pack model is drawn as it was made (not
##   the Kiln's crunched copy, and with no grain), and the ship's planking
##   loses its small blurred wood-grain picture, leaving clean painted planks.
## F8 switches it on and off while the game runs (debug builds only), to
## compare. It leaves the scene's own time of day, weather and fog alone.

const FILTER: Shader = preload("res://shaders/painted_filter.gdshader")
const STYLE: CharacterStyle = preload("res://data/art/styles/character.tres")
const TOGGLE_KEY: Key = KEY_F8
const WOOD_HUE: float = 0.06
## What a planked surface is given: no grain picture (null is plain white),
## no grain bumps, and more difference between one plank and the next.
const SURFACE: Dictionary[StringName, Variant] = {
	&"albedo_texture": null,
	&"grain_bump": 0.0,
	&"plank_tint": 0.24,
}

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
@export_range(0.0, 8.0) var brush: float = 2.3
@export_range(0.0, 8.0) var character_brush: float = 0.9
## Ink line width in pixels at 1080p, and how dark the line is.
@export_range(0.0, 4.0) var line_width: float = 1.0
@export_range(0.0, 1.0) var line_strength: float = 0.6
@export_group("Surfaces")
## How much richer and darker a planked surface's own colour is made, now
## that no grain picture colours it.
@export_range(0.5, 3.0) var surface_saturation: float = 1.55
@export_range(0.2, 1.5) var surface_value: float = 0.74
## How much sharper than usual every texture is drawn (0 is as usual): Godot
## picks a finer copy of each texture than the distance alone would.
@export_range(0.0, 2.0) var texture_sharpness: float = 0.8
@export_group("Characters")
## The brightest any one light may be on a stylised character.
@export_range(0.0, 4.0) var light_cap: float = 0.85

var _filter: MeshInstance3D
var _style: CharacterStyle
# The look for shelled creatures: two steps of shade, a wet shine, a firmer line.
var _shell_style: CharacterStyle
var _viewport_was: Dictionary[StringName, Variant] = {}
var _was: Dictionary[StringName, Variant] = {}
var _styled: Array[ThirdPartyModel] = []
# Each pack model's own [keep_as_made, grain, detail], to put back.
var _models_were: Dictionary[ThirdPartyModel, Array] = {}
# Each pack character's own [use_kiln, n64, detail], to put back.
var _people_were: Dictionary[CharacterModel, Array] = {}
# Each planked material's own settings, to put back.
var _surfaces_were: Dictionary[ShaderMaterial, Dictionary] = {}


func _enter_tree() -> void:
	# Before anything in the scene is dressed: nothing uses a Kiln copy.
	KilnJob.use_fired = not enabled


func _exit_tree() -> void:
	KilnJob.use_fired = true


func _ready() -> void:
	_style = STYLE.duplicate() as CharacterStyle
	_style.specular_strength = 0.0
	_shell_style = STYLE.duplicate() as CharacterStyle
	_shell_style.bands = 2
	_shell_style.shadow_softness = 0.03
	_shell_style.specular_strength = 0.3
	_shell_style.specular_size = 0.025
	_shell_style.rim_strength = 0.45
	_shell_style.outline_thickness = 2.6
	_shell_style.outline_max_width = 0.02
	_shell_style.outline_color = Color(0.3, 0.06, 0.07)
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
	KilnJob.use_fired = not enabled
	_apply_sharpness()
	_apply_environment()
	_apply_people()
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
	_apply_surfaces()
	if enabled:
		for found: Node in get_tree().root.find_children("*", "ThirdPartyModel", true, false):
			_on_node_added(found)
	else:
		for model: ThirdPartyModel in _styled:
			if is_instance_valid(model):
				model.style = null
		_styled.clear()
		for model: ThirdPartyModel in _models_were:
			if is_instance_valid(model):
				model.keep_as_made = _models_were[model][0]
				model.grain = _models_were[model][1]
				model.detail = _models_were[model][2]
				model.dress()
		_models_were.clear()


# Every texture in the picture is drawn from a finer copy, with the sharpest
# filtering at glancing angles.
func _apply_sharpness() -> void:
	var viewport: Viewport = get_viewport()
	if not enabled:
		for property: StringName in _viewport_was:
			viewport.set(property, _viewport_was[property])
		_viewport_was.clear()
		return
	var sharper: Dictionary[StringName, Variant] = {
		&"texture_mipmap_bias": -texture_sharpness,
		&"anisotropic_filtering_level": Viewport.ANISOTROPY_16X,
	}
	for property: StringName in sharper:
		if not _viewport_was.has(property):
			_viewport_was[property] = viewport.get(property)
		viewport.set(property, sharper[property])


# Pack characters (the player) are built from the packs' own parts at full
# quality, with their own smooth textures: no Kiln copies, no N64 filtering.
func _apply_people() -> void:
	if not enabled:
		for person: CharacterModel in _people_were:
			if is_instance_valid(person):
				person.use_kiln = _people_were[person][0]
				person.n64 = _people_were[person][1]
				person.detail = _people_were[person][2]
				person.dress()
		_people_were.clear()
		return
	for found: Node in get_tree().root.find_children("*", "CharacterModel", true, false):
		var person: CharacterModel = found as CharacterModel
		if _people_were.has(person):
			continue
		_people_were[person] = [person.use_kiln, person.n64, person.detail]
		person.use_kiln = false
		person.n64 = false
		person.detail = 1.0
		person.dress()


# Planked surfaces (the wet_surface shader) lose their blurred grain picture
# and its bumps, and each plank gets more of its own shade.
func _apply_surfaces() -> void:
	if not enabled:
		for material: ShaderMaterial in _surfaces_were:
			var was: Dictionary = _surfaces_were[material]
			for parameter: StringName in was:
				material.set_shader_parameter(parameter, was[parameter])
		_surfaces_were.clear()
		return
	var materials: Array[ShaderMaterial] = []
	for found: Node in get_tree().root.find_children("*", "SurfaceSpace", true, false):
		materials.append_array((found as SurfaceSpace).materials)
	for found: Node in get_tree().root.find_children("*", "ThirdPartyTexture", true, false):
		materials.append((found as ThirdPartyTexture).material)
	for material: ShaderMaterial in materials:
		if material == null or _surfaces_were.has(material):
			continue
		var was: Dictionary = {}
		for parameter: StringName in SURFACE:
			was[parameter] = material.get_shader_parameter(parameter)
			material.set_shader_parameter(parameter, SURFACE[parameter])
		# The grain picture also made the surface darker and browner: give
		# its own colour that richness.
		var colour: Variant = material.get_shader_parameter(&"albedo")
		if colour is Color:
			var own: Color = colour
			was[&"albedo"] = own
			# Yellowish browns lean towards a warmer, redder wood.
			var hue: float = own.h
			if hue > 0.03 and hue < 0.16:
				hue = lerpf(hue, WOOD_HUE, 0.6)
			material.set_shader_parameter(&"albedo", Color.from_hsv(hue,
					minf(own.s * surface_saturation, 1.0), own.v * surface_value, own.a))
		_surfaces_were[material] = was


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
	# Only lamps and flames bloom, not every pale thing a lamp shines on.
	_override(env, &"glow_bloom", 0.02)
	_override(env, &"glow_intensity", 0.7)
	_override(env, &"glow_hdr_threshold", 1.3)


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
	if not model.keep_as_made or model.grain or model.detail < 1.0:
		_models_were[model] = [model.keep_as_made, model.grain, model.detail]
		model.keep_as_made = true
		model.grain = false
		model.detail = 1.0
		if model.is_inside_tree() and model.model != null:
			model.dress()
	if not model.dressed.is_connected(_on_dressed):
		model.dressed.connect(_on_dressed.bind(model))
	_on_dressed.call_deferred(model.model != null, model)


# Whether [param model] is a creature with a shell: a [Crab]'s model.
func _is_shelled(model: ThirdPartyModel) -> bool:
	var node: Node = model.get_parent()
	while node != null:
		if node is Crab:
			return true
		node = node.get_parent()
	return false


func _on_dressed(shown: bool, model: ThirdPartyModel) -> void:
	if not shown or not enabled or model.model == null:
		return
	if model.model.find_children("*", "Skeleton3D", true, false).is_empty():
		return
	var shelled: bool = _is_shelled(model)
	if model.style == null:
		model.style = _shell_style if shelled else _style
		return
	for found: Node in model.model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		mesh_node.set_instance_shader_parameter(&"light_cap", light_cap)
		if shelled:
			var box: AABB = mesh_node.get_aabb()
			mesh_node.set_instance_shader_parameter(&"ball_form", 0.85)
			mesh_node.set_instance_shader_parameter(&"ball_centre", box.get_center())
			mesh_node.set_instance_shader_parameter(&"ball_radius", box.get_longest_axis_size() * 0.5)
			mesh_node.set_instance_shader_parameter(&"shell", 1.0)
		if model.outfit != null:
			mesh_node.set_instance_shader_parameter(&"round_form", 0.75)
