extends GameTestSuite
## Checks the fallback from a missing whole-character asset.


func test_a_whole_character_whose_file_is_missing_is_not_whole() -> void:
	var parts: CharacterParts = CharacterParts.new()
	parts.whole = "res://assets/third_party/no_such_pack/nobody.glb"
	assert_bool(parts.is_whole()).is_false()
	# So the look falls back to its pack parts, and is only complete if
	# those are there.
	assert_bool(parts.is_complete()).is_false()


func test_a_look_with_no_whole_character_is_not_whole() -> void:
	assert_bool(CharacterParts.new().is_whole()).is_false()
