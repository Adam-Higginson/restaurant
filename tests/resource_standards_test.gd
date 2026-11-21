extends GameTestSuite
## Guards our shader materials against the editor stripping them.
##
## When the editor opened the project, it re-saved shader materials that had
## no uid in their header. If their shader hadn't compiled yet at that moment
## (the [code]wetness[/code] global reported missing), Godot saved them with
## no shader parameters, and their textures vanished. A uid in the header
## means there's nothing to re-save, and the parameter check catches a stripped
## material before it's committed.

const MATERIAL_DIRS: Array[String] = ["res://assets/placeholder"]


func test_every_shader_material_has_a_uid_in_its_header() -> void:
	var missing: Array[String] = []
	for path: String in _shader_material_files():
		if not _header(path).contains("uid=\"uid://"):
			missing.append(path)
	assert_array(missing).override_failure_message(
		"Shader materials with no uid in their header (the editor re-saves these "
		+ "on open and can strip them): %s" % [missing]
	).is_empty()


func test_no_shader_material_has_lost_its_parameters() -> void:
	var paths: Array[String] = _shader_material_files()
	assert_array(paths).is_not_empty()
	var stripped: Array[String] = []
	for path: String in paths:
		if not FileAccess.get_file_as_string(path).contains("shader_parameter/"):
			stripped.append(path)
	assert_array(stripped).override_failure_message(
		"Shader materials saved with no shader parameters: %s" % [stripped]
	).is_empty()


func _shader_material_files() -> Array[String]:
	var paths: Array[String] = []
	for dir: String in MATERIAL_DIRS:
		_collect(dir, paths)
	return paths


func _collect(dir: String, out: Array[String]) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for file: String in DirAccess.get_files_at(dir):
		var path: String = dir.path_join(file)
		if file.ends_with(".tres") and _header(path).contains("type=\"ShaderMaterial\""):
			out.append(path)
	for sub: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), out)


func _header(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	return file.get_line()
