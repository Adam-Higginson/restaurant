class_name DialogueCondition
extends RefCounted
## Reads the conditions written after a [code]?[/code] in a dialogue script,
## and answers them from a [DialogueState].
##
## A condition is one or more checks joined by [code]and[/code]. A check is
## [code]name[/code] (set, not 0), [code]not name[/code], or a comparison
## with a whole number: [code]visits >= 2[/code], [code]day == 1[/code].

const COMPARISONS: PackedStringArray = ["==", "!=", "<=", ">=", "<", ">"]


## Whether [param condition] holds for [param state]. An empty condition
## always holds; one that can't be read never does.
static func holds(condition: String, state: DialogueState) -> bool:
	for check: String in _checks(condition):
		var words: PackedStringArray = check.split(" ", false)
		if not _is_well_formed(words):
			return false
		if not _check_holds(words, state):
			return false
	return true


## What's wrong with [param condition] as written, or "" if it reads fine.
static func error_in(condition: String) -> String:
	if condition.strip_edges().is_empty():
		return "a ? needs a condition after it"
	for check: String in _checks(condition):
		var words: PackedStringArray = check.split(" ", false)
		if not _is_well_formed(words):
			return "can't read the condition '%s'" % check.strip_edges()
	return ""


# The checks of a condition: the parts between each "and".
static func _checks(condition: String) -> PackedStringArray:
	var padded: String = " %s " % condition.strip_edges()
	var checks: PackedStringArray = PackedStringArray()
	for part: String in padded.split(" and "):
		if not part.strip_edges().is_empty() or padded.contains(" and "):
			checks.append(part.strip_edges())
	return checks


static func _is_well_formed(words: PackedStringArray) -> bool:
	match words.size():
		1:
			return _is_name(words[0])
		2:
			return words[0] == "not" and _is_name(words[1])
		3:
			return _is_name(words[0]) and COMPARISONS.has(words[1]) and words[2].is_valid_int()
	return false


static func _check_holds(words: PackedStringArray, state: DialogueState) -> bool:
	if words.size() == 1:
		return state.is_set(StringName(words[0]))
	if words.size() == 2:
		return not state.is_set(StringName(words[1]))
	var have: int = state.value(StringName(words[0]))
	var want: int = words[2].to_int()
	match words[1]:
		"==":
			return have == want
		"!=":
			return have != want
		"<=":
			return have <= want
		">=":
			return have >= want
		"<":
			return have < want
		">":
			return have > want
	return false


# Names are lower-case words, digits, underscores and dots: talked.heron.
static func _is_name(word: String) -> bool:
	if word.is_empty() or word == "not" or word == "and" or word == "else":
		return false
	for letter: String in word:
		if not (letter >= "a" and letter <= "z") and not letter.is_valid_int() \
				and letter != "_" and letter != ".":
			return false
	return not word[0].is_valid_int()
