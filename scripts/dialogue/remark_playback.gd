class_name RemarkPlayback
extends RefCounted
## Plays one [Remark]: its lines one at a time, each in a bubble over whoever
## says it, the next waiting until the last has faded. A [DialogueRunner]
## walks the remark's section, so its guards and [code]set[/code] lines work
## just as in a conversation.
##
## It stops early if a speaker goes, or is hushed (the lantern cutting in).

## Emitted when the remark is over, whether it finished or was stopped.
signal finished

## The remark playing, or null.
var remark: Remark:
	get:
		return _remark if is_playing() else null

var _runner: DialogueRunner = DialogueRunner.new()
var _remark: Remark = null
var _speakers: Dictionary[StringName, Speaker] = {}
## Who's saying the line showing now.
var _current: Speaker = null


func _init() -> void:
	_runner.line_shown.connect(_on_line)
	_runner.finished.connect(_on_finished)


## Plays [param what], with [param speakers] saying the lines (by
## [member Speaker.who]) and [param state] for its guards and flags. Returns
## whether it began.
func start(what: Remark, speakers: Dictionary[StringName, Speaker],
		state: DialogueState) -> bool:
	stop()
	_remark = what
	_speakers = speakers
	return _runner.start(what.tree, state, what.section)


## Whether a remark is playing.
func is_playing() -> bool:
	return _runner.is_active()


## Stops the remark now, hushing whoever's speaking.
func stop() -> void:
	if not _runner.is_active():
		return
	var speaking: Speaker = _current
	_let_go()
	if is_instance_valid(speaking):
		speaking.hush()
	_runner.stop()


## The lines [param what] would say, in order, given [param state]. Any
## [code]set[/code] lines in it change [param state] as they're passed.
static func lines_of(what: Remark, state: DialogueState) -> Array[DialogueStep]:
	var lines: Array[DialogueStep] = []
	var runner: DialogueRunner = DialogueRunner.new()
	runner.line_shown.connect(func(step: DialogueStep) -> void: lines.append(step))
	if runner.start(what.tree, state, what.section):
		# Each advance shows the next line, or ends it.
		for _count: int in what.tree.steps.size():
			if not runner.is_active():
				break
			runner.advance()
	return lines


func _on_line(step: DialogueStep) -> void:
	_let_go()
	var speaker: Speaker = null
	if _speakers.has(step.speaker):
		speaker = _speakers[step.speaker]
	if not is_instance_valid(speaker):
		_runner.stop()
		return
	_current = speaker
	speaker.said.connect(_on_said)
	speaker.hushed.connect(_on_hushed)
	speaker.say(step.text, Speaker.style_for(step.tag))


func _on_said(_line: String) -> void:
	_let_go()
	_runner.advance()


func _on_hushed() -> void:
	_let_go()
	_runner.stop()


func _on_finished() -> void:
	_let_go()
	finished.emit()


# Stops listening to whoever was speaking.
func _let_go() -> void:
	if is_instance_valid(_current):
		if _current.said.is_connected(_on_said):
			_current.said.disconnect(_on_said)
		if _current.hushed.is_connected(_on_hushed):
			_current.hushed.disconnect(_on_hushed)
	_current = null
