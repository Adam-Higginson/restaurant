class_name FirstQuest
extends Node
## The world's side of the first quest, warming the lantern (#158; the
## Prologue's version, #186). When the intro ends with him gone low, the
## captain goes up on deck to the helm and stays there: it's where you find
## him for the pot. Every so often, while the lantern's low, he says he could
## do with a drink, walks to the water butt, drinks, and walks back to the
## wheel. He's thirsty, not helping; but anyone on deck sees where the ship's
## water comes from. Once the lantern's well again the drinks stop: the first
## meal's cutscene (remedy.dlg) sends him back up to the wheel.
##
## The words of the quest are in the dialogue files; this only moves the
## captain (and gives him his few words about being thirsty).

## Emitted when the captain is back at the helm after a drink.
signal errand_done
## Emitted when he reaches the helm.
signal reached_helm

## Who keeps the helm and goes for the drink: a crewmate's [member Person.id].
@export var captain: StringName = &"heron"
## The mark by the water butt where he drinks, in the group [constant
## ActorCues.GROUP].
@export var butt_mark: StringName = &"WaterButt"
## The mark at the wheel where he stands, in the same group.
@export var helm_mark: StringName = &"Wheel"
## The conversation whose end sends him up to the helm.
@export var after: StringName = &"intro"
## How long he stands at the helm between drinks, in seconds.
@export var drink_every: float = 110.0
## How long he lingers at the butt after his drink, in seconds.
@export var linger_seconds: float = 4.0
## What he says as he sets off for a drink, one at random, overheard.
@export var thirsty_lines: PackedStringArray = PackedStringArray([
	"Thirsty work, this.", "Could do with a drink.", "Salt in everything. Need a drink."])
## His drinking animation (cupping water to his beak), by its name in his
## model's file. Without it he just stoops to the butt and back.
@export var drink_animation: StringName = &"Drink"
## What he says after his drink, one at random, in a speech bubble.
@export var drunk_lines: PackedStringArray = PackedStringArray([
	"Ahh. Nothing like rain.", "Sweetest water there is, rain.",
	"Storm's good for one thing, anyway."])
## How far he stoops to the butt when he has no drinking animation, in degrees.
@export var dip_degrees: float = 10.0

## Whether he's off for a drink: on his way there, drinking, or on his way
## back to the helm.
var is_on_errand: bool:
	get:
		return _on_errand

## Whether he's at the helm, keeping it.
var is_at_helm: bool:
	get:
		return _at_helm

## Whether he's on his way up to the helm.
var is_heading_to_helm: bool:
	get:
		return _heading

var _on_errand: bool = false
var _at_helm: bool = false
var _heading: bool = false
## Seconds he's stood at the helm since his last drink.
var _waited: float = 0.0


func _ready() -> void:
	# The conversation may be ready after us.
	_listen.call_deferred()


func _process(delta: float) -> void:
	if not _at_helm or _on_errand or not _is_low():
		return
	_waited += delta
	if _waited >= drink_every:
		start_errand()


## Sends the captain up to the helm. Returns whether he set off: not if he
## can't be found or has no way there.
func go_to_helm() -> bool:
	var crewmate: Crewmate = _find_captain()
	var mark: Marker3D = _find_mark(helm_mark)
	if crewmate == null or mark == null:
		return false
	var walker: CrewWalker = crewmate.get_node_or_null("Walker") as CrewWalker
	if walker == null or not walker.walk_to(mark):
		return false
	_at_helm = false
	_heading = true
	_climb(walker)
	return true


## Sends the captain for his drink and back to the helm. Returns whether he
## set off: not if he's already on his way, can't be found, or has no way
## there.
func start_errand() -> bool:
	if _on_errand:
		return false
	var crewmate: Crewmate = _find_captain()
	var mark: Marker3D = _find_mark(butt_mark)
	if crewmate == null or mark == null:
		return false
	var walker: CrewWalker = crewmate.get_node_or_null("Walker") as CrewWalker
	if walker == null or not walker.walk_to(mark):
		return false
	_on_errand = true
	_at_helm = false
	_waited = 0.0
	if not thirsty_lines.is_empty() and crewmate.head != null:
		crewmate.head.say(thirsty_lines[randi() % thirsty_lines.size()])
	_run(crewmate, walker)
	return true


func _climb(walker: CrewWalker) -> void:
	var arrived: Array[bool] = [false]
	var on_arrived: Callable = func() -> void: arrived[0] = true
	walker.arrived.connect(on_arrived, CONNECT_ONE_SHOT)
	await walker.walk_ended
	if walker.arrived.is_connected(on_arrived):
		walker.arrived.disconnect(on_arrived)
	_heading = false
	if arrived[0]:
		_at_helm = true
		_waited = 0.0
		reached_helm.emit()


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
	# Well again while he was drinking (the first meal called him away): he
	# doesn't go back up.
	var mark: Marker3D = _find_mark(helm_mark) if _is_low() else null
	if is_instance_valid(walker) and mark != null and walker.walk_to(mark):
		var back: Array[bool] = [false]
		var on_back: Callable = func() -> void: back[0] = true
		walker.arrived.connect(on_back, CONNECT_ONE_SHOT)
		await walker.walk_ended
		if walker.arrived.is_connected(on_back):
			walker.arrived.disconnect(on_back)
		_at_helm = back[0]
	_waited = 0.0
	_on_errand = false
	errand_done.emit()


# The drink (#207): he plays his drinking animation if his model has one
# ([member drink_animation]); without it he only stoops a little to the butt
# and straightens (no more tipping his whole body back). Then he says how
# good the rain is, in a speech bubble: a nudge, for anyone listening.
func _drink(crewmate: Crewmate) -> void:
	var seconds: float = 0.0
	for child: Node in crewmate.get_children():
		if child is CrewAnimator:
			seconds = (child as CrewAnimator).play_once(drink_animation)
	if seconds > 0.0:
		await get_tree().create_timer(seconds, false).timeout
	else:
		await _stoop(crewmate)
	if not drunk_lines.is_empty() and crewmate.head != null:
		crewmate.head.say(drunk_lines[randi() % drunk_lines.size()])


# Without a drinking animation: a small stoop to the butt and back.
func _stoop(crewmate: Crewmate) -> void:
	var model: Node3D = crewmate.get_node_or_null("Model") as Node3D
	if model == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(model, "rotation:x", -deg_to_rad(dip_degrees), 0.6) \
			.set_trans(Tween.TRANS_SINE)
	tween.tween_interval(1.2)
	tween.tween_property(model, "rotation:x", 0.0, 0.6).set_trans(Tween.TRANS_SINE)
	await tween.finished


func _listen() -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation != null:
		conversation.ended.connect(func(tree_id: StringName) -> void:
			if tree_id == after and _is_low():
				go_to_helm())
	# Well again: the quest's over, and he's no longer keeping the helm for it.
	Game.dialogue.flag_changed.connect(func(flag: StringName, value: int) -> void:
		if flag == LanternSpirit.LOW_FLAG and value == 0:
			_at_helm = false)
	# Moved to his place for the time of day while you slept: whatever he was
	# doing is over.
	var crewmate: Crewmate = _find_captain()
	if crewmate != null:
		var station: CrewStation = crewmate.get_node_or_null("Station") as CrewStation
		if station != null:
			station.moved.connect(func(_spot: Node3D) -> void:
				_at_helm = false
				_heading = false)


func _is_low() -> bool:
	return Game.dialogue.is_set(LanternSpirit.LOW_FLAG)


func _find_captain() -> Crewmate:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(Crewmate.GROUP):
		var crewmate: Crewmate = node as Crewmate
		if crewmate != null and crewmate.person != null and crewmate.person.id == captain:
			return crewmate
	return null


func _find_mark(mark_name: StringName) -> Marker3D:
	if not is_inside_tree():
		return null
	for node: Node in get_tree().get_nodes_in_group(ActorCues.GROUP):
		if node.name == mark_name:
			return node as Marker3D
	return null
