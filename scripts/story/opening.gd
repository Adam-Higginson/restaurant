class_name Opening
extends Node
## How the game begins. A new voyage opens with a cutscene (the script
## [member cutscene], [code]data/dialogue/intro.dlg[/code]): black, a title,
## and you wake by your bunk at night with the storm outside, the lantern at
## your shoulder and the captain in the doorway. Then the ship is yours.
##
## Before a new voyage's cutscene, over the black, you're asked who you are
## (a boy or a girl: its [LookChoice] child). A saved voyage carries on
## instead, as whoever you were: its day as the title ("Day 3. Morning"), and
## the lantern welcomes you back.
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
## The cutscene a new voyage opens with: a file in data/dialogue.
@export var cutscene: StringName = &"intro"
## The section of the cutscene to begin at. Set it to a later section's
## name to open the game on that beat while you're tuning it.
@export var start_section: StringName = DialogueTree.START
## Whether to carry on a saved voyage, if there is one.
@export var load_save: bool = true
## Whether a new voyage asks who you are first. Off, you're whoever the game
## already says ([member GameState.look]).
@export var choose_look: bool = true
## How long a saved voyage's title holds before the fade, in seconds.
@export var title_seconds: float = 2.5

## Whether the opening is playing.
var is_playing: bool:
	get:
		return _playing

var _playing: bool = false

@onready var _fade: ScreenFade = $ScreenFade
@onready var _look_choice: LookChoice = get_node_or_null("LookChoice") as LookChoice


func _ready() -> void:
	if skip or player == null or ship == null:
		return
	_playing = true
	# Black from the very first frame, before anything is seen.
	_fade.cover_now()
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
	if saved.is_empty():
		await _choose_look()
		await _begin_voyage()
	else:
		await _carry_on(saved, spirit)
	player.controls_enabled = true
	_playing = false
	if not saved.is_empty() and spirit != null:
		# A welcome back: see data/dialogue/moments.dlg.
		spirit.remark(&"returned")
	finished.emit()


# A new voyage: who are you? Skipped without a choice screen to ask with.
func _choose_look() -> void:
	if not choose_look or _look_choice == null:
		return
	_look_choice.ask()
	var body: PlayerLook.Body = await _look_choice.chosen
	Game.set_look(body)


# A new voyage: the opening cutscene, from the section asked for.
func _begin_voyage() -> void:
	var conversation: Conversation = Conversation.find(self)
	# Starting part-way in, there's no title to fade in from: just look.
	if conversation != null and start_section != DialogueTree.START:
		_fade.uncover_now()
	if conversation == null or not conversation.play(cutscene, player, start_section):
		# Nothing to play it with (a bare test scene): just open your eyes.
		await _fade.fade_in()
		return
	if conversation.is_active():
		await conversation.ended


# A saved voyage: put everything back, and say which day it is.
func _carry_on(saved: Dictionary, spirit: LanternSpirit) -> void:
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	SaveGame.restore(saved, Game.memories, time, spirit, Game.dialogue)
	Game.set_look(SaveGame.look_of(saved))
	var morning: bool = time != null and time.is_morning()
	var day: int = saved.get("day", 1)
	await _fade.show_title("Day %d. %s" % [day, "Morning" if morning else "Night"])
	await get_tree().create_timer(title_seconds).timeout
	await _fade.fade_in()
