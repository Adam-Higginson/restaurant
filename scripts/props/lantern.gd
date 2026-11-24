class_name Lantern
extends Swinging
## A ship's lantern hanging from its hook: an iron frame and cap around
## clear glass with a flame burning inside (lantern_flame.gdshader, #199),
## and a warm light. It swings like any [Swinging] thing. One scene
## (lantern.tscn) is used for every lantern aboard; each sets how bright and
## how far its light reaches, and flickers its own way.

## The group every lantern is in, so a scene in daylight can put them all
## out (see [Island]).
const GROUP: StringName = &"lanterns"

## Whether it's burning: its light on and its flame showing.
@export var lit: bool = true:
	set(value):
		lit = value
		if is_node_ready():
			_show_flame()
## How bright the lantern's light is.
@export var light_energy: float = 1.4
## How far its light reaches, in metres.
@export var light_range: float = 7.0
## Whether its light casts shadows. Shadows from point lights are costly, so
## only the lanterns that light the important things cast them.
@export var casts_shadows: bool = true
## How much the flame makes the light waver, as a fraction of its brightness:
## a little, so the light breathes without flashing.
@export_range(0.0, 0.5) var flicker: float = 0.08

@onready var _light: Flicker = $Light
@onready var _glass: GeometryInstance3D = $Glass


func _ready() -> void:
	super()
	add_to_group(GROUP)
	# Every lantern shares one glass material; each gets its own flicker.
	_glass.set_instance_shader_parameter(&"own_seed", randf() * 10.0)
	_light.base_energy = light_energy
	_light.amount = flicker
	_light.speed = 2.5
	_light.light_energy = _light.energy_at(0.0)
	_light.omni_range = light_range
	_light.shadow_enabled = casts_shadows
	_show_flame()


## Lights the lantern or puts it out.
func set_lit(burning: bool) -> void:
	lit = burning


## How much the flame behind the glass is burning: 1 lit, 0 out (the glass
## still shows, with an empty lantern and a dark wick behind it).
func flame_burning() -> float:
	var burning: float = _glass.get_instance_shader_parameter(&"burning")
	return burning


func _show_flame() -> void:
	_light.visible = lit
	_glass.set_instance_shader_parameter(&"burning", 1.0 if lit else 0.0)
