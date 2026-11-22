class_name OptionalSound
extends AudioStreamPlayer
## A sound whose recording may not be there. Give it the path of a file and
## it plays that; if the file's missing (it hasn't been recorded yet, or it
## lives in assets/third_party/, which isn't in the repo, and this is a
## fresh clone or CI) it simply stays silent, and the game carries on.
##
## With [member loop] it plays round and round for as long as it's allowed
## to run: put one inside a [Stage] and it sounds only while the stage is up.

## The recording to play, if it's there.
@export_file("*.ogg", "*.wav") var recording: String = ""
## Whether it plays on a loop whenever it can run, rather than when asked.
@export var loop: bool = false


func _ready() -> void:
	load_recording()
	_follow(can_process())


func _notification(what: int) -> void:
	if what == NOTIFICATION_DISABLED:
		_follow(false)
	elif what == NOTIFICATION_ENABLED:
		_follow(true)


## Whether there's a recording to play.
func has_recording() -> bool:
	return stream != null


## Loads [member recording] if the file is there. Returns whether it is.
func load_recording() -> bool:
	if recording.is_empty() or not ResourceLoader.exists(recording):
		return has_recording()
	var loaded: AudioStream = load(recording) as AudioStream
	if loop and loaded is AudioStreamOggVorbis:
		(loaded as AudioStreamOggVorbis).loop = true
	elif loop and loaded is AudioStreamWAV:
		(loaded as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream = loaded
	return has_recording()


# A loop sounds while it's [param running], and holds its breath otherwise.
func _follow(running: bool) -> void:
	if not loop or not has_recording() or not is_inside_tree():
		return
	stream_paused = not running
	if running and not playing:
		play()
