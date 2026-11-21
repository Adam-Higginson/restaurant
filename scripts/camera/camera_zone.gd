class_name CameraZone
extends Area3D
## A place with its own fixed, framed camera shot, like the galley. When the
## player walks in, their camera glides to [member shot]; when they walk out,
## it glides back to the free camera.
##
## Put it as a child of whatever it belongs to (the ship), so it moves with
## it. Give it a [CollisionShape3D] covering the room and a [Marker3D] child
## named [code]Shot[/code], placed and turned where the camera should be.
## The marker looks along its -Z axis, like a camera.

## Where the camera sits and which way it looks while the player is inside.
@onready var shot: Marker3D = $Shot


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


# Anything else that overlaps the zone (the ship's own body, a crate) is
# ignored: only the player's camera cares.
func _on_body_entered(body: Node3D) -> void:
	var player: Player3D = body as Player3D
	if player != null:
		player.camera_rig.enter_zone(self)


func _on_body_exited(body: Node3D) -> void:
	var player: Player3D = body as Player3D
	if player != null:
		player.camera_rig.leave_zone(self)
