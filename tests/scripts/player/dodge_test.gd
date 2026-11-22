extends GameTestSuite
## Tests for Dodge: Interact with nothing in front jumps out of the way.
## Locked on, the stick picks a sidehop, backflip or roll; not locked on, a
## roll the way you're walking. Never while the knife is cutting or charging.
##
## The player stands at the origin facing -Z, the camera behind them, so
## "move_right" points along +X.

const AHEAD: Vector3 = Vector3(0, 0, -4)


# --- Which dodge -------------------------------------------------------------------

func test_locked_on_left_and_right_sidehop() -> void:
	var facing: Vector3 = Vector3.FORWARD
	assert_int(Dodge.kind_for(Vector3.RIGHT, facing, true)).is_equal(Dodge.Kind.SIDEHOP_RIGHT)
	assert_int(Dodge.kind_for(Vector3.LEFT, facing, true)).is_equal(Dodge.Kind.SIDEHOP_LEFT)


func test_locked_on_back_or_nothing_backflips() -> void:
	var facing: Vector3 = Vector3.FORWARD
	assert_int(Dodge.kind_for(Vector3.BACK, facing, true)).is_equal(Dodge.Kind.BACKFLIP)
	assert_int(Dodge.kind_for(Vector3.ZERO, facing, true)).is_equal(Dodge.Kind.BACKFLIP)


func test_locked_on_forward_rolls() -> void:
	assert_int(Dodge.kind_for(Vector3.FORWARD, Vector3.FORWARD, true)).is_equal(Dodge.Kind.ROLL)


func test_the_stick_counts_against_the_way_you_face() -> void:
	# Facing +X, the stick pushed along -Z is to the left.
	assert_int(Dodge.kind_for(Vector3.FORWARD, Vector3.RIGHT, true)) \
			.is_equal(Dodge.Kind.SIDEHOP_LEFT)


func test_not_locked_on_walking_rolls_and_standing_does_nothing() -> void:
	assert_int(Dodge.kind_for(Vector3.LEFT, Vector3.FORWARD, false)).is_equal(Dodge.Kind.ROLL)
	assert_int(Dodge.kind_for(Vector3.ZERO, Vector3.FORWARD, false)).is_equal(Dodge.Kind.NONE)


func test_each_dodge_goes_its_way() -> void:
	var facing: Vector3 = Vector3.FORWARD
	assert_vector(Dodge.direction_for(Dodge.Kind.SIDEHOP_RIGHT, Vector3.ZERO, facing)) \
			.is_equal_approx(Vector3.RIGHT, Vector3.ONE * 0.001)
	assert_vector(Dodge.direction_for(Dodge.Kind.SIDEHOP_LEFT, Vector3.ZERO, facing)) \
			.is_equal_approx(Vector3.LEFT, Vector3.ONE * 0.001)
	assert_vector(Dodge.direction_for(Dodge.Kind.BACKFLIP, Vector3.ZERO, facing)) \
			.is_equal_approx(Vector3.BACK, Vector3.ONE * 0.001)
	assert_vector(Dodge.direction_for(Dodge.Kind.ROLL, Vector3.LEFT, facing)) \
			.is_equal_approx(Vector3.LEFT, Vector3.ONE * 0.001)


# --- Dodging -----------------------------------------------------------------------

func test_locked_on_interact_and_right_sidehops_right() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)

	runner.simulate_action_press("move_right")
	await press(runner, "interact")
	assert_bool(player.is_dodging()).is_true()
	await physics_ticks(runner, 30)
	runner.simulate_action_release("move_right")

	# A good step to the side, and still facing the target.
	assert_float(player.global_position.x).is_greater(1.5)
	assert_float(absf(player.global_position.z)).is_less(0.3)


func test_locked_on_interact_alone_backflips_away() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)

	await press(runner, "interact")
	assert_str(String(player.dodge_move.id)).is_equal("backflip")
	await physics_ticks(runner, 40)

	assert_float(player.global_position.z).is_greater(2.0)


func test_a_backflip_leaves_the_ground_and_lands() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)
	var ground: float = player.global_position.y

	await press(runner, "interact")
	await physics_ticks(runner, 8)
	assert_float(player.global_position.y).is_greater(ground + 0.1)
	await physics_ticks(runner, 40)

	assert_bool(player.is_on_floor()).is_true()
	assert_bool(player.is_dodging()).is_false()


func test_walking_without_lock_on_interact_rolls() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	runner.simulate_action_press("move_left")
	await physics_ticks(runner, 2)
	await press(runner, "interact")
	runner.simulate_action_release("move_left")

	assert_str(String(player.dodge_move.id)).is_equal("roll")
	await physics_ticks(runner, 30)
	# A roll goes further than walking for the same time.
	assert_float(player.global_position.x).is_less(-2.5)


func test_standing_still_without_lock_on_interact_does_nothing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	await press(runner, "interact")

	assert_bool(player.is_dodging()).is_false()


func test_with_something_in_front_interact_uses_it_instead() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var thing: Interactable3D = Interactable3D.new()
	thing.position = Vector3(0, 0.9, -0.8)
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3.ONE * 0.4
	shape.shape = box
	thing.add_child(shape)
	player.get_parent().add_child(thing)
	var used: Array[int] = [0]
	thing.interacted.connect(func(_p: Player3D) -> void: used[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 4)
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)

	await press(runner, "interact")

	assert_int(used[0]).is_equal(1)
	assert_bool(player.is_dodging()).is_false()


func test_no_dodging_while_charging() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	await hold(runner, "use_tool")
	await physics_ticks(runner, 30)
	assert_bool(duellist_of(player).is_charging()).is_true()

	await press(runner, "interact")

	assert_bool(player.is_dodging()).is_false()
	await release(runner, "use_tool")


func test_no_knife_mid_dodge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)
	await press(runner, "interact")

	assert_bool(duellist_of(player).strike()).is_false()


func test_a_dodge_breaks_off_the_knifes_chain() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	_lock_on_ahead(player)
	duellist_of(player).strike()
	await physics_ticks(runner, 18)
	assert_int(duellist_of(player).combo.next_index).is_equal(1)

	await press(runner, "interact")

	assert_int(duellist_of(player).combo.next_index).is_equal(0)


func test_a_sidehop_as_the_crab_commits_dodges_its_lunge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, Vector3(0, 0, -1.3))
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await hold(runner, "lock_on")
	# Just into the last 0.2 s of its 0.8 s windup: it's committed.
	await physics_ticks(runner, 35)
	assert_bool(crab.cycle.is_committed()).is_true()

	runner.simulate_action_press("move_right")
	await press(runner, "interact")
	runner.simulate_action_release("move_right")
	await physics_ticks(runner, 20)

	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.WINDUP)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	await release(runner, "lock_on")


func test_standing_still_as_it_commits_you_are_hit() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: FogCrab = new_fog_crab(player, Vector3(0, 0, -1.3))
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await hold(runner, "lock_on")

	await physics_ticks(runner, 60)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)
	await release(runner, "lock_on")


# --- The prompt --------------------------------------------------------------------

func test_locked_on_the_prompt_names_the_dodge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var dodge: Dodge = player.get_node("Dodge") as Dodge
	assert_str(dodge.prompt()).is_empty()
	_lock_on_ahead(player)
	await physics_ticks(runner, 2)

	assert_str(dodge.prompt()).is_equal("Backflip")
	runner.simulate_action_press("move_right")
	await physics_ticks(runner, 1)
	assert_str(dodge.prompt()).is_equal("Sidehop")
	runner.simulate_action_release("move_right")


# Locks the player on to a marker ahead of them, as LockOn would.
func _lock_on_ahead(player: Player3D) -> void:
	var target: Marker3D = Marker3D.new()
	target.position = AHEAD
	player.get_parent().add_child(target)
	player.lock_target = target
