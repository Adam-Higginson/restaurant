extends GameTestSuite
## Tests for the look on the lantern's face in everyday play: pleased when
## something good happens, tired when he's dim, worried or set in a fight,
## his flame as strong as his warmth, rain on his glass when he's out in it,
## and left alone while a cutscene directs him.

const WEATHER: PackedScene = preload("res://scenes/prototype/weather/weather.tscn")


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_he_looks_calm_with_nothing_going_on() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)

	assert_int(spirit.everyday_expression()).is_equal(LanternFace.Look.CALM)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.CALM)


func test_he_looks_pleased_when_something_good_happens_and_then_calm_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)

	spirit.excite()
	await physics_ticks(runner, 5)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.PLEASED)

	await physics_ticks(runner, 140)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.CALM)


func test_he_looks_tired_when_hes_dim_and_his_flame_is_low() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)
	assert_float(spirit.flame_strength()).is_equal_approx(1.0, 0.001)

	spirit.warmth = 0.3
	await physics_ticks(runner, 5)

	assert_int(spirit.face().expression).is_equal(LanternFace.Look.TIRED)
	assert_float(spirit.face().strength).is_between(0.35, 0.5)
	# Dim, but never out.
	spirit.warmth = 0.0
	assert_float(spirit.flame_strength()).is_equal_approx(0.35, 0.001)


func test_a_fight_shows_on_his_face() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)

	spirit.set_mood(LanternSpirit.Mood.WARNING)
	await physics_ticks(runner, 3)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.WORRIED)

	spirit.set_mood(LanternSpirit.Mood.OPEN)
	await physics_ticks(runner, 3)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.DETERMINED)

	# A fight's signal matters more than a moment's delight.
	spirit.excite()
	await physics_ticks(runner, 3)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.DETERMINED)

	spirit.set_mood(LanternSpirit.Mood.CALM)
	await physics_ticks(runner, 3)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.PLEASED)


func test_a_cutscenes_look_is_left_alone_until_its_given_back() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)

	spirit.face().direct("asleep")
	spirit.excite()
	await physics_ticks(runner, 5)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.ASLEEP)

	spirit.face().release()
	await physics_ticks(runner, 5)
	assert_int(spirit.face().expression).is_equal(LanternFace.Look.PLEASED)


func test_rain_runs_down_his_glass_out_in_it_and_it_fogs_when_he_comes_in() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var weather: Weather = WEATHER.instantiate() as Weather
	weather.intensity = 0.8
	player.get_parent().add_child(weather)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)
	assert_bool(spirit.face().streaked).is_true()
	assert_bool(spirit.face().fogged).is_false()

	# The rain stops (or a roof comes over): his glass mists for a while.
	weather.intensity = 0.0
	await physics_ticks(runner, 5)
	assert_bool(spirit.face().streaked).is_false()
	assert_bool(spirit.face().fogged).is_true()

	spirit.fog_seconds = 0.5
	await physics_ticks(runner, 300)
	assert_bool(spirit.face().fogged).is_false()


func test_with_no_weather_his_glass_stays_dry() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	await physics_ticks(runner, 5)

	assert_bool(spirit.face().streaked).is_false()


func test_his_own_light_takes_the_colour_of_his_flame() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var spirit: LanternSpirit = lantern_at_shoulder(player)
	var light: OmniLight3D = spirit.get_node("Light") as OmniLight3D
	await physics_ticks(runner, 30)

	assert_float(light.light_color.r).is_greater(light.light_color.b)
