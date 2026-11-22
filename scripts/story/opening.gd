class_name Opening
extends Node
## How the game begins: black, a title ("Somewhere at sea"), and you wake in
## your bunk at night with the storm outside, the lantern by your shoulder
## saying his first words. Then the ship is yours to explore.
##
## Set [member skip] to start straight on deck instead (tests and tools do).

## Emitted when the opening's over and you can move.
signal finished

## Start straight away, with no opening.
@export var skip: bool = false
## The player who wakes.
@export var player: Player3D
## The ship they wake aboard.
@export var ship: Ship
## Where they wake, in the ship's space: by their bunk.
@export var wake_spot: Vector3 = Vector3(3.3, 1.05, 12.0)
## The title over black, for a new voyage.
@export var title: String = "Somewhere at sea"
## Whether to carry on a saved voyage, if there is one.
@export var load_save: bool = true
## How long the title holds before the fade, in seconds.
@export var title_seconds: float = 2.5

## Whether the opening is playing.
var is_playing: bool:
	get:
		return _playing

var _playing: bool = false

@onready var _fade: ScreenFade = $ScreenFade


func _ready() -> void:
	if skip or player == null or ship == null:
		return
	_playing = true
	# Black from the very first frame, before anything is seen.
	_fade.show()
	(_fade.get_node("%Black") as ColorRect).modulate.a = 1.0
	_play.call_deferred()


func _play() -> void:
	player.controls_enabled = false
	player.global_position = ship.to_global(wake_spot)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	# Look aft, over your shoulder: your bunk, the stove, the stern windows.
	player.camera_rig.yaw = ship.global_rotation.y + PI
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit != null:
		spirit.snap_to_player()
	var saved: Dictionary = SaveGame.read() if load_save else {}
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	var heading: String = title
	if not saved.is_empty():
		SaveGame.restore(saved, Game.memories, time, spirit, Game.dialogue)
		var morning: bool = time != null and time.is_morning()
		var day: int = saved.get("day", 1)
		heading = "Day %d. %s" % [day, "Morning" if morning else "Night"]
	await _fade.show_title(heading)
	await get_tree().create_timer(title_seconds).timeout
	await _fade.fade_in()
	player.controls_enabled = true
	_playing = false
	if spirit != null:
		# His first words, or a welcome back: see data/dialogue/moments.dlg.
		spirit.remark(&"woke" if saved.is_empty() else &"returned")
	finished.emit()
