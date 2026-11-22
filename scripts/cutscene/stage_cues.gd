class_name StageCues
extends CueHandler
## Brings a [Stage] up over the game and puts it away again.
## [code]@stage underwater[/code] shows the stage named for the cue (the
## node [code]Underwater[/code]), closing any other that's up;
## [code]@stage off[/code] closes whichever is up. A cutscene never leaves a
## stage up: when it ends (or is skipped to its end) they're all put away.


func cues() -> Array[StringName]:
	return [&"stage"]


## The stage called [param stage_name], or null.
func find_stage(stage_name: String) -> Stage:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(Stage.GROUP):
		if String(node.name).to_snake_case() == stage_name:
			return node as Stage
	return null


## The stage that's up now, or null.
func open_stage() -> Stage:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(Stage.GROUP):
		var stage: Stage = node as Stage
		if stage != null and stage.is_open:
			return stage
	return null


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	var wanted: Stage = null
	if args[0] != "off":
		wanted = find_stage(args[0])
		if wanted == null:
			warn("no stage called '%s' (a Stage in group '%s')" % [args[0], Stage.GROUP])
			return
	_close_all(wanted, is_skipping())
	if wanted != null:
		wanted.open(is_skipping())


func _on_ended(_tree_id: StringName) -> void:
	_close_all(null, true)


# Closes every stage that's up, except [param keep].
func _close_all(keep: Stage, at_once: bool) -> void:
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(Stage.GROUP):
		var stage: Stage = node as Stage
		if stage != null and stage != keep and stage.is_open:
			stage.close(at_once)
