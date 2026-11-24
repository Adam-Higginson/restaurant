class_name SupperSpot
extends Node3D
## The little round table by the bunk room's stove, where the lantern lives
## (its [code]Perch[/code] is his home) and where you share supper with him:
## holding a bowl or plate with a dish in it, Interact. The dish sits on the
## table a moment while he drifts down to it, then it's gone and he glows
## warm again: more for a better dish. The bowl stays with you. With nothing
## to share, Interact talks to him instead.
##
## Home from the sea low (#158), he only stirs for the old book's remedy
## (#155): set it down by him and [member remedy_scene] plays at once, the
## first meal (#186). He takes it in during the scene, which clears the low
## flag and with it the bowl, and he comes back to himself.

## Emitted when a meal is shared, with the dish and how much it warmed him.
signal shared(dish: ItemInstance, warmth: float)
## Emitted when the remedy has brought him back from being low.
signal mended

## How much a ★ dish warms him; each star more adds [member per_star].
@export var base_warmth: float = 0.25
@export var per_star: float = 0.15
## How long the dish sits on the table while he eats, in seconds.
@export var eat_seconds: float = 2.5
## The conversation Interact starts when you've nothing to share: a file in
## [code]data/dialogue[/code].
@export var talk: StringName = &"lantern"
## The dish that brings him back when he's low: the old book's remedy. While
## he's low it's the only one he stirs for.
@export var remedy: Item
## The cutscene the remedy plays once he's had it: a file in
## [code]data/dialogue[/code]. It clears his low flag.
@export var remedy_scene: StringName = &"remedy"

## The first meal's bowl, on the table until he's well.
var _waiting: Node3D = null

@onready var _reach: Interactable3D = $Reach
@onready var _plate_spot: Node3D = $PlateSpot


func _ready() -> void:
	_reach.interacted.connect(use)
	Game.dialogue.flag_changed.connect(_on_flag_changed)
	_reach.describe_interact = func(player: Player3D) -> String: return prompt(player.arms)


## The dish in what [param arms] hold, if it's a plate or bowl with food, or null.
func dish_in(arms: Arms) -> ItemInstance:
	var held: ItemInstance = arms.top()
	if held == null or not held.is_vessel() or not held.item.carried_whole:
		return null
	var food: Array[ItemInstance] = held.contents.get_contents()
	return null if food.is_empty() else food[0]


## Whether the dish in [param arms] can be shared with him now: any dish,
## but while he's low only [member remedy].
func can_share(arms: Arms) -> bool:
	var dish: ItemInstance = dish_in(arms)
	if dish == null:
		return false
	return not _is_low() or (remedy != null and dish.item.id == remedy.id)


## What Interact would do, for the HUD: "Share Tomato Soup with the lantern".
func prompt(arms: Arms) -> String:
	var dish: ItemInstance = dish_in(arms)
	if dish == null or not can_share(arms):
		return "Talk to the lantern" if can_talk() else ""
	return "Share %s with the lantern" % dish.item.display_name


## Whether there's a conversation to have here.
func can_talk() -> bool:
	return talk != &"" and Conversation.find(self) != null


## What Interact does: shares the dish [param player] holds, or with none,
## talks to the lantern.
func use(player: Player3D) -> void:
	if share(player):
		return
	var conversation: Conversation = Conversation.find(self)
	if conversation != null and talk != &"":
		conversation.begin(talk, player)


## How much [param dish] warms him.
func warmth_of(dish: ItemInstance) -> float:
	return base_warmth + per_star * float(dish.quality - 1)


## Shares the held dish with [param player]'s lantern. Returns whether it did.
func share(player: Player3D) -> bool:
	if not can_share(player.arms):
		return false
	var dish: ItemInstance = dish_in(player.arms)
	var was_low: bool = _is_low()
	player.arms.top().contents.remove_item(dish)
	var amount: float = warmth_of(dish)
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if was_low:
		# The first meal: the bowl waits on the table through the cutscene,
		# which moves him to it.
		_set_down(dish, true)
		if spirit != null:
			spirit.rekindle_when_well(amount)
		shared.emit(dish, amount)
		_mend.call_deferred(player)
		return true
	_set_down(dish)
	if spirit != null:
		spirit.visit(_plate_spot, eat_seconds)
		spirit.rekindle(amount)
		spirit.remark(&"supper")
		spirit.hum()
	shared.emit(dish, amount)
	return true


# The remedy's down: the cutscene of the first meal plays, and clears his low
# flag. With no conversation to play it in, he simply comes back.
func _mend(player: Player3D) -> void:
	var conversation: Conversation = Conversation.find(self)
	var played: bool = conversation != null and is_instance_valid(player) \
			and conversation.play(remedy_scene, player)
	if not played:
		Game.dialogue.clear(LanternSpirit.LOW_FLAG)
	mended.emit()


func _is_low() -> bool:
	return Game.dialogue.is_set(LanternSpirit.LOW_FLAG)


# Shows the dish on the table while he eats, then clears it away: after
# [member eat_seconds], or with [param until_well], once he's well again.
func _set_down(dish: ItemInstance, until_well: bool = false) -> void:
	for child: Node in _plate_spot.get_children():
		child.queue_free()
	var model: Node3D = ItemModel.build(dish)
	_plate_spot.add_child(model)
	if until_well:
		_waiting = model
		return
	get_tree().create_timer(eat_seconds).timeout.connect(func() -> void:
		if is_instance_valid(model):
			model.queue_free())


# Well again: the first meal's bowl has been taken in.
func _on_flag_changed(flag: StringName, value: int) -> void:
	if flag == LanternSpirit.LOW_FLAG and value == 0 and is_instance_valid(_waiting):
		_waiting.queue_free()
		_waiting = null
