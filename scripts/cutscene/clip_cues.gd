class_name ClipCues
extends CueHandler
## Plays movements shaped on Godot's animation timeline. A clip is an
## animation in any [AnimationPlayer] that's in the group [constant GROUP]:
## open its scene, select the AnimationPlayer, and the timeline at the
## bottom of the editor shows the clip, to scrub and reshape.
##
## [code]@play lantern_descends[/code] plays the clip of that name and holds
## the script until it ends. [code]@start drifting[/code] starts one and
## carries straight on, for a clip that loops under whatever comes next.
## Skipping a cutscene jumps each clip to its last frame, so everything it
## moves ends up where it should be.

## The group the AnimationPlayers with clips are in.
const GROUP: StringName = &"clips"


func cues() -> Array[StringName]:
	return [&"play", &"start"]


## The AnimationPlayer that has a clip called [param clip], or null.
func find_player(clip: StringName) -> AnimationPlayer:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var player: AnimationPlayer = node as AnimationPlayer
		if player != null and player.has_animation(clip):
			return player
	return null


func _perform(cue: StringName, args: PackedStringArray) -> void:
	var clip: StringName = StringName(args[0])
	var player: AnimationPlayer = find_player(clip)
	if player == null:
		warn("no clip called '%s' (an animation in an AnimationPlayer in group '%s')"
				% [clip, GROUP])
		return
	if is_skipping():
		_jump_to_end(player, clip)
		return
	player.play(clip)
	if cue == &"start":
		return
	var held: int = hold()
	while is_holding(held) and is_inside_tree() and is_instance_valid(player) \
			and player.is_playing() and player.current_animation == clip:
		await get_tree().physics_frame
	release(held)


func _on_skip_started() -> void:
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		var player: AnimationPlayer = node as AnimationPlayer
		if player != null and player.is_playing():
			_jump_to_end(player, StringName(player.current_animation))


# Puts everything [param clip] moves where it leaves it, without playing it.
func _jump_to_end(player: AnimationPlayer, clip: StringName) -> void:
	var animation: Animation = player.get_animation(clip)
	player.play(clip)
	# A looping clip has no end to jump to: it just stops where it starts.
	if animation.loop_mode == Animation.LOOP_NONE:
		player.seek(animation.length, true)
	else:
		player.seek(0.0, true)
	player.stop(true)
