extends GameTestSuite
## Tests for night and dawn: one number blends the sky, the light, the fog
## and the rain; and sleeping in your bunk moves it on. And the clear day
## (#197): a second number carries the morning on to blue sky and a turquoise
## sea, turned by the @clear cue.

const SEA: PackedScene = preload("res://scenes/prototype/weather/sea_surface.tscn")


func test_night_is_the_storm_and_dawn_the_drizzle() -> void:
	var time: TimeOfDay = _rig()
	assert_float(time.weather.intensity).is_equal_approx(0.8, 0.001)
	assert_bool(time.is_morning()).is_false()

	time.dawn = 1.0

	assert_float(time.weather.intensity).is_equal_approx(0.15, 0.001)
	assert_float(time.world.environment.ambient_light_energy).is_equal_approx(1.1, 0.001)
	assert_bool(time.is_morning()).is_true()


func test_the_moon_becomes_a_low_warm_sun() -> void:
	var time: TimeOfDay = _rig()

	time.dawn = 1.0

	assert_float(time.moon.light_color.r).is_greater(time.moon.light_color.b)
	assert_float(time.moon.light_energy).is_greater(1.0)


func test_halfway_is_halfway() -> void:
	var time: TimeOfDay = _rig()

	time.dawn = 0.5

	assert_float(time.world.environment.fog_depth_end).is_equal_approx(41.5, 0.001)
	var sky: ShaderMaterial = time.world.environment.sky.sky_material as ShaderMaterial
	var top: Color = sky.get_shader_parameter("top_color")
	assert_float(top.r).is_equal_approx(0.16, 0.001)


func test_a_clear_day_is_blue_sky_thin_cloud_and_no_rain() -> void:
	var time: TimeOfDay = _rig()
	time.dawn = 1.0

	time.clear = 1.0

	assert_float(time.weather.intensity).is_equal_approx(0.0, 0.001)
	assert_float(time.world.environment.fog_depth_end).is_equal_approx(220.0, 0.001)
	var sky: ShaderMaterial = time.world.environment.sky.sky_material as ShaderMaterial
	var top: Color = sky.get_shader_parameter("top_color")
	assert_float(top.b).is_greater(top.r * 2.0)
	assert_float(sky.get_shader_parameter("cloud_cover")).is_equal_approx(0.2, 0.001)


func test_the_sea_turns_turquoise_and_back() -> void:
	var time: TimeOfDay = _rig()
	var sea: Sea = SEA.instantiate() as Sea
	add_child(sea)
	auto_free(sea)
	var water: ShaderMaterial = sea.material_override as ShaderMaterial
	time.dawn = 1.0
	time.clear = 0.0
	var slate: Color = water.get_shader_parameter("crest_color")

	time.clear = 1.0
	var turquoise: Color = water.get_shader_parameter("crest_color")
	time.clear = 0.0

	assert_float(turquoise.g).is_greater(slate.g + 0.3)
	assert_float(turquoise.g).is_greater(turquoise.r * 3.0)
	assert_vector(Vector3(slate.r, slate.g, slate.b)) \
			.is_equal_approx(Vector3(0.07, 0.22, 0.23), Vector3(0.001, 0.001, 0.001))


func test_the_clear_cue_turns_it_over_time_or_at_once_when_skipped() -> void:
	var time: TimeOfDay = _rig()
	var player: Player3D = new_player_3d_on_floor()
	var conversation: Conversation = new_conversation(player)
	player.get_parent().add_child(TimeCues.new())
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 3)

	play_cutscene(conversation, player,
			"@clear 1.0 1.0\nheron: Clearing.\n@clear 0.0 5.0\nheron: Again.")
	await physics_ticks(runner, 20)
	assert_float(time.clear).is_between(0.05, 0.95)
	await physics_ticks(runner, 50)
	assert_float(time.clear).is_equal_approx(1.0, 0.001)
	conversation.press()
	await physics_ticks(runner, 2)
	conversation.skip()
	await physics_ticks(runner, 3)

	assert_float(time.clear).is_equal_approx(0.0, 0.001)


func test_sleeping_in_your_bunk_brings_the_morning_and_back() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.0, 1.05, 13.4))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var time: TimeOfDay = TimeOfDay.new()
	ship.get_parent().add_child(time)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bedside: Bedside = ship.get_node("BunkRoom/Bedside") as Bedside
	(bedside.get_node("ScreenFade") as ScreenFade).fade_seconds = 0.05
	bedside.sleep_seconds = 0.05
	await physics_ticks(runner, 2)
	assert_str(bedside.prompt()).is_equal("Sleep until morning")

	await bedside.sleep(player)

	assert_bool(time.is_morning()).is_true()
	assert_bool(player.controls_enabled).is_true()
	assert_str(bedside.prompt()).is_equal("Rest until nightfall")

	await bedside.sleep(player)

	assert_bool(time.is_morning()).is_false()


func test_you_cannot_walk_off_while_asleep() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.0, 1.05, 13.4))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var bedside: Bedside = ship.get_node("BunkRoom/Bedside") as Bedside
	(bedside.get_node("ScreenFade") as ScreenFade).fade_seconds = 0.2
	await physics_ticks(runner, 2)

	bedside.sleep(player)
	await physics_ticks(runner, 3)

	assert_bool(bedside.is_sleeping).is_true()
	assert_bool(player.controls_enabled).is_false()


# A time of day with its own sky, moon and weather.
func _rig() -> TimeOfDay:
	var world: WorldEnvironment = WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.sky = Sky.new()
	var sky: ShaderMaterial = ShaderMaterial.new()
	sky.shader = load("res://shaders/night_sky.gdshader") as Shader
	world.environment.sky.sky_material = sky
	var moon: DirectionalLight3D = DirectionalLight3D.new()
	var weather: Weather = (load("res://scenes/prototype/weather/weather.tscn") as PackedScene) \
			.instantiate() as Weather
	var time: TimeOfDay = TimeOfDay.new()
	time.world = world
	time.moon = moon
	time.weather = weather
	for node: Node in [world, moon, weather, time]:
		add_child(node)
		auto_free(node)
	return time
