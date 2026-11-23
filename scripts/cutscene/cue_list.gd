class_name CueList
extends RefCounted
## Every cue a script can give the scene (the lines that start with @), and
## how each is written. [DialogueScript] checks a script's cues against this
## as it reads, so a mistyped one is reported with its line number instead of
## quietly doing nothing.
##
## Each cue is acted on by a [CueHandler] in the scene. To add a new cue,
## write its handler and add a line here.

## How each cue is written, by name. Shown when a script gets one wrong.
const USAGE: Dictionary[StringName, String] = {
	&"shot": "@shot stove_nook or @shot free, with 'cut' after to cut instead of glide",
	&"fade": "@fade out or @fade in, with seconds after if you like: @fade in 2.0",
	&"title": "@title Somewhere at sea",
	&"wait": "@wait 1.5",
	&"wait_for": "@wait_for interact or @wait_for any, with a prompt after if you like: "
			+ "@wait_for interact Take his hand",
	&"place": "@place heron doorway",
	&"face": "@face heron player",
	&"hide": "@hide heron",
	&"show": "@show heron",
	&"home": "@home heron",
	&"go": "@go lantern room_middle (the lantern floats to a mark and stays)",
	&"stage": "@stage underwater or @stage off",
	&"play": "@play lantern_descends",
	&"start": "@start drifting",
	&"queue": "@queue offered (to follow the clip that's playing now)",
	&"say": "@say lantern 2.0 Someone in the water! (who, seconds it's up for, the words)",
	&"say_in": "@say_in 3.5 lantern 2.0 Come on. (seconds until, who, seconds it's up for, "
			+ "the words)",
	&"sound": "@sound splash",
	&"muffle": "@muffle on or @muffle off",
	&"hush": "@hush on or @hush off",
	&"lightning": "@lightning",
	&"look": "@look hook_lantern determined (a look for his eyes: calm, surprised, "
			+ "determined, worried, pleading, effort, tired, asleep, pleased; or for his "
			+ "glass: fogged, clear, streaked, dry, cracked, mended)",
	&"who_are_you": "@who_are_you (asks a boy or a girl, and waits for the answer)",
}


## What's wrong with the cue [param cue] followed by the words [param args],
## or "" if it's written properly.
static func error_in(cue: StringName, args: PackedStringArray) -> String:
	if not USAGE.has(cue):
		var names: PackedStringArray = PackedStringArray()
		for known: StringName in USAGE:
			names.append("@%s" % known)
		return "there's no cue called '@%s'. The cues are: %s" % [cue, ", ".join(names)]
	if not _fits(cue, args):
		return "can't read this @%s. It's written like: %s" % [cue, USAGE[cue]]
	return ""


# Whether the words after a cue are the ones it takes.
static func _fits(cue: StringName, args: PackedStringArray) -> bool:
	match cue:
		&"shot":
			return args.size() == 1 or (args.size() == 2 and args[1] == "cut")
		&"fade":
			if args.is_empty() or args.size() > 2 or not ["in", "out"].has(args[0]):
				return false
			return args.size() == 1 or _is_seconds(args[1])
		&"title":
			return not args.is_empty()
		&"wait":
			return args.size() == 1 and _is_seconds(args[0])
		&"wait_for":
			return not args.is_empty() and ["interact", "any"].has(args[0])
		&"place", &"face", &"go":
			return args.size() == 2
		&"hide", &"show", &"home", &"stage", &"play", &"start", &"queue", &"sound":
			return args.size() == 1
		&"say":
			return args.size() >= 3 and _is_seconds(args[1])
		&"say_in":
			return args.size() >= 4 and _is_seconds(args[0]) and _is_seconds(args[2])
		&"muffle", &"hush":
			return args.size() == 1 and ["on", "off"].has(args[0])
		&"lightning", &"who_are_you":
			return args.is_empty()
		&"look":
			return args.size() == 2 and LanternFace.knows(args[1])
	return false


static func _is_seconds(word: String) -> bool:
	return word.is_valid_float() and word.to_float() >= 0.0
