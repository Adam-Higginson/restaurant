extends GameTestSuite
## Tests for the lantern's warmth at his round table by the stove: he fades
## slowly (never out) and says so when he's low. Supper itself is at the
## galley table now: supper_table_test.gd.

## In the bunk room, just short of the nook's round table, facing it (aft).
const BY_THE_TABLE: Vector3 = Vector3(-1.0, 1.05, 10.25)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_he_fades_slowly_but_never_goes_out() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var light: OmniLight3D = spirit.get_node("Light") as OmniLight3D
	await physics_ticks(runner, 2)
	var full_reach: float = light.omni_range

	spirit.warmth_per_minute = 120.0
	await physics_ticks(runner, 60)

	assert_float(spirit.warmth).is_equal_approx(spirit.min_warmth, 0.001)
	assert_float(light.omni_range).is_less(full_reach)


func test_he_says_so_when_he_is_getting_low() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 2)

	spirit.warmth = 0.39
	await physics_ticks(runner, 2)

	assert_bool(spirit.saying() in moment_lines(&"dim")).is_true()


func _spirit(rig: Array[Node3D]) -> LanternSpirit:
	return rig[1].get_node("LanternSpirit") as LanternSpirit
