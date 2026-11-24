class_name LightFlow
extends Node3D
## The lantern's light pouring out of his hand into you, once your hands
## have closed (#183): a stream of golden motes from [member from] (his palm)
## to [member to] (your chest), and a warm glow growing in you as it fills.
## A clip moves [member flow] (how hard it pours) and [member filled] (how
## much of his light is in you now).
##
## Its children: [code]Motes[/code] (a [CPUParticles3D] that's moved to his
## palm and aimed at you every frame) and [code]Glow[/code] (an
## [OmniLight3D] kept at your chest).

## Where the light comes from: his palm.
@export var from: Node3D
## Where it goes: you.
@export var to: Node3D
## How hard the light is pouring, 0 (not at all) to 1.
@export_range(0.0, 1.0) var flow: float = 0.0:
	set(value):
		flow = clampf(value, 0.0, 1.0)
		_apply()
## How much of his light is in you, 0 (none) to 1.
@export_range(0.0, 1.0) var filled: float = 0.0:
	set(value):
		filled = clampf(value, 0.0, 1.0)
		_apply()
## How bright the glow in you is when you're full of his light.
@export var glow_energy: float = 4.0
## How long a mote takes to travel from his palm to you, in seconds.
@export var travel_seconds: float = 0.9

@onready var _motes: CPUParticles3D = $Motes
@onready var _glow: OmniLight3D = $Glow


func _ready() -> void:
	# Set once: changing a particle's lifetime restarts the stream.
	_motes.lifetime = travel_seconds
	_apply()


func _process(_delta: float) -> void:
	_follow()


## How fast a mote travels to cover the distance between the hand and you
## in [member travel_seconds], in metres a second.
func mote_speed() -> float:
	if not is_instance_valid(from) or not is_instance_valid(to) or travel_seconds <= 0.0:
		return 0.0
	return from.global_position.distance_to(to.global_position) / travel_seconds


func _follow() -> void:
	if not is_instance_valid(from) or not is_instance_valid(to):
		return
	if _motes == null:
		return
	_motes.global_position = from.global_position
	var toward: Vector3 = to.global_position - from.global_position
	if toward.length() > 0.01:
		# The motes' own space turns with this node's: aim in it.
		_motes.direction = _motes.global_basis.inverse() * toward.normalized()
	var speed: float = mote_speed()
	_motes.initial_velocity_min = speed * 0.9
	_motes.initial_velocity_max = speed * 1.1
	_glow.global_position = to.global_position


func _apply() -> void:
	if _motes == null:
		return
	_motes.emitting = flow > 0.0
	# Fainter as it eases off (the motes' material takes this colour).
	_motes.color = Color(1.0, 1.0, 1.0, flow)
	_glow.light_energy = filled * glow_energy
	_glow.light_volumetric_fog_energy = filled * 2.0
	_follow()
