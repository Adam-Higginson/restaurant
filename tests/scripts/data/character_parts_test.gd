extends GameTestSuite
## Tests for CharacterParts' Kiln jobs: the outfit, the head cut from a body
## with the eyebrows painted on, and the hair in its colour.


func test_without_looks_nothing_is_fired() -> void:
	assert_int(_parts(false).jobs().size()).is_equal(0)


func test_the_outfit_fires_at_the_size_its_drawn() -> void:
	var parts: CharacterParts = _parts()
	var job: KilnJob = parts.outfit_job()
	assert_array(Array(job.sources)).contains_exactly(["res://packs/outfit.gltf"])
	assert_float(job.scale).is_equal(parts.game_scale)
	assert_object(job.look).is_same(parts.body_look)


func test_the_head_is_cut_from_the_body_with_the_eyebrows_painted_on() -> void:
	var parts: CharacterParts = _parts()
	var job: KilnJob = parts.head_job()
	assert_array(Array(job.sources)).contains_exactly(["res://packs/body.gltf",
			"res://packs/eyebrows.gltf"])
	assert_array(Array(job.keep_bones)).contains_exactly(Array(CharacterParts.HEAD_BONES))
	# The base body's own eyebrows are left out: the parts bring their own.
	assert_array(Array(job.drop_meshes)).contains_exactly([CharacterParts.BASE_EYEBROWS])
	# The eyebrows are painted in the hair's colour, the head as it is.
	assert_that(job.tints[0]).is_equal(Color.WHITE)
	assert_that(job.tints[1]).is_equal(parts.hair_colour)


func test_without_eyebrows_the_head_is_fired_alone() -> void:
	var parts: CharacterParts = _parts()
	parts.eyebrows = ""
	assert_int(parts.head_job().sources.size()).is_equal(1)


func test_the_hair_is_fired_in_its_colour() -> void:
	var parts: CharacterParts = _parts()
	var job: KilnJob = parts.hair_job()
	assert_array(Array(job.sources)).contains_exactly(["res://packs/hair.gltf"])
	assert_that(job.tints[0]).is_equal(parts.hair_colour)


func test_no_hair_no_hair_job() -> void:
	var parts: CharacterParts = _parts()
	parts.hair = ""
	assert_object(parts.hair_job()).is_null()
	assert_int(parts.jobs().size()).is_equal(2)


func test_the_boy_and_girl_have_looks_for_every_part() -> void:
	for file: String in ["res://data/characters/boy.tres", "res://data/characters/girl.tres"]:
		var parts: CharacterParts = load(file) as CharacterParts
		assert_object(parts.body_look).override_failure_message(file).is_not_null()
		assert_object(parts.head_look).override_failure_message(file).is_not_null()
		assert_object(parts.hair_look).override_failure_message(file).is_not_null()


func _parts(with_looks: bool = true) -> CharacterParts:
	var parts: CharacterParts = CharacterParts.new()
	parts.outfit = "res://packs/outfit.gltf"
	parts.head_from = "res://packs/body.gltf"
	parts.hair = "res://packs/hair.gltf"
	parts.eyebrows = "res://packs/eyebrows.gltf"
	parts.hair_colour = Color(0.4, 0.2, 0.1)
	if with_looks:
		parts.body_look = ArtLook.new()
		parts.head_look = ArtLook.new()
		parts.hair_look = ArtLook.new()
	return parts
