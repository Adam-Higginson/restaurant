extends GameTestSuite
## Tests for ArtLook: the name fired files carry, and the settings handed to
## the Kiln.


func test_a_preset_is_named_by_its_file() -> void:
	var look: ArtLook = load("res://data/art/looks/prop.tres") as ArtLook
	assert_str(look.tag()).is_equal("prop")


func test_a_given_name_wins_over_the_file() -> void:
	var look: ArtLook = ArtLook.new()
	look.resource_name = "Shore Rock"
	assert_str(look.tag()).is_equal("shore_rock")


func test_a_look_made_in_a_scene_is_custom() -> void:
	assert_str(ArtLook.new().tag()).is_equal("custom")


func test_the_kiln_gets_every_firing_setting() -> void:
	var look: ArtLook = ArtLook.new()
	look.triangles = 123
	look.grain = 0.2
	look.symmetric = true
	var firing: Dictionary = look.firing()
	var triangles: int = firing["triangles"]
	var grain: float = firing["grain"]
	var symmetric: bool = firing["symmetric"]
	assert_int(triangles).is_equal(123)
	assert_float(grain).is_equal_approx(0.2, 0.0001)
	assert_bool(symmetric).is_true()
	for key: String in ["pixels_per_metre", "max_texture", "flatten_degrees", "creases",
			"protect_edges"]:
		assert_bool(firing.has(key)).override_failure_message(key).is_true()


func test_drawing_settings_are_not_firing_settings() -> void:
	# Changing how it's drawn mustn't make the model stale.
	var firing: Dictionary = ArtLook.new().firing()
	for key: String in ["faceted", "roughness", "specular"]:
		assert_bool(firing.has(key)).override_failure_message(key).is_false()


func test_the_presets_keep_to_the_n64_budgets() -> void:
	var budgets: Dictionary[String, int] = {
		"prop": 200, "creature": 1000, "character_body": 1000,
		"character_head": 400, "character_hair": 300,
	}
	for preset: String in budgets:
		var look: ArtLook = load("res://data/art/looks/%s.tres" % preset) as ArtLook
		assert_int(look.triangles).override_failure_message(preset) \
				.is_less_equal(budgets[preset])
		assert_float(look.pixels_per_metre).override_failure_message(preset) \
				.is_greater_equal(64.0)
