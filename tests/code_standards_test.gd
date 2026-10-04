extends GdUnitTestSuite
## Loads every project script so CI fails if any of them breaks the GDScript
## warnings set as errors in project settings (e.g. an untyped variable).

const SCRIPT_DIRS: Array[String] = ["res://scripts", "res://ui", "res://tests"]


func test_all_project_scripts_compile() -> void:
	var paths: Array[String] = []
	for dir: String in SCRIPT_DIRS:
		_collect_scripts(dir, paths)
	assert_array(paths).is_not_empty()

	var broken: Array[String] = []
	for path: String in paths:
		var script: GDScript = load(path) as GDScript
		if script == null or not script.can_instantiate():
			broken.append(path)
	assert_array(broken).override_failure_message(
		"Scripts failed to compile (see the parse errors above): %s" % [broken]
	).is_empty()


func _collect_scripts(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		_collect_scripts(dir.path_join(sub), out)
