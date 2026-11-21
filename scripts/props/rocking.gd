class_name Rocking
extends Node3D
## Something sitting loose aboard (a mug, a bowl, a row of jars) that moves
## with the sea: it tips and slides a touch from side to side across the
## ship, as if the boat were rolling under it, then back. It never goes far,
## so nothing falls off.
##
## Every rocking thing keeps time from the same clock (the physics frames
## since the game began), so the whole room's loose things lean together,
## like a real roll. A small [member phase] lets each lag a moment behind.
## Not physics, just a slow sway.

## The widest tip either way, in degrees.
@export var tip_degrees: float = 1.0
## The furthest it slides either way, in metres.
@export var slide_metres: float = 0.008
## Seconds for one full roll, there and back.
@export var period: float = 5.5
## How far behind the roll this one is, 0 to 1. Keep it small so the room
## still moves together.
@export_range(0.0, 1.0) var phase: float = 0.0

var _rest: Transform3D = Transform3D.IDENTITY
var _ship: Node3D = null


func _ready() -> void:
	_rest = transform
	_ship = _find_ship()
	apply(sea_time())


# On physics ticks, so it moves smoothly with physics interpolation like the
# ship around it.
func _physics_process(_delta: float) -> void:
	apply(sea_time())


## The shared clock every rocking thing keeps time by, in seconds.
static func sea_time() -> float:
	return float(Engine.get_physics_frames()) / Engine.physics_ticks_per_second


## How far through its roll this is at [param time], from -1 (leaning to
## port) to 1 (leaning to starboard).
func roll_at(time: float) -> float:
	if period <= 0.0:
		return 0.0
	return sin(TAU * (time / period - phase))


## Leans and slides to where the roll is at [param time].
func apply(time: float) -> void:
	var roll: float = roll_at(time)
	var along: Vector3 = Vector3.BACK
	var across: Vector3 = Vector3.RIGHT
	var parent: Node3D = get_parent_node_3d()
	if is_instance_valid(_ship) and parent != null:
		# The ship's length and width, seen from whatever this sits on.
		var to_parent: Basis = parent.global_basis.inverse()
		along = (to_parent * _ship.global_basis.z).normalized()
		across = (to_parent * _ship.global_basis.x).normalized()
	var tip: Basis = Basis(along, deg_to_rad(tip_degrees) * roll)
	transform = Transform3D(tip * _rest.basis, _rest.origin + across * slide_metres * roll)


# The ship this sits aboard, if any: the nearest [Ship] above it.
func _find_ship() -> Node3D:
	var node: Node = get_parent()
	while node != null:
		if node is Ship:
			return node as Node3D
		node = node.get_parent()
	return null
