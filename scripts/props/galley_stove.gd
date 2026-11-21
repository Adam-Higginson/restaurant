class_name GalleyStove
extends StaticBody3D
## The galley's hearth: a cast-iron ship's stove with a fire behind its door,
## a pot steaming on top and embers drifting up from the door's grate. Its
## firelight ([Flicker]) is the warmest light aboard.
##
## The steam and embers are particle systems built here in code, so their
## settings sit in one place (like [RainEffect]). They start at the
## SteamSpot and EmberSpot markers, and move with the stove (local
## coordinates), so they rise straight up on a sailing ship.

## Puffs of steam a second from the pot.
@export var steam_rate: float = 9.0
## Embers a second from the fire door.
@export var ember_rate: float = 3.0

var _steam: GPUParticles3D = null
var _embers: GPUParticles3D = null

@onready var _steam_spot: Marker3D = $SteamSpot
@onready var _ember_spot: Marker3D = $EmberSpot


func _ready() -> void:
	_steam = _make_steam()
	_steam_spot.add_child(_steam)
	_embers = _make_embers()
	_ember_spot.add_child(_embers)


## The steam rising from the pot.
func steam() -> GPUParticles3D:
	return _steam


## The embers drifting from the fire.
func embers() -> GPUParticles3D:
	return _embers


func _make_steam() -> GPUParticles3D:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.08
	process.direction = Vector3.UP
	process.spread = 12.0
	process.initial_velocity_min = 0.25
	process.initial_velocity_max = 0.4
	process.gravity = Vector3(0.05, 0.08, 0.0)
	process.damping_min = 0.05
	process.damping_max = 0.1
	# Each puff swells and thins out as it rises.
	process.scale_min = 0.6
	process.scale_max = 1.0
	process.scale_curve = _curve_texture([Vector2(0.0, 0.3), Vector2(1.0, 1.6)])
	process.color_ramp = _fade([0.0, 0.2, 1.0], [0.0, 0.12, 0.0])

	var material: StandardMaterial3D = _soft_material(Color(0.95, 0.93, 0.9, 1.0))
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.35, 0.35)
	mesh.material = material

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "Steam"
	particles.local_coords = true
	particles.lifetime = 2.6
	particles.amount = maxi(ceili(steam_rate * particles.lifetime), 1)
	particles.preprocess = 2.6
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 3, 2))
	return particles


func _make_embers() -> GPUParticles3D:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.12, 0.04, 0.02)
	process.direction = Vector3(0.0, 1.0, 0.6)
	process.spread = 25.0
	process.initial_velocity_min = 0.2
	process.initial_velocity_max = 0.45
	# Warm air lifts them; a wobble makes them drift rather than fly straight.
	process.gravity = Vector3(0.0, 0.25, 0.0)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.4
	process.turbulence_noise_scale = 1.5
	process.scale_min = 0.6
	process.scale_max = 1.2
	process.color_ramp = _fade([0.0, 0.1, 0.7, 1.0], [0.0, 1.0, 0.8, 0.0])

	var material: StandardMaterial3D = _soft_material(Color(1.0, 0.55, 0.18, 1.0))
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.12)
	material.emission_energy_multiplier = 6.0
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.025, 0.025)
	mesh.material = material

	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.name = "Embers"
	particles.local_coords = true
	particles.lifetime = 2.2
	particles.amount = maxi(ceili(ember_rate * particles.lifetime), 1)
	particles.process_material = process
	particles.draw_pass_1 = mesh
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.visibility_aabb = AABB(Vector3(-1, -0.5, -1), Vector3(2, 3, 2))
	return particles


# A camera-facing soft round puff that fades by the particles' colour.
func _soft_material(color: Color) -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var soft: Gradient = Gradient.new()
	soft.set_color(0, Color(1, 1, 1, 1))
	soft.set_color(1, Color(1, 1, 1, 0))
	var disc: GradientTexture2D = GradientTexture2D.new()
	disc.gradient = soft
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(1.0, 0.5)
	disc.width = 32
	disc.height = 32
	material.albedo_texture = disc
	return material


func _curve_texture(points: Array[Vector2]) -> CurveTexture:
	var curve: Curve = Curve.new()
	curve.max_value = 2.0
	for point: Vector2 in points:
		curve.add_point(point)
	var texture: CurveTexture = CurveTexture.new()
	texture.curve = curve
	return texture


# A white ramp whose alpha passes through [param alphas] at [param offsets].
func _fade(offsets: Array[float], alphas: Array[float]) -> GradientTexture1D:
	var gradient: Gradient = Gradient.new()
	var packed_offsets: PackedFloat32Array = PackedFloat32Array()
	var colors: PackedColorArray = PackedColorArray()
	for i: int in offsets.size():
		packed_offsets.append(offsets[i])
		colors.append(Color(1, 1, 1, alphas[i]))
	gradient.offsets = packed_offsets
	gradient.colors = colors
	var texture: GradientTexture1D = GradientTexture1D.new()
	texture.gradient = gradient
	return texture
