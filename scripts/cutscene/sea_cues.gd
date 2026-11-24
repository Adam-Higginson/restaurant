class_name SeaCues
extends CueHandler
## The sea, on cue. [code]@grave on[/code] brings up the Grave of the
## Lanterns under the open sea: a few faint lights far below the surface,
## fading in over [member fade_seconds] (see [member Sea.grave]).
## [code]@grave off[/code] lets them fade away again. The script carries on
## while they fade.
##
## [code]@leaping_fish on[/code] sets the [LeapingFish] leaping alongside the
## ship, and [code]@leaping_fish off[/code] lets the ones in the air land and
## no more leap (#197).
##
## The sea is never left showing them: when a cutscene ends, the lights are
## gone and the fish stop.

## The sea it works.
@export var sea: Sea
## How long the lights take to come up or fade away, in seconds.
@export var fade_seconds: float = 2.5

var _tween: Tween = null


func cues() -> Array[StringName]:
	return [&"grave", &"leaping_fish"]


func _perform(cue: StringName, args: PackedStringArray) -> void:
	if cue == &"leaping_fish":
		_set_fish(args[0] == "on")
		return
	_fade_to(1.0 if args[0] == "on" else 0.0, is_skipping())


func _on_ended(_tree_id: StringName) -> void:
	_fade_to(0.0, true)
	_set_fish(false)


func _set_fish(on: bool) -> void:
	if is_inside_tree():
		get_tree().call_group(LeapingFish.GROUP, &"set_leaping", on)


func _on_skip_started() -> void:
	# Whatever was fading gets where it was going at once.
	if _tween != null and _tween.is_valid():
		_tween.custom_step(fade_seconds)


func _fade_to(amount: float, at_once: bool) -> void:
	if not is_instance_valid(sea):
		return
	if _tween != null:
		_tween.kill()
		_tween = null
	if at_once or fade_seconds <= 0.0:
		sea.grave = amount
		return
	_tween = create_tween()
	_tween.tween_property(sea, "grave", amount, fade_seconds)
