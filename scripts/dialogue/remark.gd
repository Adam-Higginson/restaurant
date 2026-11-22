class_name Remark
extends RefCounted
## Something said in passing: one section of a file of remarks in
## [code]data/dialogue[/code], a single line or a short exchange. Nobody stops
## to talk; the words float up in speech bubbles (see [Speaker]) and you
## overhear them.
##
## How often and when a remark comes up is written in its section's header
## (see [DialogueScript]):
## [codeblock]
## ? night and not raining              its guard: said only when this holds
## ~ stove_drawing [weight 2] [cooldown 180] [priority 1]
## ~ caught_1 [on caught]               said when the game says "caught"
## [/codeblock]
## The [Chatter] picks remarks with no [code]on[/code] to fill quiet moments;
## the ones with an [code]on[/code] are the lantern's reactions to things you
## do (see [method LanternSpirit.tell]).

## The tags a remark's line may have, each a style of bubble.
const LINE_TAGS: PackedStringArray = ["thought", "shout", "sound"]
## How long before a remark can be said again, in seconds, unless its header
## says otherwise. Reactions ([member moment]) can be said again straight away.
const DEFAULT_COOLDOWN: float = 120.0

## The tree it's in.
var tree: DialogueTree = null
## Its section's name.
var section: StringName = &""
## Who says it, each a [member Person.id], in the order they first speak.
var speakers: Array[StringName] = []
## The condition it's said under, as written, or "" for always.
var guard: String = ""
## How likely it is to be picked, against the others: 2 is twice as likely as 1.
var weight: int = 1
## Seconds before it can be said again.
var cooldown: float = DEFAULT_COOLDOWN
## When several can be said, only the ones with the highest priority are
## picked from.
var priority: int = 0
## What it's a reaction to (&"caught"), or &"" if it's just chatter.
var moment: StringName = &""

## Tells one remark from all the others in every file: "ambient/stove_drawing".
var key: String:
	get:
		return "%s/%s" % [tree.id if tree != null else &"", section]


## Every remark in [param tree], in the order written.
static func all_in(tree: DialogueTree) -> Array[Remark]:
	var found: Array[Remark] = []
	if tree == null:
		return found
	for section: StringName in tree.sections:
		found.append(from_section(tree, section))
	return found


## The remark in [param tree]'s [param section], read from its header.
static func from_section(tree: DialogueTree, section: StringName) -> Remark:
	var remark: Remark = Remark.new()
	remark.tree = tree
	remark.section = section
	if tree.section_guards.has(section):
		remark.guard = tree.section_guards[section]
	var tags: PackedStringArray = PackedStringArray()
	if tree.section_tags.has(section):
		tags = tree.section_tags[section]
	var cooldown_set: bool = false
	for tag: String in tags:
		var value: String = tag.get_slice(" ", 1)
		match tag.get_slice(" ", 0):
			"weight":
				remark.weight = value.to_int()
			"cooldown":
				remark.cooldown = value.to_float()
				cooldown_set = true
			"priority":
				remark.priority = value.to_int()
			"on":
				remark.moment = StringName(value)
	if remark.moment != &"" and not cooldown_set:
		remark.cooldown = 0.0
	for step: DialogueStep in steps_of(tree, section):
		if step.kind == DialogueStep.Kind.LINE and step.speaker != &"" \
				and not remark.speakers.has(step.speaker):
			remark.speakers.append(step.speaker)
	return remark


## The steps written in [param tree]'s [param section], up to the next section.
static func steps_of(tree: DialogueTree, section: StringName) -> Array[DialogueStep]:
	var found: Array[DialogueStep] = []
	if not tree.has_section(section):
		return found
	var first: int = tree.sections[section]
	var last: int = tree.steps.size()
	for other: StringName in tree.sections:
		var start: int = tree.sections[other]
		if start > first and start < last:
			last = start
	for index: int in range(first, last):
		found.append(tree.steps[index])
	return found


## What's wrong with a section's tag called [param tag] with [param value],
## or "" if it's fine.
static func tag_error(tag: String, value: String) -> String:
	match tag:
		"weight":
			if not value.is_valid_int() or value.to_int() < 1:
				return "[weight] needs a whole number from 1, like [weight 2]"
		"cooldown":
			if not value.is_valid_int() or value.to_int() < 0:
				return "[cooldown] needs a number of seconds, like [cooldown 90]"
		"priority":
			if not value.is_valid_int():
				return "[priority] needs a whole number, like [priority 1]"
		"on":
			if value.is_empty() or value.contains(" ") \
					or DialogueCondition.error_in(value) != "":
				return "[on] needs the name of a moment, like [on caught]"
		_:
			return "a section can't have the tag [%s]. Use weight, cooldown, priority or on" \
					% tag
	return ""
