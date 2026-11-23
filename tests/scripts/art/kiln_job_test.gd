extends GameTestSuite
## Tests for KilnJob: where a fired model goes, whether it's stale, and the
## job file handed to Blender.
##
## Reports are written to a folder of this test copy's own under user://.

const POT: String = "res://assets/third_party/kaykit_restaurant/Assets/gltf/pot_A.gltf"
const STAND_IN: String = "res://tests/fixtures/box_model.tscn"

var _scratch: String = "user://test_kiln%s/" % OS.get_environment("TEST_SHARD")


func after_test() -> void:
	KilnJob.out_root = KilnJob.OUT_ROOT
	KilnJob.fired_extension = "glb"
	_clear(_scratch)


func test_fired_files_mirror_the_packs_under_the_kiln_folder() -> void:
	var job: KilnJob = KilnJob.new(POT, load("res://data/art/looks/prop.tres") as ArtLook)
	var stem: String = "res://assets/third_party/_kiln/kaykit_restaurant/Assets/gltf/pot_A.prop"
	assert_str(job.fired_path()).is_equal(stem + ".glb")
	assert_str(job.texture_path()).is_equal(stem + ".png")
	assert_str(job.report_path()).is_equal(stem + ".glb.kiln.json")


func test_a_model_outside_the_packs_goes_by_its_file_name() -> void:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_str(job.fired_path()).is_equal("res://assets/third_party/_kiln/box_model.test.glb")


func test_each_size_a_model_is_fitted_to_gets_its_own_fired_files() -> void:
	var small: KilnJob = KilnJob.new(STAND_IN, _look())
	small.fit_size = Vector3(0.3, 0.2, 0.3)
	var big: KilnJob = KilnJob.new(STAND_IN, _look())
	big.fit_size = Vector3(0.6, 0.4, 0.6)
	var again: KilnJob = KilnJob.new(STAND_IN, _look())
	again.fit_size = Vector3(0.3, 0.2, 0.3)
	assert_str(small.fired_path()).is_not_equal(big.fired_path())
	assert_str(small.fired_path()).is_equal(again.fired_path())
	assert_str(small.fired_path()).starts_with("res://assets/third_party/_kiln/box_model.test.")


func test_a_second_firing_of_a_model_gets_its_own_files() -> void:
	var usual: KilnJob = KilnJob.new(STAND_IN, _look())
	var asleep: KilnJob = KilnJob.new(STAND_IN, _look())
	asleep.variant = "asleep"
	assert_str(asleep.fired_path()).is_equal("res://assets/third_party/_kiln/box_model.test.asleep.glb")
	assert_str(asleep.texture_path()).is_equal("res://assets/third_party/_kiln/box_model.test.asleep.png")
	assert_str(asleep.fired_path()).is_not_equal(usual.fired_path())


func test_it_can_fire_only_with_a_look_and_every_file() -> void:
	assert_bool(KilnJob.new(STAND_IN, null).can_fire()).is_false()
	assert_bool(KilnJob.new("res://no_such_model.glb", _look()).can_fire()).is_false()
	assert_bool(KilnJob.new(STAND_IN, _look()).can_fire()).is_true()
	var with_missing: KilnJob = KilnJob.new(STAND_IN, _look())
	with_missing.sources.append("res://no_such_eyebrows.glb")
	assert_bool(with_missing.can_fire()).is_false()


func test_the_fingerprint_follows_everything_that_changes_the_model() -> void:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	var first: String = job.fingerprint()
	assert_str(KilnJob.new(STAND_IN, _look()).fingerprint()).is_equal(first)
	job.look.triangles = 99
	assert_str(job.fingerprint()).is_not_equal(first)
	var tinted: KilnJob = KilnJob.new(STAND_IN, _look())
	tinted.tints = [Color.RED]
	assert_str(tinted.fingerprint()).is_not_equal(first)
	var bigger: KilnJob = KilnJob.new(STAND_IN, _look())
	bigger.fit_size = Vector3.ONE
	assert_str(bigger.fingerprint()).is_not_equal(first)


func test_drawing_settings_dont_make_it_stale() -> void:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	var first: String = job.fingerprint()
	job.look.roughness = 0.1
	job.look.faceted = false
	assert_str(job.fingerprint()).is_equal(first)


func test_it_is_stale_until_fired_with_these_settings() -> void:
	KilnJob.out_root = _scratch
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_bool(job.is_stale()).is_true()
	_write_report(job, {"fingerprint": job.fingerprint(), "triangles": 40.0})
	assert_bool(job.is_stale()).is_false()
	job.look.triangles = 20
	assert_bool(job.is_stale()).is_true()


func test_it_reads_what_was_made() -> void:
	KilnJob.out_root = _scratch
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_bool(job.report().is_empty()).is_true()
	_write_report(job, {"fingerprint": job.fingerprint(), "triangles": 40.0,
			"source_triangles": 300.0, "texture": 32.0, "pixels_per_metre": 63.6})
	assert_str(job.status()).is_equal(
			"Fired: 40 triangles (from 300), 32 px texture, 64 px per metre")


func test_its_status_says_what_to_do_next() -> void:
	KilnJob.out_root = _scratch
	assert_str(KilnJob.new(STAND_IN, null).status()).starts_with("No look")
	assert_str(KilnJob.new("res://no_such_model.glb", _look()).status()) \
			.starts_with("Pack file missing")
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_str(job.status()).starts_with("Not fired yet")
	_write_report(job, {"fingerprint": "older"})
	assert_str(job.status()).starts_with("Stale")


func test_the_job_file_gives_blender_full_paths() -> void:
	KilnJob.out_root = _scratch
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	job.keep_bones = ["Head"]
	var written: String = job.write()
	assert_str(written).is_equal(ProjectSettings.globalize_path(job.job_path()))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(job.job_path()))
	assert_bool(parsed is Dictionary).is_true()
	var file: Dictionary = parsed
	var sources: Array = file["sources"]
	assert_str(str(sources[0])).is_equal(ProjectSettings.globalize_path(STAND_IN))
	assert_str(str(file["out"])).is_equal(ProjectSettings.globalize_path(job.fired_path()))
	assert_str(str(file["out_png"])).is_equal(ProjectSettings.globalize_path(job.texture_path()))
	assert_str(str(file["fingerprint"])).is_equal(job.fingerprint())
	var keep: Array = file["keep_bones"]
	assert_str(str(keep[0])).is_equal("Head")
	assert_bool(file.has("triangles")).is_true()


func test_it_is_fired_when_the_model_and_texture_are_there() -> void:
	var job: KilnJob = KilnJob.new(STAND_IN, _look())
	assert_bool(job.is_fired()).is_false()
	KilnJob.out_root = "res://tests/fixtures/kiln/"
	KilnJob.fired_extension = "tscn"
	assert_bool(job.is_fired()).is_true()


# A look named "test", matching the stand-in fired files' names.
func _look() -> ArtLook:
	var look: ArtLook = ArtLook.new()
	look.resource_name = "test"
	return look


func _write_report(job: KilnJob, report: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(
			job.report_path().get_base_dir()))
	var file: FileAccess = FileAccess.open(job.report_path(), FileAccess.WRITE)
	file.store_string(JSON.stringify(report))
	file.close()


func _clear(folder: String) -> void:
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null:
		return
	for file: String in dir.get_files():
		dir.remove(file)
	for inner: String in dir.get_directories():
		_clear(folder.path_join(inner))
	DirAccess.remove_absolute(folder)
