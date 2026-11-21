class_name Sea
extends MeshInstance3D
## The sea around the ship: a big, finely divided plane drawn by the water
## shader (shaders/water.gdshader), with waves from [member settings].
##
## Every frame it keeps the plane centred under the ship and hands the shader
## its uniforms. The ship's body never moves up and down (the deck must stay
## level for walking and cooking), so instead the sea moves around it: the
## plane is lowered by the wave height under the ship, so the swell rises and
## falls past the hull, and the ship's visuals tilt a little with the slope.

## The waves. Shared with [Waves], so heights asked about match what's drawn.
@export var settings: WaveSettings
## The ship riding the sea. Optional: without one the sea stays put.
@export var ship: Ship
## Half the hull's width and length, in metres: where the water is cut out,
## and where hull foam forms.
@export var hull_half: Vector2 = Vector2(6.0, 15.0)
## The plane moves in steps this long, so its vertices never slide across the
## waves (which would make them shimmer).
@export var grid_step: float = 4.0
## The most the ship's visuals tilt with the swell, in degrees. Kept small:
## the deck you walk on stays level, so big tilts would show your feet
## floating.
@export var max_tilt_degrees: float = 3.0

## Rain intensity, 0 to 1, for the rain rings. Set by the weather.
var rain: float = 0.0:
	set(value):
		rain = clampf(value, 0.0, 1.0)

## Seconds of wave time. Shared with [Waves] calls so they agree with the shader.
var time: float:
	get:
		return _time

var _time: float = 0.0
var _material: ShaderMaterial = null


func _ready() -> void:
	_material = material_override as ShaderMaterial
	_follow_ship()
	_apply()


# On rendered frames, following where the ship is drawn, so the water and
# the hull never drift apart between physics ticks.
func _process(delta: float) -> void:
	_time += delta
	_follow_ship()
	_apply()


# The tilt goes to the ship on physics ticks, when it moves its visuals, so
# physics interpolation smooths it like the rest of the ship.
func _physics_process(_delta: float) -> void:
	if is_instance_valid(ship):
		ship.swell_tilt = tilt_under(ship.global_transform)


## How high the sea's surface is at world spot [param spot] (x and z) right
## now, above its still level, before the plane is lowered for the ship.
func height_at(spot: Vector2) -> float:
	if settings == null:
		return 0.0
	return Waves.height_at(settings, spot, _time)


## The pitch (x) and roll (z) the ship's visuals should have on the swell
## under [param ship_transform], in radians, each within
## [member max_tilt_degrees]. Pitch lifts the bow; roll lifts the starboard
## side.
func tilt_under(ship_transform: Transform3D) -> Vector2:
	var bow: Vector3 = ship_transform * Vector3(0.0, 0.0, -hull_half.y)
	var stern: Vector3 = ship_transform * Vector3(0.0, 0.0, hull_half.y)
	var port: Vector3 = ship_transform * Vector3(-hull_half.x, 0.0, 0.0)
	var starboard: Vector3 = ship_transform * Vector3(hull_half.x, 0.0, 0.0)
	var rise_bow: float = height_at(Vector2(bow.x, bow.z)) - height_at(Vector2(stern.x, stern.z))
	var rise_starboard: float = height_at(Vector2(starboard.x, starboard.z)) \
			- height_at(Vector2(port.x, port.z))
	var limit: float = deg_to_rad(max_tilt_degrees)
	var pitch: float = clampf(atan2(rise_bow, hull_half.y * 2.0), -limit, limit)
	var roll: float = clampf(atan2(rise_starboard, hull_half.x * 2.0), -limit, limit)
	return Vector2(pitch, roll)


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
	_material.set_shader_parameter("hull_half", hull_half)
	if is_instance_valid(ship):
		var hull: Transform3D = ship.get_global_transform_interpolated()
		_material.set_shader_parameter("hull_inverse", Projection(hull.affine_inverse()))
		_material.set_shader_parameter("wake", 1.0 if ship.is_sailing else 0.0)
