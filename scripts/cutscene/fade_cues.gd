class_name FadeCues
extends CueHandler
## Fades and title cards for cutscenes. [code]@fade out[/code] fades the
## screen to black and [code]@fade in[/code] back again ([code]@fade white[/code]
## fades it to white, for a whiteout; @fade out from there turns the white to
## black), each holding the
## script until it's done; a number after says how many seconds it takes
## ([code]@fade in 2.0[/code]). [code]@title Somewhere at sea[/code] shows
## those words over black, making the screen black first if it isn't.
##
## While a cutscene is skipped the screen is black, and afterwards it's
## left the way the script last asked for. A cutscene never ends on black:
## if a script forgets to fade in, the screen fades in when it's over.

## The fade it works: the black overlay and its title.
@export var fade: ScreenFade

## Whether the script last asked for a black screen.
var _black_wanted: bool = false


func cues() -> Array[StringName]:
	return [&"fade", &"title"]


func _perform(cue: StringName, args: PackedStringArray) -> void:
	if not is_instance_valid(fade):
		return
	if cue == &"title":
		_black_wanted = true
		if is_skipping():
			return
		var title_held: int = hold()
		fade.cover_now()
		await fade.show_title(" ".join(args))
		release(title_held)
		return
	var seconds: float = args[1].to_float() if args.size() > 1 else -1.0
	# White covers the screen as black does (and skipped, it's black).
	_black_wanted = args[0] != "in"
	if is_skipping():
		return
	var held: int = hold()
	match args[0]:
		"out":
			await fade.fade_out(seconds)
		"white":
			await fade.fade_to_white(seconds)
		_:
			await fade.fade_in(seconds)
	release(held)


func _on_skip_started() -> void:
	if is_instance_valid(fade):
		fade.cover_now()


func _on_skip_ended() -> void:
	# At the cutscene's end, _on_ended uncovers the screen instead.
	if not is_instance_valid(fade) or not conversation.is_active():
		return
	if not _black_wanted:
		fade.fade_in()


func _on_ended(_tree_id: StringName) -> void:
	_black_wanted = false
	if is_instance_valid(fade) and fade.visible:
		fade.fade_in()
