extends GameTestSuite
## Tests for the list of cues a script can give the scene: each is read when
## it's written properly, and a mistyped or miswritten one is a mistake that
## says how it should be written.


func test_every_cue_written_properly_is_fine() -> void:
	var fine: Array[String] = [
		"shot stove_nook", "shot stove_nook cut", "shot free", "shot free cut",
		"fade in", "fade out", "fade in 2.0", "fade out 0",
		"title Somewhere at sea", "title Home",
		"wait 1.5", "wait 0", "wait_for interact", "wait_for any",
		"wait_for interact Take his hand", "wait_for any Press any button",
		"place heron doorway", "face heron player",
		"hide heron", "show heron", "home heron",
		"stage underwater", "stage off", "play lantern_descends", "start drifting",
		"sound splash", "muffle on", "muffle off", "lightning",
		"look hook_lantern determined", "look lantern asleep", "look lantern fogged",
		"look lantern mended", "who_are_you",
	]
	for written: String in fine:
		assert_str(_error(written)).override_failure_message("@%s" % written).is_empty()


func test_a_cue_written_wrongly_says_how_its_written() -> void:
	var wrong: Array[String] = [
		"shot", "shot stove_nook slowly", "shot a b c",
		"fade", "fade sideways", "fade in soon", "fade in -1", "fade in 1 2",
		"title",
		"wait", "wait a moment", "wait -2", "wait 1 2",
		"wait_for", "wait_for ages", "wait_for ages Take his hand",
		"place heron", "place heron doorway now", "face heron",
		"hide", "show heron now", "home",
		"stage", "stage a b", "play", "play a b", "start", "sound", "sound a b",
		"muffle", "muffle half", "muffle on now", "lightning now",
		"look", "look lantern", "look lantern grumpy", "look lantern calm now",
		"who_are_you now",
	]
	for written: String in wrong:
		var cue: String = written.split(" ")[0]
		assert_str(_error(written)).override_failure_message("@%s" % written) \
				.contains(CueList.USAGE[StringName(cue)])


func test_a_cue_that_doesnt_exist_lists_the_ones_that_do() -> void:
	var error: String = _error("fdae in 2.0")

	assert_str(error).contains("@fdae")
	for cue: StringName in CueList.USAGE:
		assert_str(error).contains("@%s" % cue)


func test_every_cue_says_how_its_written() -> void:
	for cue: StringName in CueList.USAGE:
		assert_str(CueList.USAGE[cue]).contains("@%s" % cue)


# What's wrong with a cue written as [param written], without its @.
func _error(written: String) -> String:
	var words: PackedStringArray = written.split(" ", false)
	return CueList.error_in(StringName(words[0]), words.slice(1))
