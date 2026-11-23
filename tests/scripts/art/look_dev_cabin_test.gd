extends GameTestSuite
## Tests for the look-dev cabin's switches: stylised or as-made characters,
## outlines, and golden or plain light. The art isn't in the repo, so in CI
## the characters are greybox, but the switches work the same.

const CABIN: String = "res://scenes/tools/look_dev_cabin.tscn"
const SHARED_STYLE: String = "res://data/art/styles/character.tres"


func test_the_characters_start_stylised() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CABIN)
	var cabin: LookDevCabin = runner.scene() as LookDevCabin

	assert_int(cabin.characters.size()).is_equal(2)
	for character: ThirdPartyModel in cabin.characters:
		assert_object(character.style).is_same(cabin.style)


func test_the_characters_switch_to_as_made_and_back() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CABIN)
	var cabin: LookDevCabin = runner.scene() as LookDevCabin

	cabin.set_stylised(false)
	for character: ThirdPartyModel in cabin.characters:
		assert_object(character.style).is_null()

	cabin.set_stylised(true)
	for character: ThirdPartyModel in cabin.characters:
		assert_object(character.style).is_same(cabin.style)


func test_switching_outlines_off_never_touches_the_shared_style() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CABIN)
	var cabin: LookDevCabin = runner.scene() as LookDevCabin

	cabin.set_outlined(false)

	assert_bool(cabin.style.outline).is_false()
	var shared: CharacterStyle = load(SHARED_STYLE) as CharacterStyle
	assert_object(cabin.style).is_not_same(shared)
	assert_bool(shared.outline).is_true()


func test_plain_light_swaps_the_environment_and_puts_the_lamps_out() -> void:
	var runner: GdUnitSceneRunner = scene_runner(CABIN)
	var cabin: LookDevCabin = runner.scene() as LookDevCabin
	assert_object(cabin.world.environment).is_same(cabin.golden)

	cabin.set_golden(false)

	assert_object(cabin.world.environment).is_same(cabin.plain)
	assert_that(cabin.sun.light_color).is_equal(cabin.plain_sun_color)
	assert_int(cabin.lamps.size()).is_equal(3)
	for lamp: Light3D in cabin.lamps:
		assert_bool(lamp.visible).is_false()

	cabin.set_golden(true)

	assert_object(cabin.world.environment).is_same(cabin.golden)
	for lamp: Light3D in cabin.lamps:
		assert_bool(lamp.visible).is_true()
