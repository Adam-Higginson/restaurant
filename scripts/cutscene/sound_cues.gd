class_name SoundCues
extends CueHandler
## One-off sounds for a cutscene. [code]@sound splash[/code] plays the child
## of this node named for the cue ([code]Splash[/code], an
## [AudioStreamPlayer]) and carries straight on. To add a sound, add a
## player as a child and give it a recording.
##
## Nothing is played while a cutscene is being skipped.


func cues() -> Array[StringName]:
	return [&"sound"]


## The player for the sound called [param sound_name], or null.
func find_sound(sound_name: String) -> AudioStreamPlayer:
	for child: Node in get_children():
		if String(child.name).to_snake_case() == sound_name:
			return child as AudioStreamPlayer
	return null


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	var player: AudioStreamPlayer = find_sound(args[0])
	if player == null:
		warn("no sound called '%s' (an AudioStreamPlayer under %s)" % [args[0], name])
		return
	if not is_skipping():
		player.play()
