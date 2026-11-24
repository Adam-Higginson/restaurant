extends GameTestSuite
## Tests for your bunk's sleep (#207): not while the lantern's low, so the
## first quest, his soup, comes before any sleep.


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_no_sleep_while_the_lantern_is_low() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.0, 1.05, 13.95))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var bedside: Bedside = rig[0].get_node("BunkRoom/Bedside") as Bedside
	await physics_ticks(runner, 2)
	Game.dialogue.set_flag(LanternSpirit.LOW_FLAG)

	assert_bool(bedside.can_sleep()).is_false()
	assert_str(bedside.prompt()).is_empty()
	bedside.sleep(rig[1] as Player3D)
	assert_bool(bedside.is_sleeping).is_false()


func test_once_hes_had_his_soup_you_can_sleep() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(4.0, 1.05, 13.95))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var bedside: Bedside = rig[0].get_node("BunkRoom/Bedside") as Bedside
	await physics_ticks(runner, 2)

	assert_bool(bedside.can_sleep()).is_true()
	assert_str(bedside.prompt()).is_equal("Sleep until morning")
