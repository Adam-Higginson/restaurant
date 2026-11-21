class_name CarriedStack3D
extends Node3D
## Shows the item the player carries as a small model above their head.
## Bobs gently while the player walks.
##
## Display only: it reads the player's [Arms] and rebuilds when they change.

## How far the stack bobs up and down while walking, in metres.
@export var bob_height: float = 0.04
## Bobs per second while walking.
@export var bob_rate: float = 3.0

## Seconds spent walking since the player last stood still.
var _bob_time: float = 0.0
## Where the stack sits when not bobbing, as placed in the scene.
var _rest_height: float = 0.0

@onready var _player: Player3D = get_parent() as Player3D


func _ready() -> void:
	_rest_height = position.y
	_player.arms.changed.connect(_rebuild)
	_rebuild()


# On physics ticks, like the player: the stack is drawn part-way between ticks
# along with the body, so it moves smoothly with it.
func _physics_process(delta: float) -> void:
	if _player.is_walking:
		_bob_time += delta
	else:
		_bob_time = 0.0
	position.y = _rest_height + bob_offset(_bob_time, bob_height, bob_rate)


## How far the stack is lifted (or dropped) after [param walked] seconds of
## walking: a sine wave of [param height] metres at [param rate] bobs per
## second, starting from rest.
static func bob_offset(walked: float, height: float, rate: float) -> float:
	return sin(walked * rate * TAU) * height


# Throws the old model away and builds one of what's carried now.
func _rebuild() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var item: ItemInstance = _player.arms.top()
	if item != null:
		add_child(ItemModel.build(item))
