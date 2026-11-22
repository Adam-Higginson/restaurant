class_name Opening
extends Node
## How the game begins: black, a title ("Somewhere at sea"), and you wake in
## your bunk at night with the storm outside, the lantern by your shoulder
## saying his first words. Then the ship is yours to explore.
##
## Set [member skip] to start straight on deck instead (tests and tools do).

## Emitted when the opening's over and you can move.
signal finished

## The lantern's first words, in order.
const FIRST_WORDS: PackedStringArray = [
	"There you are.",
	"You were in the water. I pulled. You held on. Good holding.",
	"I'll get you home. I know exactly where it is. Roughly.",
]

## Start straight away, with no opening.
@export var skip: bool = false
## The player who wakes.
@export var player: Player3D
## The ship they wake aboard.
@export var ship: Ship
## Where they wake, in the ship's space: by their bunk.
@export var wake_spot: Vector3 = Vector3(3.3, 1.05, 12.0)
## The title over black.
@export var title: String = "Somewhere at sea"
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
	await _fade.show_title(title)
	await get_tree().create_timer(title_seconds).timeout
	await _fade.fade_in()
	player.controls_enabled = true
	_playing = false
	if spirit != null:
		for line: String in FIRST_WORDS:
			spirit.say(line)
	finished.emit()
