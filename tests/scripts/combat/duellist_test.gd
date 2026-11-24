extends GameTestSuite
## Tests for Duellist and Crab together: a crab's hit costs half a heart,
## the pan parries it inside the window, the knife counts only in an
## opening, and a defeat sends you back to the landing with half your items.
##
## The player stands at the origin facing -Z with the crab just ahead. The
## crab rears up for 0.8 s (48 physics ticks), so its first hit lands about
## tick 49, and it's open from about tick 64 for 1.2 s.

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
const PAN: Item = preload("res://data/items/frying_pan.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const CLOSE: Vector3 = Vector3(0, 0, -1.3)
## Ticks until just after the crab's first hit has landed.
const FIRST_HIT: int = 56
## Ticks until the crab is open after its first attack: its blow lands
## about tick 49 and freezes the game for a moment.
const FIRST_OPENING: int = 70 + HitStop.HURT_TICKS


# --- Being hit -------------------------------------------------------------------

func test_a_crabs_hit_costs_half_a_heart() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, FIRST_HIT)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)


func test_no_hit_lands_before_the_windup_ends() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 40)

	assert_int(crab.cycle.state).is_equal(CrabCycle.State.WINDUP)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_out_of_its_reach_the_attack_misses() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -5))
	# It can't close the distance.
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, FIRST_HIT)

	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.WINDUP)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_beside_the_crab_its_lunge_misses() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -1.3))
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	# Facing away from the player (it would turn back, but it's committed).
	await physics_ticks(runner, 40)
	crab.rotation.y = PI / 2.0
	await physics_ticks(runner, FIRST_HIT - 42)

	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_committed_it_stops_turning_to_follow() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	# The last 0.2 s of its 0.8 s windup.
	await physics_ticks(runner, 40)
	assert_bool(crab.cycle.is_committed()).is_true()
	var aim: float = crab.rotation.y

	player.global_position = Vector3(3, 0, -1.3)
	await physics_ticks(runner, 4)

	assert_float(crab.rotation.y).is_equal_approx(aim, 0.001)


func test_stepping_aside_as_it_commits_dodges_the_lunge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 40)

	# Still in its reach, but off to its side.
	player.global_position = Vector3(1.4, 0, -1.0)
	await physics_ticks(runner, FIRST_HIT - 40)

	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.WINDUP)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_its_lunge_reaches_ahead_not_aside() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3.ZERO)
	crab.notice_range = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	crab.global_position = Vector3(0, 0, -5)
	crab.rotation.y = 0.0
	await physics_ticks(runner, 1)

	assert_bool(crab.lunge_reaches(Vector3(0, 0, -6.5))).is_true()
	assert_bool(crab.lunge_reaches(Vector3(1.5, 0, -5.5))).is_false()
	assert_bool(crab.lunge_reaches(Vector3(0, 0, -7.5))).is_false()


func test_a_far_off_crab_stays_idle() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -15))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, FIRST_HIT)

	assert_int(crab.cycle.state).is_equal(CrabCycle.State.IDLE)


func test_the_crab_closes_in_while_it_rears_up() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -5))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 40)

	assert_float(crab.global_position.z).is_greater(-4.0)


# --- The pan ---------------------------------------------------------------------

func test_a_parry_inside_the_window_turns_the_hit_and_staggers_the_crab() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	var parried: Array[int] = [0]
	duellist_of(player).parried.connect(func() -> void: parried[0] += 1)
	# 40 ticks is 0.67 s: the pan is up until 0.97 s, and the hit lands at 0.8 s.
	await physics_ticks(runner, 40)

	assert_bool(duellist_of(player).raise_pan()).is_true()
	await physics_ticks(runner, FIRST_HIT - 40)

	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	assert_int(crab.cycle.state).is_equal(CrabCycle.State.STAGGERED)
	assert_int(parried[0]).is_equal(1)


func test_a_parry_just_in_time_flips_the_crab() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	var flips: Array[int] = [0]
	crab.flipped.connect(func() -> void: flips[0] += 1)
	# The hit lands about tick 49: the pan goes up 4 ticks (0.07 s) before.
	await physics_ticks(runner, 45)

	duellist_of(player).raise_pan()
	await physics_ticks(runner, FIRST_HIT - 45)

	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	assert_bool(crab.is_flipped()).is_true()
	assert_int(flips[0]).is_equal(1)


func test_a_parry_too_early_doesnt_stop_the_hit() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	# 10 ticks is 0.17 s: the pan is down again by 0.47 s.
	await physics_ticks(runner, 10)

	duellist_of(player).raise_pan()
	await physics_ticks(runner, FIRST_HIT - 10)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)
	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.STAGGERED)


func test_without_a_pan_there_is_no_parry() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 40)

	assert_bool(duellist_of(player).raise_pan()).is_false()
	await physics_ticks(runner, FIRST_HIT - 40)

	assert_int(duellist_of(player).hearts.halves).is_equal(5)


func test_the_pan_works_from_any_slot_not_just_the_selected_one() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	player.toolbar.add(ItemInstance.new(TOMATO))
	player.toolbar.select(0)
	await physics_ticks(runner, 2)

	assert_bool(duellist_of(player).has_pan()).is_true()
	assert_bool(duellist_of(player).raise_pan()).is_true()


func test_the_parry_button_raises_the_pan() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	await physics_ticks(runner, 2)

	await press(runner, "parry")

	assert_bool(duellist_of(player).parry.is_active()).is_true()


# --- The knife -------------------------------------------------------------------

func test_use_tool_with_nothing_to_work_on_swings_the_knife() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	await press(runner, "use_tool")

	assert_bool(duellist_of(player).is_striking()).is_true()


func test_use_tool_on_something_a_tool_works_on_doesnt_swing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var board: Interactable3D = _interactable(player, Vector3(0, 0.9, -0.8))
	var used: Array[int] = [0]
	board.tool_used.connect(func(_p: Player3D, _t: HandTool) -> void: used[0] += 1)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 4)

	await press(runner, "use_tool")

	assert_int(used[0]).is_equal(1)
	assert_bool(duellist_of(player).is_striking()).is_false()


func test_without_a_tool_there_is_no_swing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	player.toolbar.set_tool(0, null)

	assert_bool(duellist_of(player).strike()).is_false()


func test_holding_a_tomato_use_doesnt_swing_the_knife() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	player.toolbar.add(ItemInstance.new(TOMATO))

	await press(runner, "use_tool")

	assert_bool(duellist_of(player).is_knife_out()).is_false()
	assert_bool(duellist_of(player).is_striking()).is_false()


func test_a_second_swing_waits_for_the_first() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	assert_bool(duellist_of(player).strike()).is_true()
	assert_bool(duellist_of(player).strike()).is_false()
	await physics_ticks(runner, 40)

	assert_bool(duellist_of(player).strike()).is_true()


func test_a_strike_counts_while_the_crab_is_open() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var hits: Array[bool] = []
	duellist_of(player).struck.connect(func(hit: bool) -> void: hits.append(hit))

	await physics_ticks(runner, FIRST_OPENING)
	await strike_and_land(runner, player)

	assert_int(crab.cycle.state).is_equal(CrabCycle.State.OPENING)
	assert_int(crab.cycle.damage_taken).is_equal(Duellist.CHOP.damage)
	assert_array(hits).contains_exactly([true])


func test_a_strike_during_the_windup_doesnt_count() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var hits: Array[bool] = []
	duellist_of(player).struck.connect(func(hit: bool) -> void: hits.append(hit))

	await physics_ticks(runner, 20)
	await strike_and_land(runner, player)

	assert_int(crab.cycle.damage_taken).is_equal(0)
	assert_array(hits).contains_exactly([false])


func test_a_strike_misses_a_crab_behind_you() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, Vector3(0, 0, 1.3))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, FIRST_OPENING)
	await strike_and_land(runner, player)

	assert_bool(crab.cycle.is_open()).is_true()
	assert_int(crab.cycle.damage_taken).is_equal(0)


func test_reach_is_a_distance_and_an_arc() -> void:
	var ahead: Vector3 = Vector3.FORWARD
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, Vector3(0, 0, -1.5), 2.0, 120.0)).is_true()
	# Too far.
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, Vector3(0, 0, -2.5), 2.0, 120.0)).is_false()
	# Just inside the arc (50 degrees off), and just outside it (70).
	var inside: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(50.0)) * 1.5
	var outside: Vector3 = Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(70.0)) * 1.5
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, inside, 2.0, 120.0)).is_true()
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, outside, 2.0, 120.0)).is_false()
	# Height doesn't matter.
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, Vector3(0, 3, -1.5), 2.0, 120.0)).is_true()
	# All round reaches straight behind, too.
	assert_bool(Duellist.in_reach(Vector3.ZERO, ahead, Vector3(0, 0, 1.5), 2.0, 360.0)).is_true()


# --- The combo and the fillet ------------------------------------------------------

func test_three_taps_in_an_opening_chop_slice_and_cleave() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	# Knocked back no distance, so every cut stays in reach.
	crab.skid_fade = 10000.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var cuts: Array[StringName] = []
	duellist_of(player).cut_started.connect(func(cut: KnifeCut) -> void: cuts.append(cut.id))
	await physics_ticks(runner, FIRST_OPENING)

	for i: int in 3:
		await strike_and_land(runner, player)
		await physics_ticks(runner, 12)

	assert_array(cuts).contains_exactly([&"chop", &"slice", &"cleave"])
	assert_int(crab.cycle.damage_taken).is_equal(40)


func test_a_pause_starts_the_chain_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var cuts: Array[StringName] = []
	duellist_of(player).cut_started.connect(func(cut: KnifeCut) -> void: cuts.append(cut.id))
	await physics_ticks(runner, 2)

	duellist_of(player).strike()
	await physics_ticks(runner, 60)
	duellist_of(player).strike()

	assert_array(cuts).contains_exactly([&"chop", &"chop"])


func test_holding_use_tool_charges_and_letting_go_fillets() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var cuts: Array[StringName] = []
	duellist_of(player).cut_started.connect(func(cut: KnifeCut) -> void: cuts.append(cut.id))
	await physics_ticks(runner, 2)

	await hold(runner, "use_tool")
	await physics_ticks(runner, 30)
	assert_bool(duellist_of(player).is_charging()).is_true()
	await physics_ticks(runner, 32)
	assert_bool(duellist_of(player).combo.is_charged()).is_true()
	await release(runner, "use_tool")

	assert_array(cuts).contains_exactly([&"chop", &"fillet"])


func test_letting_go_early_gives_the_weak_spin() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var cuts: Array[StringName] = []
	duellist_of(player).cut_started.connect(func(cut: KnifeCut) -> void: cuts.append(cut.id))
	await physics_ticks(runner, 2)

	await hold(runner, "use_tool")
	await physics_ticks(runner, 30)
	await release(runner, "use_tool")

	assert_array(cuts).contains_exactly([&"chop", &"weak_spin"])


func test_charging_you_walk_at_half_speed() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var full_speed: float = player.move_speed

	await hold(runner, "use_tool")
	await physics_ticks(runner, 30)

	assert_float(player.move_speed).is_equal_approx(full_speed / 2.0, 0.01)
	await release(runner, "use_tool")
	await physics_ticks(runner, 2)
	assert_float(player.move_speed).is_equal_approx(full_speed, 0.01)


func test_a_blow_breaks_the_charge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var cuts: Array[StringName] = []
	duellist_of(player).cut_started.connect(func(cut: KnifeCut) -> void: cuts.append(cut.id))
	await physics_ticks(runner, 2)
	await hold(runner, "use_tool")
	await physics_ticks(runner, 60)

	duellist_of(player).receive_hit(1, CLOSE)
	await release(runner, "use_tool")

	assert_bool(duellist_of(player).is_charging()).is_false()
	assert_array(cuts).contains_exactly([&"chop"])


func test_holding_use_tool_at_a_board_doesnt_charge() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_interactable(player, Vector3(0, 0.9, -0.8))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 4)

	await hold(runner, "use_tool")
	await physics_ticks(runner, 70)

	assert_bool(duellist_of(player).is_charging()).is_false()
	await release(runner, "use_tool")
	assert_bool(duellist_of(player).is_striking()).is_false()


func test_a_fillet_as_the_crab_lunges_flips_it() -> void:
	var player: Player3D = new_player_3d_on_floor()
	# Once the chop that starts the charge has stepped the player 0.3 m in,
	# just out of its lunge's reach and inside the fillet's.
	var crab: Crab = new_crab(player, Vector3(0, 0, -2.6))
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	await hold(runner, "use_tool")

	# Charged, and the crab just starting to lunge.
	for tick: int in 400:
		if duellist_of(player).combo.is_charged() \
				and crab.cycle.state == CrabCycle.State.ATTACK \
				and crab.cycle.time_in_state < 0.05:
			break
		await physics_ticks(runner, 1)
	await release(runner, "use_tool")
	await physics_ticks(runner, 12)

	assert_bool(crab.is_flipped()).is_true()
	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_a_fillet_hits_all_round() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	# Behind the player, where a chop can't reach, and out of its own lunge's
	# reach (a blow would break the charge) once the chop has stepped the
	# player 0.3 m away.
	var crab: Crab = new_crab(player, Vector3(0, 0, 2.1))
	crab.scuttle_speed = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await hold(runner, "use_tool")

	for tick: int in 400:
		if duellist_of(player).combo.is_charged() and crab.cycle.state == CrabCycle.State.OPENING:
			break
		await physics_ticks(runner, 1)
	await release(runner, "use_tool")
	await physics_ticks(runner, 12)

	assert_int(crab.cycle.damage_taken).is_equal(Duellist.FILLET.damage)


# --- Killing the crab -------------------------------------------------------------

func test_two_good_openings_clear_a_crab() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	crab.skid_fade = 10000.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var openings: Array[int] = [0]
	crab.cycle.state_changed.connect(func(state: CrabCycle.State) -> void:
		if state == CrabCycle.State.OPENING:
			openings[0] += 1)

	# Tapping all through every opening, for up to 10 seconds.
	for tick: int in 600:
		if crab.is_dead():
			break
		if crab.cycle.is_open():
			duellist_of(player).strike()
		await physics_ticks(runner, 1)

	assert_bool(crab.is_dead()).is_true()
	assert_int(openings[0]).is_equal(2)

func test_strikes_in_openings_kill_it_and_it_never_hits_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	crab.health_override = 30
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var deaths: Array[int] = [0]
	crab.died.connect(func() -> void: deaths[0] += 1)

	# Strike whenever it's open, for up to 15 seconds.
	for tick: int in 900:
		if crab.is_dead():
			break
		if crab.cycle.is_open():
			duellist_of(player).strike()
		await physics_ticks(runner, 1)

	assert_bool(crab.is_dead()).is_true()
	assert_int(deaths[0]).is_equal(1)
	assert_bool(crab.is_in_group(LockOn.GROUP)).is_false()
	# It lies still and never hits again.
	var hearts_then: int = duellist_of(player).hearts.halves
	var where: Vector3 = crab.global_position
	await physics_ticks(runner, 120)
	assert_float(crab.global_position.distance_to(where)).is_less(0.3)
	assert_int(duellist_of(player).hearts.halves).is_equal(hearts_then)


func test_a_dead_crab_lies_there_then_sinks_and_is_gone() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, Vector3(0, 0, -4))
	crab.notice_range = 0.0
	crab.health_override = 1
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	crab.cycle.engage()
	crab.cycle.tick(crab.windup_seconds + crab.attack_seconds)

	crab.take_strike()
	await physics_ticks(runner, int(crab.linger_seconds * 60.0) - 10)
	assert_bool(is_instance_valid(crab)).is_true()
	assert_float(crab.sunk_amount()).is_equal(0.0)
	await physics_ticks(runner, int(crab.sink_seconds * 60.0) + 20)

	assert_bool(is_instance_valid(crab)).is_false()


func test_a_parry_then_strikes_in_the_stagger_count() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	# The knife back in hand to strike (#207): only the selected slot is used.
	player.toolbar.select(0)
	await physics_ticks(runner, 40)
	duellist_of(player).raise_pan()
	await physics_ticks(runner, FIRST_HIT - 40)

	await strike_and_land(runner, player)

	assert_int(crab.cycle.damage_taken).is_equal(Duellist.CHOP.damage)


# --- Defeat ----------------------------------------------------------------------

func test_defeat_returns_you_to_the_landing_with_half_your_items() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var landing: Marker3D = _landing(player, Vector3(10, 0, 10))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	for item: Item in [PAN, TOMATO, LETTUCE, TOMATO] as Array[Item]:
		player.toolbar.add(ItemInstance.new(item))
	var lost: Array[int] = []
	duellist_of(player).defeated.connect(
			func(items: Array[ItemInstance]) -> void: lost.append(items.size()))
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(6, Vector3.ZERO)
	await physics_ticks(runner, 2)

	assert_float(LockOn.flat_distance(player.global_position, landing.global_position)) \
			.is_less(0.1)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	assert_array(player.toolbar.get_tools()).contains_exactly([KNIFE])
	assert_int(player.toolbar.size()).is_equal(2)
	assert_object(player.toolbar.get_item(1).item).is_same(PAN)
	assert_object(player.toolbar.get_item(2).item).is_same(TOMATO)
	assert_array(lost).contains_exactly([2])


func test_a_crab_can_beat_you_hit_by_hit() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var landing: Marker3D = _landing(player, Vector3(10, 0, 10))
	new_crab(player, CLOSE)
	# One heart: two hits.
	duellist_of(player).max_hearts = 1
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var defeats: Array[int] = [0]
	duellist_of(player).defeated.connect(
			func(_items: Array[ItemInstance]) -> void: defeats[0] += 1)

	# The second hit lands 2.25 s after the first: about tick 184.
	await physics_ticks(runner, 200)

	assert_int(defeats[0]).is_equal(1)
	assert_float(LockOn.flat_distance(player.global_position, landing.global_position)) \
			.is_less(0.1)
	assert_int(duellist_of(player).hearts.halves).is_equal(2)


func test_a_crab_that_wins_is_whole_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	_landing(player, Vector3(20, 0, 20))
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)
	await strike_and_land(runner, player)
	assert_int(crab.cycle.damage_taken).is_equal(Duellist.CHOP.damage)
	# Until the moment after the crab's own blow has passed.
	await physics_ticks(runner, 45)

	duellist_of(player).receive_hit(6, Vector3.ZERO)
	await physics_ticks(runner, 3)

	assert_int(crab.cycle.damage_taken).is_equal(0)
	assert_int(crab.cycle.state).is_equal(CrabCycle.State.IDLE)


func test_defeat_lets_go_of_lock_on() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_landing(player, Vector3(20, 0, 20))
	var crab: Crab = new_crab(player, Vector3(0, 0, -4))
	crab.notice_range = 0.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")
	assert_object(player.lock_target).is_same(crab)

	duellist_of(player).receive_hit(6, Vector3.ZERO)

	assert_object(player.lock_target).is_null()
	await release(runner, "lock_on")


# --- The lantern's light ----------------------------------------------------------

func test_the_lantern_warns_of_the_windup_and_brightens_at_the_opening() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_crab(player, CLOSE)
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	assert_int(spirit.mood).is_equal(LanternSpirit.Mood.CALM)

	await hold(runner, "lock_on")
	assert_int(spirit.mood).is_equal(LanternSpirit.Mood.WARNING)

	await physics_ticks(runner, FIRST_OPENING - 7)
	assert_int(spirit.mood).is_equal(LanternSpirit.Mood.OPEN)

	await release(runner, "lock_on")
	assert_int(spirit.mood).is_equal(LanternSpirit.Mood.CALM)


func test_each_state_has_its_mood() -> void:
	assert_int(Duellist.mood_for(CrabCycle.State.IDLE)).is_equal(LanternSpirit.Mood.CALM)
	assert_int(Duellist.mood_for(CrabCycle.State.WINDUP)).is_equal(LanternSpirit.Mood.WARNING)
	assert_int(Duellist.mood_for(CrabCycle.State.ATTACK)).is_equal(LanternSpirit.Mood.CALM)
	assert_int(Duellist.mood_for(CrabCycle.State.OPENING)).is_equal(LanternSpirit.Mood.OPEN)
	assert_int(Duellist.mood_for(CrabCycle.State.STAGGERED)).is_equal(LanternSpirit.Mood.OPEN)
	assert_int(Duellist.mood_for(CrabCycle.State.DEAD)).is_equal(LanternSpirit.Mood.CALM)
	assert_int(Duellist.mood_for(CrabCycle.State.FLIPPED)).is_equal(LanternSpirit.Mood.OPEN)


# --- Weight: swings, knock back and the moment after a blow ----------------------

func test_the_chop_lasts_a_quarter_of_a_second() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).strike()
	await physics_ticks(runner, 13)
	assert_bool(duellist_of(player).is_striking()).is_true()
	await physics_ticks(runner, 3)

	assert_bool(duellist_of(player).is_striking()).is_false()
	assert_float(Duellist.CHOP.seconds).is_equal(0.25)


func test_a_blow_throws_the_player_back_away_from_it() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	# From ahead of them (-Z), so they go back (+Z).
	duellist_of(player).receive_hit(1, Vector3(0, 0, -1.3))
	await physics_ticks(runner, 40)

	assert_float(player.global_position.z).is_greater(0.5)
	assert_float(absf(player.global_position.x)).is_less(0.05)


func test_a_blow_from_the_side_throws_the_player_sideways() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(1, Vector3(2, 0, 0))
	await physics_ticks(runner, 40)

	assert_float(player.global_position.x).is_less(-0.5)
	assert_float(absf(player.global_position.z)).is_less(0.05)


func test_a_blow_leaves_the_player_stumbling_for_a_moment() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(1, Vector3(0, 0, -1.3))

	assert_bool(player.is_stumbling()).is_true()
	await physics_ticks(runner, 40)
	assert_bool(player.is_stumbling()).is_false()


func test_a_strike_knocks_the_crab_back_away_from_the_player() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: Crab = new_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)
	var before: Vector3 = crab.global_position

	await strike_and_land(runner, player)
	assert_bool(crab.is_skidding()).is_true()
	await physics_ticks(runner, 30)

	# The player is behind it (+Z), so it goes on ahead (-Z).
	assert_float(crab.global_position.z).is_less(before.z - 0.5)
	assert_bool(crab.is_skidding()).is_false()


func test_a_second_blow_straight_after_the_first_does_nothing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var duellist: Duellist = duellist_of(player)

	assert_int(duellist.receive_hit(1, CLOSE)).is_equal(Duellist.Hit.LANDED)
	assert_bool(duellist.is_invulnerable()).is_true()
	assert_int(duellist.receive_hit(1, CLOSE)).is_equal(Duellist.Hit.IGNORED)

	assert_int(duellist.hearts.halves).is_equal(5)


func test_once_the_moment_passes_blows_land_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var duellist: Duellist = duellist_of(player)
	duellist.receive_hit(1, CLOSE)

	# A second of game time, after the freeze.
	await physics_ticks(runner, HitStop.HURT_TICKS + 62)

	assert_bool(duellist.is_invulnerable()).is_false()
	assert_int(duellist.receive_hit(1, CLOSE)).is_equal(Duellist.Hit.LANDED)
	assert_int(duellist.hearts.halves).is_equal(4)


func test_a_crabs_blow_in_that_moment_doesnt_stagger_it() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = new_crab(player, CLOSE)
	crab.scuttle_speed = 0.0
	crab.attack_reach = 5.0
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var duellist: Duellist = duellist_of(player)
	# Hurt by something else, just before the crab's own blow lands.
	await physics_ticks(runner, 40)
	duellist.receive_hit(1, CLOSE)

	await physics_ticks(runner, FIRST_HIT - 42 + HitStop.HURT_TICKS)

	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.WINDUP)
	assert_int(crab.cycle.state).is_not_equal(CrabCycle.State.STAGGERED)
	assert_int(duellist.hearts.halves).is_equal(5)


# A landing marker at [param pos] in [param player]'s world.
func _landing(player: Player3D, pos: Vector3) -> Marker3D:
	var landing: Marker3D = Marker3D.new()
	landing.position = pos
	landing.add_to_group(Duellist.LANDING_GROUP)
	player.get_parent().add_child(landing)
	return landing


# Something a tool works on, at [param pos] in [param player]'s world.
func _interactable(player: Player3D, pos: Vector3) -> Interactable3D:
	var area: Interactable3D = Interactable3D.new()
	area.position = pos
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3.ONE * 0.4
	shape.shape = box
	area.add_child(shape)
	player.get_parent().add_child(area)
	return area


# --- The tools you carry (#152) ---------------------------------------------------

func test_the_pan_you_carry_sets_the_parry_window() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	var better: Item = PAN.duplicate() as Item
	better.parry_seconds = 0.5
	better.perfect_parry_seconds = 0.2
	player.toolbar.add(ItemInstance.new(better))

	assert_bool(duellist_of(player).raise_pan()).is_true()

	assert_float(duellist_of(player).parry.window_seconds).is_equal(0.5)
	assert_float(duellist_of(player).parry.perfect_seconds).is_equal(0.2)


func test_a_better_knife_hits_harder() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	var better: HandTool = KNIFE.duplicate() as HandTool
	better.damage = 1.5
	player.toolbar.set_tool(0, better)

	assert_float(duellist_of(player).knife_damage()).is_equal(1.5)


func test_the_cheap_knife_hits_as_hard_as_its_cuts_say() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	assert_float(duellist_of(player).knife_damage()).is_equal(1.0)
