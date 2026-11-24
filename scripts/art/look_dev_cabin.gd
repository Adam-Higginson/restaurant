class_name LookDevCabin
extends Node3D
## The look-dev cabin (#168): one wooden cabin, lit like the golden-hour
## reference, for trying the stylised look on our characters and props before
## it goes anywhere else. Open scenes/tools/look_dev_cabin.tscn and press F6.
##
## The buttons in the corner switch, while it runs:
## - the characters between stylised and as made ([method set_stylised]);
## - their outlines ([method set_outlined]);
## - the light between the golden cabin and plain studio light, which shows
##   the models as they come ([method set_golden]).
## The characters wear the shared style (data/art/styles/character.tres) in
## the saved scene, so tuning that file shows on them in the editor at once.
## While it runs, the buttons work on a copy of the style, so they never
## change the shared file, and nothing here changes any other scene.
##
## Run with [code]-- --capture=<folder>[/code] and it photographs every shot
## (the Marker3D nodes under Shots) in each treatment, saves the pictures
## there and quits. That's how the look is checked by eye.

## One way of drawing the cabin, photographed by --capture.
class Treatment:
	var name: String
	var stylised: bool
	var outlined: bool
	var golden: bool

	func _init(called: String, styled: bool, lined: bool, gold: bool) -> void:
		name = called
		stylised = styled
		outlined = lined
		golden = gold


## Frames to wait before each photograph, for the light shafts to settle.
const SETTLE_FRAMES: int = 45
## The cartoon finish's dials (prototype): brush widths in pixels at 1080p,
## and how much the characters' colours are held back so sunlit skin and
## cloth stay as flat colour and don't burn out.
const CARTOON_BRUSH: float = 3.5
const CARTOON_CHARACTER_BRUSH: float = 0.9
const CARTOON_ROUND_FORM: float = 0.75
const CARTOON_LIGHT_CAP: float = 1.3
const CARTOON_CHARACTER_TINT: Color = Color(0.95, 0.95, 0.95)
const PAINTED_FILTER: Shader = preload("res://shaders/painted_filter.gdshader")
## The painted light pass's dials (prototype).
const PAINTED_SUN_COLOR: Color = Color(1.0, 0.76, 0.46)
const PAINTED_SUN_ENERGY: float = 3.0
const PAINTED_LAMP_COLOR: Color = Color(1.0, 0.7, 0.38)
const PAINTED_LAMP_BOOST: float = 1.8
const PAINTED_GLASS_BOOST: float = 5.0
const PAINTED_BOUNCE_SPOTS: Array[Vector3] = [Vector3(-1.5, 0.5, 1.0), Vector3(2.0, 0.5, 0.5)]
const PAINTED_BOUNCE_ENERGY: float = 0.6
const PAINTED_WOOD_SATURATION: float = 1.1
const PAINTED_WOOD_VALUE: float = 1.25

## The stylised look put on the characters.
@export var style: CharacterStyle
## The characters' models, which the style is put on.
@export var characters: Array[ThirdPartyModel] = []
@export var world: WorldEnvironment
@export var sun: DirectionalLight3D
## The soft cool fill from the room side, off in plain studio light.
@export var fill: Light3D
## The golden-hour cabin's environment, and plain studio light.
@export var golden: Environment
@export var plain: Environment
## Characters with no animator of their own: their model's first animation
## is played on a loop.
@export var posed: Array[ThirdPartyModel] = []
## The lanterns' lights, out in plain studio light.
@export var lamps: Array[Light3D] = []
@export_group("Sun")
@export var golden_sun_color: Color = Color(1.0, 0.88, 0.74)
@export var golden_sun_energy: float = 2.6
@export var plain_sun_color: Color = Color.WHITE
@export var plain_sun_energy: float = 1.2

## Whether the characters are drawn stylised.
var stylised: bool = true
## Whether the characters have outlines.
var outlined: bool = true
## Whether it's lit as the golden cabin (or plain studio light).
var golden_light: bool = true

## Whether the painted light pass is on (the prototype of the reference's
## saturated light, bounce and glow; see [method set_painted]).
var painted: bool = false

## Whether the painted cartoon finish is on (see [method set_cartoon]).
var cartoon: bool = false

var _capture_folder: String = ""
var _filter: MeshInstance3D
var _style_specular: Dictionary[CharacterStyle, float] = {}
var _only_treatment: String = ""
var _painted_environment: Environment
var _painted_extras: Node3D
var _wood_colors: Dictionary[StandardMaterial3D, Color] = {}
var _lamp_energies: Dictionary[Light3D, float] = {}
var _glass_energies: Dictionary[PaintedGlow, float] = {}

@onready var _camera: Camera3D = $Camera
@onready var _shots: Node3D = $Shots


func _ready() -> void:
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--capture="):
			_capture_folder = option.trim_prefix("--capture=")
		if option.begins_with("--treatment="):
			_only_treatment = option.trim_prefix("--treatment=")
		if option.begins_with("--outfit="):
			# Dress whoever wears an outfit in this one, to photograph it.
			var outfit: CharacterOutfit = load(option.trim_prefix("--outfit=")) as CharacterOutfit
			for character: ThirdPartyModel in characters:
				if character != null and character.outfit != null and outfit != null:
					character.outfit = outfit
	if style != null:
		style = style.duplicate() as CharacterStyle
	for character: ThirdPartyModel in posed:
		if character != null:
			character.dressed.connect(_loop_first_animation.bind(character))
			_loop_first_animation(character.model != null, character)
	set_stylised(stylised)
	set_outlined(outlined)
	set_golden(golden_light)
	if _capture_folder.is_empty():
		_add_buttons()
	else:
		await _capture_all()
		get_tree().quit()


## Draws the characters stylised, or as made.
func set_stylised(on: bool) -> void:
	stylised = on
	for character: ThirdPartyModel in characters:
		if character != null:
			character.style = style if on else null


## Gives the stylised characters outlines, or not.
func set_outlined(on: bool) -> void:
	outlined = on
	if style != null:
		style.outline = on


## Lights the cabin at golden hour, or in plain studio light.
func set_golden(on: bool) -> void:
	golden_light = on
	if world != null:
		world.environment = golden if on else plain
	if sun != null:
		sun.light_color = golden_sun_color if on else plain_sun_color
		sun.light_energy = golden_sun_energy if on else plain_sun_energy
	if fill != null:
		fill.visible = on
	for lamp: Light3D in lamps:
		if lamp != null:
			lamp.visible = on


## PROTOTYPE: lights the golden cabin the way the reference picture is
## painted. Light stays saturated orange where it lands, the sun patch on the
## floor bounces into the room so shadows are deep red-brown and never black,
## the wood is richer, and the lanterns and windows glow. Everything is set
## here in code so it's quick to change; it moves into the scene and an
## Environment file once the look is agreed.
func set_painted(on: bool) -> void:
	painted = on
	set_golden(golden_light)
	_paint_wood(on)
	if _painted_extras != null:
		_painted_extras.visible = on
	for found: Node in find_children("*", "PaintedGlow", true, false):
		var glass: PaintedGlow = found as PaintedGlow
		if not _glass_energies.has(glass):
			_glass_energies[glass] = glass.energy
		glass.energy = _glass_energies[glass] * (PAINTED_GLASS_BOOST if on else 1.0)
		if glass.model != null:
			glass.model.dress()
	for lamp: Light3D in lamps:
		if lamp == null:
			continue
		if not _lamp_energies.has(lamp):
			_lamp_energies[lamp] = lamp.light_energy
		lamp.light_energy = _lamp_energies[lamp] * (PAINTED_LAMP_BOOST if on else 1.0)
		lamp.light_color = PAINTED_LAMP_COLOR if on else Color(1.0, 0.66, 0.36)
	if not on or not golden_light:
		return
	if _painted_environment == null:
		_painted_environment = _make_painted_environment()
	if _painted_extras == null:
		_painted_extras = _make_painted_extras()
		add_child(_painted_extras)
	world.environment = _painted_environment
	sun.light_color = PAINTED_SUN_COLOR
	sun.light_energy = PAINTED_SUN_ENERGY
	sun.light_angular_distance = 1.2
	sun.light_volumetric_fog_energy = 6.0
	if fill != null:
		fill.light_color = Color(0.75, 0.5, 0.62)
		fill.light_energy = 0.25


## PROTOTYPE: the cartoon finish. A painterly filter and ink lines over the
## whole picture (shaders/painted_filter.gdshader), and the room's wood lit
## in two flat steps, not a smooth fade.
func set_cartoon(on: bool) -> void:
	cartoon = on
	if on and _filter == null:
		# The room gets the broad brush; characters a fine one, so faces
		# stay readable. Characters mark the stencil buffer as they're drawn.
		_filter = _make_filter("compare_not_equal", CARTOON_BRUSH)
		_filter.add_child(_make_filter("compare_equal", CARTOON_CHARACTER_BRUSH))
		_camera.add_child(_filter)
	if _filter != null:
		_filter.visible = on
	if sun != null:
		sun.shadow_normal_bias = 3.0 if on else 2.0
	if style != null:
		style.base_tint = CARTOON_CHARACTER_TINT if on else Color.WHITE
		if not _style_specular.has(style):
			_style_specular[style] = style.specular_strength
		style.specular_strength = 0.0 if on else _style_specular[style]
	for character: ThirdPartyModel in characters:
		if character == null:
			continue
		if not character.dressed.is_connected(_light_as_cartoon):
			character.dressed.connect(_light_as_cartoon.bind(character))
		_light_as_cartoon(character.model != null, character)
	for wood: StandardMaterial3D in _wood_colors:
		wood.diffuse_mode = (BaseMaterial3D.DIFFUSE_TOON if on
				else BaseMaterial3D.DIFFUSE_BURLEY)
		wood.specular_mode = (BaseMaterial3D.SPECULAR_DISABLED if on
				else BaseMaterial3D.SPECULAR_SCHLICK_GGX)


# Lights a character the cartoon way: no one light burns it out, and a
# character wearing an outfit is lit as a smooth round form.
func _light_as_cartoon(shown: bool, character: ThirdPartyModel) -> void:
	if not shown:
		return
	for found: Node in character.model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		mesh_node.set_instance_shader_parameter(&"light_cap",
				CARTOON_LIGHT_CAP if cartoon else 0.0)
		if character.outfit == null:
			continue
		mesh_node.set_instance_shader_parameter(&"round_form",
				CARTOON_ROUND_FORM if cartoon else 0.0)


func _make_filter(compare: String, brush: float) -> MeshInstance3D:
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	var shader: Shader = Shader.new()
	shader.code = PAINTED_FILTER.code.replace("// STENCIL",
			"stencil_mode read, %s, 1;" % compare)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter(&"brush_size", brush)
	material.render_priority = 100
	quad.material = material
	var screen: MeshInstance3D = MeshInstance3D.new()
	screen.name = "PaintedFilter"
	screen.mesh = quad
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Never culled: the shader puts it over the whole screen.
	screen.extra_cull_margin = 16384.0
	return screen


func _make_painted_environment() -> Environment:
	var env: Environment = golden.duplicate(true) as Environment
	# Filmic keeps bright colours saturated; AgX fades them towards white.
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.3
	env.tonemap_white = 5.0
	# Shadows are lit by a warm red-brown, never grey.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.5, 0.56)
	env.ambient_light_energy = 0.6
	# Outside the windows: a pale gold evening sky over sunlit green.
	var outside: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	outside.sky_top_color = Color(0.5, 0.68, 0.86)
	outside.sky_horizon_color = Color(1.0, 0.86, 0.6)
	outside.sky_curve = 0.25
	outside.ground_horizon_color = Color(0.86, 0.8, 0.42)
	outside.ground_bottom_color = Color(0.3, 0.5, 0.22)
	outside.ground_curve = 0.3
	outside.sun_angle_max = 20.0
	var sky: Sky = Sky.new()
	sky.sky_material = outside
	env.sky = sky
	env.background_energy_multiplier = 0.9
	# Real bounce light: the sun patch on the floor lights walls and ceiling.
	env.sdfgi_enabled = true
	env.sdfgi_use_occlusion = true
	env.sdfgi_bounce_feedback = 0.7
	env.sdfgi_cascades = 4
	env.sdfgi_min_cell_size = 0.1
	env.sdfgi_energy = 1.6
	env.sdfgi_read_sky_light = false
	env.ssil_intensity = 1.0
	env.ssao_intensity = 0.8
	env.ssao_light_affect = 0.0
	# Lanterns and windows bloom.
	env.glow_enabled = true
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	env.glow_hdr_threshold = 3.2
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.set_glow_level(3, 1.0)
	env.set_glow_level(4, 0.8)
	env.set_glow_level(5, 0.8)
	# Thin haze, so the fog shows as shafts and doesn't grey the room.
	env.volumetric_fog_density = 0.004
	env.volumetric_fog_albedo = Color(1.0, 0.72, 0.45)
	# The grade: richer colour, and blacks lifted to a warm red-brown.
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = 1.05
	var curve: Gradient = Gradient.new()
	curve.set_color(0, Color(0.06, 0.04, 0.055))
	curve.set_color(1, Color(1.0, 0.985, 0.95))
	var grade: GradientTexture1D = GradientTexture1D.new()
	grade.gradient = curve
	env.adjustment_color_correction = grade
	return env


func _make_painted_extras() -> Node3D:
	var extras: Node3D = Node3D.new()
	extras.name = "PaintedExtras"
	# The sun patch on the floor, bouncing back up into the room.
	for spot: Vector3 in PAINTED_BOUNCE_SPOTS:
		var bounce: OmniLight3D = OmniLight3D.new()
		bounce.position = spot
		bounce.light_color = Color(1.0, 0.72, 0.46)
		bounce.light_energy = PAINTED_BOUNCE_ENERGY
		bounce.omni_range = 7.0
		bounce.omni_attenuation = 0.6
		bounce.light_specular = 0.0
		bounce.light_volumetric_fog_energy = 0.0
		extras.add_child(bounce)
	return extras


## Makes the shell's wood richer and more orange, or puts it back.
func _paint_wood(on: bool) -> void:
	var shell: Node = get_node_or_null(^"Shell")
	if shell == null:
		return
	for found: Node in shell.find_children("*", "MeshInstance3D"):
		var mesh_node: MeshInstance3D = found as MeshInstance3D
		var wood: StandardMaterial3D = mesh_node.get_active_material(0) as StandardMaterial3D
		if wood == null:
			continue
		if not _wood_colors.has(wood):
			_wood_colors[wood] = wood.albedo_color
		var was: Color = _wood_colors[wood]
		if on and was.v > 0.2 and was.h < 0.12 and was.s > 0.25:
			wood.albedo_color = Color.from_hsv(lerpf(was.h, 0.08, 0.6),
					minf(was.s * PAINTED_WOOD_SATURATION, 1.0),
					minf(was.v * PAINTED_WOOD_VALUE, 1.0))
		else:
			wood.albedo_color = was


func _loop_first_animation(shown: bool, character: ThirdPartyModel) -> void:
	if not shown:
		return
	var players: Array[Node] = character.model.find_children("*", "AnimationPlayer")
	if players.is_empty():
		return
	var player: AnimationPlayer = players[0] as AnimationPlayer
	var names: PackedStringArray = player.get_animation_list()
	if names.is_empty():
		return
	player.get_animation(names[0]).loop_mode = Animation.LOOP_LINEAR
	player.play(names[0])


func _add_buttons() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(16.0, 16.0)
	layer.add_child(column)
	column.add_child(_button("Stylised characters", stylised, set_stylised))
	column.add_child(_button("Outlines", outlined, set_outlined))
	column.add_child(_button("Golden cabin light", golden_light, set_golden))
	column.add_child(_button("Painted light (prototype)", painted, set_painted))
	column.add_child(_button("Cartoon finish (prototype)", cartoon, set_cartoon))


func _button(label: String, on: bool, action: Callable) -> CheckButton:
	var button: CheckButton = CheckButton.new()
	button.text = label
	button.button_pressed = on
	button.toggled.connect(action)
	return button


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_folder)
	var treatments: Array[Treatment] = [
		Treatment.new("plain_as_made", false, false, false),
		Treatment.new("golden_as_made", false, false, true),
		Treatment.new("golden_stylised", true, true, true),
		Treatment.new("golden_no_outline", true, false, true),
		Treatment.new("painted", true, true, true),
		Treatment.new("cartoon", true, true, true),
	]
	for treatment: Treatment in treatments:
		if not _only_treatment.is_empty() and treatment.name != _only_treatment:
			continue
		set_stylised(treatment.stylised)
		set_outlined(treatment.outlined)
		set_golden(treatment.golden)
		set_painted(treatment.name == "painted" or treatment.name == "cartoon")
		set_cartoon(treatment.name == "cartoon")
		for shot: Node in _shots.get_children():
			var mark: Node3D = shot as Node3D
			if mark == null:
				continue
			_camera.global_transform = mark.global_transform
			for frame: int in SETTLE_FRAMES:
				await get_tree().process_frame
			var picture: Image = get_viewport().get_texture().get_image()
			picture.save_png("%s/%s_%s.png" % [_capture_folder, mark.name.to_snake_case(),
					treatment.name])
