extends GameTestSuite
## Tests for KilnReport: every fired model against its look's budgets.

const STAND_IN: String = "res://tests/fixtures/box_model.tscn"

var _scratch: String = "user://test_kiln_report%s/" % OS.get_environment("TEST_SHARD")


func before_test() -> void:
	KilnJob.out_root = _scratch


func after_test() -> void:
	KilnJob.out_root = KilnJob.OUT_ROOT
	for file: String in DirAccess.get_files_at(_scratch):
		DirAccess.remove_absolute(_scratch.path_join(file))
	DirAccess.remove_absolute(_scratch)


func test_a_model_within_budget_is_ok() -> void:
	var job: KilnJob = _fired({"triangles": 150.0, "pixels_per_metre": 66.0, "texture": 32.0})
	assert_array(Array(KilnReport.problems(job))).is_empty()


func test_an_unfired_model_says_so() -> void:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_array(Array(KilnReport.problems(job))).contains_exactly(["not fired"])


func test_too_many_triangles_is_over_budget() -> void:
	var job: KilnJob = _fired({"triangles": 200.0, "pixels_per_metre": 64.0, "texture": 32.0})
	assert_array(Array(KilnReport.problems(job))).contains(["over budget"])


func test_pixels_far_from_the_looks_size_are_flagged() -> void:
	var coarse: KilnJob = _fired({"triangles": 10.0, "pixels_per_metre": 30.0, "texture": 32.0})
	assert_array(Array(KilnReport.problems(coarse))).contains(["pixels too big"])
	var capped: KilnJob = _fired({"triangles": 10.0, "pixels_per_metre": 30.0, "texture": 128.0})
	assert_array(Array(KilnReport.problems(capped))) \
			.contains(["pixels too big (texture at its cap)"])
	var fine: KilnJob = _fired({"triangles": 10.0, "pixels_per_metre": 100.0, "texture": 32.0})
	assert_array(Array(KilnReport.problems(fine))).contains(["pixels too small"])


func test_a_bone_with_nothing_to_move_is_flagged_but_not_fingers() -> void:
	var job: KilnJob = _fired({"triangles": 10.0, "pixels_per_metre": 64.0, "texture": 32.0,
			"bones_lost": ["middle_03_l", "neck_01"]})
	assert_array(Array(KilnReport.problems(job))) \
			.contains_exactly(["bone neck_01 has nothing to move"])


func test_the_table_has_a_row_per_model() -> void:
	var jobs: Array[KilnJob] = [
		_fired({"triangles": 150.0, "pixels_per_metre": 66.0, "texture": 32.0}),
	]
	var table: String = KilnReport.table(jobs)
	assert_str(table).contains("| box_model | test | 150 (160) | 32 px | 66 (64) | ok |")
	assert_int(KilnReport.count_problems(jobs)).is_equal(0)


# A look like the prop preset, named "test".
func _look() -> ArtLook:
	var look: ArtLook = ArtLook.new()
	look.resource_name = "test"
	look.triangles = 160
	look.pixels_per_metre = 64.0
	look.max_texture = 128
	return look


# A job whose fired model was made as [param made] says, with this job's
# fingerprint (so it isn't stale).
func _fired(made: Dictionary) -> KilnJob:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	made["fingerprint"] = job.fingerprint()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_scratch))
	var file: FileAccess = FileAccess.open(job.report_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(made))
	file.close()
	return job
