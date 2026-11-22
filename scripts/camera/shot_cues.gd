class_name ShotCues
extends Node
## Camera work for conversations that ask for it. A script line
## [code]@shot stove_nook[/code] glides the camera to the shot of that name;
## [code]@shot free[/code], or the conversation ending, gives it back. A
## conversation with no [code]@shot[/code] never moves the camera.
##
## A shot is a [Marker3D] placed where the camera should be, in the group
## [constant GROUP], named for the cue: the marker [code]StoveNook[/code]
## answers [code]@shot stove_nook[/code].

## The cue this listens for.
const CUE: StringName = &"shot"
## The word that gives the camera back.
const FREE: String = "free"
## The group shot markers are in.
const GROUP: StringName = &"shots"

## The player whose camera it moves.
@export var player: Player3D


func _ready() -> void:
	# The conversation may be ready after us.
	_listen.call_deferred()


## The shot marker called [param shot_name], or null.
func find_shot(shot_name: String) -> Marker3D:
	for node: Node in get_tree().get_nodes_in_group(GROUP):
		if String(node.name).to_snake_case() == shot_name:
			return node as Marker3D
	return null


## Acts on a cue from a script: only [constant CUE] means anything here.
func handle(cue: StringName, args: PackedStringArray) -> void:
	if cue != CUE or not is_instance_valid(player):
		return
	if args.is_empty() or args[0] == FREE:
		player.camera_rig.release_shot()
		return
	var shot: Marker3D = find_shot(args[0])
	if shot == null:
		push_warning("ShotCues: no shot called '%s' (a Marker3D in group '%s')" % [args[0], GROUP])
		return
	player.camera_rig.hold_shot(shot)


func _listen() -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null:
		return
	conversation.cue.connect(handle)
	conversation.ended.connect(func(_tree_id: StringName) -> void:
		if is_instance_valid(player):
			player.camera_rig.release_shot())
