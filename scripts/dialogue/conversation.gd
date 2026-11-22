class_name Conversation
extends Node
## A proper conversation with someone, from the first word to the last. It
## stops the player walking, turns them and the speaker to face each other,
## runs the script with a [DialogueRunner], shows it in the [DialogueBox],
## reads the buttons, and puts everything back when it's over.
##
## One lives in the world's scene; anything that wants to talk finds it with
## [method find]. The world keeps running while you talk, and the camera
## stays yours unless the script asks for a shot.

## Emitted when a conversation begins, before its first line.
signal started(tree_id: StringName)
## Emitted when it's over and the player can move again.
signal ended(tree_id: StringName)
## Emitted when the script has a cue for the scene, e.g. &"shot".
signal cue(name: StringName, args: PackedStringArray)
## Emitted when somebody starts a line.
signal line_said(speaker: Person)
## Emitted when a press moves on to the next line.
signal advanced
## Emitted when the cursor moves between choices.
signal choice_moved
## Emitted when a choice is picked.
signal choice_made

## The group this node joins, so it can be found.
const GROUP: StringName = &"conversation"

## Where the words are shown. Set by the HUD; without one the conversation
## still runs (tests do this).
var box: DialogueBox = null

## The conversation under way, or &"".
var talking: StringName:
	get:
		return _tree_id if _active else &""

var _runner: DialogueRunner = DialogueRunner.new()
var _active: bool = false
var _tree_id: StringName = &""
var _player: Player3D = null
var _speaker: Crewmate = null
var _selected: int = 0
var _people: Catalog = Catalog.load_default()


func _ready() -> void:
	add_to_group(GROUP)
	_runner.line_shown.connect(_on_line_shown)
	_runner.choices_shown.connect(_on_choices_shown)
	_runner.cue.connect(func(name: StringName, args: PackedStringArray) -> void:
		cue.emit(name, args))
	_runner.finished.connect(_on_finished)


func _process(_delta: float) -> void:
	# Whoever you were talking to has gone (a scene change): let go.
	if _active and not is_instance_valid(_player):
		_runner.stop()


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not InteractionDetector3D.accepts_event(event, Input.mouse_mode):
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		press()
	elif _runner.is_choosing():
		if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
			get_viewport().set_input_as_handled()
			move_choice(-1)
		elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
			get_viewport().set_input_as_handled()
			move_choice(1)


## The world's conversation, looked for from [param from], or null if the
## scene hasn't one.
static func find(from: Node) -> Conversation:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(GROUP) as Conversation


## Starts the conversation called [param tree_id] (a file in
## [code]data/dialogue[/code]) for [param player], with [param speaker]
## turning to face them. Returns whether it started: not if one's already
## under way or there's no such conversation.
func begin(tree_id: StringName, player: Player3D, speaker: Crewmate = null) -> bool:
	if _active:
		return false
	return begin_tree(DialogueLibrary.find(tree_id), player, speaker)


## Starts [param tree], a conversation already read (see [method begin]).
func begin_tree(tree: DialogueTree, player: Player3D, speaker: Crewmate = null) -> bool:
	if _active or tree == null or not tree.has_section(DialogueTree.START):
		return false
	_active = true
	_tree_id = tree.id
	_player = player
	_speaker = speaker
	if is_instance_valid(player):
		player.controls_enabled = false
		if is_instance_valid(speaker):
			player.face_towards(speaker.global_position)
			speaker.face_towards(player.global_position)
	started.emit(_tree_id)
	_runner.start(tree, Game.dialogue)
	return true


## Whether a conversation is under way.
func is_active() -> bool:
	return _active


## What the Interact button does while talking: shows the rest of a line
## that's still typing, picks the choice the cursor is on, or moves on.
func press() -> void:
	if not _active:
		return
	if box != null and box.is_typing():
		box.finish_typing()
	elif _runner.is_choosing():
		choice_made.emit()
		_runner.choose(_selected)
	else:
		advanced.emit()
		_runner.advance()


## Moves the cursor [param step] choices down (or up, if negative), wrapping
## round at either end.
func move_choice(step: int) -> void:
	if not _runner.is_choosing():
		return
	_selected = posmod(_selected + step, _runner.choices.size())
	if box != null:
		box.select(_selected)
	choice_moved.emit()


## Which choice the cursor is on, from 0.
func selected_choice() -> int:
	return _selected


## Ends the conversation now, wherever it had got to.
func stop() -> void:
	_runner.stop()


func _on_line_shown(line: DialogueStep) -> void:
	var speaker: Person = _people.find_person(line.speaker) if line.speaker != &"" else null
	if box != null:
		box.show_line(speaker, line.text)
	line_said.emit(speaker)


func _on_choices_shown(choices: Array[DialogueStep]) -> void:
	_selected = 0
	if box == null:
		return
	var options: PackedStringArray = PackedStringArray()
	for choice: DialogueStep in choices:
		options.append(choice.text)
	box.show_choices(options)


func _on_finished() -> void:
	if not _active:
		return
	_active = false
	if box != null:
		box.close()
	if is_instance_valid(_player):
		_player.controls_enabled = true
	if is_instance_valid(_speaker):
		_speaker.rest()
	# So scripts can tell a first meeting from a fifth: talked.heron.
	Game.dialogue.add(StringName("talked.%s" % _tree_id))
	_player = null
	_speaker = null
	ended.emit(_tree_id)
