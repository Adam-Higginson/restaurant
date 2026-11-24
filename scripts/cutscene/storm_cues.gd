class_name StormCues
extends CueHandler
## The storm, on cue. [code]@muffle on[/code] makes the weather sound as it
## does from under the water, a dull rumble, and [code]@muffle off[/code]
## brings it back. [code]@hush on[/code] silences the weather altogether,
## for a held breath, and [code]@hush off[/code] lets it back in.
## [code]@lightning[/code] strikes now, so a flash can land on the moment a
## scene needs it. [code]@rain 0.25 6.0[/code] eases (or brings on) the rain
## to that much (0 dry, 1 a downpour) over so many seconds (#187); it stays
## so after the cutscene, until the time of day next changes.
##
## The sound is never left muffled or hushed: when a cutscene ends it's put
## back.

## The weather it works: its Ambience (the sound) and Lightning children.
@export var weather: Weather


func cues() -> Array[StringName]:
	return [&"muffle", &"hush", &"lightning", &"rain"]


func _perform(cue: StringName, args: PackedStringArray) -> void:
	if not is_instance_valid(weather):
		return
	if cue == &"muffle":
		_set_submerged(args[0] == "on")
		return
	if cue == &"hush":
		# Skipped, the silence is never heard.
		_set_hushed(args[0] == "on" and not is_skipping())
		return
	if cue == &"rain":
		var seconds: float = args[1].to_float() if args.size() > 1 else 0.0
		_rain_to(clampf(args[0].to_float(), 0.0, 1.0), 0.0 if is_skipping() else seconds)
		return
	var lightning: Lightning = weather.get_node_or_null("Lightning") as Lightning
	if lightning != null:
		lightning.strike()


func _on_ended(_tree_id: StringName) -> void:
	_set_submerged(false)
	_set_hushed(false)


func _on_skip_started() -> void:
	_set_hushed(false)


func _rain_to(amount: float, seconds: float) -> void:
	if seconds <= 0.0:
		weather.intensity = amount
		return
	create_tween().tween_property(weather, "intensity", amount, seconds) \
			.set_trans(Tween.TRANS_SINE)


func _set_submerged(submerged: bool) -> void:
	if not is_instance_valid(weather):
		return
	var ambience: Ambience = weather.get_node_or_null("Ambience") as Ambience
	if ambience != null:
		ambience.submerged = submerged


func _set_hushed(hushed: bool) -> void:
	if not is_instance_valid(weather):
		return
	var ambience: Ambience = weather.get_node_or_null("Ambience") as Ambience
	if ambience != null:
		ambience.hushed = hushed
