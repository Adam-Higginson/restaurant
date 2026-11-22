class_name CueHandler
extends Node
## Acts on some of a script's cues (the lines that start with @, see
## [CueList]). This is the part every handler shares: finding the world's
## [Conversation], listening for cues, and making the script wait.
##
## To add a cue, extend this, say which cues you answer in [method cues],
## do the work in [method _perform], and put the node in the scene. A cue
## that takes time holds the script while it works:
##
## [codeblock]
## func _perform(_cue: StringName, args: PackedStringArray) -> void:
##     var held: int = hold()
##     await pause(args[0].to_float(), held)
##     release(held)
## [/codeblock]
##
## While a cutscene is being skipped [method hold] holds nothing and
## [method pause] returns at once, so the same code simply happens
## instantly. Anything that would be seen (a fade) should check
## [method is_skipping] and jump to its end instead.

## The conversation this listens to. Found when the scene starts.
var conversation: Conversation = null


func _ready() -> void:
	_listen()
	if conversation == null:
		# It may join the scene after us.
		_listen.call_deferred()


## The cues this answers, without the @: [code][&"fade", &"title"][/code].
func cues() -> Array[StringName]:
	return []


## Acts on [param cue] if it's one of ours (see [method cues]).
func handle(cue: StringName, args: PackedStringArray) -> void:
	if cues().has(cue):
		_perform(cue, args)


## Makes the script wait for this handler. Give the number it returns to
## [method release] when the work's done. See [method Conversation.hold].
func hold() -> int:
	if not is_instance_valid(conversation):
		return -1
	return conversation.hold(self)


## Lets the script carry on. See [method Conversation.release].
func release(held: int) -> void:
	if is_instance_valid(conversation):
		conversation.release(held)


## Whether the hold numbered [param held] is still open. False once the
## cutscene has been skipped or stopped, when any waiting should end.
func is_holding(held: int) -> bool:
	return is_instance_valid(conversation) and conversation.is_holding(held)


## Whether a cutscene is being skipped: do the cue's work at once.
func is_skipping() -> bool:
	return is_instance_valid(conversation) and conversation.is_skipping()


## Waits [param seconds] of game time, or until the hold numbered
## [param held] is gone (skipped or stopped), whichever is first. Counted
## in physics ticks, so it's the same on any machine.
func pause(seconds: float, held: int) -> void:
	var left: float = seconds
	while left > 0.0 and is_holding(held) and is_inside_tree():
		await get_tree().physics_frame
		left -= get_physics_process_delta_time()


## The [Marker3D] in [param group] named for [param marker_name]: the
## marker [code]StoveNook[/code] answers [code]stove_nook[/code]. Null if
## there isn't one.
func find_marker(group: StringName, marker_name: String) -> Marker3D:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(group):
		if String(node.name).to_snake_case() == marker_name:
			return node as Marker3D
	return null


## Warns about a cue that can't be acted on, saying where in the script it is.
func warn(message: String) -> void:
	var where: String = "a cue"
	if is_instance_valid(conversation) and conversation.is_active():
		where = conversation.where()
	push_warning("%s: %s" % [where, message])


## Does the work of [param cue], one of [method cues]. Override this.
func _perform(_cue: StringName, _args: PackedStringArray) -> void:
	pass


## Called when a conversation or cutscene ends. Override to tidy up.
func _on_ended(_tree_id: StringName) -> void:
	pass


## Called when a cutscene starts being skipped. Override to jump to the end
## of anything half done.
func _on_skip_started() -> void:
	pass


## Called when the skipping is over. Override to show the scene again.
func _on_skip_ended() -> void:
	pass


## Called when Interact is pressed while a cue is holding the script.
func _on_pressed_while_held() -> void:
	pass


func _listen() -> void:
	if conversation != null:
		return
	conversation = Conversation.find(self)
	if conversation == null:
		return
	conversation.cue.connect(handle)
	conversation.ended.connect(_on_ended)
	conversation.skip_started.connect(_on_skip_started)
	conversation.skip_ended.connect(_on_skip_ended)
	conversation.pressed_while_held.connect(_on_pressed_while_held)
