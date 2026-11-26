class_name SupperTable
extends Node3D
## A place set at the galley's long table for supper (#207). Holding a bowl
## or plate with a dish in it, Use sets it down here; Interact picks it back
## up. Then ring the galley bell ([DinnerBell]) and whoever you've cooked for
## comes to eat.
##
## For now that's the lantern. He drifts over from his table, eats, and the
## bowl is left empty for you to clear:
## - Well, any dish warms him: more for a better one.
## - Low (the first quest, #158), only the old book's remedy will do: set
##   down, it plays [member remedy_scene], the first meal, which clears his
##   low flag. Anything else he eats sadly, and [member hint_scene] has him
##   hint that he needs something warmer.

## Emitted when a dish is eaten, with the dish and how much it warmed him.
signal shared(dish: ItemInstance, warmth: float)
## Emitted when the remedy has brought him back from being low.
signal mended

## The group the table is in, so the bell can find it.
const GROUP: StringName = &"supper_tables"

## How much a ★ dish warms him; each star more adds [member per_star].
@export var base_warmth: float = 0.25
@export var per_star: float = 0.15
## How long he eats for, in seconds, before the bowl is empty.
@export var eat_seconds: float = 2.5
## The dish that brings him back when he's low: the old book's remedy.
@export var remedy: Item
## The cutscene the remedy plays: a file in [code]data/dialogue[/code]. It
## clears his low flag.
@export var remedy_scene: StringName = &"remedy"
## The cutscene of him eating something else while he's low, hinting at
## what he needs.
@export var hint_scene: StringName = &"supper_hint"

## The bowl or plate set here, with its dish, or null.
var place: ItemInstance:
	get:
		return _place

var _place: ItemInstance = null
## Whether the dish here is being eaten.
var _eating: bool = false

@onready var _reach: Interactable3D = $Reach
@onready var _plate_spot: Node3D = $PlateSpot


func _ready() -> void:
	add_to_group(GROUP)
	_reach.used.connect(func(player: Player3D) -> void: set_down(player.arms))
	_reach.interacted.connect(func(player: Player3D) -> void: pick_up(player.arms))
	_reach.describe_use = func(player: Player3D) -> String: return use_prompt(player.arms)
	_reach.describe_interact = func(player: Player3D) -> String:
		return interact_prompt(player.arms)
	Game.dialogue.flag_changed.connect(_on_flag_changed)


## The dish in [param vessel], if it's a plate or bowl with food, or null.
static func dish_of(vessel: ItemInstance) -> ItemInstance:
	if vessel == null or not vessel.is_vessel() or not vessel.item.carried_whole:
		return null
	var food: Array[ItemInstance] = vessel.contents.get_contents()
	return null if food.is_empty() else food[0]


## The dish set here, or null (an empty bowl, or nothing).
func dish() -> ItemInstance:
	return dish_of(_place)


## Whether [param arms] hold a dish that could be set down here.
func can_set_down(arms: Arms) -> bool:
	return _place == null and dish_of(arms.top()) != null


## Sets the held bowl or plate down here. Returns whether it did.
func set_down(arms: Arms) -> bool:
	if not can_set_down(arms):
		return false
	_place = arms.take_top()
	_show()
	return true


## Picks up what's here, bowl and all. Returns whether it did.
func pick_up(arms: Arms) -> bool:
	if _place == null or _eating or arms.is_full():
		return false
	arms.add(_place)
	_place = null
	_show()
	return true


## The Use prompt: "Set Tomato Soup on the table", or "".
func use_prompt(arms: Arms) -> String:
	if not can_set_down(arms):
		return ""
	return "Set %s on the table" % dish_of(arms.top()).item.display_name


## The Interact prompt: "Pick up Bowl", or "".
func interact_prompt(arms: Arms) -> String:
	if _place == null or _eating or arms.is_full():
		return ""
	return "Pick up %s" % _place.item.display_name


## How much [param food] warms him.
func warmth_of(food: ItemInstance) -> float:
	return base_warmth + per_star * float(food.quality - 1)


## The bell's rung: whoever is fed comes to eat what's here. Returns whether
## anyone came to eat (not with nothing on the table, or while eating).
func call_to_supper(player: Player3D) -> bool:
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	var food: ItemInstance = dish()
	if food == null or _eating:
		if spirit != null and food == null:
			spirit.remark(&"table_bare")
		return false
	var amount: float = warmth_of(food)
	if _is_low():
		if remedy != null and food.item.id == remedy.id:
			_mend(player, spirit, food, amount)
		else:
			_eat_sadly(player, spirit, food)
		return true
	_eating = true
	_invite_captain()
	if spirit != null:
		spirit.visit(_plate_spot, eat_seconds)
		spirit.rekindle(amount)
		spirit.remark(&"supper")
		spirit.hum()
	shared.emit(food, amount)
	_finish_eating.call_deferred(food, eat_seconds)
	return true


# Everyday supper keeps control with the player as the captain walks over.
func _invite_captain() -> void:
	var seat: Marker3D = null
	for node: Node in get_tree().get_nodes_in_group(ActorCues.GROUP):
		if node.name == &"CaptainSupperSeat" and node is Marker3D:
			seat = node as Marker3D
			break
	if seat == null:
		return
	for node: Node in get_tree().get_nodes_in_group(Crewmate.GROUP):
		var crew: Crewmate = node as Crewmate
		if crew != null and crew.person != null and crew.person.id == &"heron":
			var walker: CrewWalker = crew.get_node_or_null("Walker") as CrewWalker
			if walker != null and walker.walk_to(seat):
				await walker.walk_ended
				await get_tree().create_timer(eat_seconds).timeout
				if is_instance_valid(walker):
					walker.walk_home()
			return


## Where the dish sits on the table.
func plate_spot() -> Node3D:
	return _plate_spot


# The remedy: the first meal's cutscene plays, which takes him to the bowl
# and clears his low flag; the bowl empties as he's well again.
func _mend(player: Player3D, spirit: LanternSpirit, food: ItemInstance, amount: float) -> void:
	_eating = true
	if spirit != null:
		spirit.rekindle_when_well(amount)
	shared.emit(food, amount)
	var conversation: Conversation = Conversation.find(self)
	var played: bool = conversation != null and conversation.play(remedy_scene, player)
	if not played:
		Game.dialogue.clear(LanternSpirit.LOW_FLAG)
	mended.emit()


# Anything but the remedy while he's low: he eats it, but sadly, and hints
# he needs something warmer.
func _eat_sadly(player: Player3D, spirit: LanternSpirit, food: ItemInstance) -> void:
	_eating = true
	shared.emit(food, 0.0)
	var plain: bool = food.item.id == &"tomato_soup"
	if plain:
		Game.dialogue.set_flag(&"served_plain_soup")
		Game.dialogue.set_flag(&"supper_plain_soup")
	var conversation: Conversation = Conversation.find(self)
	var played: bool = conversation != null and conversation.play(hint_scene, player)
	if not played and spirit != null:
		spirit.visit(_plate_spot, eat_seconds)
	if plain:
		if played:
			await conversation.ended
		else:
			await get_tree().create_timer(eat_seconds).timeout
		Game.dialogue.clear(&"supper_plain_soup")
		_eating = false
		return
	_finish_eating.call_deferred(food, eat_seconds)


# After [param seconds], [param food] is gone and the bowl is left empty.
func _finish_eating(food: ItemInstance, seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	_clear(food)


func _clear(food: ItemInstance) -> void:
	_eating = false
	if _place != null and food in _place.contents.get_contents():
		_place.contents.remove_item(food)
	_show()


func _is_low() -> bool:
	return Game.dialogue.is_set(LanternSpirit.LOW_FLAG)


# Shows what's set here.
func _show() -> void:
	for child: Node in _plate_spot.get_children():
		_plate_spot.remove_child(child)
		child.queue_free()
	if _place != null:
		_plate_spot.add_child(ItemModel.build(_place))


# Well again: the remedy's been taken in.
func _on_flag_changed(flag: StringName, value: int) -> void:
	if flag == LanternSpirit.LOW_FLAG and value == 0 and _eating:
		var food: ItemInstance = dish()
		if food != null:
			_clear(food)
		_eating = false
