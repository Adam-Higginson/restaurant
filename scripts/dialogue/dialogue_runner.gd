class_name DialogueRunner
extends RefCounted
## Walks a [DialogueTree] one step at a time: says each line and waits to be
## told to go on, offers choices and waits for one to be picked, and quietly
## does the rest (guards, flags, cues, jumps). Pure logic with no nodes; the
## [Conversation] shows what it says and passes on the button presses.
##
## A cue usually passes straight through, but whoever acts on it can ask the
## script to wait with [method hold] (a fade that takes two seconds, say) and
## let it go on with [method release]. That's what makes a cutscene possible:
## the script reads no further until every hold has been released.

## Emitted when someone says something. Call [method advance] to go on.
signal line_shown(said: DialogueStep)
## Emitted when there are replies to pick from. Call [method choose].
signal choices_shown(offered: Array[DialogueStep])
## Emitted when the script has a cue for the scene, e.g. &"shot".
signal cue(name: StringName, args: PackedStringArray)
## Emitted when the conversation is over.
signal finished

## The most steps run between two lines, so a script that jumps in a circle
## ends instead of hanging the game.
const STEP_LIMIT: int = 500

## The line showing now, or null.
var line: DialogueStep:
	get:
		return _line

## The choices on offer now, or empty.
var choices: Array[DialogueStep]:
	get:
		return _choices

var _tree: DialogueTree = null
var _state: DialogueState = null
## The step to run next.
var _next: int = 0
var _active: bool = false
var _line: DialogueStep = null
var _choices: Array[DialogueStep] = []
## Whether the last guard held, for a "? else" after it.
var _guard_held: bool = true
## How many holds are open. The script waits while there are any.
var _holds: int = 0
## The line of the script file the step being run was written on.
var _line_number: int = 0
## Whether the script stopped at a cue to wait for its holds, and so should
## carry on by itself when the last one is released.
var _waiting_on_holds: bool = false


## Starts [param tree] at [param section], reading and changing flags in
## [param state]. Returns false, starting nothing, if the section is missing.
func start(tree: DialogueTree, state: DialogueState,
		section: StringName = DialogueTree.START) -> bool:
	if tree == null or not tree.has_section(section):
		return false
	_tree = tree
	_state = state
	_next = tree.sections[section]
	_active = true
	_guard_held = true
	_holds = 0
	_waiting_on_holds = false
	_run()
	return true


## Whether a conversation is under way.
func is_active() -> bool:
	return _active


## Whether it's waiting for a choice to be picked.
func is_choosing() -> bool:
	return _active and not _choices.is_empty()


## Whether a cue is holding the script: it's waiting for [method release].
func is_held() -> bool:
	return _active and _holds > 0


## The section being read now ([code]&"start"[/code], say), or &"" when
## nothing's under way.
func section() -> StringName:
	if not _active or _tree == null:
		return &""
	# The step being waited on is the one before the next to run.
	var at: int = maxi(_next - 1, 0)
	var found: StringName = &""
	var found_at: int = -1
	for name: StringName in _tree.sections:
		var starts: int = _tree.sections[name]
		if starts <= at and starts > found_at:
			found = name
			found_at = starts
	return found


## The line of the script file being read now, for pointing at a mistake.
func line_number() -> int:
	return _line_number


## Goes on from the line showing. Does nothing while choosing, while a cue
## is holding the script, or when over.
func advance() -> void:
	if not _active or is_choosing() or is_held():
		return
	_run()


## Asks the script to wait: it reads no further until [method release] has
## been called once for every hold. Call it while acting on a cue.
func hold() -> void:
	if _active:
		_holds += 1


## Lets go of one hold. When the last is released the script carries on from
## where it stopped.
func release() -> void:
	if not _active or _holds <= 0:
		return
	_holds -= 1
	if _holds == 0 and _waiting_on_holds:
		_waiting_on_holds = false
		_run()


## Lets go of every hold at once, so the script carries on now.
func release_all() -> void:
	if not _active or _holds <= 0:
		return
	_holds = 1
	release()


## Picks choice [param index] of the ones on offer, and goes on from it.
func choose(index: int) -> void:
	if not is_choosing() or index < 0 or index >= _choices.size():
		return
	var picked: DialogueStep = _choices[index]
	_choices = []
	_jump(picked.target)
	if _active:
		_run()


## Ends the conversation now.
func stop() -> void:
	if not _active:
		return
	_active = false
	_line = null
	_choices = []
	_holds = 0
	_waiting_on_holds = false
	finished.emit()


# Runs steps until there's something to wait for.
func _run() -> void:
	_line = null
	for _count: int in STEP_LIMIT:
		if not _active:
			return
		if _next >= _tree.steps.size():
			stop()
			return
		var step: DialogueStep = _tree.steps[_next]
		if step.kind == DialogueStep.Kind.CHOICE:
			if _offer_choices():
				return
			continue
		_next += 1
		if not _passes(step):
			continue
		_line_number = step.line_number
		match step.kind:
			DialogueStep.Kind.LINE:
				_line = step
				line_shown.emit(step)
				return
			DialogueStep.Kind.SET:
				if step.change == DialogueStep.Change.BY:
					_state.add(step.flag, step.amount)
				else:
					_state.set_flag(step.flag, step.amount)
			DialogueStep.Kind.CUE:
				cue.emit(step.cue, step.args)
				# Somebody acting on the cue asked us to wait for them.
				if _active and _holds > 0:
					_waiting_on_holds = true
					return
			DialogueStep.Kind.JUMP:
				_jump(step.target)
	push_error("DialogueRunner: '%s' ran %d steps without a line; is it jumping in a circle?"
			% [_tree.id, STEP_LIMIT])
	stop()


# Gathers the run of choices starting at the next step, leaving out any
# whose guard fails. Returns whether there's a menu to wait on.
func _offer_choices() -> bool:
	var offered: Array[DialogueStep] = []
	while _next < _tree.steps.size() and _tree.steps[_next].kind == DialogueStep.Kind.CHOICE:
		var choice: DialogueStep = _tree.steps[_next]
		_next += 1
		if _passes(choice):
			offered.append(choice)
	if offered.is_empty():
		return false
	_choices = offered
	choices_shown.emit(offered)
	return true


# Whether a step's guard lets it run, remembering the answer for an else.
func _passes(step: DialogueStep) -> bool:
	if step.is_else:
		return not _guard_held
	if step.guard.is_empty():
		return true
	_guard_held = DialogueCondition.holds(step.guard, _state)
	return _guard_held


func _jump(target: StringName) -> void:
	if target == DialogueStep.END or not _tree.has_section(target):
		stop()
		return
	_next = _tree.sections[target]
