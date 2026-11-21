class_name Flicker
extends OmniLight3D
## Firelight: a light whose brightness wavers like flames, never steady and
## never jumpy. The waver comes from smooth noise rather than random jumps,
## so it breathes rather than strobes.

## The brightness it wavers around.
@export var base_energy: float = 2.5
## How far it wavers either way, as a fraction of [member base_energy].
@export_range(0.0, 1.0) var amount: float = 0.25
## How quickly it wavers: higher is a livelier fire.
@export var speed: float = 6.0

var _noise: FastNoiseLite = FastNoiseLite.new()
var _time: float = 0.0


func _init() -> void:
	# Each fire wavers its own way.
	_noise.seed = randi()
	_noise.frequency = 1.0
	_noise.fractal_octaves = 3


func _ready() -> void:
	light_energy = energy_at(0.0)


func _process(delta: float) -> void:
	_time += delta
	light_energy = energy_at(_time)


## The brightness at [param time] seconds, always within
## [member base_energy] times (1 ± [member amount]).
func energy_at(time: float) -> float:
	var waver: float = clampf(_noise.get_noise_1d(time * speed) * 1.6, -1.0, 1.0)
	return base_energy * (1.0 + amount * waver)
