@tool
class_name Shore
extends Node
## Keeps the shore water and the sand in step. The water rises and falls up
## the beach every few seconds (the swash); the sand has to go dark and wet
## exactly where the water has just been. Both shaders work that out for
## themselves, so both must be given the same numbers: this node is the one
## place those numbers live, and it hands them to both materials.
##
## It also gives the water the ground's height picture (see
## [method IslandGround.height_texture]), which is how the water knows how
## deep it is at every spot.

## The ground the water laps against.
@export var ground: IslandGround
## The water's mesh. Its material must be a [ShaderMaterial] with
## shaders/shore_water.gdshader.
@export var water: MeshInstance3D
## The height of still water, in metres.
@export var sea_level: float = 0.0:
	set(value):
		sea_level = value
		apply()
## How far the water rises and falls with each wave, in metres. On a gentle
## beach a few centimetres of rise carries the edge a metre or two up the sand.
@export var swash_height: float = 0.09:
	set(value):
		swash_height = value
		apply()
## Seconds from one wave to the next.
@export var swash_period: float = 6.0:
	set(value):
		swash_period = value
		apply()


func _ready() -> void:
	if ground != null:
		ground.built.connect(apply)
	apply()


## How far up its rise the water is at [param time] seconds, from 0 (drawn
## right back) to 1 (as far up the beach as it gets). The shaders do this
## same sum, so gameplay can ask where the water is.
static func swash(time: float, period: float) -> float:
	return 0.5 + 0.5 * cos(TAU * (time / period - 0.1))


## The height of the water's edge at [param time] seconds.
func water_level(time: float) -> float:
	return sea_level + swash_height * swash(time, swash_period)


## Hands the shore's numbers to the water's and the sand's materials.
func apply() -> void:
	for material: ShaderMaterial in materials():
		material.set_shader_parameter(&"sea_level", sea_level)
		material.set_shader_parameter(&"swash_height", swash_height)
		material.set_shader_parameter(&"swash_period", swash_period)
	var water_material: ShaderMaterial = _water_material()
	if water_material != null and ground != null and ground.height_texture() != null:
		var rect: Rect2 = ground.height_rect()
		water_material.set_shader_parameter(&"ground_heights", ground.height_texture())
		water_material.set_shader_parameter(&"ground_corner", rect.position)
		water_material.set_shader_parameter(&"ground_size", rect.size)


## The materials that share the shore's numbers: the water's and the sand's.
func materials() -> Array[ShaderMaterial]:
	var found: Array[ShaderMaterial] = []
	var water_material: ShaderMaterial = _water_material()
	if water_material != null:
		found.append(water_material)
	if ground != null:
		var sand: ShaderMaterial = ground.material as ShaderMaterial
		if sand != null:
			found.append(sand)
	return found


func _water_material() -> ShaderMaterial:
	if water == null:
		return null
	return water.material_override as ShaderMaterial
