extends GameTestSuite
## Tests for Porthole: cold moonlight through the glass that flares up when
## lightning flashes.

const SCENE: String = "res://scenes/prototype/props/porthole.tscn"


func test_it_is_lit_by_lightning() -> void:
	var porthole: Porthole = _new_porthole()
	assert_bool(porthole.is_in_group(Lightning.LIT_GROUP)).is_true()


func test_lightning_brightens_the_moonlight_then_it_settles() -> void:
	var porthole: Porthole = _new_porthole()
	var moonlight: SpotLight3D = porthole.get_node("Moonlight") as SpotLight3D
	var resting: float = moonlight.light_energy

	porthole.set_lightning(1.0)
	assert_float(moonlight.light_energy).is_equal_approx(
			resting + porthole.flash_energy, 0.0001)

	porthole.set_lightning(0.0)
	assert_float(moonlight.light_energy).is_equal_approx(resting, 0.0001)


func test_the_moonlight_is_cold() -> void:
	var moonlight: SpotLight3D = _new_porthole().get_node("Moonlight") as SpotLight3D
	assert_float(moonlight.light_color.b).is_greater(moonlight.light_color.r)


func _new_porthole() -> Porthole:
	var porthole: Porthole = (load(SCENE) as PackedScene).instantiate() as Porthole
	add_child(porthole)
	auto_free(porthole)
	return porthole
