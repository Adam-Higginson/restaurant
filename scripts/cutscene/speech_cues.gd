class_name SpeechCues
extends CueHandler
## Things said in a cutscene that don't wait for a button. They're shown
## in the same dialogue box as every other line, with the speaker's name,
## but the box puts itself away when the line's time is up.
##
## [code]@say lantern 2.0 Someone in the water![/code] has the lantern say
## it for two seconds and carries straight on, so the scene keeps moving
## under it; follow it with [code]@wait[/code] to give it room.
## [code]@say_in 3.5 lantern 2.0 Come on. Come on.[/code] does the same
## after a delay (here three and a half seconds), for words that should
## land while the script is waiting on something else, such as the
## player's hand.
##
## Anything still to come is dropped, and anything up is put away, the
## moment the player presses Interact, when the cutscene is skipped, and
## when it ends: nobody goes on pleading after they've been answered.

## Words waiting to be said: each is [seconds until, speaker, seconds
## shown, words].
var _waiting: Array[Array] = []
## How long the line that's up has left, in seconds. 0 when none is.
var _left: float = 0.0


func cues() -> Array[StringName]:
	return [&"say", &"say_in"]


func _physics_process(delta: float) -> void:
	if _left > 0.0:
		_left -= delta
		if _left <= 0.0 and is_instance_valid(conversation):
			conversation.end_aside()
	if _waiting.is_empty():
		return
	var still_waiting: Array[Array] = []
	for entry: Array in _waiting:
		var until: float = entry[0]
		until -= delta
		if until <= 0.0:
			var speaker: StringName = entry[1]
			var seconds: float = entry[2]
			var words: String = entry[3]
			_say(speaker, words, seconds)
		else:
			still_waiting.append([until, entry[1], entry[2], entry[3]])
	_waiting = still_waiting


## How many lines are still waiting for their moment.
func waiting_count() -> int:
	return _waiting.size()


## How long the line that's up has left, in seconds. 0 when none is.
func seconds_left() -> float:
	return maxf(_left, 0.0)


## Drops everything still to come and puts away what's being said.
func hush() -> void:
	_waiting.clear()
	_left = 0.0
	if is_instance_valid(conversation):
		conversation.end_aside()


func _perform(cue: StringName, args: PackedStringArray) -> void:
	if is_skipping():
		return
	if cue == &"say":
		_say(StringName(args[0]), " ".join(args.slice(2)), args[1].to_float())
		return
	_waiting.append([args[0].to_float(), StringName(args[1]), args[2].to_float(),
			" ".join(args.slice(3))])


func _on_pressed_while_held() -> void:
	hush()


func _on_skip_started() -> void:
	hush()


func _on_ended(_tree_id: StringName) -> void:
	hush()


func _say(speaker: StringName, words: String, seconds: float) -> void:
	if not is_instance_valid(conversation):
		return
	conversation.say_aside(speaker, words)
	_left = maxf(seconds, 0.0)
