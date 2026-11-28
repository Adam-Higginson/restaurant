class_name ToolbarBar
extends Control
## The 3D player's toolbar along the bottom of the screen, as in Stardew
## Valley: one box per slot, the selected one outlined. Each slot shows a
## picture of the real model (#206), taken by [ItemIcons]: a dish shows what's
## in it. Until its picture is ready (or where nothing is drawn, as in tests)
## a slot shows a placeholder: a tool as a handle with a head in its colour,
## an item as a square in its colour, a plate or bowl as a flat dish with a
## dot for any food on it.
##
## Display only: it reads the player's [Toolbar] and redraws when it changes.
## [Hud3D] hands it the player.

const SLOT_SIZE: int = 16
const GAP: int = 2
const SLOT_COLOR: Color = Color(0.1, 0.09, 0.09, 0.75)
const SLOT_BORDER_COLOR: Color = Color(0.35, 0.32, 0.3, 1)
const SELECTED_COLOR: Color = Color(1, 1, 1, 1)
const HANDLE_COLOR: Color = Color(0.45, 0.3, 0.18, 1)

## How far in from a slot's edge its picture is drawn, in canvas pixels.
const ICON_INSET: float = 1.0

var _player: Player3D = null
var _icons: ItemIcons = null


func _ready() -> void:
	custom_minimum_size = Vector2(
		Toolbar.SLOT_COUNT * (SLOT_SIZE + GAP) - GAP, SLOT_SIZE
	)
	# The pictures are drawn smaller than they're taken: smooth them, rather
	# than the crisp pixels the rest of the HUD uses.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_icons = ItemIcons.new()
	_icons.name = "Icons"
	add_child(_icons)
	_icons.icon_made.connect(func(_key: String) -> void: queue_redraw())


func _draw() -> void:
	if _player == null:
		return
	var toolbar: Toolbar = _player.toolbar
	for i: int in Toolbar.SLOT_COUNT:
		var slot: Rect2 = slot_rect(i)
		draw_rect(slot, SLOT_COLOR)
		PixelDraw.outline(self, slot, SLOT_BORDER_COLOR)
		var tool: HandTool = toolbar.get_tool(i)
		var item: ItemInstance = toolbar.get_item(i)
		var picture: Texture2D = null
		if tool != null:
			picture = _icons.icon_for_tool(tool)
		elif item != null:
			picture = _icons.icon_for_item(item)
		if picture != null:
			draw_texture_rect(picture, slot.grow(-ICON_INSET), false)
		elif tool != null:
			_draw_tool(slot, tool)
		elif item != null:
			_draw_item(slot, item)
		if i == toolbar.selected_index:
			PixelDraw.outline(self, slot.grow(1.0), SELECTED_COLOR)


## Starts showing [param player]'s toolbar.
func setup(player: Player3D) -> void:
	_player = player
	_player.toolbar.changed.connect(queue_redraw)
	_player.toolbar.vessel_contents_changed.connect(queue_redraw)
	queue_redraw()


## What takes the slots' pictures.
func icons() -> ItemIcons:
	return _icons


## Where slot [param index] is drawn, in the bar's own space.
func slot_rect(index: int) -> Rect2:
	return Rect2(index * (SLOT_SIZE + GAP), 0, SLOT_SIZE, SLOT_SIZE)


# A placeholder until there's real art: a handle with a head in the tool's
# colour, lying across the slot.
func _draw_tool(slot: Rect2, tool: HandTool) -> void:
	var middle: float = slot.position.y + SLOT_SIZE / 2.0 - 1.0
	draw_rect(Rect2(slot.position.x + 3, middle, 4, 2), HANDLE_COLOR)
	draw_rect(Rect2(slot.position.x + 7, middle - 1, 6, 3), tool.color)


# A placeholder: food is a square in its colour; a vessel is a flat dish, with
# a dot in the colour of its first food.
func _draw_item(slot: Rect2, instance: ItemInstance) -> void:
	if not instance.is_vessel():
		draw_rect(Rect2(slot.position + Vector2(4, 4), Vector2(8, 8)), instance.item.color)
		return
	draw_rect(Rect2(slot.position + Vector2(2, 9), Vector2(12, 3)), instance.item.color)
	var food: Array[ItemInstance] = instance.contents.get_contents()
	if not food.is_empty():
		draw_rect(Rect2(slot.position + Vector2(6, 5), Vector2(4, 4)), food[0].item.color)
