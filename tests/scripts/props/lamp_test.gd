extends GameTestSuite
## Tests for Lamp, the ceiling lamp the day light turns up at night.

const LAMP_SCENE: String = "res://scenes/props/lamp.tscn"


func test_starts_off() -> void:
	var lamp: Lamp = _new_lamp()
	assert_float(lamp.level).is_equal(0.0)
	assert_bool(_light(lamp).enabled).is_false()


func test_fully_on_gives_full_energy() -> void:
	var lamp: Lamp = _new_lamp()
	lamp.level = 1.0
	assert_bool(_light(lamp).enabled).is_true()
	assert_float(_light(lamp).energy).is_equal_approx(lamp.max_energy, 0.001)


func test_energy_scales_with_level_and_max_energy() -> void:
	var lamp: Lamp = _new_lamp()
	lamp.max_energy = 0.6
	lamp.level = 0.5
	assert_float(_light(lamp).energy).is_equal_approx(0.3, 0.001)


func test_turning_back_down_switches_the_light_off() -> void:
	var lamp: Lamp = _new_lamp()
	lamp.level = 1.0
	lamp.level = 0.0
	assert_bool(_light(lamp).enabled).is_false()


func test_level_is_kept_between_zero_and_one() -> void:
	var lamp: Lamp = _new_lamp()
	lamp.level = 2.0
	assert_float(lamp.level).is_equal(1.0)
	lamp.level = -1.0
	assert_float(lamp.level).is_equal(0.0)


func test_a_level_set_before_it_is_added_still_applies() -> void:
	var lamp: Lamp = (load(LAMP_SCENE) as PackedScene).instantiate() as Lamp
	auto_free(lamp)
	lamp.level = 1.0
	add_child(lamp)
	assert_bool(_light(lamp).enabled).is_true()
	assert_float(_light(lamp).energy).is_equal_approx(lamp.max_energy, 0.001)


func test_joins_the_lamps_group() -> void:
	var lamp: Lamp = _new_lamp()
	assert_bool(lamp.is_in_group(Lamp.GROUP)).is_true()


func test_casts_shadows() -> void:
	var lamp: Lamp = _new_lamp()
	assert_bool(_light(lamp).shadow_enabled).is_true()


func _new_lamp() -> Lamp:
	var lamp: Lamp = (load(LAMP_SCENE) as PackedScene).instantiate() as Lamp
	auto_free(lamp)
	add_child(lamp)
	return lamp


func _light(lamp: Lamp) -> PointLight2D:
	return lamp.get_node("Light") as PointLight2D
