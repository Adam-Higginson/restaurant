class_name Drips
extends GPUParticles3D
## Water dripping off an edge: the hatch rim, the foot of the sail. Drops
## form somewhere along a line ([member length] long, along local x), fall
## and vanish when they hit something a particle collider covers.
##
## Drips only fall while it's wet: the [Weather] calls [method set_wetness]
## on everything in the "drips" group.

## How long the dripping edge is, in metres, along local x.
@export var length: float = 2.0
## Drops a second along the whole edge when soaked.
@export var rate: float = 12.0

## How wet it is, 0 to 1: how many of the drops fall.
var wetness: float = 1.0:
	set(value):
		wetness = clampf(value, 0.0, 1.0)
		amount_ratio = wetness
		emitting = wetness > 0.0


func _ready() -> void:
	add_to_group(&"drips")
	var process: ParticleProcessMaterial = ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(length / 2.0, 0.0, 0.01)
	process.direction = Vector3.DOWN
	process.spread = 0.0
	process.initial_velocity_min = 0.0
	process.initial_velocity_max = 0.3
	process.gravity = Vector3(0.0, -9.8, 0.0)
	process.particle_flag_align_y = true
	process.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT

	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = Vector3(0.012, 0.07, 0.012)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.75, 0.8, 0.85, 0.45)
	mesh.material = material

	process_material = process
	draw_pass_1 = mesh
	lifetime = 1.6
	amount = maxi(ceili(rate * lifetime), 1)
	# Drops belong to whatever they drip from, so they fall straight down onto
	# the deck of a sailing ship instead of trailing behind it.
	local_coords = true
	collision_base_size = 0.02
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3(-length, -12.0, -1.0), Vector3(length * 2.0, 13.0, 2.0))
	wetness = wetness


## Sets how wet it is. Called by the [Weather] on the "drips" group.
func set_wetness(value: float) -> void:
	wetness = value
