class_name Opening
extends Node
## How the game begins: with a cutscene (the script [member cutscene],
## [code]data/dialogue/intro.dlg[/code]). It opens on the title over the
## dark sea, and waits for a button.
##
## A new voyage first asks who you are, a boy or a girl, over the black (its
## [LookChoice] child). Then it goes under: the rescue, and you wake by your
## bunk at night with the storm outside, the lantern across the room and the
## captain in the doorway. Then the ship is yours.
##
## A saved voyage carries on instead, as whoever you were: after the title,
## its day ("Day 3. Morning"), and the lantern welcomes you back. The script
## can tell which it is by asking [constant SAVED_FACT].
##
## Set [member skip] to start straight on deck instead (tests and tools do).

## Emitted when the opening's over and you can move.
signal finished

## What a script asks to know whether a saved voyage is being carried on:
## [code]? saved_voyage[/code].
const SAVED_FACT: StringName = &"saved_voyage"

## Start straight away, with no opening.
@export var skip: bool = false
## The player who wakes.
@export var player: Player3D
## The ship they wake aboard.
@export var ship: Ship
## Where they wake, in the ship's space: by their bunk.
@export var wake_spot: Vector3 = Vector3(3.3, 1.05, 12.0)
## The cutscene the game opens with: a file in data/dialogue.
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
	var carrying_on: bool = not saved.is_empty()
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	if carrying_on:
		# Before the title, so the sea behind it is as the voyage left it.
		SaveGame.restore(saved, Game.memories, time, spirit, Game.dialogue)
		Game.set_look(SaveGame.look_of(saved))
	else:
		await _choose_look()
	Game.dialogue.set_fact(SAVED_FACT, func() -> int: return 1 if carrying_on else 0)
	var played: bool = await _play_cutscene()
	if carrying_on:
		await _carry_on(saved, time, played)
	elif not played:
		# Nothing to play it with (a bare test scene): just open your eyes.
		await _fade.fade_in()
	player.controls_enabled = true
	_playing = false
	if carrying_on and spirit != null:
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


# Plays the opening cutscene from the section asked for, and waits for it
# to end. Returns whether there was anything to play it with.
func _play_cutscene() -> bool:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null:
		return false
	# Starting part-way in, there's no black to fade in from: just look.
	if start_section != DialogueTree.START:
		_fade.uncover_now()
	if not conversation.play(cutscene, player, start_section):
		return false
	if conversation.is_active():
		await conversation.ended
	return true


# A saved voyage: say which day it is, then open your eyes.
func _carry_on(saved: Dictionary, time: TimeOfDay, after_cutscene: bool) -> void:
	if after_cutscene:
		# The cutscene left the screen black, and as it ended the fade began
		# to clear it: let that start, then take the screen back.
		await get_tree().process_frame
	_fade.cover_now()
	var morning: bool = time != null and time.is_morning()
	var day: int = saved.get("day", 1)
	await _fade.show_title("Day %d. %s" % [day, "Morning" if morning else "Night"])
	await get_tree().create_timer(title_seconds).timeout
	await _fade.fade_in()
