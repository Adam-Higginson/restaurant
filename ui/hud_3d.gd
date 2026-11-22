class_name Hud3D
extends CanvasLayer
## The 3D player's on-screen HUD: the toolbar and what they're holding at the
## bottom, their hearts in the top-left corner, and what Interact and Use
## tool would do in the top-right.
## While you're in a conversation those step aside for the dialogue box.
##
## Set [member player] in the scene; this hands it to each part when ready.

## The player the HUD shows. Set in the scene.
@export var player: Player3D

@onready var _toolbar: ToolbarBar = %Toolbar
@onready var _held_item: HeldItemLabel3D = %HeldItem
@onready var _action_prompt: ActionPrompt = %ActionPrompt
@onready var _hearts: HeartsBar = %HeartsBar
@onready var _memory_card: MemoryCard = %MemoryCard
@onready var _dialogue_box: DialogueBox = %DialogueBox
@onready var _dialogue_sounds: DialogueSounds = %DialogueSounds


func _ready() -> void:
	if player == null:
		push_error("Hud3D: no player set")
		return
	_toolbar.setup(player)
	_held_item.setup(player)
	_action_prompt.setup(player)
	_hearts.setup(player)
	# The lantern lights up when a memory comes back.
	Game.memories.remembered.connect(_on_remembered)
	# The world's conversation may be ready after us.
	_join_conversation.call_deferred()


## Whether the toolbar, the held item's name and the action prompt are
## showing: not while you're talking.
func shows_play_parts() -> bool:
	return _toolbar.visible


# Gives the world's conversation (if it has one) the box to speak through,
# and steps the rest of the HUD aside while it does.
func _join_conversation() -> void:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null:
		return
	conversation.box = _dialogue_box
	_dialogue_sounds.setup(conversation, _dialogue_box)
	conversation.started.connect(func(_tree_id: StringName) -> void: _show_play_parts(false))
	conversation.ended.connect(func(_tree_id: StringName) -> void: _show_play_parts(true))


func _show_play_parts(shown: bool) -> void:
	_toolbar.visible = shown
	_held_item.visible = shown
	_action_prompt.visible = shown


func _on_remembered(_memory: Memory) -> void:
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit != null:
		spirit.excite()
