class_name Lamp
extends Node2D
## A ceiling lamp that casts a warm pool of light. The day light turns every
## lamp up and down with the time of day through [member level].
##
## Lamps join the [constant GROUP] group, so the day light finds them all
## without knowing where they are.

const GROUP: StringName = &"lamps"
const OFF_COLOR: Color = Color(0.35, 0.3, 0.25, 1)
const ON_COLOR: Color = Color(1.0, 0.86, 0.55, 1)
## The fitting drawn on the ceiling, centred on the lamp.
const FITTING_RADIUS: float = 3.0

## The light's energy when fully on. Lower it where the floor is pale and
## would wash out, such as the kitchen.
@export var max_energy: float = 1.0

## How far on the lamp is, from 0 (off) to 1 (fully on).
var level: float = 0.0:
	set(value):
		level = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_level()

@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group(GROUP)
	_apply_level()


func _draw() -> void:
	draw_circle(Vector2.ZERO, FITTING_RADIUS, OFF_COLOR.lerp(ON_COLOR, level))


func _apply_level() -> void:
	_light.energy = level * max_energy
	# A light at zero energy still costs a shadow pass, so switch it off.
	_light.enabled = level > 0.0
	queue_redraw()
