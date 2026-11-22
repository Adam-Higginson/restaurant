class_name ShotCues
extends CueHandler
## Camera work for conversations and cutscenes that ask for it. A script
## line [code]@shot stove_nook[/code] glides the camera to the shot of that
## name (from another shot it cuts, as a film would);
## [code]@shot stove_nook cut[/code] always cuts straight to it;
## [code]@shot free[/code], or the conversation ending, gives the camera
## back with a glide, and [code]@shot free cut[/code] with a cut. A
## conversation with no [code]@shot[/code] never moves the camera.
##
## A shot is a [Marker3D] placed where the camera should be, in the group
## [constant GROUP], named for the cue: the marker [code]StoveNook[/code]
## answers [code]@shot stove_nook[/code].

## The cue this listens for.
const CUE: StringName = &"shot"
## The word that gives the camera back.
const FREE: String = "free"
## The word after a shot's name that cuts to it instead of gliding.
const CUT: String = "cut"
## The group shot markers are in.
const GROUP: StringName = &"shots"

## The player whose camera it moves.
@export var player: Player3D


func cues() -> Array[StringName]:
	return [CUE]


## The shot marker called [param shot_name], or null.
func find_shot(shot_name: String) -> Marker3D:
	return find_marker(GROUP, shot_name)


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	if not is_instance_valid(player):
		return
	var cut: bool = args.size() > 1 and args[1] == CUT
	if args.is_empty() or args[0] == FREE:
		player.camera_rig.release_shot(cut)
		return
	var shot: Marker3D = find_shot(args[0])
	if shot == null:
		warn("no shot called '%s' (a Marker3D in group '%s')" % [args[0], GROUP])
		return
	player.camera_rig.hold_shot(shot, cut)


func _on_ended(_tree_id: StringName) -> void:
	if is_instance_valid(player):
		player.camera_rig.release_shot()
