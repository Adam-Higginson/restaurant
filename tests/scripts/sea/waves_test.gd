extends GameTestSuite
## Tests for WaveLayer, WaveSettings and Waves: the sea's wave maths, shared
## with the water shader.

const NIGHT_SWELL: WaveSettings = preload("res://data/sea/night_swell.tres")


func test_a_sea_with_no_layers_is_flat() -> void:
	var calm: WaveSettings = WaveSettings.new()
	assert_float(Waves.height_at(calm, Vector2(12.0, -7.0), 3.5)).is_equal(0.0)
	assert_vector(Waves.offset(calm, Vector2(1.0, 2.0), 9.0)).is_equal(Vector3.ZERO)


func test_waves_never_rise_above_their_amplitudes_added_up() -> void:
	var highest: float = 0.0
	for layer: WaveLayer in NIGHT_SWELL.used_layers():
		highest += layer.amplitude
	for i: int in 50:
		var spot: Vector2 = Vector2(i * 3.7, i * -2.3)
		var height: float = Waves.height_at(NIGHT_SWELL, spot, i * 0.41)
		assert_float(absf(height)).is_less_equal(highest + 0.001)


func test_one_smooth_wave_is_a_sine() -> void:
	var settings: WaveSettings = _one_wave(0.0, 40.0, 1.5, 0.0)
	# Rolling towards -Z, so the phase runs along -z: a quarter wavelength
	# ahead is the crest.
	assert_float(Waves.height_at(settings, Vector2(0.0, -10.0), 0.0)).is_equal_approx(1.5, 0.001)
	assert_float(Waves.height_at(settings, Vector2(0.0, 0.0), 0.0)).is_equal_approx(0.0, 0.001)
	assert_float(Waves.height_at(settings, Vector2(0.0, 10.0), 0.0)).is_equal_approx(-1.5, 0.001)


func test_waves_roll_along_their_direction() -> void:
	var settings: WaveSettings = _one_wave(0.0, 40.0, 1.0, 0.0)
	var layer: WaveLayer = settings.layers[0]
	# After the crest has travelled 5 m, the height 5 m further on matches
	# the height here at the start.
	var travel_time: float = 5.0 / layer.speed()
	var before: float = Waves.height_at(settings, Vector2(0.0, -3.0), 0.0)
	var after: float = Waves.height_at(settings, Vector2(0.0, -8.0), travel_time)
	assert_float(after).is_equal_approx(before, 0.001)


func test_height_at_finds_the_point_the_waves_carried_there() -> void:
	var spot: Vector2 = Vector2(5.0, -11.0)
	var time: float = 2.0
	var height: float = Waves.height_at(NIGHT_SWELL, spot, time)
	# Search back the same way, then check that point really lands on the spot.
	var still: Vector2 = spot
	for i: int in 8:
		var moved: Vector3 = Waves.offset(NIGHT_SWELL, still, time)
		still = spot - Vector2(moved.x, moved.z)
	var landed: Vector3 = Waves.offset(NIGHT_SWELL, still, time)
	assert_float((still + Vector2(landed.x, landed.z)).distance_to(spot)).is_less(0.05)
	assert_float(height).is_equal_approx(landed.y, 0.05)


func test_a_stopped_clock_freezes_the_sea() -> void:
	var settings: WaveSettings = NIGHT_SWELL.duplicate() as WaveSettings
	settings.time_scale = 0.0
	var spot: Vector2 = Vector2(3.0, 4.0)
	assert_float(Waves.height_at(settings, spot, 0.0)).is_equal_approx(
			Waves.height_at(settings, spot, 30.0), 0.0001)


func test_layer_directions_and_speeds() -> void:
	var layer: WaveLayer = WaveLayer.new()
	layer.direction_degrees = 0.0
	assert_vector(layer.direction()).is_equal_approx(Vector2(0.0, -1.0), Vector2.ONE * 0.0001)
	layer.direction_degrees = 90.0
	assert_vector(layer.direction()).is_equal_approx(Vector2(-1.0, 0.0), Vector2.ONE * 0.0001)
	# Longer waves travel faster: speed = sqrt(g * wavelength / 2pi).
	layer.wavelength = 60.0
	assert_float(layer.speed()).is_equal_approx(sqrt(9.8 * 60.0 / TAU), 0.001)


func test_steepness_is_limited_so_the_surface_never_folds() -> void:
	var layer: WaveLayer = WaveLayer.new()
	layer.wavelength = 10.0
	layer.amplitude = 3.0
	layer.steepness = 1.0
	assert_float(layer.sideways() * layer.wave_number() * layer.amplitude).is_less_equal(1.0001)


func test_only_four_layers_are_used() -> void:
	var settings: WaveSettings = WaveSettings.new()
	for i: int in 6:
		settings.layers.append(WaveLayer.new())
	assert_int(settings.used_layers().size()).is_equal(WaveSettings.MAX_LAYERS)


func _one_wave(direction: float, length: float, amp: float, steep: float) -> WaveSettings:
	var layer: WaveLayer = WaveLayer.new()
	layer.direction_degrees = direction
	layer.wavelength = length
	layer.amplitude = amp
	layer.steepness = steep
	var settings: WaveSettings = WaveSettings.new()
	settings.layers.append(layer)
	return settings
