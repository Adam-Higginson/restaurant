class_name TimeOfDay
extends Node
## Night or dawn at sea, and everything in between, from one number:
## [member dawn], 0 for the storm at night and 1 for a misty grey-rose
## morning. It blends the sky (its colours, cloud and moon), the world's
## ambient light, fog and exposure, the moonlight (which becomes a low warm
## sun) and how hard it rains. Sleeping in your bunk moves it on ([Bedside]).
##
## A second number, [member clear], carries the morning on to a clear bright
## day (#197): a blue sky with thin cloud, a warm sun, the fog drawn back, no
## rain, and the sea turning from slate to turquoise. The voyage montage turns
## it ([code]@clear[/code]); nothing else does yet, and it isn't saved.

## Emitted when [member dawn] changes.
signal changed(dawn: float)
## Emitted when a new day begins (you've slept through to morning).
signal day_began(day: int)

## Sky shader colours at night, at dawn, and on a clear day.
const SKY: Dictionary[String, Array] = {
	"top_color": [Color(0.02, 0.028, 0.042), Color(0.3, 0.34, 0.42), Color(0.1, 0.34, 0.8)],
	"horizon_color": [Color(0.09, 0.105, 0.125), Color(0.82, 0.62, 0.55),
			Color(0.56, 0.76, 0.92)],
	"below_color": [Color(0.01, 0.014, 0.02), Color(0.14, 0.16, 0.19), Color(0.12, 0.26, 0.34)],
	"cloud_color": [Color(0.06, 0.07, 0.085), Color(0.46, 0.47, 0.52), Color(0.96, 0.96, 0.98)],
	"lining_color": [Color(0.55, 0.62, 0.75), Color(1.0, 0.8, 0.66), Color(1.0, 0.96, 0.88)],
	"moon_color": [Color(0.86, 0.9, 1.0), Color(1.0, 0.86, 0.7), Color(1.0, 0.95, 0.84)],
}
## Sky shader numbers at night, at dawn, and on a clear day.
const SKY_NUMBERS: Dictionary[String, Vector3] = {
	"moon_energy": Vector3(4.0, 2.0, 3.0),
	"cloud_cover": Vector3(0.62, 0.5, 0.2),
}
## The water's colours at night (as at dawn: the sky's reflection does the
## changing) and on a clear day.
const WATER: Dictionary[String, Array] = {
	"deep_color": [Color(0.025, 0.06, 0.075), Color(0.02, 0.24, 0.32)],
	"crest_color": [Color(0.07, 0.22, 0.23), Color(0.1, 0.66, 0.64)],
}

## 0 night, 1 dawn.
@export_range(0.0, 1.0) var dawn: float = 0.0:
	set(value):
		var was_morning: bool = dawn >= 0.5
		dawn = clampf(value, 0.0, 1.0)
		if dawn >= 0.5 and not was_morning:
			day += 1
			day_began.emit(day)
		if is_node_ready():
			_apply()
		changed.emit(dawn)

## How far the morning has cleared into a bright day: 0 as [member dawn]
## has it, 1 clear blue sky and a turquoise sea.
@export_range(0.0, 1.0) var clear: float = 0.0:
	set(value):
		clear = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply()

## The world's environment and sky.
@export var world: WorldEnvironment
## The moon (at dawn, the sun).
@export var moon: DirectionalLight3D
## The weather, whose rain eases at dawn.
@export var weather: Weather

## How hard it rains at night, and at dawn.
@export var night_rain: float = 0.8
@export var dawn_rain: float = 0.15

## Which day at sea it is, from 1. Moves on each time night turns to morning.
var day: int = 1

## The colour grade's curve, and its own colours, kept to blend back to.
var _grade_curve: Gradient = null
var _grade_colours: PackedColorArray = PackedColorArray()


func _ready() -> void:
	add_to_group(&"time_of_day")
	_apply()


## Whether it's (nearer) morning than night.
func is_morning() -> bool:
	return dawn >= 0.5


## [param night] blended towards [param day] by [param t].
static func blend_colour(night: Color, day: Color, t: float) -> Color:
	return night.lerp(day, clampf(t, 0.0, 1.0))


## The colour now of something that's [param night] at night, [param dawn_to]
## at dawn and [param clear_to] on a clear day.
func colour_of(night: Color, dawn_to: Color, clear_to: Color) -> Color:
	return blend_colour(blend_colour(night, dawn_to, dawn), clear_to, clear)


## The number now of something that's [param night] at night, [param dawn_to]
## at dawn and [param clear_to] on a clear day.
func number_of(night: float, dawn_to: float, clear_to: float) -> float:
	return lerpf(lerpf(night, dawn_to, dawn), clear_to, clear)


# The night's colour grade (a curve per colour channel that cools and greys
# the picture) eases off to no grade at all as the day clears: a grey at each
# of its points is a curve that changes nothing.
func _grade(env: Environment) -> void:
	var texture: GradientTexture1D = env.adjustment_color_correction as GradientTexture1D
	if texture == null or texture.gradient == null:
		return
	if _grade_curve != texture.gradient:
		_grade_curve = texture.gradient
		_grade_colours = _grade_curve.colors.duplicate()
	var colours: PackedColorArray = PackedColorArray()
	for i: int in _grade_colours.size():
		var level: float = _grade_curve.offsets[i]
		colours.append(blend_colour(_grade_colours[i], Color(level, level, level), clear))
	_grade_curve.colors = colours


func _apply() -> void:
	if is_instance_valid(world) and world.environment != null:
		var env: Environment = world.environment
		env.ambient_light_energy = number_of(0.5, 1.1, 1.35)
		env.tonemap_exposure = number_of(1.25, 1.0, 1.0)
		env.fog_light_color = colour_of(Color(0.13, 0.155, 0.18), Color(0.56, 0.56, 0.6),
				Color(0.5, 0.7, 0.86))
		env.fog_depth_end = number_of(45.0, 80.0, 220.0)
		env.volumetric_fog_albedo = colour_of(Color(0.55, 0.6, 0.65), Color(0.85, 0.82, 0.8),
				Color(0.92, 0.95, 0.97))
		# Clear air: thinner fog, and none of it over the sky.
		env.fog_density = number_of(1.0, 1.0, 0.3)
		env.fog_sky_affect = number_of(0.5, 0.5, 0.05)
		env.volumetric_fog_density = number_of(0.03, 0.03, 0.006)
		_grade(env)
		var sky: ShaderMaterial = env.sky.sky_material as ShaderMaterial if env.sky != null else null
		if sky != null:
			for key: String in SKY:
				var three: Array = SKY[key]
				var at_night: Color = three[0]
				var at_dawn: Color = three[1]
				var when_clear: Color = three[2]
				sky.set_shader_parameter(key, colour_of(at_night, at_dawn, when_clear))
			for key: String in SKY_NUMBERS:
				var numbers: Vector3 = SKY_NUMBERS[key]
				sky.set_shader_parameter(key, number_of(numbers.x, numbers.y, numbers.z))
	if is_instance_valid(moon):
		moon.light_color = colour_of(Color(0.55, 0.65, 0.85), Color(1.0, 0.78, 0.6),
				Color(1.0, 0.94, 0.84))
		moon.light_energy = number_of(0.6, 1.3, 1.9)
	if is_instance_valid(weather):
		weather.intensity = number_of(night_rain, dawn_rain, 0.0)
	# The sea glows a little by itself at night so the swell reads in the dark;
	# by day it doesn't need to, and it mirrors a paler sky. On a clear day it
	# turns turquoise.
	var sea: Sea = get_tree().get_first_node_in_group(&"sea") as Sea if is_inside_tree() else null
	if sea != null and sea.material_override is ShaderMaterial:
		var water: ShaderMaterial = sea.material_override as ShaderMaterial
		water.set_shader_parameter("night_glow", number_of(0.6, 0.12, 0.05))
		water.set_shader_parameter("sky_reflection", colour_of(Color(0.2, 0.24, 0.28),
				Color(0.62, 0.58, 0.58), Color(0.34, 0.58, 0.76)))
		for key: String in WATER:
			var pair: Array = WATER[key]
			var usual: Color = pair[0]
			var turquoise: Color = pair[1]
			water.set_shader_parameter(key, blend_colour(usual, turquoise, clear))
