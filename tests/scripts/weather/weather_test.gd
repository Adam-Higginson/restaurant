extends GameTestSuite
## Tests for Weather, ShelterZone, RainEffect and Ambience: one rain intensity
## shown everywhere, drops landing on the ship and splashing, the galley
## counting as sheltered, and silence when the third-party sounds aren't there.

const WEATHER_SCENE: String = "res://scenes/prototype/weather/weather.tscn"
const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"
## Below deck in the galley, and up on the aft deck, in the ship's own space.
const IN_GALLEY: Vector3 = Vector3(0, 1.05, 6)
const ON_DECK: Vector3 = Vector3(0, 5.35, 11)


func test_intensity_is_clamped_and_announced() -> void:
	var weather: Weather = _new_weather()
	var heard: Array[float] = []
	weather.intensity_changed.connect(func(value: float) -> void: heard.append(value))

	weather.intensity = 2.0
	weather.intensity = 2.0

	assert_float(weather.intensity).is_equal(1.0)
	assert_array(heard).contains_exactly([1.0])


func test_the_rain_and_the_sea_follow_the_intensity() -> void:
	var weather: Weather = _new_weather()
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	add_child(sea)
	auto_free(sea)
	weather.sea = sea

	weather.intensity = 0.3

	assert_float(sea.rain).is_equal_approx(0.3, 0.0001)
	assert_float(weather.rain.intensity).is_equal_approx(0.3, 0.0001)
	weather.intensity = 0.0
	assert_bool(weather.rain.is_raining()).is_false()


func test_wetness_is_a_shader_global_every_material_can_read() -> void:
	# The headless test renderer doesn't keep global values, so this checks the
	# global is declared; the drips test checks the weather sends it out.
	var setting: String = "shader_globals/" + String(Weather.WETNESS)
	assert_bool(ProjectSettings.has_setting(setting)).is_true()
	var declared: Dictionary = ProjectSettings.get_setting(setting)
	assert_str(str(declared["type"])).is_equal("float")


func test_the_deck_and_its_trim_are_wet_surfaces() -> void:
	var ship: Ship = new_moored_ship_with_player(ON_DECK)[0] as Ship
	var wet_shader: Shader = load("res://shaders/wet_surface.gdshader") as Shader
	for path: String in ["Visuals/DeckAft", "Visuals/DeckFore", "Visuals/RailPort", "Visuals/Mast"]:
		var mesh: MeshInstance3D = ship.get_node(path) as MeshInstance3D
		var material: ShaderMaterial = mesh.material_override as ShaderMaterial
		assert_object(material).is_not_null()
		assert_object(material.shader).is_same(wet_shader)


func test_the_galley_is_sheltered_and_the_deck_is_not() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(ON_DECK)
	var ship: Ship = rig[0] as Ship
	var weather: Weather = (load(WEATHER_SCENE) as PackedScene).instantiate() as Weather
	ship.get_parent().add_child(weather)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	assert_bool(weather.sheltered).is_false()

	place_player_3d(runner, ship.to_global(IN_GALLEY))
	await physics_ticks(runner, 5)

	assert_bool(weather.sheltered).is_true()
	# It still rains: the deck above catches the drops, not a switch.
	assert_bool(weather.rain.is_raining()).is_true()

	place_player_3d(runner, ship.to_global(ON_DECK))
	await physics_ticks(runner, 5)

	assert_bool(weather.sheltered).is_false()


func test_drops_vanish_where_they_land_and_splash_there() -> void:
	var weather: Weather = _new_weather()
	var streaks: GPUParticles3D = weather.rain.streaks()
	var falling: ShaderMaterial = streaks.process_material as ShaderMaterial

	assert_object(falling.shader).is_same(RainEffect.DROPS_SHADER)
	assert_object(streaks.get_node(streaks.sub_emitter)).is_same(weather.rain.splashes())


func test_the_ship_catches_rain_over_its_whole_deck() -> void:
	var ship: Ship = new_moored_ship_with_player(ON_DECK)[0] as Ship
	var catcher: GPUParticlesCollisionHeightField3D = 			ship.get_node("RainCatcher") as GPUParticlesCollisionHeightField3D
	# Every corner of the deck and the top of the mast are inside it.
	var box: AABB = AABB(catcher.position - catcher.size / 2.0, catcher.size)
	for corner: Vector3 in [Vector3(-6, 5.3, -15), Vector3(6, 5.3, 15), Vector3(0, 16.5, -4)]:
		assert_bool(box.has_point(corner)).is_true()
	# It follows the sailing ship, so it has to redraw every frame.
	assert_int(catcher.update_mode).is_equal(
			GPUParticlesCollisionHeightField3D.UPDATE_MODE_ALWAYS)


func test_ambience_stays_silent_without_its_sounds() -> void:
	var weather: Weather = (load(WEATHER_SCENE) as PackedScene).instantiate() as Weather
	var ambience: Ambience = weather.get_node("Ambience") as Ambience
	ambience.rain_path = "res://assets/third_party/audio/no_such_sound.ogg"
	ambience.waves_path = ""
	add_child(weather)
	auto_free(weather)

	assert_object((ambience.get_node("Rain") as AudioStreamPlayer).stream).is_null()
	assert_object((ambience.get_node("Waves") as AudioStreamPlayer).stream).is_null()
	assert_bool(Ambience.has_sound("")).is_false()


func test_ambience_plays_on_its_own_bus() -> void:
	assert_int(AudioServer.get_bus_index(Ambience.BUS)).is_greater(0)
	var weather: Weather = _new_weather()
	var rain: AudioStreamPlayer = weather.get_node("Ambience/Rain") as AudioStreamPlayer
	assert_str(String(rain.bus)).is_equal(String(Ambience.BUS))


func _new_weather() -> Weather:
	var weather: Weather = (load(WEATHER_SCENE) as PackedScene).instantiate() as Weather
	add_child(weather)
	auto_free(weather)
	return weather
