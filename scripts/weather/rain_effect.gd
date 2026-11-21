class_name RainEffect
extends Node3D
## The falling rain: thin streaks around the camera and small splashes at
## the player's feet. Only the space around the camera rains, so it costs the
## same however big the sea is. Hidden under a roof.
##
## Both particle systems are built here in code, so every setting is in one
## place. [Weather] sets [member intensity] and [member sheltered].

## How many streaks fall in a downpour (intensity 1).
const STREAK_COUNT: int = 6000
## How many splashes land in a downpour.
const SPLASH_COUNT: int = 120
## The streaks fall from this high above the camera.
const STREAK_HEIGHT: float = 9.0
## Half the size of the box streaks start in, across.
const STREAK_SPREAD: float = 14.0
## Half the size of the patch splashes land on, around the player's feet.
const SPLASH_SPREAD: float = 2.2

## The camera the rain surrounds.
@export var camera: Node3D
## The player whose feet the splashes surround.
@export var player: Node3D
## Wind pushing the rain sideways, in metres per second.
@export var wind: Vector3 = Vector3(1.5, 0.0, 0.8)

## How hard it's raining: 0 none, 1 a downpour.
var intensity: float = 1.0:
	set(value):
		intensity = clampf(value, 0.0, 1.0)
		_update_emitting()
## Whether the player is under a roof, so no rain falls around them.
var sheltered: bool = false:
	set(value):
		sheltered = value
		_update_emitting()

var _streaks: GPUParticles3D = null
var _splashes: GPUParticles3D = null


func _ready() -> void:
	_streaks = _make_streaks()
	_splashes = _make_splashes()
	add_child(_streaks)
	add_child(_splashes)
	_update_emitting()


# Every frame, so the rain moves with the camera as smoothly as it does.
func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		_streaks.global_position = camera.global_position + Vector3.UP * STREAK_HEIGHT
	if is_instance_valid(player):
		_splashes.global_position = player.global_position + Vector3.UP * 0.03


## Whether streaks are falling right now.
func is_raining() -> bool:
	return _streaks != null and _streaks.emitting


func _update_emitting() -> void:
	if _streaks == null:
		return
	var on: bool = intensity > 0.0 and not sheltered
	_streaks.emitting = on
	_splashes.emitting = on
	_streaks.amount_ratio = intensity
	_splashes.amount_ratio = intensity


func _make_streaks() -> GPUParticles3D:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(STREAK_SPREAD, 0.5, STREAK_SPREAD)
	process.direction = Vector3(0.0, -1.0, 0.0)
	process.spread = 2.0
	process.initial_velocity_min = 15.0
	process.initial_velocity_max = 19.0
	process.gravity = wind
	process.particle_flag_align_y = true

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
	particles.visibility_aabb = AABB(Vector3(-20, -25, -20), Vector3(40, 30, 40))
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


func _make_splashes() -> GPUParticles3D:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(SPLASH_SPREAD, 0.0, SPLASH_SPREAD)
	process.gravity = Vector3.ZERO
	# Each splash starts as a dot and spreads into a fading ring.
	var grow: Curve = Curve.new()
	grow.add_point(Vector2(0.0, 0.2))
	grow.add_point(Vector2(1.0, 1.0))
	var grow_texture: CurveTexture = CurveTexture.new()
	grow_texture.curve = grow
	process.scale_curve = grow_texture
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.18))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var fade_texture: GradientTexture1D = GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.14, 0.004, 0.14)
	var material: StandardMaterial3D = _rain_material(Color(0.5, 0.55, 0.6, 1.0))
	material.vertex_color_use_as_albedo = true
	mesh.material = material

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "Splashes"
	particles.amount = SPLASH_COUNT
	particles.lifetime = 0.3
	particles.local_coords = false
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


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
