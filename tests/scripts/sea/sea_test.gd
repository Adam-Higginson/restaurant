extends GameTestSuite
## Tests for Sea: following the ship, moving around it on the swell, and the
## tilt it hands the ship's visuals.

const SEA_SCENE: String = "res://scenes/prototype/weather/sea_surface.tscn"


func test_centres_under_the_ship_and_drops_by_the_wave_height() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var sea: Sea = _add_sea(ship)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	# The sea follows the ship on rendered frames.
	await get_tree().process_frame
	await get_tree().process_frame

	var under: Vector2 = Vector2(ship.global_position.x, ship.global_position.z)
	assert_float(sea.global_position.x).is_equal_approx(snappedf(under.x, sea.grid_step), 0.001)
	assert_float(sea.global_position.z).is_equal_approx(snappedf(under.y, sea.grid_step), 0.001)
	assert_float(sea.global_position.y).is_equal_approx(-sea.height_at(under), 0.01)


func test_hands_the_ship_a_small_tilt() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var sea: Sea = _add_sea(ship)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)

	var limit: float = deg_to_rad(sea.max_tilt_degrees) + 0.0001
	assert_float(absf(ship.swell_tilt.x)).is_less_equal(limit)
	assert_float(absf(ship.swell_tilt.y)).is_less_equal(limit)
	assert_vector(ship.swell_tilt).is_equal_approx(sea.tilt_under(ship.global_transform),
			Vector2.ONE * 0.01)


func test_pitch_lifts_the_bow_when_the_sea_is_higher_there() -> void:
	var sea: Sea = _new_sea(_one_wave(0.0, 120.0, 1.0))
	# At time 0 the wave rises towards -Z (the bow of an unturned ship) up to
	# a crest 30 m ahead, so the bow sits higher than the stern.
	var tilt: Vector2 = sea.tilt_under(Transform3D.IDENTITY)
	assert_float(tilt.x).is_greater(0.0)
	assert_float(tilt.y).is_equal_approx(0.0, 0.0001)


func test_roll_lifts_starboard_when_the_sea_is_higher_there() -> void:
	# 270 degrees rolls towards +X, so at time 0 the sea is higher on the
	# starboard (+X) side.
	var sea: Sea = _new_sea(_one_wave(270.0, 60.0, 1.0))
	assert_float(sea.tilt_under(Transform3D.IDENTITY).y).is_greater(0.0)


func test_tilt_never_passes_the_limit() -> void:
	var sea: Sea = _new_sea(_one_wave(0.0, 20.0, 5.0))
	sea.max_tilt_degrees = 2.0
	var tilt: Vector2 = sea.tilt_under(Transform3D.IDENTITY.translated(Vector3(0, 0, 3)))
	assert_float(absf(tilt.x)).is_less_equal(deg_to_rad(2.0) + 0.0001)


func test_rain_is_kept_between_zero_and_one() -> void:
	var sea: Sea = _new_sea(WaveSettings.new())
	sea.rain = 3.0
	assert_float(sea.rain).is_equal(1.0)
	sea.rain = -1.0
	assert_float(sea.rain).is_equal(0.0)


func _add_sea(ship: Ship) -> Sea:
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	sea.ship = ship
	ship.get_parent().add_child(sea)
	return sea


func _new_sea(settings: WaveSettings) -> Sea:
	var sea: Sea = (load(SEA_SCENE) as PackedScene).instantiate() as Sea
	sea.settings = settings
	add_child(sea)
	auto_free(sea)
	return sea


func _one_wave(direction: float, length: float, amp: float) -> WaveSettings:
	var layer: WaveLayer = WaveLayer.new()
	layer.direction_degrees = direction
	layer.wavelength = length
	layer.amplitude = amp
	layer.steepness = 0.0
	var settings: WaveSettings = WaveSettings.new()
	settings.layers.append(layer)
	return settings
