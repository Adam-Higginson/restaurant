class_name Sea
extends MeshInstance3D
## The sea around the ship: a big, finely divided plane drawn by the water
## shader (shaders/water.gdshader), with waves from [member settings].
##
## Every frame it keeps the plane centred under the ship and hands the shader
## its uniforms. The ship's body never moves up and down (the deck must stay
## level for walking and cooking), so instead the sea moves around it: the
## plane is lowered by the wave height under the ship, so the swell rises and
## falls past the hull. The ship itself never tilts.

## The waves. Shared with [Waves], so heights asked about match what's drawn.
@export var settings: WaveSettings
## The ship riding the sea. Optional: without one the sea stays put.
@export var ship: Ship
## Half the hull's width and length, in metres: where the water is cut out,
## and where hull foam forms.
@export var hull_half: Vector2 = Vector2(6.0, 15.0)
## How far the pointed bow reaches forward of that box at the waterline, in
## metres. The water is cut out and foams round it too.
@export var bow_reach: float = 3.6
## The plane moves in steps this long, so its vertices never slide across the
## waves (which would make them shimmer).
@export var grid_step: float = 4.0

## Rain intensity, 0 to 1, for the rain rings. Set by the weather.
var rain: float = 0.0:
	set(value):
		rain = clampf(value, 0.0, 1.0)

## How much of the Grave of the Lanterns shows far below the surface, 0 to
## 1: a few faint lights at different depths that stay put under the water
## as the camera moves. 0 (the open sea) unless a cutscene brings it up with
## [code]@grave on[/code] (see [SeaCues]).
var grave: float = 0.0:
	set(value):
		grave = clampf(value, 0.0, 1.0)

## Seconds of wave time. Shared with [Waves] calls so they agree with the shader.
var time: float:
	get:
		return _time

var _time: float = 0.0
var _material: ShaderMaterial = null


func _ready() -> void:
	# So things aboard (a fishing float) can find the water's height.
	add_to_group(&"sea")
	_material = material_override as ShaderMaterial
	_follow_ship()
	_apply()


# On rendered frames, following where the ship is drawn, so the water and
# the hull never drift apart between physics ticks.
func _process(delta: float) -> void:
	_time += delta
	_follow_ship()
	_apply()


## How high the sea's surface is at world spot [param spot] (x and z) right
## now, above its still level, before the plane is lowered for the ship.
func height_at(spot: Vector2) -> float:
	if settings == null:
		return 0.0
	return Waves.height_at(settings, spot, _time)


# Centres the plane under the ship (in grid steps) and lowers it by the wave
# height there, so the waterline stays put on the hull while the sea moves.
func _follow_ship() -> void:
	if not is_instance_valid(ship):
		return
	var at: Transform3D = ship.get_global_transform_interpolated()
	var spot: Vector2 = Vector2(at.origin.x, at.origin.z)
	global_position = Vector3(
		snappedf(spot.x, grid_step),
		at.origin.y - height_at(spot),
		snappedf(spot.y, grid_step),
	)


# Hands the shader the waves, the time, the hull and the weather.
func _apply() -> void:
	if _material == null or settings == null:
		return
	var a: PackedVector4Array = PackedVector4Array()
	var b: PackedVector4Array = PackedVector4Array()
	for layer: WaveLayer in settings.used_layers():
		var dir: Vector2 = layer.direction()
		a.append(Vector4(dir.x, dir.y, layer.wave_number(), layer.speed()))
		b.append(Vector4(layer.amplitude, layer.sideways(), 0.0, 0.0))
	while a.size() < WaveSettings.MAX_LAYERS:
		a.append(Vector4.ZERO)
		b.append(Vector4.ZERO)
	_material.set_shader_parameter("wave_count", settings.used_layers().size())
	_material.set_shader_parameter("wave_a", a)
	_material.set_shader_parameter("wave_b", b)
	_material.set_shader_parameter("wave_time", _time * settings.time_scale)
	_material.set_shader_parameter("rain", rain)
	_material.set_shader_parameter("grave", grave)
	_material.set_shader_parameter("hull_half", hull_half)
	_material.set_shader_parameter("bow_reach", bow_reach)
	if is_instance_valid(ship):
		var hull: Transform3D = ship.get_global_transform_interpolated()
		_material.set_shader_parameter("hull_inverse", Projection(hull.affine_inverse()))
		_material.set_shader_parameter("wake", ship.way)
