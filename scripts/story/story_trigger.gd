class_name StoryTrigger
extends Area3D
## A place that starts a cutscene when you walk into it, once, when the story
## is ready for it (#187): the deck talk as you first come up on deck after
## the lantern's soup.
##
## It plays [member cutscene] when the player enters, if [member requires] is
## set (or empty) and [member done] isn't. The cutscene's script should set
## [member done] itself; the trigger sets it too, so it never plays twice.

## The cutscene to play: a file in [code]data/dialogue[/code].
@export var cutscene: StringName = &""
## The flag that must be set before it plays. Empty plays it any time.
@export var requires: StringName = &""
## The flag set once it's played, so it never plays again.
@export var done: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Whether walking in now would play it.
func is_ready_to_play() -> bool:
	if cutscene == &"":
		return false
	if requires != &"" and not Game.dialogue.is_set(requires):
		return false
	return done == &"" or not Game.dialogue.is_set(done)


## Plays it for [param player], if the story's ready. Returns whether it
## started.
func play_for(player: Player3D) -> bool:
	if not is_ready_to_play():
		return false
	var conversation: Conversation = Conversation.find(self)
	if conversation == null or conversation.is_active():
		return false
	if not conversation.play(cutscene, player):
		return false
	if done != &"":
		Game.dialogue.set_flag(done)
	return true


func _on_body_entered(body: Node3D) -> void:
	var player: Player3D = body as Player3D
	if player != null:
		play_for(player)
