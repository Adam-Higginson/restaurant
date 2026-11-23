extends GameTestSuite
## Tests for Kiln: how Blender is found and started. Blender itself isn't
## run here (CI hasn't got it); firing is checked by eye with the Lookbook.

var _blender_before: String = ""


func before_test() -> void:
	_blender_before = OS.get_environment("BLENDER")


func after_test() -> void:
	OS.set_environment("BLENDER", _blender_before)


func test_blender_is_found_where_it_usually_is() -> void:
	OS.set_environment("BLENDER", "")
	assert_str(Kiln.blender()).is_equal(Kiln.DEFAULT_BLENDER)


func test_the_blender_variable_says_where_else_it_is() -> void:
	OS.set_environment("BLENDER", "D:/tools/blender.exe")
	assert_str(Kiln.blender()).is_equal("D:/tools/blender.exe")


func test_without_blender_it_says_so() -> void:
	OS.set_environment("BLENDER", "res://no/such/blender.exe")
	assert_bool(Kiln.has_blender()).is_false()


func test_blender_runs_the_firing_script_on_the_job_quietly() -> void:
	var arguments: PackedStringArray = Kiln.arguments("C:/jobs/pot.job.json")
	assert_array(Array(arguments)).contains_exactly(["-b", "--factory-startup", "--python",
			ProjectSettings.globalize_path(Kiln.SCRIPT), "--", "C:/jobs/pot.job.json"])


func test_the_firing_script_is_there() -> void:
	assert_bool(FileAccess.file_exists(Kiln.SCRIPT)).is_true()


func test_nothing_starts_without_the_pack_file() -> void:
	var job: KilnJob = KilnJob.new("res://no_such_model.glb", ArtLook.new())
	assert_int(Kiln.start(job)).is_equal(-1)
	assert_bool(Kiln.run(job)).is_false()


func test_firing_nothing_in_the_background_finishes_at_once() -> void:
	var job: KilnJob = KilnJob.new("res://no_such_model.glb", ArtLook.new())
	var jobs: Array[KilnJob] = [job]
	var fresh: int = await Kiln.fire_in_background(jobs)
	assert_int(fresh).is_equal(0)


func test_outside_the_editor_nothing_is_imported() -> void:
	assert_bool(Kiln.import_in_editor(KilnJob.new())).is_false()
