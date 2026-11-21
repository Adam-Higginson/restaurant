class_name ShelterZone
extends Area3D
## A space with a roof, like the galley below deck. While the player is inside
## one, the rain sounds muffled. (The roof itself keeps the rain off: drops
## land on whatever is above, see [RainEffect].) [Weather] finds
## every zone in the "shelters" group and listens to it.
##
## Give it a [CollisionShape3D] child covering the sheltered space.

## Emitted when the player comes in under this roof.
signal player_entered
## Emitted when the player leaves.
signal player_exited


func _ready() -> void:
	add_to_group(&"shelters")
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is Player3D:
		player_entered.emit()


func _on_body_exited(body: Node3D) -> void:
	if body is Player3D:
		player_exited.emit()
