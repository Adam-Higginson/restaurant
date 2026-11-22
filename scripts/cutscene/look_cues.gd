class_name LookCues
extends CueHandler
## Directs the lantern spirit's face in a cutscene.
## [code]@look hook_lantern determined[/code] gives the lantern called
## [code]hook_lantern[/code] (its [member LanternFace.look_name]) that look.
## The word is one of [constant LanternFace.LOOK_WORDS] for his eyes
## (calm, surprised, determined, worried, pleading, effort, tired, asleep,
## pleased) or [constant LanternFace.GLASS_WORDS] for his glass (fogged,
## clear, streaked, dry, cracked, mended).
##
## While a cutscene directs a face, whoever usually decides its look leaves
## it alone. When the cutscene ends every face is given back.


func cues() -> Array[StringName]:
	return [&"look"]


## The face a script calls [param face_name], or null.
func find_face(face_name: String) -> LanternFace:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(LanternFace.GROUP):
		var face: LanternFace = node as LanternFace
		if face != null and face.look_name == face_name:
			return face
	return null


func _perform(_cue: StringName, args: PackedStringArray) -> void:
	var face: LanternFace = find_face(args[0])
	if face == null:
		warn("no lantern called '%s' (a LanternFace's Look Name)" % args[0])
		return
	if not face.direct(args[1]):
		warn("'%s' isn't a look" % args[1])
		return
	# Skipping, there's nobody to watch the change: just be there.
	if is_skipping():
		face.snap()


func _on_ended(_tree_id: StringName) -> void:
	if not is_inside_tree():
		return
	for node: Node in get_tree().get_nodes_in_group(LanternFace.GROUP):
		var face: LanternFace = node as LanternFace
		if face != null:
			face.release()
