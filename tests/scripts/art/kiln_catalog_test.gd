extends GameTestSuite
## Tests for KilnCatalog: finding every model the game fires, in scenes and
## in the characters' parts.

const FIXTURES: String = "res://tests/fixtures/kiln"


func test_it_finds_scenes_and_resources_in_every_folder() -> void:
	var files: PackedStringArray = KilnCatalog.files_in("res://tests/fixtures")
	assert_bool(files.has(FIXTURES + "/dressed.tscn")).is_true()
	assert_bool(files.has("res://tests/fixtures/character/outfit.tscn")).is_true()
	for file: String in files:
		assert_bool(file.ends_with(".tscn") or file.ends_with(".tres")).is_true()


func test_only_models_with_a_look_are_fired() -> void:
	var jobs: Array[KilnJob] = KilnCatalog.jobs_in_scene(FIXTURES + "/dressed.tscn")
	assert_int(jobs.size()).is_equal(1)
	assert_str(jobs[0].look.tag()).is_equal("test")
	assert_vector(jobs[0].fit_size).is_equal(Vector3(0.5, 0.5, 0.5))


func test_copies_of_the_models_come_without_their_scene() -> void:
	var models: Array[ThirdPartyModel] = KilnCatalog.models_in_scene(FIXTURES + "/dressed.tscn")
	assert_int(models.size()).is_equal(1)
	assert_str(String(models[0].name)).is_equal("Fired")
	assert_bool(models[0].is_inside_tree()).is_false()
	assert_int(models[0].stand_ins.size()).is_equal(0)
	models[0].free()


func test_characters_parts_each_fire() -> void:
	var jobs: Array[KilnJob] = KilnCatalog.jobs_in_resource("res://data/characters/boy.tres")
	assert_int(jobs.size()).is_equal(3)


func test_other_resources_have_nothing_to_fire() -> void:
	var jobs: Array[KilnJob] = KilnCatalog.jobs_in_resource("res://data/art/looks/prop.tres")
	assert_int(jobs.size()).is_equal(0)


func test_the_game_fires_its_props_crab_and_player_each_once() -> void:
	var fired: PackedStringArray = []
	for job: KilnJob in KilnCatalog.all_jobs():
		fired.append(job.fired_path().get_file())
	for wanted: String in ["pot_A.prop.glb", "kettle.prop.glb", "crab.creature.glb",
			"Male_Peasant.character_body.glb", "Superhero_Female_FullBody.character_head.glb",
			"Hair_Buns.character_hair.glb"]:
		assert_bool(fired.has(wanted)).override_failure_message(wanted).is_true()
	var once: Dictionary = {}
	for file: String in fired:
		assert_bool(once.has(file)).override_failure_message(file).is_false()
		once[file] = true
