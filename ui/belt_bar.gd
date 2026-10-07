class_name BeltBar
extends Control
## The belt bar at the bottom of the screen: one box per belt slot, the
## selected one outlined, each tool as a placeholder shape in its colour.
## Dimmed while the player carries anything, as tools need empty arms.
##
## Display only: it reads the player's [ToolBelt] and [Arms] and redraws when
## they change.

const SLOT_SIZE: int = 16
const GAP: int = 2
const SLOT_COLOR: Color = Color(0.1, 0.09, 0.09, 0.75)
const SLOT_BORDER_COLOR: Color = Color(0.35, 0.32, 0.3, 1)
## Matches the interact highlight, so "selected" looks the same everywhere.
const SELECTED_COLOR: Color = Interactable.HIGHLIGHT_COLOR
const HANDLE_COLOR: Color = Color(0.45, 0.3, 0.18, 1)
const DIMMED: Color = Color(1, 1, 1, 0.4)

## The player whose belt this shows. Set in the scene.
@export var player: Player


func _ready() -> void:
	custom_minimum_size = Vector2(
		ToolBelt.SLOT_COUNT * (SLOT_SIZE + GAP) - GAP, SLOT_SIZE
	)
	player.belt.changed.connect(queue_redraw)
	player.arms.changed.connect(_update_dimmed)
	_update_dimmed()


func _draw() -> void:
	var belt: ToolBelt = player.belt
	for i: int in ToolBelt.SLOT_COUNT:
		var slot: Rect2 = Rect2(i * (SLOT_SIZE + GAP), 0, SLOT_SIZE, SLOT_SIZE)
		draw_rect(slot, SLOT_COLOR)
		PixelDraw.outline(self, slot, SLOT_BORDER_COLOR)
		var tool: HandTool = belt.get_tool(i)
		if tool != null:
			_draw_tool(slot, tool)
		if i == belt.selected_index:
			PixelDraw.outline(self, slot.grow(1.0), SELECTED_COLOR)


## A placeholder until there's real art: a handle with a head in the tool's
## colour, lying across the slot.
func _draw_tool(slot: Rect2, tool: HandTool) -> void:
	var middle: float = slot.position.y + SLOT_SIZE / 2.0 - 1.0
	draw_rect(Rect2(slot.position.x + 3, middle, 4, 2), HANDLE_COLOR)
	draw_rect(Rect2(slot.position.x + 7, middle - 1, 6, 3), tool.color)


func _update_dimmed() -> void:
	modulate = Color.WHITE if player.arms.is_empty() else DIMMED
