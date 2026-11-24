class_name TimeCues
extends CueHandler
## The sky, on cue (#197). [code]@clear 1.0 12.0[/code] clears the morning
## into a bright day (1) or back (0) over so many seconds: the [TimeOfDay]'s
## [member TimeOfDay.clear]. The script carries straight on while it turns,
## and skipping puts it there at once. It stays so after the cutscene.

var _tween: Tween = null


func cues() -> Array[StringName]:
	return [&"clear"]


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	var time: TimeOfDay = _time_of_day()
	if time == null:
		return
	var amount: float = clampf(args[0].to_float(), 0.0, 1.0)
	var seconds: float = args[1].to_float() if args.size() > 1 else 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if seconds <= 0.0 or is_skipping():
		time.clear = amount
		return
	_tween = create_tween()
	_tween.tween_property(time, "clear", amount, seconds).set_trans(Tween.TRANS_SINE)


func _on_skip_started() -> void:
	# Whatever was clearing gets there at once.
	if _tween != null and _tween.is_valid():
		_tween.custom_step(1000.0)


func _time_of_day() -> TimeOfDay:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
