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
## You've shared a meal with him.
const SUPPER: PackedStringArray = [
	"Oh, that's warm all the way through.",
	"Mm. Tastes like a Tuesday. A good one.",
	"I'm glowing. Am I glowing? I'm glowing.",
	"You cook like someone who's been missed.",
]
## His warmth is running low.
const DIM: PackedStringArray = [
	"I'm a bit... dim. Is there soup?",
	"Is it me, or is it darker in here? It's me, isn't it.",
]
## You're at the bow at night, looking towards the far light.
const FAR_LIGHT: PackedStringArray = [
	"A light! That's it. That's home. Probably. Almost certainly. Maybe.",
	"If it isn't home, it's very good at pretending.",
	"Somebody's keeping that light lit. For somebody.",
]

## You've come back to a saved voyage.
const WELCOME_BACK: PackedStringArray = [
	"You're back. I kept the light on.",
	"There you are again. I didn't go anywhere. I can't, really.",
]
## You're at the bow at dawn, and the island has come out of the mist.
const ISLAND: PackedStringArray = [
	"There! An island. With a lighthouse. Lighthouses are for people who are lost. So, us.",
	"That's where the light lives. I knew it. I didn't, but I knew it.",
	"Do you think it remembers you? Islands are very good at remembering.",
]
## A fog-crab has beaten you, and he's pulled you back to the landing.
const PULLED_OUT: PackedStringArray = [
	"Got you! I've got you. You dropped some things. I didn't count.",
	"Up you come. It didn't mean it. It's the fog that pinches.",
	"That's twice I've pulled you out of somewhere. I'm keeping score. Kindly.",
]
## You've cleared the fog from a creature.
const FOG_CLEARED: PackedStringArray = [
	"Look at it go! It only wanted its head clear.",
	"There. All shaken off. It'll remember being a crab now.",
	"Oh, well done. Gently done.",
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
