class_name Weather
extends Node
## The weather at sea: how hard it's raining, and whether the player is under
## a roof. One rain intensity drives everything that shows it: the rain
## falling ([RainEffect]), the rings on the sea ([Sea]), the sound
## ([Ambience]) and how wet every surface looks (the [code]wetness[/code]
## shader global, read by shaders/wet_surface.gdshader).
##
## It listens to every [ShelterZone] (the "shelters" group) to know when the
## player is under cover.

## Emitted when the rain gets heavier or lighter.
signal intensity_changed(intensity: float)
## Emitted when the player goes under a roof or back out.
signal sheltered_changed(sheltered: bool)

## The shader global every wet surface reads (Project Settings > Shader
## Globals).
const WETNESS: StringName = &"wetness"

## How hard it's raining: 0 dry, 1 a downpour.
@export_range(0.0, 1.0) var intensity: float = 0.8:
	set(value):
		var clamped: float = clampf(value, 0.0, 1.0)
		if is_equal_approx(clamped, intensity):
			return
		intensity = clamped
		intensity_changed.emit(intensity)
		_apply()
## The sea that shows rain rings. Optional.
@export var sea: Sea
## The falling rain. Optional.
@export var rain: RainEffect
## The camera the rain falls around, handed to [member rain].
@export var camera: Node3D
## The ship the rain lands on, handed to [member rain] so its splashes sail
## with it. Optional.
@export var ship: Ship

## Whether the player is under a roof right now.
var sheltered: bool:
	get:
		return _shelters_inside > 0

## How many shelter zones the player is inside (they can overlap).
var _shelters_inside: int = 0


func _ready() -> void:
	if is_instance_valid(rain):
		rain.camera = camera
		rain.carrier = ship
	# Once the whole scene is ready, so zones later in the tree have joined
	# the group too.
	_listen_to_shelters.call_deferred()
	_apply()


# Listens to every shelter zone in the scene.
func _listen_to_shelters() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"shelters"):
		var zone: ShelterZone = node as ShelterZone
		if zone != null and not zone.player_entered.is_connected(_on_player_entered):
			zone.player_entered.connect(_on_player_entered)
			zone.player_exited.connect(_on_player_exited)


# Shows the current rain everywhere it's shown.
func _apply() -> void:
	RenderingServer.global_shader_parameter_set(WETNESS, intensity)
	if is_inside_tree():
		get_tree().call_group(&"drips", &"set_wetness", intensity)
	if is_instance_valid(sea):
		sea.rain = intensity
	if is_instance_valid(rain):
		rain.intensity = intensity


func _on_player_entered() -> void:
	var was: bool = sheltered
	_shelters_inside += 1
	if sheltered != was:
		sheltered_changed.emit(sheltered)


func _on_player_exited() -> void:
	var was: bool = sheltered
	_shelters_inside = maxi(_shelters_inside - 1, 0)
	if sheltered != was:
		sheltered_changed.emit(sheltered)
