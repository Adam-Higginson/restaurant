extends GameTestSuite
## Tests for the names a build goes by: its label on the title, its version,
## its release tag and its zips.


func test_a_build_is_named_by_its_day_and_commit() -> void:
	assert_str(BuildInfo.label_for("2026.11.23", "a1b2c3d")).is_equal("2026.11.23 (a1b2c3d)")


func test_without_a_version_its_dev() -> void:
	assert_str(BuildInfo.label_for("", "a1b2c3d")).is_equal(BuildInfo.DEV)
	assert_str(BuildInfo.label_for("", "")).is_equal("dev")


func test_without_a_commit_its_just_the_day() -> void:
	assert_str(BuildInfo.label_for("2026.11.23", "")).is_equal("2026.11.23")


func test_run_from_the_project_its_dev() -> void:
	# Only the publish workflow stamps a version, and never commits it.
	assert_str(BuildInfo.label()).is_equal("dev")


func test_the_version_is_the_day_padded() -> void:
	var date: Dictionary = {"year": 2027, "month": 3, "day": 7}
	assert_str(BuildInfo.version_for(date)).is_equal("2027.03.07")


func test_the_tag_and_zips_carry_the_same_names() -> void:
	assert_str(BuildInfo.tag_for("2026.11.23", "a1b2c3d")).is_equal("build-2026.11.23-a1b2c3d")
	assert_str(BuildInfo.zip_name("2026.11.23", "a1b2c3d", "macos")) \
			.is_equal("SaltAndEmber-2026.11.23-a1b2c3d-macos.zip")


func test_the_names_are_written_for_a_shell_script() -> void:
	var env: String = BuildInfo.env_for("2026.11.23", "a1b2c3d")
	var lines: PackedStringArray = env.strip_edges().split("\n")

	assert_array(Array(lines)).contains([
		"VERSION='2026.11.23'",
		"COMMIT='a1b2c3d'",
		"LABEL='2026.11.23 (a1b2c3d)'",
		"TAG='build-2026.11.23-a1b2c3d'",
		"WINDOWS_ZIP='SaltAndEmber-2026.11.23-a1b2c3d-windows.zip'",
		"MACOS_ZIP='SaltAndEmber-2026.11.23-a1b2c3d-macos.zip'",
	])
	assert_int(lines.size()).is_equal(6)
