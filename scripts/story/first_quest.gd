class_name FirstQuest
extends Node
## The world's side of the first quest, warming the lantern (#158). When the
## intro ends with him gone low, the captain, having sent you off, goes up on
## deck for a drink at the water butt and walks back down to his fire. He's
## thirsty, not helping; but anyone who follows him, or is on deck, sees where
## the ship's water comes from.
##
## The words of the quest (the captain's hints, the lantern's silence) are in
## the dialogue files; this only moves the captain.

## Emitted when the captain is back by his fire after his drink.
signal errand_done

## Who goes for the drink: a crewmate's [member Person.id].
@export var captain: StringName = &"heron"
## The mark by the water butt where he drinks, in the group [constant
## ActorCues.GROUP].
@export var butt_mark: StringName = &"WaterButt"
## The conversation whose end starts the errand.
@export var after: StringName = &"intro"
## How long he lingers at the butt after his drink, in seconds.
@export var linger_seconds: float = 4.0
## How far he bends to dip the ladle, and tips back to swallow, in degrees.
@export var dip_degrees: float = 18.0
@export var tip_degrees: float = 14.0

## Whether he's on his way there, drinking, or on his way back.
var is_on_errand: bool:
	get:
		return _on_errand

var _on_errand: bool = false


func _ready() -> void:
	# The conversation may be ready after us.
	_listen.call_deferred()


## Sends the captain for his drink and back. Returns whether he set off: not
## if he's already on his way, can't be found, or has no way there.
func start_errand() -> bool:
	if _on_errand:
		return false
	var crewmate: Crewmate = _find_captain()
	var mark: Marker3D = _find_mark()
	if crewmate == null or mark == null:
		return false
	var walker: CrewWalker = crewmate.get_node_or_null("Walker") as CrewWalker
	if walker == null or not walker.walk_to(mark):
		return false
	_on_errand = true
	_run(crewmate, walker)
	return true


func _run(crewmate: Crewmate, walker: CrewWalker) -> void:
	var arrived: Array[bool] = [false]
	var on_arrived: Callable = func() -> void: arrived[0] = true
	walker.arrived.connect(on_arrived, CONNECT_ONE_SHOT)
	await walker.walk_ended
	if not arrived[0] or not is_instance_valid(crewmate):
		# Stopped on the way (moved to his post while you slept): it's off.
		if walker.arrived.is_connected(on_arrived):
			walker.arrived.disconnect(on_arrived)
		_on_errand = false
		return
	await _drink(crewmate)
	await get_tree().create_timer(linger_seconds, false).timeout
	if is_instance_valid(walker):
		walker.walk_home()
		await walker.walk_ended
	_on_errand = false
	errand_done.emit()


# The drink: he bends to dip the ladle, straightens, then tips his head back
# to swallow, as herons do. His whole body leans: there's no drinking
# animation yet, so this stands in for one.
func _drink(crewmate: Crewmate) -> void:
	var model: Node3D = crewmate.get_node_or_null("Model") as Node3D
	if model == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(model, "rotation:x", -deg_to_rad(dip_degrees), 0.6) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.5)
	tween.tween_property(model, "rotation:x", deg_to_rad(tip_degrees), 0.7) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.9)
	tween.tween_property(model, "rotation:x", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tween.finished


func _listen() -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null:
		return
	conversation.ended.connect(func(tree_id: StringName) -> void:
		if tree_id == after and Game.dialogue.is_set(LanternSpirit.LOW_FLAG):
			start_errand())


func _find_captain() -> Crewmate:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(Crewmate.GROUP):
		var crewmate: Crewmate = node as Crewmate
		if crewmate != null and crewmate.person != null and crewmate.person.id == captain:
			return crewmate
	return null


func _find_mark() -> Marker3D:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(ActorCues.GROUP):
		if node.name == butt_mark:
			return node as Marker3D
	return null
