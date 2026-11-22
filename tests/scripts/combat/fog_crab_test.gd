extends GameTestSuite
## Tests for the fog crab's model: with the real crab model it plays its own
## idle and walk, lifts its claws as it rears up, and flashes white when a
## strike lands; without the model file the greybox crab stays. (How it looks
## isn't tested.)
##
## Built from a small stand-in for the model (tests/fixtures/crab_rig.tscn):
## the real crab's body and upper arm bones, and "idle" and "walk".

const RIG: String = "res://tests/fixtures/crab_rig.tscn"
const CLOSE: Vector3 = Vector3(0, 0, -1.3)


func test_it_walks_while_it_moves_and_stands_still_otherwise() -> void:
	assert_str(String(FogCrab.animation_for(true))).is_equal("walk")
	assert_str(String(FogCrab.animation_for(false))).is_equal("idle")


func test_without_its_model_the_greybox_crab_stays() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, Vector3(0, 0, -15))
	_dresser(crab).path = "res://assets/third_party/not_here.glb"
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	assert_str(String(crab.playing())).is_empty()
	assert_bool((crab.get_node("Model/Shell") as Node3D).visible).is_true()


func test_standing_by_it_plays_its_idle() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = _new_rigged_crab(player, Vector3(0, 0, -15))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	assert_str(String(crab.playing())).is_equal("idle")
	assert_bool((crab.get_node("Model/Shell") as Node3D).visible).is_false()


func test_scuttling_in_it_plays_its_walk() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = _new_rigged_crab(player, Vector3(0, 0, -5))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	# Rearing up, it closes the distance.
	await physics_ticks(runner, 20)

	assert_str(String(crab.playing())).is_equal("walk")


func test_its_claws_lift_through_its_arms_as_it_rears_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = _new_rigged_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var skeleton: Skeleton3D = crab.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var arm: int = skeleton.find_bone("left arm 1.1")
	var resting: Quaternion = skeleton.get_bone_pose_rotation(arm)

	# Most of the way through the 0.8 s rear-up.
	await physics_ticks(runner, 40)

	assert_float(crab.claw_lift()).is_greater(0.6)
	var lifted: Quaternion = skeleton.get_bone_pose_rotation(arm)
	assert_float(resting.angle_to(lifted)).is_greater(0.4)


func test_a_strike_flashes_the_real_model_white() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = _new_rigged_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	# Its first blow lands and freezes the game; then it's open.
	await physics_ticks(runner, 70 + HitStop.HURT_TICKS)

	assert_bool(await strike_and_land(runner, player)).is_true()
	await physics_ticks(runner, 1)

	var shell: MeshInstance3D = crab.find_child("Shell", true, false) as MeshInstance3D
	var model_shell: MeshInstance3D = null
	for node: Node in _dresser(crab).model.find_children("Shell", "MeshInstance3D", true, false):
		model_shell = node as MeshInstance3D
	assert_object(model_shell).is_not_null()
	assert_object(model_shell.material_overlay).is_not_null()
	assert_object(shell).is_not_null()


func test_flipped_it_rolls_onto_its_back_and_back_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	# Mid-lunge, just after its first blow.
	await physics_ticks(runner, 49 + HitStop.HURT_TICKS)
	assert_int(crab.cycle.state).is_equal(CrabCycle.State.ATTACK)

	assert_bool(crab.cycle.flip()).is_true()
	await physics_ticks(runner, 30)

	assert_float(crab.flipped_amount()).is_equal(1.0)
	var model: Node3D = crab.get_node("Model") as Node3D
	assert_float(absf(model.rotation.z)).is_greater(3.0)
	assert_float(model.position.y).is_greater(0.4)
	# Rolled back up and rearing again once its time is up.
	await physics_ticks(runner, int(crab.flip_seconds * 60.0))
	assert_float(crab.flipped_amount()).is_equal(0.0)
	assert_float(absf(model.rotation.z)).is_less(0.5)


func test_flipped_its_legs_scrabble_at_the_air() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = _new_rigged_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 49 + HitStop.HURT_TICKS)

	crab.cycle.flip()
	await physics_ticks(runner, 10)

	assert_str(String(crab.playing())).is_equal("walk")


# A fog crab at [param pos] wearing the stand-in model.
func _new_rigged_crab(player: Player3D, pos: Vector3) -> FogCrab:
	var crab: FogCrab = new_fog_crab(player, pos)
	_dresser(crab).path = RIG
	return crab


func _dresser(crab: FogCrab) -> ThirdPartyModel:
	return crab.get_node("Model/Crab") as ThirdPartyModel
