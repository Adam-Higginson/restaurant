extends GameTestSuite
## Tests for the ship's lanterns: their flame makes the light waver a little,
## never far from the brightness each lantern is set to; put out, the glass
## stays but the flame behind it stops (#199); each flickers its own way.

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


func test_a_lantern_put_out_keeps_its_glass_but_its_flame_stops() -> void:
	var lantern: Lantern = (load(LANTERN_SCENE) as PackedScene).instantiate() as Lantern
	auto_free(lantern)
	add_child(lantern)
	var glass: MeshInstance3D = lantern.get_node("Glass") as MeshInstance3D
	assert_float(lantern.flame_burning()).is_equal(1.0)

	lantern.set_lit(false)

	assert_float(lantern.flame_burning()).is_equal(0.0)
	assert_bool(glass.visible).is_true()
	assert_bool((lantern.get_node("Light") as Light3D).visible).is_false()

	lantern.set_lit(true)

	assert_float(lantern.flame_burning()).is_equal(1.0)


func test_every_lantern_flickers_its_own_way() -> void:
	var seeds: Array[float] = []
	for i: int in 3:
		var lantern: Lantern = (load(LANTERN_SCENE) as PackedScene).instantiate() as Lantern
		auto_free(lantern)
		add_child(lantern)
		var glass: MeshInstance3D = lantern.get_node("Glass") as MeshInstance3D
		var own: float = glass.get_instance_shader_parameter(&"own_seed")
		seeds.append(own)
	# They share one material, so each needs its own seed to differ.
	assert_bool(seeds[0] == seeds[1] and seeds[1] == seeds[2]).is_false()


func test_its_glass_sits_where_its_light_and_flame_are() -> void:
	var lantern: Lantern = (load(LANTERN_SCENE) as PackedScene).instantiate() as Lantern
	auto_free(lantern)
	var glass: MeshInstance3D = lantern.get_node("Glass") as MeshInstance3D
	var light: Node3D = lantern.get_node("Light") as Node3D
	var box: AABB = glass.transform * glass.get_aabb()
	# The light shines from inside the glass, so the frame shadows it and
	# it pours out through the panes.
	assert_bool(box.has_point(light.position)).is_true()
