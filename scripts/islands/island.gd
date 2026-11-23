class_name Island
extends Node3D
## An island scene's root. It does three small things.
##
## It smooths the edges of everything drawn while the island is showing.
## Antialiasing is a setting of the viewport (the surface the game is drawn
## on), normally set for the whole game in the project settings. The island
## sets it for itself when it comes in and puts it back when it leaves, so
## the rest of the game is drawn as before (#134 decides it game-wide).
## MSAA smooths the outlines of models, which is what an island is made of:
## fronds, blades of grass, rocks against the sky.
##
## It stands the player where the visit begins (on the ship's deck, looking
## at the island), and it puts them back there if they ever fall out of the
## world (over the ship's rail, say).

## How much to smooth edges while the island is showing.
@export var edge_smoothing: Viewport.MSAA = Viewport.MSAA_4X
## The player visiting.
@export var player: Player3D
## Where the visit begins: the player stands here, facing the way this node
## faces (its -Z).
@export var start: Node3D
## Fall below this height and you're put back at [member start].
@export var fall_below: float = -8.0

var _smoothing_before: Viewport.MSAA = Viewport.MSAA_DISABLED


func _enter_tree() -> void:
	var viewport: Viewport = get_viewport()
	_smoothing_before = viewport.msaa_3d
	viewport.msaa_3d = edge_smoothing


func _exit_tree() -> void:
	get_viewport().msaa_3d = _smoothing_before


func _ready() -> void:
	if player != null and start != null:
		stand_at(player, start)


func _physics_process(_delta: float) -> void:
	if player != null and start != null and player.global_position.y < fall_below:
		stand_at(player, start)


## Stands [param who] at [param spot] at once, still, facing the way the
## spot faces (its -Z), with the camera behind them and the lantern at their
## shoulder. A jump, not a walk: used for arriving somewhere.
static func stand_at(who: Player3D, spot: Node3D) -> void:
	who.global_position = spot.global_position
	who.velocity = Vector3.ZERO
	# Draw them there at once, rather than gliding over from where they were.
	who.reset_physics_interpolation()
	var ahead: Vector3 = -spot.global_basis.z
	ahead.y = 0.0
	if ahead.length() > 0.001:
		who.face_towards(who.global_position + ahead)
		who.camera_rig.look_along(ahead.normalized())
	var spirit: LanternSpirit = who.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit != null:
		spirit.snap_to_player()
