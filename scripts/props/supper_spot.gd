class_name SupperSpot
extends Node3D
## The little round table by the bunk room's stove, where the lantern lives
## (its [code]Perch[/code] is his home) and where you share supper with him:
## holding a bowl or plate with a dish in it, Interact. The dish sits on the
## table a moment while he drifts down to it, then it's gone and he glows
## warm again: more for a better dish. The bowl stays with you. With nothing
## to share, Interact talks to him instead.

## Emitted when a meal is shared, with the dish and how much it warmed him.
signal shared(dish: ItemInstance, warmth: float)

## How much a ★ dish warms him; each star more adds [member per_star].
@export var base_warmth: float = 0.25
@export var per_star: float = 0.15
## How long the dish sits on the table while he eats, in seconds.
@export var eat_seconds: float = 2.5
## The conversation Interact starts when you've nothing to share: a file in
## [code]data/dialogue[/code].
@export var talk: StringName = &"lantern"

@onready var _reach: Interactable3D = $Reach
@onready var _plate_spot: Node3D = $PlateSpot


func _ready() -> void:
	_reach.interacted.connect(use)
	_reach.describe_interact = func(player: Player3D) -> String: return prompt(player.arms)


## The dish in what [param arms] hold, if it's a plate or bowl with food, or null.
func dish_in(arms: Arms) -> ItemInstance:
	var held: ItemInstance = arms.top()
	if held == null or not held.is_vessel() or not held.item.carried_whole:
		return null
	var food: Array[ItemInstance] = held.contents.get_contents()
	return null if food.is_empty() else food[0]


## What Interact would do, for the HUD: "Share Tomato Soup with the lantern".
func prompt(arms: Arms) -> String:
	var dish: ItemInstance = dish_in(arms)
	if dish == null:
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
	var dish: ItemInstance = dish_in(player.arms)
	if dish == null:
		return false
	player.arms.top().contents.remove_item(dish)
	var amount: float = warmth_of(dish)
	_set_down(dish)
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit != null:
		spirit.visit(_plate_spot, eat_seconds)
		spirit.rekindle(amount)
		spirit.say(LanternLines.pick(LanternLines.SUPPER))
		spirit.hum()
	shared.emit(dish, amount)
	return true


# Shows the dish on the table while he eats, then clears it away.
func _set_down(dish: ItemInstance) -> void:
	for child: Node in _plate_spot.get_children():
		child.queue_free()
	var model: Node3D = ItemModel.build(dish)
	_plate_spot.add_child(model)
	get_tree().create_timer(eat_seconds).timeout.connect(func() -> void:
		if is_instance_valid(model):
			model.queue_free())
