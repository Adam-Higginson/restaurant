class_name RainEffect
extends Node3D
## The falling rain: thin streaks in a box around the camera that land on
## whatever is below them. Only the space around the camera rains, so it costs
## the same however big the sea is.
##
## A drop lands where a [GPUParticlesCollisionHeightField3D] says something is
## (the ship has one covering it, called RainCatcher). There the drop vanishes
## and a splash ring spreads where it hit: on the deck, the rail, a barrel or
## your head. Below deck the deck above catches the rain, so nothing falls
## there except through the open hatch. Over the open sea the drops fall
## through, and the water shader draws its own rings.
##
## Both particle systems are built here in code, so every setting is in one
## place. [Weather] sets [member intensity].

## How many streaks fall in a downpour (intensity 1).
const STREAK_COUNT: int = 6000
## The most splashes alive at once. Each drop that lands makes one.
const SPLASH_COUNT: int = 1500
## The streaks fall from this high above the camera.
const STREAK_HEIGHT: float = 9.0
## Half the size of the box streaks start in, across.
const STREAK_SPREAD: float = 14.0
## Moves each drop, and splashes it when it lands.
const DROPS_SHADER: Shader = preload("res://shaders/rain_drops.gdshader")

## The camera the rain surrounds.
@export var camera: Node3D
## Wind pushing the rain sideways, in metres per second.
@export var wind: Vector3 = Vector3(1.5, 0.0, 0.8)

## How hard it's raining: 0 none, 1 a downpour.
var intensity: float = 1.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_update_emitting()

var _streaks: GPUParticles3D = null
var _splashes: GPUParticles3D = null


func _ready() -> void:
	_streaks = _make_streaks()
	_splashes = _make_splashes()
	add_child(_streaks)
	add_child(_splashes)
	# Every drop that lands starts one splash where it landed.
	_streaks.sub_emitter = _streaks.get_path_to(_splashes)
	_update_emitting()


# Every frame, so the rain moves with the camera as smoothly as it does. The
# particles live in world space, so moving the emitters doesn't drag drops
# already falling.
func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		_streaks.global_position = camera.global_position + Vector3.UP * STREAK_HEIGHT
		_splashes.global_position = camera.global_position


## Whether streaks are falling right now.
func is_raining() -> bool:
	return _streaks != null and _streaks.emitting


## The particles that make the splashes, for tests and tuning.
func splashes() -> GPUParticles3D:
	return _splashes


## The falling streaks, for tests and tuning.
func streaks() -> GPUParticles3D:
	return _streaks


func _update_emitting() -> void:
	if _streaks == null:
		return
	_streaks.emitting = intensity > 0.0
	_streaks.amount_ratio = intensity


func _make_streaks() -> GPUParticles3D:
	# Our own particles shader rather than a ParticleProcessMaterial: the
	# built-in "hide on contact" removes a drop before it can start its
	# splash, so the shader does both itself, in the right order.
	var process: ShaderMaterial = ShaderMaterial.new()
	process.shader = DROPS_SHADER
	process.set_shader_parameter("box_extents", Vector3(STREAK_SPREAD, 0.5, STREAK_SPREAD))
	process.set_shader_parameter("wind", wind)

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.006, 0.5, 0.006)
	mesh.material = _rain_material(Color(0.62, 0.7, 0.78, 0.16))

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "Streaks"
	particles.amount = STREAK_COUNT
	particles.lifetime = 1.1
	particles.preprocess = 1.1
	particles.local_coords = false
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.collision_base_size = 0.02
	# Drops fall about 0.3 m a step at 60 steps a second, less than the deck
	# is thick, so none is ever drawn poking through into the galley.
	particles.fixed_fps = 60
	particles.interpolate = false
	particles.visibility_aabb = AABB(Vector3(-20, -25, -20), Vector3(40, 30, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


func _make_splashes() -> GPUParticles3D:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.gravity = Vector3.ZERO
	# Each splash starts as a small bright ring and spreads, fading.
	var grow: Curve = Curve.new()
	grow.add_point(Vector2(0.0, 0.25))
	grow.add_point(Vector2(1.0, 1.0), 0.0, 0.0)
	var grow_texture: CurveTexture = CurveTexture.new()
	grow_texture.curve = grow
	process.scale_curve = grow_texture
	process.scale_min = 0.7
	process.scale_max = 1.3
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.55))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var fade_texture: GradientTexture1D = GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture

	# A flat ring lying on whatever the drop hit.
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.16, 0.16)
	mesh.orientation = PlaneMesh.FACE_Y
	var material: StandardMaterial3D = _rain_material(Color(0.7, 0.76, 0.82, 1.0))
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = _ring_texture()
	mesh.material = material

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "Splashes"
	particles.amount = SPLASH_COUNT
	particles.lifetime = 0.28
	particles.local_coords = false
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.visibility_aabb = AABB(Vector3(-20, -20, -20), Vector3(40, 40, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


# A soft ring: clear in the middle, bright near the edge, clear outside.
func _ring_texture() -> GradientTexture2D:
	var ring: Gradient = Gradient.new()
	ring.offsets = PackedFloat32Array([0.0, 0.55, 0.8, 1.0])
	ring.colors = PackedColorArray([
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.15), Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.0),
	])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = ring
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 32
	texture.height = 32
	return texture


func _rain_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.disable_receive_shadows = true
	# Fade out drops right in front of the lens, which would otherwise be
	# huge bright smears.
	material.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_PIXEL_ALPHA
	material.distance_fade_min_distance = 0.4
	material.distance_fade_max_distance = 1.6
	return material
