class_name Lantern
extends Swinging
## A ship's lantern hanging from its hook: an iron frame and cap around
## glowing panes, with a warm light inside. It swings like any [Swinging]
## thing. One scene (lantern.tscn) is used for every lantern aboard; each
## sets how bright and how far its light reaches.

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


func _ready() -> void:
	super()
	add_to_group(GROUP)
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


func _show_flame() -> void:
	_light.visible = lit
	for pane: String in ["Pane1", "Pane2", "Pane3", "Pane4"]:
		var glass: Node3D = get_node_or_null(pane) as Node3D
		if glass != null:
			glass.visible = lit
