class_name ActorCues
extends CueHandler
## Puts people where a cutscene needs them. Placing, hiding and sending home
## happen at once: do them while the camera is looking elsewhere. The crew
## can walk somewhere while you watch ([code]@walk[/code], [code]@send[/code],
## #157), and the lantern can float ([code]@go[/code]).
##
## [codeblock]
## @place heron doorway     stand them on the mark called Doorway
## @face heron player       turn them towards someone, or towards a mark
## @hide heron              take them out of the scene
## @show heron              bring them back
## @home heron              send them back to their usual spot
## @go lantern room_middle  the lantern floats over to a mark, and stays
## @walk heron water_butt   they walk there along the walkways; the script
##                          waits until they arrive
## @send heron water_butt   they set off walking there; the script goes on
## @walk heron home         walk back to their usual spot (@send too)
## [/codeblock]
##
## Someone is named by their [member Person.id] ([code]heron[/code]),
## [code]player[/code], or [code]lantern[/code] (the lantern spirit: placed on
## a mark he stays there, over following you, until [code]@home lantern[/code]).
## Hiding the player hides only their body, not him. A thing can be moved,
## hidden and shown too: a prop
## is any [Node3D] in the group [constant PROPS], named for the cue
## ([code]ReachingBoathook[/code] answers [code]reaching_boathook[/code]).
## A mark is a [Marker3D] in the group
## [constant GROUP], named for the cue: [code]Doorway[/code] answers
## [code]doorway[/code]. They stand on the mark facing the way its blue
## arrow (its -Z) points.

## The group marks are in.
const GROUP: StringName = &"marks"
## The group props are in: things a cutscene can show, hide and place.
const PROPS: StringName = &"props"
## The name for the player in a script.
const PLAYER: String = "player"
## The name for the lantern spirit in a script.
const LANTERN: String = "lantern"
## The place name for someone's usual spot, in [code]@walk[/code] and
## [code]@send[/code].
const HOME: String = "home"

## The player, for [code]@place player ...[/code] and [code]@face ... player[/code].
@export var player: Player3D

## Walks a cue started that are still under way: each walker, and the mark
## it's walking to. Skipping finishes them at once.
var _walks: Dictionary[CrewWalker, Node3D] = {}


func cues() -> Array[StringName]:
	return [&"place", &"face", &"hide", &"show", &"home", &"go", &"walk", &"send"]


## Whoever (or whatever) is called [param who] in a script, or null: the
## player, the crewmate with that [member Person.id], or the prop of that name.
func find_actor(who: String) -> Node3D:
	if who == PLAYER:
		return player if is_instance_valid(player) else null
	if who == LANTERN:
		return player.get_node_or_null("LanternSpirit") as LanternSpirit \
				if is_instance_valid(player) else null
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(Crewmate.GROUP):
		var crewmate: Crewmate = node as Crewmate
		if crewmate != null and crewmate.person != null and String(crewmate.person.id) == who:
			return crewmate
	for node: Node in get_tree().get_nodes_in_group(PROPS):
		if String(node.name).to_snake_case() == who:
			return node as Node3D
	return null


## The mark called [param mark_name], or null.
func find_mark(mark_name: String) -> Marker3D:
	return find_marker(GROUP, mark_name)


func _perform(cue: StringName, args: PackedStringArray) -> void:
	var actor: Node3D = find_actor(args[0])
	if actor == null:
		warn("nobody and nothing is called '%s' (a crewmate's Person id, 'player', or a "
				% args[0] + "prop in group '%s')" % PROPS)
		return
	match cue:
		&"place":
			_place(actor, args[1])
		&"face":
			_face(actor, args[1])
		&"hide":
			_set_present(actor, false)
		&"show":
			_set_present(actor, true)
		&"home":
			_send_home(actor)
		&"go":
			_go(actor, args[1])
		&"walk", &"send":
			_walk(actor, args[1], cue == &"walk")


func _place(actor: Node3D, mark_name: String) -> void:
	var mark: Marker3D = find_mark(mark_name)
	if mark == null:
		warn("no mark called '%s' (a Marker3D in group '%s')" % [mark_name, GROUP])
		return
	var ahead: Vector3 = mark.global_position - mark.global_basis.z
	if actor is LanternSpirit:
		(actor as LanternSpirit).hold_at(mark, true)
	elif actor is Player3D:
		var body: Player3D = actor as Player3D
		body.global_position = mark.global_position
		body.velocity = Vector3.ZERO
		body.face_towards(ahead)
	else:
		# Put somewhere, they stop wherever they were walking to.
		var walker: CrewWalker = actor.get_node_or_null("Walker") as CrewWalker
		if walker != null:
			walker.stop()
		actor.global_transform = mark.global_transform
		if actor is Crewmate:
			(actor as Crewmate).rest()
	# A jump, not a move: draw them there at once rather than gliding over.
	actor.reset_physics_interpolation()


func _face(actor: Node3D, target: String) -> void:
	var point: Vector3
	var mark: Marker3D = find_mark(target)
	var other: Node3D = find_actor(target)
	if mark != null:
		point = mark.global_position
	elif other != null:
		point = other.global_position
	else:
		warn("nothing to face called '%s' (a mark, a crewmate or 'player')" % target)
		return
	if actor is Player3D:
		(actor as Player3D).face_towards(point)
	elif actor is Crewmate:
		(actor as Crewmate).face_towards(point)
	elif actor is LanternSpirit:
		(actor as LanternSpirit).face_actor(mark if mark != null else other)


# Whatever a cutscene did to the player and the lantern doesn't outlast it:
# your body shows, and he goes back to his usual place.
func _on_ended(_tree_id: StringName) -> void:
	if not is_instance_valid(player):
		return
	_set_present(player, true)
	var spirit: LanternSpirit = find_actor(LANTERN) as LanternSpirit
	if spirit != null:
		spirit.face_actor(null)
		if spirit.held != null:
			spirit.let_go()


# Skipping: whoever is still walking somewhere is there at once.
func _on_skip_started() -> void:
	for walker: CrewWalker in _walks.keys():
		var mark: Node3D = _walks[walker]
		var actor: Node3D = walker.get_parent() as Node3D
		walker.stop()
		if is_instance_valid(mark) and actor != null:
			actor.global_transform = mark.global_transform
			actor.reset_physics_interpolation()
	_walks.clear()


# Floats the lantern over to the mark called [param mark_name], to stay.
func _go(actor: Node3D, mark_name: String) -> void:
	var spirit: LanternSpirit = actor as LanternSpirit
	if spirit == null:
		warn("only the lantern can float somewhere ('@go lantern <mark>'); "
				+ "'@place' moves anyone else at once")
		return
	var mark: Marker3D = find_mark(mark_name)
	if mark == null:
		warn("no mark called '%s' (a Marker3D in group '%s')" % [mark_name, GROUP])
		return
	spirit.hold_at(mark)


# Walks [param actor] to the mark called [param place_name] (or home), the
# script waiting until they're there if [param wait]. Skipping, they're simply
# put there.
func _walk(actor: Node3D, place_name: String, wait: bool) -> void:
	var walker: CrewWalker = actor.get_node_or_null("Walker") as CrewWalker
	if walker == null:
		warn("'%s' can't walk (only crew with a CrewWalker called Walker can)" % actor.name)
		return
	var mark: Node3D = null
	if place_name == HOME:
		for child: Node in actor.get_children():
			if child is CrewStation:
				mark = (child as CrewStation).post()
	else:
		mark = find_mark(place_name)
	if mark == null:
		warn("nowhere called '%s' to walk to (a Marker3D in group '%s', or 'home')"
				% [place_name, GROUP])
		return
	if is_skipping():
		walker.stop()
		actor.global_transform = mark.global_transform
		actor.reset_physics_interpolation()
		return
	if not walker.walk_to(mark):
		warn("no way for '%s' to '%s' along the walkways" % [actor.name, place_name])
		return
	_walks[walker] = mark
	walker.walk_ended.connect(func() -> void: _walks.erase(walker), CONNECT_ONE_SHOT)
	if wait:
		var held: int = hold()
		walker.walk_ended.connect(func() -> void: release(held), CONNECT_ONE_SHOT)


func _set_present(actor: Node3D, present: bool) -> void:
	if actor is Player3D:
		# Just their body: the lantern is the player's too, and stays.
		var body: Node3D = actor.get_node_or_null("Model") as Node3D
		if body != null:
			body.visible = present
		return
	if actor is Crewmate:
		(actor as Crewmate).set_present(present)
	else:
		actor.visible = present


func _send_home(actor: Node3D) -> void:
	if actor is LanternSpirit:
		(actor as LanternSpirit).let_go()
		return
	_set_present(actor, true)
	if actor is Crewmate:
		(actor as Crewmate).rest()
	for child: Node in actor.get_children():
		if child is CrewStation:
			(child as CrewStation).return_to_post()
			return
	warn("'%s' has no usual spot to go home to (a CrewStation)" % actor.name)
