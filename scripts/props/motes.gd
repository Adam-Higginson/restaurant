class_name Motes
extends GPUParticles3D
## Specks of dust and spark drifting slowly through the warm air of a room,
## catching the lantern light: the galley's golden motes. They drift in a box
## [member extents] around this node and move with it (local coordinates),
## so they stay put in a sailing ship.

## Half the size of the box the motes drift in, in metres.
@export var extents: Vector3 = Vector3(2.0, 0.8, 2.0)
## How many motes float at once.
@export var count: int = 40


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
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fade.colors = PackedColorArray([
		Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0),
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
	material.emission_energy_multiplier = 3.0
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.02, 0.02)
	mesh.material = material

	process_material = process
	draw_pass_1 = mesh
	amount = count
	lifetime = 6.0
	preprocess = 6.0
	local_coords = true
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(-extents * 1.5, extents * 3.0)
