extends GameTestSuite
## Tests for the lightning's light: as bright as the flash, and off between
## flashes.


func test_it_is_off_in_the_dark() -> void:
	var light: LightningLight = _new_light()

	assert_bool(light.visible).is_false()
	assert_float(light.light_energy).is_equal(0.0)


func test_it_is_as_bright_as_the_flash() -> void:
	var light: LightningLight = _new_light()
	light.peak_energy = 4.0

	light.set_lightning(0.5)

	assert_bool(light.visible).is_true()
	assert_float(light.light_energy).is_equal_approx(2.0, 0.0001)


func test_the_lightning_lights_it_when_it_strikes() -> void:
	var weather: Weather = (load("res://scenes/prototype/weather/weather.tscn") as PackedScene) \
			.instantiate() as Weather
	add_child(weather)
	auto_free(weather)
	var light: LightningLight = weather.get_node("LightningLight") as LightningLight
	var lightning: Lightning = weather.get_node("Lightning") as Lightning

	lightning.strike()
	lightning.advance(0.01)

	assert_bool(light.visible).is_true()
	assert_float(light.light_energy).is_greater(0.0)


func _new_light() -> LightningLight:
	var light: LightningLight = LightningLight.new()
	add_child(light)
	auto_free(light)
	return light
