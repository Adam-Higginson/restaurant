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
##
## A [b]cutscene[/b] is the same thing started with [method play]: a script
## nobody in particular begins, whose cues (see [CueList]) stage the scene.
## A [CueHandler] acting on a cue can make the script wait for it with
## [method hold] and [method release]. A cutscene can be skipped by holding
## [constant SKIP_ACTION]: the script then runs to its end at once, so its
## flags are set and everyone ends up where they should be.

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
## Emitted when the replies are offered, before one is picked.
signal choices_offered
## Emitted when the cursor moves between choices.
signal choice_moved
## Emitted when a choice is picked.
signal choice_made
## Emitted when Interact is pressed while a cue is holding the script, for
## a cue that's waiting for exactly that ([code]@wait_for interact[/code]).
signal pressed_while_held
## Emitted when a cutscene starts being skipped.
signal skip_started
## Emitted when the skipping is over: at the cutscene's end, or at a choice,
## which is never picked for you.
signal skip_ended

## The group this node joins, so it can be found.
const GROUP: StringName = &"conversation"
## The button held to skip a cutscene.
const SKIP_ACTION: StringName = &"skip_cutscene"
## How long it's held before the cutscene skips, in seconds.
const SKIP_HOLD_SECONDS: float = 1.0

## Where the words are shown. Set by the HUD; without one the conversation
## still runs (tests do this).
var box: DialogueBox = null

## The conversation under way, or &"".
var talking: StringName:
	get:
		return _tree_id if _active else &""
## Who the conversation under way is with: the crewmate it was begun with, or
## null (a cutscene, or nothing under way).
var partner: Crewmate:
	get:
		return _speaker if _active and is_instance_valid(_speaker) else null

var _runner: DialogueRunner = DialogueRunner.new()
var _active: bool = false
var _tree_id: StringName = &""
var _player: Player3D = null
var _speaker: Crewmate = null
var _selected: int = 0
var _people: Catalog = Catalog.load_default()
## Whether what's under way was started with [method play].
var _cutscene: bool = false
var _skipping: bool = false
## How long the skip button has been held, in seconds.
var _skip_held: float = 0.0
## The holds that are open, and which node asked for each (its instance id,
## so one that's been freed can be told apart safely).
var _holds: Dictionary[int, int] = {}
## The number given to the last hold. Never reused, so a hold from an
## earlier conversation can't release this one.
var _last_hold: int = 0
## What was last started and who for, so [method replay] can start it again.
var _last_tree: DialogueTree = null
var _last_section: StringName = DialogueTree.START
var _last_player: Player3D = null
var _last_speaker: Crewmate = null
## Whether what's in the box was said in passing (see [method say_aside]).
var _aside: bool = false
var _last_was_cutscene: bool = false


func _enter_tree() -> void:
	# Before anyone's _ready, so cue handlers can find it as they start.
	add_to_group(GROUP)


func _ready() -> void:
	_runner.line_shown.connect(_on_line_shown)
	_runner.choices_shown.connect(_on_choices_shown)
	_runner.cue.connect(func(name: StringName, args: PackedStringArray) -> void:
		cue.emit(name, args))
	_runner.finished.connect(_on_finished)


func _process(delta: float) -> void:
	if not _active:
		return
	# Whoever you were talking to has gone (a scene change): let go.
	if not is_instance_valid(_player):
		_runner.stop()
		return
	# A handler that's gone can't release its hold: do it for them, or the
	# script would wait for ever.
	for id: int in _holds.keys():
		var holder: Node = null
		if is_instance_id_valid(_holds[id]):
			holder = instance_from_id(_holds[id]) as Node
		if holder == null or not holder.is_inside_tree():
			release(id)
	if _cutscene and not _skipping and InputMap.has_action(SKIP_ACTION) \
			and Input.is_action_pressed(SKIP_ACTION):
		_skip_held += delta
		if _skip_held >= SKIP_HOLD_SECONDS:
			skip()
	else:
		_skip_held = 0.0


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
## turning to face them, at [param section]. Returns whether it started: not
## if one's already under way or there's no such conversation or section.
func begin(tree_id: StringName, player: Player3D, speaker: Crewmate = null,
		section: StringName = DialogueTree.START) -> bool:
	if _active:
		return false
	return begin_tree(DialogueLibrary.find(tree_id), player, speaker, section)


## Starts [param tree], a conversation already read (see [method begin]).
func begin_tree(tree: DialogueTree, player: Player3D, speaker: Crewmate = null,
		section: StringName = DialogueTree.START) -> bool:
	return _start(tree, player, speaker, section, false)


## Plays the cutscene called [param tree_id] (a file in
## [code]data/dialogue[/code]) for [param player], from [param section].
## Returns whether it started.
func play(tree_id: StringName, player: Player3D,
		section: StringName = DialogueTree.START) -> bool:
	if _active:
		return false
	return play_tree(DialogueLibrary.find(tree_id), player, section)


## Plays [param tree], a cutscene already read (see [method play]).
func play_tree(tree: DialogueTree, player: Player3D,
		section: StringName = DialogueTree.START) -> bool:
	return _start(tree, player, null, section, true)


## Whether a conversation is under way.
func is_active() -> bool:
	return _active


## Whether what's under way is a cutscene (started with [method play]).
func is_cutscene() -> bool:
	return _active and _cutscene


## Whether a cutscene is being skipped: cues should happen at once.
func is_skipping() -> bool:
	return _active and _skipping


## How far the skip button is towards skipping, from 0 to 1.
func skip_progress() -> float:
	return clampf(_skip_held / SKIP_HOLD_SECONDS, 0.0, 1.0)


## The section of the script being read now, or &"" when nothing's under way.
func section() -> StringName:
	return _runner.section()


## Where the script has got to, for pointing at a mistake in it:
## "intro.dlg, line 12".
func where() -> String:
	return "%s%s, line %d" % [_tree_id, DialogueLibrary.ENDING, _runner.line_number()]


## Makes the script wait for [param by], a node acting on a cue, until it
## calls [method release] with the number this returns. Returns -1, holding
## nothing, if nothing's under way or a cutscene is being skipped (so
## there's nothing to wait for and the cue should happen at once).
func hold(by: Node) -> int:
	if not _active or _skipping:
		return -1
	# Whatever was last said has been read: the box steps aside for the
	# scene. (Something said in passing stays: it goes when its time is up.)
	if box != null and not _aside:
		box.close()
	_last_hold += 1
	_holds[_last_hold] = by.get_instance_id()
	_runner.hold()
	return _last_hold


## Lets go of the hold numbered [param id]. The script carries on once
## every hold is released. A hold that's already gone (the conversation
## ended, or was skipped) is ignored.
func release(id: int) -> void:
	if _holds.erase(id):
		_runner.release()


## Whether the hold numbered [param id] is still open: false once it's
## released, skipped past, or the conversation has ended.
func is_holding(id: int) -> bool:
	return _holds.has(id)


## What the Interact button does while talking: shows the rest of a line
## that's still typing, picks the choice the cursor is on, or moves on.
func press() -> void:
	if not _active:
		return
	if _runner.is_held():
		pressed_while_held.emit()
	elif box != null and box.is_typing():
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


## Has [param speaker_id] (a [Person]'s id) say [param text] in passing: it
## shows in the dialogue box like any line, but the script doesn't wait for
## it to be read and the box doesn't step aside when a cue holds the
## script. Whoever asked puts it away with [method end_aside]. See
## [SpeechCues].
func say_aside(speaker_id: StringName, text: String) -> void:
	_aside = true
	if box != null:
		box.show_line(_people.find_person(speaker_id), text, true, false)


## The hero (the player) as a [Person], for the name on what he says, or
## null while the story hasn't given him a name (see [constant DialogueStep.HERO]).
func hero() -> Person:
	return _people.find_person(DialogueStep.HERO)


## Puts away what was said in passing, if it's still up.
func end_aside() -> void:
	if not _aside:
		return
	_aside = false
	if box != null:
		box.close()


## Whether something said in passing is up.
func is_aside_up() -> bool:
	return _aside


## Skips the cutscene under way: the script runs to its end now, with every
## wait and fade made instant. It stops at a choice, if it comes to one
## (a choice with only one answer is made for you).
## Does nothing in an ordinary conversation.
func skip() -> void:
	if not _active or not _cutscene or _skipping or _runner.is_choosing():
		return
	_skipping = true
	_skip_held = 0.0
	_aside = false
	if box != null:
		box.close()
	skip_started.emit()
	_holds.clear()
	if _runner.is_held():
		_runner.release_all()
	else:
		_runner.advance()


## Starts the last conversation or cutscene again from the section it had
## reached (or the one it began at, if it's over), reading its file afresh
## first. For tuning a scene while the game runs: edit the file, save,
## replay. If the edited file has mistakes they're reported and the version
## already read is played instead. Returns whether anything started.
func replay() -> bool:
	if _last_tree == null or not is_instance_valid(_last_player):
		return false
	var from: StringName = _last_section
	if _active and _runner.section() != &"":
		from = _runner.section()
	var fresh: DialogueTree = DialogueLibrary.reread(_last_tree.id)
	var tree: DialogueTree = fresh if fresh != null else _last_tree
	if not tree.has_section(from):
		from = DialogueTree.START
	var speaker: Crewmate = _last_speaker if is_instance_valid(_last_speaker) else null
	stop()
	return _start(tree, _last_player, speaker, from, _last_was_cutscene)


func _start(tree: DialogueTree, player: Player3D, speaker: Crewmate, from: StringName,
		cutscene: bool) -> bool:
	if _active or tree == null or not tree.has_section(from):
		return false
	_active = true
	_cutscene = cutscene
	_skipping = false
	_skip_held = 0.0
	_holds.clear()
	_tree_id = tree.id
	_player = player
	_speaker = speaker
	_last_tree = tree
	_last_section = from
	_last_player = player
	_last_speaker = speaker
	_last_was_cutscene = cutscene
	if is_instance_valid(player):
		player.controls_enabled = false
		if is_instance_valid(speaker):
			player.face_towards(speaker.global_position)
			speaker.face_towards(player.global_position)
	started.emit(_tree_id)
	_runner.start(tree, Game.dialogue, from)
	return true


func _on_line_shown(line: DialogueStep) -> void:
	# Skipping: nobody's reading, so go straight on.
	if _skipping:
		_runner.advance()
		return
	var speaker: Person = _people.find_person(line.speaker) if line.speaker != &"" else null
	_aside = false
	if box != null:
		box.show_line(speaker, line.text)
	line_said.emit(speaker)


func _on_choices_shown(choices: Array[DialogueStep]) -> void:
	_selected = 0
	if _skipping and choices.size() == 1:
		# One answer isn't a choice (your silent replies on waking, #184):
		# it's made for you, and the skip goes on.
		_runner.choose(0)
		return
	# A choice is yours to make, even when skipping.
	if _skipping:
		_skipping = false
		skip_ended.emit()
	choices_offered.emit()
	if box == null:
		return
	var options: PackedStringArray = PackedStringArray()
	for choice: DialogueStep in choices:
		options.append(choice.text)
	# The replies are the hero's to say: his name, or none while he has none.
	box.show_choices(options, hero())


func _on_finished() -> void:
	if not _active:
		return
	_active = false
	_holds.clear()
	var was_skipping: bool = _skipping
	_skipping = false
	_cutscene = false
	if was_skipping:
		skip_ended.emit()
	_aside = false
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
