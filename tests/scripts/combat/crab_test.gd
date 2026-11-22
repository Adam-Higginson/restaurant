extends GameTestSuite
## Tests for the crab's model: with the real crab model it plays its own
## idle and walk, lifts its claws as it rears up, and flashes white when a
## strike lands; without the model file the greybox crab stays. (How it looks
## isn't tested.)
##
## Built from a small stand-in for the model (tests/fixtures/crab_rig.tscn):
## the real crab's body and upper arm bones, and "idle" and "walk".

const RIG: String = "res://tests/fixtures/crab_rig.tscn"
const CLOSE: Vector3 = Vector3(0, 0, -1.3)


func test_it_walks_while_it_moves_and_stands_still_otherwise() -> void:
	assert_str(String(Crab.animation_for(true))).is_equal("walk")
	assert_str(String(Crab.animation_for(false))).is_equal("idle")


func test_without_its_model_the_greybox_crab_stays() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -15))
	_dresser(crab).path = "res://assets/third_party/not_here.glb"
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	assert_str(String(crab.playing())).is_empty()
	assert_bool((crab.get_node("Model/Shell") as Node3D).visible).is_true()


func test_standing_by_it_plays_its_idle() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _new_rigged_crab(player, Vector3(0, 0, -15))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	assert_str(String(crab.playing())).is_equal("idle")
	assert_bool((crab.get_node("Model/Shell") as Node3D).visible).is_false()


func test_scuttling_in_it_plays_its_walk() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _new_rigged_crab(player, Vector3(0, 0, -5))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	# Rearing up, it closes the distance.
	await physics_ticks(runner, 20)

	assert_str(String(crab.playing())).is_equal("walk")


func test_its_claws_lift_through_its_arms_as_it_rears_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _new_rigged_crab(player, CLOSE)
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
	var crab: Crab = _new_rigged_crab(player, CLOSE)
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
	var crab: Crab = new_crab(player, CLOSE)
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
	var crab: Crab = _new_rigged_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 49 + HitStop.HURT_TICKS)

	crab.cycle.flip()
	await physics_ticks(runner, 10)

	assert_str(String(crab.playing())).is_equal("walk")


# --- Health, level and criticals ---------------------------------------------------

func test_its_health_comes_from_its_level() -> void:
	assert_int(Crab.health_for(1)).is_equal(80)
	assert_int(Crab.health_for(2)).is_equal(160)
	assert_int(Crab.health_for(0)).is_equal(80)


func test_a_crabs_health_is_set_by_its_level() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	crab.level = 2
	scene_runner(player.get_parent())

	assert_int(crab.cycle.health).is_equal(160)
	assert_int(crab.health_left()).is_equal(160)


func test_its_level_shows_over_its_head() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	crab.level = 3
	scene_runner(player.get_parent())

	var label: Label3D = crab.get_node("LevelLabel") as Label3D
	assert_str(label.text).is_equal("Lv 3")
	assert_bool(label.visible).is_true()


func test_a_hit_takes_its_damage_and_shows_a_number() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	_open(crab)
	assert_bool(crab.take_strike(Vector3.ZERO, 10)).is_true()

	assert_int(crab.health_left()).is_equal(70)
	var numbers: Array[DamageNumber] = _numbers(player)
	assert_int(numbers.size()).is_equal(1)
	assert_int(numbers[0].amount).is_equal(10)
	assert_bool(numbers[0].critical).is_false()


func test_a_hit_on_its_back_is_a_critical_for_double() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var hits: Array[Array] = []
	crab.damaged.connect(func(amount: int, critical: bool) -> void: hits.append([amount, critical]))

	crab.cycle.engage()
	crab.cycle.tick(crab.windup_seconds)
	crab.cycle.flip()
	crab.take_strike(Vector3.ZERO, 10)

	assert_int(crab.health_left()).is_equal(60)
	assert_array(hits).contains_exactly([[20, true]])
	assert_bool(crab.last_hit_critical).is_true()
	assert_bool(_numbers(player)[0].critical).is_true()


func test_a_hit_that_doesnt_count_shows_no_number() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	assert_bool(crab.take_strike(Vector3.ZERO, 10)).is_false()

	assert_int(crab.health_left()).is_equal(80)
	assert_array(_numbers(player)).is_empty()


func test_a_fillet_that_flips_it_does_no_damage() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	crab.cycle.engage()
	crab.cycle.tick(crab.windup_seconds)
	assert_bool(crab.take_strike(Vector3.ZERO, 20, true)).is_true()

	assert_bool(crab.is_flipped()).is_true()
	assert_int(crab.health_left()).is_equal(80)
	assert_array(_numbers(player)).is_empty()


# --- Death and its meat ------------------------------------------------------------

func test_when_its_health_is_gone_it_dies_and_leaves_its_meat() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	_open(crab)
	crab.take_strike(Vector3.ZERO, 70)
	assert_bool(crab.is_dead()).is_false()
	crab.take_strike(Vector3.ZERO, 10)
	await physics_ticks(runner, 2)

	assert_bool(crab.is_dead()).is_true()
	assert_bool((crab.get_node("LevelLabel") as Label3D).visible).is_false()
	var pickups: Array[Pickup3D] = _pickups(player)
	assert_int(pickups.size()).is_equal(1)
	assert_object(pickups[0].item.item).is_same(Crab.CRAB_MEAT)
	assert_int(pickups[0].item.quality).is_equal(1)
	assert_float(pickups[0].global_position.distance_to(crab.global_position)).is_less(0.5)


func test_its_meat_is_as_good_as_its_level() -> void:
	assert_int(Crab.meat_quality_for(1)).is_equal(1)
	assert_int(Crab.meat_quality_for(2)).is_equal(2)
	assert_int(Crab.meat_quality_for(3)).is_equal(3)
	assert_int(Crab.meat_quality_for(7)).is_equal(3)


func test_a_level_two_crab_leaves_two_star_meat() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	crab.level = 2
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	_open(crab)
	crab.take_strike(Vector3.ZERO, crab.health_left())
	await physics_ticks(runner, 2)

	assert_int(_pickups(player)[0].item.quality).is_equal(2)


func test_dead_it_rolls_onto_its_back_and_stays() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _still_crab(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	_open(crab)
	crab.take_strike(Vector3.ZERO, 80)
	await physics_ticks(runner, 60)

	assert_float(crab.flipped_amount()).is_equal(1.0)
	assert_float(absf((crab.get_node("Model") as Node3D).rotation.z)).is_greater(3.0)
	assert_bool(crab.take_strike(Vector3.ZERO, 10)).is_false()


# A crab that won't fight (nobody's near enough for it to notice), far
# enough away not to bother the player.
func _still_crab(player: Player3D) -> Crab:
	var crab: Crab = new_crab(player, Vector3(0, 0, -5))
	crab.notice_range = 0.0
	return crab


# Puts [param crab] straight into its opening, so strikes count. Strike in the
# same tick: left alone, a crab nobody's near stops fighting.
func _open(crab: Crab) -> void:
	crab.cycle.engage()
	crab.cycle.tick(crab.windup_seconds + crab.attack_seconds)


func _numbers(player: Player3D) -> Array[DamageNumber]:
	var found: Array[DamageNumber] = []
	for node: Node in player.get_parent().get_children():
		if node is DamageNumber:
			found.append(node as DamageNumber)
	return found


func _pickups(player: Player3D) -> Array[Pickup3D]:
	var found: Array[Pickup3D] = []
	for node: Node in player.get_parent().get_children():
		if node is Pickup3D:
			found.append(node as Pickup3D)
	return found


# A crab at [param pos] wearing the stand-in model.
func _new_rigged_crab(player: Player3D, pos: Vector3) -> Crab:
	var crab: Crab = new_crab(player, pos)
	_dresser(crab).path = RIG
	return crab


func _dresser(crab: Crab) -> ThirdPartyModel:
	return crab.get_node("Model/Crab") as ThirdPartyModel
