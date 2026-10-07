extends Node2D
## Draws what the player carries as coloured squares stacked above their head,
## bottom item lowest, with the active top item outlined. Bobs while walking.
##
## Display only: it reads the player's [Arms] and redraws when they change.

const ITEM_SIZE: int = 7
const GAP: int = 1
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
		var top: float = BASE_Y - (i + 1) * ITEM_SIZE - i * GAP
		var rect: Rect2 = Rect2(-ITEM_SIZE / 2.0, top, ITEM_SIZE, ITEM_SIZE)
		# Snap to whole pixels: an odd size centred on 0 would land on halves.
		rect.position = rect.position.floor()
		draw_rect(rect, items[i].item.color)
		if i == items.size() - 1:
			PixelDraw.outline(self, rect.grow(1.0), TOP_OUTLINE_COLOR)
