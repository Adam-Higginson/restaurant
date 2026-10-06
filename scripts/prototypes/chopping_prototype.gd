class_name ChoppingPrototype
extends Node2D
## A throwaway testing ground for the reaction engine (#31): a chopping board
## holding one item. Use tool (F) sends one cut through the engine. #8 replaces
## this with the real board.
##
## The scene only forwards input and draws what the engine reports. It doesn't
## know what a tomato turns into; that's all in the data.

var _catalog: Catalog = Catalog.load_default()
var _cut: Element = _catalog.find_element(&"cut")
var _board: VesselContents

@onready var _food: ColorRect = $Board/Food
@onready var _progress: ProgressBar = $Progress
@onready var _status: Label = $Status


func _ready() -> void:
	_board = VesselContents.new(_catalog.find_item(&"chopping_board"), _catalog.reactions, 1)
	_board.contents_changed.connect(_redraw)
	_board.reaction_started.connect(_on_reaction_changed)
	_board.reaction_progressed.connect(_on_reaction_changed)
	_board.reaction_finished.connect(
		func(_active: ActiveReaction, _result: ItemInstance) -> void: _redraw()
	)
	reset(&"tomato")


# _input rather than _unhandled_input: gdUnit's scene runner calls a scene
# root's _unhandled_input directly as well as sending the event, which would
# count every simulated press twice. Nothing else in this scene takes input.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("use_tool"):
		_board.add_element(_cut)
	elif event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key: Key = (event as InputEventKey).physical_keycode
		if key == KEY_R:
			reset(&"tomato")
		elif key == KEY_L:
			reset(&"lettuce")


## The board's contents, for tests.
func get_board() -> VesselContents:
	return _board


## Clears the board and puts a fresh, normal-quality item with [param item_id] on it.
func reset(item_id: StringName) -> void:
	for instance: ItemInstance in _board.get_contents():
		_board.remove_item(instance)
	_board.add_item(ItemInstance.new(_catalog.find_item(item_id)))
	_redraw()


func _on_reaction_changed(_active: ActiveReaction) -> void:
	_redraw()


func _redraw() -> void:
	var contents: Array[ItemInstance] = _board.get_contents()
	if contents.is_empty():
		_food.visible = false
		_status.text = "Empty board"
		return
	var instance: ItemInstance = contents[0]
	_food.visible = true
	_food.color = instance.item.color
	_status.text = "%s %s" % [instance.item.display_name, "★".repeat(instance.quality)]
	var active: Array[ActiveReaction] = _board.get_active_reactions()
	if active.is_empty():
		_progress.value = 0.0
		_status.text += "\nNothing more to do with the knife"
		return
	var reaction: ActiveReaction = active[0]
	_progress.value = reaction.get_fraction()
	_status.text += "\n%s → %s: cut %d / %d" % [
		instance.item.display_name, reaction.reaction.result.display_name,
		reaction.progress, reaction.reaction.amount,
	]
