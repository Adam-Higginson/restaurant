class_name TimeOfDay
extends Node
## Night or dawn at sea, and everything in between, from one number:
## [member dawn], 0 for the storm at night and 1 for a misty grey-rose
## morning. It blends the sky (its colours, cloud and moon), the world's
## ambient light, fog and exposure, the moonlight (which becomes a low warm
## sun) and how hard it rains. Sleeping in your bunk moves it on ([Bedside]).

## Emitted when [member dawn] changes.
signal changed(dawn: float)

## Sky shader colours at night and at dawn.
const SKY: Dictionary[String, Array] = {
	"top_color": [Color(0.02, 0.028, 0.042), Color(0.3, 0.34, 0.42)],
	"horizon_color": [Color(0.09, 0.105, 0.125), Color(0.82, 0.62, 0.55)],
	"below_color": [Color(0.01, 0.014, 0.02), Color(0.14, 0.16, 0.19)],
	"cloud_color": [Color(0.06, 0.07, 0.085), Color(0.46, 0.47, 0.52)],
	"lining_color": [Color(0.55, 0.62, 0.75), Color(1.0, 0.8, 0.66)],
	"moon_color": [Color(0.86, 0.9, 1.0), Color(1.0, 0.86, 0.7)],
}
## Sky shader numbers at night and at dawn.
const SKY_NUMBERS: Dictionary[String, Vector2] = {
	"moon_energy": Vector2(4.0, 2.0),
	"cloud_cover": Vector2(0.62, 0.5),
}

## 0 night, 1 dawn.
@export_range(0.0, 1.0) var dawn: float = 0.0:
	set(value):
		dawn = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply()
		changed.emit(dawn)

## The world's environment and sky.
@export var world: WorldEnvironment
## The moon (at dawn, the sun).
@export var moon: DirectionalLight3D
## The weather, whose rain eases at dawn.
@export var weather: Weather

## How hard it rains at night, and at dawn.
@export var night_rain: float = 0.8
@export var dawn_rain: float = 0.15


func _ready() -> void:
	add_to_group(&"time_of_day")
	_apply()


## Whether it's (nearer) morning than night.
func is_morning() -> bool:
	return dawn >= 0.5


## [param night] blended towards [param day] by [param t].
static func blend_colour(night: Color, day: Color, t: float) -> Color:
	return night.lerp(day, clampf(t, 0.0, 1.0))


func _apply() -> void:
	if is_instance_valid(world) and world.environment != null:
		var env: Environment = world.environment
		env.ambient_light_energy = lerpf(0.5, 1.1, dawn)
		env.tonemap_exposure = lerpf(1.25, 1.0, dawn)
		env.fog_light_color = blend_colour(Color(0.13, 0.155, 0.18), Color(0.56, 0.56, 0.6), dawn)
		env.fog_depth_end = lerpf(45.0, 80.0, dawn)
		env.volumetric_fog_albedo = blend_colour(Color(0.55, 0.6, 0.65), Color(0.85, 0.82, 0.8), dawn)
		var sky: ShaderMaterial = env.sky.sky_material as ShaderMaterial if env.sky != null else null
		if sky != null:
			for key: String in SKY:
				var pair: Array = SKY[key]
				var night: Color = pair[0]
				var day: Color = pair[1]
				sky.set_shader_parameter(key, blend_colour(night, day, dawn))
			for key: String in SKY_NUMBERS:
				var range_of: Vector2 = SKY_NUMBERS[key]
				sky.set_shader_parameter(key, lerpf(range_of.x, range_of.y, dawn))
	if is_instance_valid(moon):
		moon.light_color = blend_colour(Color(0.55, 0.65, 0.85), Color(1.0, 0.78, 0.6), dawn)
		moon.light_energy = lerpf(0.6, 1.3, dawn)
	if is_instance_valid(weather):
		weather.intensity = lerpf(night_rain, dawn_rain, dawn)
	# The sea glows a little by itself at night so the swell reads in the dark;
	# by day it doesn't need to, and it mirrors a paler sky.
	var sea: Sea = get_tree().get_first_node_in_group(&"sea") as Sea if is_inside_tree() else null
	if sea != null and sea.material_override is ShaderMaterial:
		var water: ShaderMaterial = sea.material_override as ShaderMaterial
		water.set_shader_parameter("night_glow", lerpf(0.6, 0.12, dawn))
		water.set_shader_parameter("sky_reflection",
				blend_colour(Color(0.2, 0.24, 0.28), Color(0.62, 0.58, 0.58), dawn))
