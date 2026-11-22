class_name CandleFlame
extends Node3D
## A candle's flame, wavering: it leans a little this way and that and
## stretches taller and shorter, on smooth noise rather than random jumps, so
## it breathes like a real flame instead of jittering. Put its origin at the
## wick, with the flame mesh as a child above it.
##
## Each flame wavers its own way, so a row of candles never moves in step.

## How far the flame leans at most, in degrees, either way.
@export var lean_degrees: float = 9.0
## How much taller or shorter it gets at most, as a fraction of its height.
@export_range(0.0, 1.0) var stretch: float = 0.25
## How quickly it wavers: higher is livelier.
@export var speed: float = 2.5

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0


func _init() -> void:
	_noise.seed = randi()
	_noise.frequency = 1.0
	_noise.fractal_octaves = 2


func _ready() -> void:
	_shape_to(0.0)


func _process(delta: float) -> void:
	_time += delta
	_shape_to(_time)


## The flame's shape at [param time] seconds: x and z are how far it leans
## about those axes, in radians, each within [member lean_degrees]; y is its
## height as a multiple of its own, within 1 ± [member stretch].
func shape_at(time: float) -> Vector3:
	var t: float = time * speed
	var widest: float = deg_to_rad(lean_degrees)
	return Vector3(
			widest * _waver(t, 0.0),
			1.0 + stretch * _waver(t, 37.0),
			widest * _waver(t, 71.0))


func _waver(t: float, offset: float) -> float:
	return clampf(_noise.get_noise_1d(t + offset) * 1.6, -1.0, 1.0)


func _shape_to(time: float) -> void:
	var shape: Vector3 = shape_at(time)
	rotation = Vector3(shape.x, 0.0, shape.z)
	scale = Vector3(1.0, shape.y, 1.0)
