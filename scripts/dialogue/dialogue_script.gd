class_name DialogueScript
extends RefCounted
## Reads a conversation written as plain text (a [code].dlg[/code] file) into
## a [DialogueTree]. One statement to a line:
##
## [codeblock]
## # a comment
## ~ start                              a section
## heron: Rough night out there. [gruff] someone says something, with a tag
## lantern: I like it. It's *soft*.     *...* is highlighted
## - How's the weather? -> weather      a reply to pick; replies in a row
## - Never mind. -> END                   make one menu
## ? not asked_heading                  a guard: only the NEXT line obeys it
## ? else                               ...or runs if that guard failed
## set asked_heading                    flag = 1
## set visits + 1    set mood = 3       add to a flag, or set it
## clear news_fish                      flag = 0
## @shot stove_nook                     a cue for the scene (see [CueList])
## -> weather        -> END             carry on elsewhere, or finish
## [/codeblock]
##
## A section ends where the next begins, and the conversation with it unless
## it jumps. Mistakes are listed in [member DialogueTree.errors] with their
## line numbers rather than stopping the game.
##
## A file of remarks (things said in passing, see [Remark]) is read the same
## way, with three differences. It needs no [code]~ start[/code]. A section
## may have tags after its name and a guard on the line before it:
##
## [codeblock]
## ? night and not raining              only said when this holds
## ~ stove_drawing [weight 2] [cooldown 180] [priority 1] [on caught]
## heron: Mm-hm-hmm. [sound]            a line's tag is its bubble's style
## [/codeblock]
##
## And a remark can't offer choices or cue the scene, and a line's tag must
## be one of [constant Remark.LINE_TAGS].

const _NAME: String = "[a-z_][a-z0-9_.]*"

static var _line_pattern: RegEx = RegEx.create_from_string(
		"^(%s)?\\s*:\\s*(.*?)(?:\\s*\\[([a-z_]+)\\])?$" % _NAME)
static var _choice_pattern: RegEx = RegEx.create_from_string(
		"^-\\s*(.+?)\\s*->\\s*([A-Za-z_][A-Za-z0-9_.]*)$")
static var _set_pattern: RegEx = RegEx.create_from_string(
		"^set\\s+(%s)(?:\\s*([+\\-=])\\s*(\\d+))?$" % _NAME)
static var _name_pattern: RegEx = RegEx.create_from_string("^%s$" % _NAME)
static var _tag_pattern: RegEx = RegEx.create_from_string("\\[([^\\]]*)\\]")


## Reads [param text] into a tree called [param id]. Set [param remarks] for a
## file of remarks rather than a conversation.
static func parse(text: String, id: StringName = &"", remarks: bool = false) -> DialogueTree:
	var tree: DialogueTree = DialogueTree.new()
	tree.id = id
	# The guard waiting for the statement after it.
	var guard: String = ""
	var is_else: bool = false
	var guard_line: int = 0
	var number: int = 0
	for raw: String in text.split("\n"):
		number += 1
		var line: String = raw.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("?"):
			if guard_line > 0:
				_error(tree, guard_line, "this ? has nothing after it to guard")
			guard = line.substr(1).strip_edges()
			is_else = guard == "else"
			guard_line = number
			if is_else:
				guard = ""
			else:
				var wrong: String = DialogueCondition.error_in(guard)
				if not wrong.is_empty():
					_error(tree, number, wrong)
			continue
		if line.begins_with("~"):
			var section_guard: String = ""
			if guard_line > 0:
				if remarks and not is_else:
					section_guard = guard
				elif remarks:
					_error(tree, guard_line, "a section can't be guarded by ? else")
				else:
					_error(tree, guard_line, "this ? has nothing after it to guard")
				guard_line = 0
			_begin_section(tree, line.substr(1).strip_edges(), number, remarks, section_guard)
			continue
		var step: DialogueStep = _read_statement(tree, line, number, remarks)
		if step == null:
			guard_line = 0
			continue
		if tree.sections.is_empty():
			tree.sections[DialogueTree.START] = 0
		step.line_number = number
		if guard_line > 0:
			step.guard = guard
			step.is_else = is_else
			guard_line = 0
		tree.steps.append(step)
	if guard_line > 0:
		_error(tree, guard_line, "this ? has nothing after it to guard")
	_end_section(tree)
	_check_targets(tree, remarks)
	return tree


# Starts a new section, closing the one before. [param header] is everything
# after the ~: the name, then any tags.
static func _begin_section(tree: DialogueTree, header: String, number: int, remarks: bool,
		guard: String) -> void:
	var name: String = header
	var tags_at: int = header.find("[")
	if tags_at >= 0:
		name = header.substr(0, tags_at).strip_edges()
	if _name_pattern.search(name) == null:
		_error(tree, number, "a section needs a name in lower case, like '~ start'")
		return
	if tree.sections.has(StringName(name)):
		_error(tree, number, "there's already a section called '%s'" % name)
		return
	_end_section(tree)
	tree.sections[StringName(name)] = tree.steps.size()
	if not guard.is_empty():
		tree.section_guards[StringName(name)] = guard
	if tags_at < 0:
		return
	if not remarks:
		_error(tree, number, "only a file of remarks has tags after a section's name")
		return
	var tags_text: String = header.substr(tags_at)
	if not _tag_pattern.sub(tags_text, "", true).strip_edges().is_empty():
		_error(tree, number, "can't read the tags '%s'. Each is written like [weight 2]"
				% tags_text)
		return
	var tags: PackedStringArray = PackedStringArray()
	for found: RegExMatch in _tag_pattern.search_all(tags_text):
		var words: PackedStringArray = found.get_string(1).strip_edges().split(" ", false)
		var tag: String = words[0] if not words.is_empty() else ""
		var value: String = " ".join(words.slice(1))
		var wrong: String = Remark.tag_error(tag, value)
		if not wrong.is_empty():
			_error(tree, number, wrong)
			continue
		tags.append("%s %s" % [tag, value])
	tree.section_tags[StringName(name)] = tags


# Sections don't run on into each other: each ends the conversation.
static func _end_section(tree: DialogueTree) -> void:
	if tree.steps.is_empty():
		return
	var end: DialogueStep = DialogueStep.new()
	end.kind = DialogueStep.Kind.JUMP
	end.target = DialogueStep.END
	tree.steps.append(end)


# Reads one statement, or notes an error and returns null.
static func _read_statement(tree: DialogueTree, line: String, number: int,
		remarks: bool) -> DialogueStep:
	var step: DialogueStep = DialogueStep.new()
	if line.begins_with("->"):
		step.kind = DialogueStep.Kind.JUMP
		step.target = StringName(line.substr(2).strip_edges())
		if step.target == &"":
			_error(tree, number, "-> needs a section to go to, or END")
			return null
		return step
	if line.begins_with("-"):
		if remarks:
			_error(tree, number, "a remark can't offer choices")
			return null
		var choice: RegExMatch = _choice_pattern.search(line)
		if choice == null:
			_error(tree, number, "a choice is written '- What you say -> section'")
			return null
		step.kind = DialogueStep.Kind.CHOICE
		step.text = choice.get_string(1)
		step.target = StringName(choice.get_string(2))
		return step
	if line.begins_with("@"):
		if remarks:
			_error(tree, number, "a remark can't cue the scene")
			return null
		var words: PackedStringArray = line.substr(1).split(" ", false)
		if words.is_empty():
			_error(tree, number, "@ needs a cue's name after it, like '@shot stove_nook'")
			return null
		step.kind = DialogueStep.Kind.CUE
		step.cue = StringName(words[0])
		step.args = words.slice(1)
		var wrong_cue: String = CueList.error_in(step.cue, step.args)
		if not wrong_cue.is_empty():
			_error(tree, number, wrong_cue)
			return null
		return step
	if line.begins_with("set ") or line == "set":
		var setting: RegExMatch = _set_pattern.search(line)
		if setting == null:
			_error(tree, number, "set is written 'set flag', 'set flag + 1' or 'set flag = 3'")
			return null
		step.kind = DialogueStep.Kind.SET
		step.flag = StringName(setting.get_string(1))
		var operator: String = setting.get_string(2)
		if not operator.is_empty():
			step.amount = setting.get_string(3).to_int()
		if operator == "+":
			step.change = DialogueStep.Change.BY
		elif operator == "-":
			step.change = DialogueStep.Change.BY
			step.amount = -step.amount
		return step
	if line.begins_with("clear ") or line == "clear":
		var flag: String = line.substr(5).strip_edges()
		if _name_pattern.search(flag) == null:
			_error(tree, number, "clear is written 'clear flag'")
			return null
		step.kind = DialogueStep.Kind.SET
		step.flag = StringName(flag)
		step.amount = 0
		return step
	var said: RegExMatch = _line_pattern.search(line)
	if said == null or said.get_string(2).is_empty():
		_error(tree, number, "can't read '%s'. A line is written 'speaker: words'" % line)
		return null
	step.kind = DialogueStep.Kind.LINE
	step.speaker = StringName(said.get_string(1))
	if step.speaker == DialogueStep.NARRATOR:
		step.speaker = &""
	step.text = said.get_string(2)
	step.tag = StringName(said.get_string(3))
	if remarks and step.tag != &"" and not Remark.LINE_TAGS.has(String(step.tag)):
		_error(tree, number, "a remark's line can be tagged [%s], not [%s]"
				% ["], [".join(Remark.LINE_TAGS), step.tag])
		return null
	return step


# Every jump and choice must lead to a section that exists, or to END. A
# conversation must have somewhere to start.
static func _check_targets(tree: DialogueTree, remarks: bool) -> void:
	if not remarks and not tree.steps.is_empty() and not tree.has_section(DialogueTree.START):
		tree.errors.append("there's no '~ start' section to begin at")
	for step: DialogueStep in tree.steps:
		if step.kind != DialogueStep.Kind.JUMP and step.kind != DialogueStep.Kind.CHOICE:
			continue
		if step.target != DialogueStep.END and not tree.has_section(step.target):
			_error(tree, step.line_number, "there's no section called '%s'" % step.target)


static func _error(tree: DialogueTree, number: int, message: String) -> void:
	tree.errors.append("line %d: %s" % [number, message])
