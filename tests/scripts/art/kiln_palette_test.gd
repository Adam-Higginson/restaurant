extends GameTestSuite
## Tests for KilnPalette (the shared paintbox) and how looks use it.

const SALT_AND_EMBER: String = "res://data/art/palettes/salt_and_ember.tres"


func test_a_colour_snaps_to_the_nearest_as_the_eye_sees_it() -> void:
	var palette: KilnPalette = KilnPalette.new()
	palette.colours = [Color.BLACK, Color(0.8, 0.2, 0.1), Color(0.1, 0.3, 0.8), Color.WHITE]
	assert_that(palette.nearest(Color(0.7, 0.25, 0.15))).is_equal(Color(0.8, 0.2, 0.1))
	assert_that(palette.nearest(Color(0.15, 0.25, 0.7))).is_equal(Color(0.1, 0.3, 0.8))
	assert_that(palette.nearest(Color(0.95, 0.95, 0.9))).is_equal(Color.WHITE)


func test_an_empty_palette_keeps_the_colour() -> void:
	assert_that(KilnPalette.new().nearest(Color.ORANGE)).is_equal(Color.ORANGE)


func test_oklab_lightness_runs_from_black_to_white() -> void:
	assert_float(KilnPalette.oklab(Color.BLACK).x).is_equal_approx(0.0, 0.001)
	assert_float(KilnPalette.oklab(Color.WHITE).x).is_equal_approx(1.0, 0.001)
	# Greys have no colour.
	var grey: Vector3 = KilnPalette.oklab(Color(0.5, 0.5, 0.5))
	assert_float(grey.y).is_equal_approx(0.0, 0.001)
	assert_float(grey.z).is_equal_approx(0.0, 0.001)


func test_the_kiln_gets_the_palettes_colours() -> void:
	var look: ArtLook = ArtLook.new()
	look.palette = KilnPalette.new()
	look.palette.colours = [Color(0.25, 0.5, 1.0)]
	look.palette_strength = 0.5
	var firing: Dictionary = look.firing()
	var colours: Array = firing["palette"]
	var first: Array = colours[0]
	assert_float(float(str(first[2]))).is_equal_approx(1.0, 0.0001)
	var strength: float = firing["palette_strength"]
	assert_float(strength).is_equal_approx(0.5, 0.0001)


func test_a_new_palette_makes_fired_models_stale() -> void:
	var look: ArtLook = ArtLook.new()
	look.palette = KilnPalette.new()
	look.palette.colours = [Color.RED]
	var job: KilnJob = KilnJob.new("res://tests/fixtures/box_model.tscn", look)
	var first: String = job.fingerprint()
	look.palette.colours = [Color.BLUE]
	assert_str(job.fingerprint()).is_not_equal(first)


func test_salt_and_ember_is_a_small_shared_paintbox() -> void:
	var palette: KilnPalette = load(SALT_AND_EMBER) as KilnPalette
	assert_int(palette.colours.size()).is_between(16, 64)
	for colour: Color in palette.colours:
		assert_float(colour.a).is_equal(1.0)


func test_every_look_paints_with_salt_and_ember() -> void:
	for preset: String in ["prop", "creature", "character_body", "character_head",
			"character_hair"]:
		var look: ArtLook = load("res://data/art/looks/%s.tres" % preset) as ArtLook
		assert_object(look.palette).override_failure_message(preset).is_not_null()
		assert_str(look.palette.resource_path).is_equal(SALT_AND_EMBER)
		assert_float(look.palette_strength).override_failure_message(preset).is_greater(0.0)
