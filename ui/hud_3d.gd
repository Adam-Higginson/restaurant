class_name Hud3D
extends CanvasLayer
## The 3D player's on-screen HUD: the toolbar and what they're holding at the
## bottom, and what Interact and Use tool would do in the top-right corner.
##
## Set [member player] in the scene; this hands it to each part when ready.

## The player the HUD shows. Set in the scene.
@export var player: Player3D

@onready var _toolbar: ToolbarBar = %Toolbar
@onready var _held_item: HeldItemLabel3D = %HeldItem
@onready var _action_prompt: ActionPrompt = %ActionPrompt


func _ready() -> void:
	if player == null:
		push_error("Hud3D: no player set")
		return
	_toolbar.setup(player)
	_held_item.setup(player)
	_action_prompt.setup(player)
