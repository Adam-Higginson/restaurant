class_name Motes
extends GPUParticles3D
## Soft glowing fireflies drifting slowly through the warm air of a room and
## twinkling as they go: the galley's golden motes. They drift in a box
## [member extents] around this node and move with it (local coordinates),
## so they stay put in a sailing ship.

## Half the size of the box the motes drift in, in metres.
@export var extents: Vector3 = Vector3(2.0, 0.8, 2.0)
## How many motes float at once.
@export var count: int = 22


func _ready() -> void:
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.gravity = Vector3(0.0, 0.02, 0.0)
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.05
	process.spread = 180.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.15
	process.turbulence_noise_scale = 2.0
	var fade: Gradient = Gradient.new()
	# Each one twinkles: brightening and dimming a few times over its life.
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.3, 0.45, 0.6, 0.75, 1.0])
	fade.colors = PackedColorArray([
		Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.25), Color(1, 1, 1, 1),
		Color(1, 1, 1, 0.3), Color(1, 1, 1, 1), Color(1, 1, 1, 0),
	])
	var fade_texture: GradientTexture1D = GradientTexture1D.new()
	fade_texture.gradient = fade
	process.color_ramp = fade_texture

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1.0, 0.78, 0.35, 0.8)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.3)
	material.emission_energy_multiplier = 4.0
	# The soft gradient gives each mote a bright centre and a round edge (#137).
	var soft: Gradient = Gradient.new()
	soft.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
	soft.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
	var disc: GradientTexture2D = GradientTexture2D.new()
	disc.gradient = soft
	disc.fill = GradientTexture2D.FILL_RADIAL
	disc.fill_from = Vector2(0.5, 0.5)
	disc.fill_to = Vector2(1.0, 0.5)
	disc.width = 16
	disc.height = 16
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.albedo_texture = disc
	material.emission_texture = disc
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.05, 0.05)
	mesh.material = material

	process_material = process
	draw_pass_1 = mesh
	amount = count
	lifetime = 6.0
	preprocess = 6.0
	local_coords = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-extents * 1.5, extents * 3.0)
