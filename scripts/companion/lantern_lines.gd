class_name LanternLines
extends RefCounted
## What the lantern says, and when. He's cheerful, and cheerfully wrong about
## where home is; underneath, a little tender (see the Story in the GDD).
## Each moment has a few lines; one is picked at random, never the same one
## twice in a row.

## A memory of home has just come back.
const REMEMBERED: PackedStringArray = [
	"Was that home? It sounded like home.",
	"Oh! Say it again. Slower.",
	"I think I remember that too. I don't. But I'd like to.",
	"Hold on to that one.",
]
## You've landed a fish.
const CAUGHT: PackedStringArray = [
	"A fish! Is home a fish? ...No. Probably not.",
	"That one looked like it knew the way.",
	"Supper! I'll watch. I'm very good at watching.",
]
## You've woken at dawn.
const MORNING: PackedStringArray = [
	"Morning! Did you sleep? I don't. I just glow quieter.",
	"The rain's tired too, I think.",
	"Look, it's grey and pink. That's my favourite colour.",
]
## You've stopped the ship at the bell.
const HOVE_TO: PackedStringArray = [
	"Stopping? Good. I like it when the sea holds still.",
	"The fish will come now. Fish like quiet.",
]
## You're at the bow at night, looking towards the far light.
const FAR_LIGHT: PackedStringArray = [
	"A light! That's it. That's home. Probably. Almost certainly. Maybe.",
	"If it isn't home, it's very good at pretending.",
	"Somebody's keeping that light lit. For somebody.",
]

static var _last: String = ""


## One of [param lines], not the same as the last one picked (if it can help it).
static func pick(lines: PackedStringArray) -> String:
	if lines.is_empty():
		return ""
	var line: String = lines[randi_range(0, lines.size() - 1)]
	if line == _last and lines.size() > 1:
		line = lines[(lines.find(line) + 1) % lines.size()]
	_last = line
	return line
