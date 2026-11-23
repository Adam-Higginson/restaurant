extends GameTestSuite
## Tests for night and dawn: one number blends the sky, the light, the fog
## and the rain; and sleeping in your bunk moves it on.


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

	assert_float(time.world.environment.fog_depth_end).is_equal_approx(62.5, 0.001)
	var sky: ShaderMaterial = time.world.environment.sky.sky_material as ShaderMaterial
	var top: Color = sky.get_shader_parameter("top_color")
	assert_float(top.r).is_equal_approx(0.16, 0.001)


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
