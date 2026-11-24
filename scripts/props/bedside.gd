class_name Bedside
extends Node3D
## Your bunk, as something to do: Interact to sleep. The screen fades to
## black, the night passes (or the day), a title says so, and you wake to the
## other: a misty dawn after the storm, or night again. The [TimeOfDay] does
## the changing; this is the going to sleep.
##
## Once the captain has sent you to bed after the deck talk (the flag
## [constant BOUND_FLAG], #187), sleeping sails on through the night instead:
## the screen goes dark, it's morning, and [member voyage_scene] plays, the
## passage out of the strange waters that ends at the island.

## Not while the lantern's low (#207): the first quest, warming him, comes
## before any sleep, so the bunk offers nothing until he's had his soup.

## Emitted after you wake, with whether it's morning now.
signal woke(morning: bool)
## Emitted when you sleep and the voyage to the island begins.
signal voyage_began

## Set by the deck talk: you've been sent to bed, and the island's next.
const BOUND_FLAG: StringName = &"deck_talk"
## Set once you've reached the island: the voyage is behind you.
const ARRIVED_FLAG: StringName = &"at_cove"

## How long you're asleep, with the screen black, in seconds.
@export var sleep_seconds: float = 1.4
## The cutscene that plays when you sleep on the way to the island: a file
## in [code]data/dialogue[/code].
@export var voyage_scene: StringName = &"voyage"

## Whether you're asleep right now.
var is_sleeping: bool:
	get:
		return _sleeping

var _sleeping: bool = false

@onready var _reach: Interactable3D = $Reach
@onready var _fade: ScreenFade = $ScreenFade


func _ready() -> void:
	_reach.interacted.connect(sleep)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


## What Interact would do now, for the HUD.
func prompt() -> String:
	if _sleeping or not can_sleep():
		return ""
	if is_bound_for_land():
		return "Sleep until we make land"
	var time: TimeOfDay = _time_of_day()
	if time != null and time.is_morning():
		return "Rest until nightfall"
	return "Sleep until morning"


## Whether you can sleep now: not while the lantern's low, before his soup.
func can_sleep() -> bool:
	return not Game.dialogue.is_set(LanternSpirit.LOW_FLAG)


## Whether sleeping now sails on to the island: after the deck talk, before
## arriving.
func is_bound_for_land() -> bool:
	return Game.dialogue.is_set(BOUND_FLAG) and not Game.dialogue.is_set(ARRIVED_FLAG)


## Sleeps, moving the time on, while [param player] can't move.
func sleep(player: Player3D) -> void:
	if _sleeping or not can_sleep():
		return
	if is_bound_for_land():
		_sail_on(player)
		return
	_sleeping = true
	player.controls_enabled = false
	await _fade.fade_out()
	var time: TimeOfDay = _time_of_day()
	var morning: bool = time == null or not time.is_morning()
	if time != null:
		time.dawn = 1.0 if morning else 0.0
	var title: String = "Night"
	if morning:
		title = "Day %d. Morning" % time.day if time != null else "Morning"
	await _fade.show_title(title)
	await get_tree().create_timer(sleep_seconds).timeout
	await _fade.fade_in()
	player.controls_enabled = true
	_sleeping = false
	if morning:
		var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
		if spirit != null:
			spirit.snap_to_player()
			spirit.tell(&"morning")
	_save(player)
	woke.emit(morning)


# The night passes in the dark, and the voyage cutscene takes over: it's
# morning, the strange waters are behind, and the island's ahead. With
# nothing to play it in, you simply wake to the morning.
func _sail_on(player: Player3D) -> void:
	_sleeping = true
	player.controls_enabled = false
	await _fade.fade_out()
	var time: TimeOfDay = _time_of_day()
	if time != null:
		time.dawn = 1.0
	voyage_began.emit()
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and conversation.play(voyage_scene, player):
		# The cutscene opens in its own black (@fade out 0.0): hand over to it.
		await get_tree().process_frame
		_fade.uncover_now()
		if conversation.is_active():
			await conversation.ended
	else:
		await _fade.fade_in()
	if is_instance_valid(player):
		player.controls_enabled = true
	_sleeping = false


# Sleeping is where the voyage is kept: save it on waking.
func _save(player: Player3D) -> void:
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	var warmth: float = spirit.warmth if spirit != null else 1.0
	SaveGame.write(SaveGame.capture(_time_of_day(), warmth, Game.dialogue,
			Game.look))


func _time_of_day() -> TimeOfDay:
	return get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
