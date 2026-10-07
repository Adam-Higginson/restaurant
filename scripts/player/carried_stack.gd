extends Node2D
## Draws what the player carries as coloured squares stacked above their head,
## each overlapping the one below, with the active top item outlined. A plate
## shows its food on it. Bobs while walking.
##
## Display only: it reads the player's [Arms] and redraws when they change.

const ITEM_SIZE: int = 7
## How many pixels each item covers of the one below it.
const OVERLAP: int = 2
## Each item's own border, a darker shade of its colour, keeps overlapping
## items of similar colours apart.
const BORDER_DARKEN: float = 0.35
## Where the bottom item's lower edge sits, just above the player's head.
const BASE_Y: int = -10
## Dark, so it shows on light items like plates as well as dark ones.
const TOP_OUTLINE_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
## Bobs per second while walking.
const BOB_RATE: float = 3.0

var _bob_time: float = 0.0

@onready var _player: Player = get_parent() as Player


func _ready() -> void:
	_player.arms.changed.connect(queue_redraw)


func _process(delta: float) -> void:
	if _player.velocity == Vector2.ZERO:
		_bob_time = 0.0
	else:
		_bob_time += delta
	# Whole pixels only, so the pixel art stays crisp: -1, 0 or 1.
	position.y = roundf(sin(_bob_time * BOB_RATE * TAU))


func _draw() -> void:
	var items: Array[ItemInstance] = _player.arms.get_items()
	for i: int in items.size():
		var top: float = BASE_Y - ITEM_SIZE - i * (ITEM_SIZE - OVERLAP)
		var rect: Rect2 = Rect2(-ITEM_SIZE / 2.0, top, ITEM_SIZE, ITEM_SIZE)
		# Snap to whole pixels: an odd size centred on 0 would land on halves.
		rect.position = rect.position.floor()
		var color: Color = items[i].item.color
		ItemDraw.draw_item(self, items[i], rect)
		PixelDraw.outline(self, rect, color.darkened(BORDER_DARKEN))
		if i == items.size() - 1:
			PixelDraw.outline(self, rect.grow(1.0), TOP_OUTLINE_COLOR)
