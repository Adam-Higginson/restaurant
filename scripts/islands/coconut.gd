class_name Coconut
extends RigidBody3D
## A fallen coconut lying on the sand. Walk into it and it rolls away.
##
## A [RigidBody3D] is a thing the physics engine moves by itself: it falls,
## rolls and comes to rest. The player's body doesn't shove rigid bodies
## about, so the coconut does it for itself: when someone moving comes
## within reach it gives itself a kick (an impulse: a sudden push) the way
## they were going. It's on a physics layer of its own, so it rests on the
## ground but never blocks the player or a crab.

## Emitted when someone walks into it and sends it rolling.
signal kicked

## The physics layer coconuts are on (layer 3): nothing collides with them.
const LAYER: int = 1 << 2

## How close someone must come to kick it, in metres.
@export var kick_reach: float = 0.55
## How hard it's kicked, for each metre a second they were moving.
@export var kick_strength: float = 0.5
## How much of the kick goes upwards, so it hops before it rolls.
@export var kick_lift: float = 0.35
## The slowest walk that moves it, in metres a second.
@export var least_speed: float = 0.8
## How long before it can be kicked again, in seconds.
@export var rest_seconds: float = 0.4

var _rest_left: float = 0.0


func _ready() -> void:
	collision_layer = LAYER
	# It rests on the ground and props (layer 1) and on other coconuts.
	collision_mask = 1 | LAYER


func _physics_process(delta: float) -> void:
	if _rest_left > 0.0:
		_rest_left -= delta
		return
	for node: Node in get_tree().get_nodes_in_group(Player3D.GROUP):
		var walker: CharacterBody3D = node as CharacterBody3D
		if walker != null and try_kick(walker.global_position, walker.velocity):
			return


## Kicks the coconut if someone at [param from], moving at [param moving],
## is close enough and going fast enough. Returns whether it was kicked.
func try_kick(from: Vector3, moving: Vector3) -> bool:
	var apart: Vector3 = global_position - from
	apart.y = 0.0
	var going: Vector3 = Vector3(moving.x, 0.0, moving.z)
	if apart.length() > kick_reach or going.length() < least_speed:
		return false
	# Mostly the way they were going, a little away from them, and up a bit.
	var push: Vector3 = going * kick_strength + apart.normalized() * 0.4
	push.y = going.length() * kick_lift
	apply_central_impulse(push * mass)
	_rest_left = rest_seconds
	kicked.emit()
	return true
