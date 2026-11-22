extends GameTestSuite
## Tests for the ship's lanterns: their flame makes the light waver a little,
## never far from the brightness each lantern is set to.

const LANTERN_SCENE: String = "res://scenes/prototype/props/lantern.tscn"


func test_the_light_flickers_around_its_brightness() -> void:
	var lantern: Lantern = (load(LANTERN_SCENE) as PackedScene).instantiate() as Lantern
	lantern.light_energy = 2.0
	lantern.flicker = 0.1
	auto_free(lantern)
	var runner: GdUnitSceneRunner = scene_runner(lantern)
	var light: OmniLight3D = lantern.get_node("Light") as OmniLight3D
	var lowest: float = INF
	var highest: float = -INF

	for i: int in 40:
		await runner.simulate_frames(1)
		lowest = minf(lowest, light.light_energy)
		highest = maxf(highest, light.light_energy)

	assert_float(lowest).is_greater_equal(1.8 - 0.0001)
	assert_float(highest).is_less_equal(2.2 + 0.0001)
	assert_float(highest - lowest).is_greater(0.01)


func test_a_steady_lantern_does_not_flicker() -> void:
	var lantern: Lantern = (load(LANTERN_SCENE) as PackedScene).instantiate() as Lantern
	lantern.light_energy = 1.5
	lantern.flicker = 0.0
	auto_free(lantern)
	var runner: GdUnitSceneRunner = scene_runner(lantern)
	var light: OmniLight3D = lantern.get_node("Light") as OmniLight3D

	await runner.simulate_frames(20)

	assert_float(light.light_energy).is_equal_approx(1.5, 0.0001)
