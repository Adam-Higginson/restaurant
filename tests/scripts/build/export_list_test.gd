extends GameTestSuite
## Tests for which files go into a build: ours, the pack files the game
## names by path, never the tests or tools.


func test_finds_pack_paths_named_in_a_scene() -> void:
	var text: String = "\n".join([
		"[ext_resource type=\"Script\" path=\"res://scripts/player.gd\" id=\"1\"]",
		"outfit = \"res://assets/third_party/quaternius/Outfits [Standard]/Male_Peasant.gltf\"",
		"files = PackedStringArray(\"res://assets/third_party/ual/A.glb\", "
				+ "\"res://assets/third_party/ual/B.glb\")",
	])

	assert_array(Array(ExportList.named_in(text))).contains_exactly([
		"res://assets/third_party/quaternius/Outfits [Standard]/Male_Peasant.gltf",
		"res://assets/third_party/ual/A.glb",
		"res://assets/third_party/ual/B.glb",
	])


func test_a_path_named_twice_is_listed_once() -> void:
	var text: String = "\"res://assets/third_party/a.ogg\" and again \"res://assets/third_party/a.ogg\""

	assert_array(Array(ExportList.named_in(text))).contains_exactly(["res://assets/third_party/a.ogg"])


func test_tests_tools_and_packs_are_left_out() -> void:
	assert_bool(ExportList.is_left_out("res://tests/game_test_suite.gd")).is_true()
	assert_bool(ExportList.is_left_out("res://tools/build/prepare_export.gd")).is_true()
	assert_bool(ExportList.is_left_out("res://addons/gdUnit4/plugin.cfg")).is_true()
	assert_bool(ExportList.is_left_out("res://assets/third_party/meshy/heron/heron.glb")).is_true()
	assert_bool(ExportList.is_left_out("res://scenes/prototype/sea.tscn")).is_false()
	# A folder that only starts the same isn't left out.
	assert_bool(ExportList.is_left_out("res://testsuite.gd")).is_false()


func test_the_list_has_the_game_and_none_of_the_tests() -> void:
	var listed: PackedStringArray = ExportList.build()

	assert_bool(listed.has(str(ProjectSettings.get_setting("application/run/main_scene")))).is_true()
	assert_bool(listed.has("res://scripts/build/export_list.gd")).is_true()
	assert_bool(listed.has("res://ui/build_tag.tscn")).is_true()
	for path: String in listed:
		assert_bool(path.begins_with("res://tests/") or path.begins_with("res://tools/")) \
				.override_failure_message("%s shouldn't be exported" % path).is_false()
