extends GameTestSuite
## Tests for the greybox duel arena: what the player starts with, a whole
## duel won with the real buttons, and one lost.

const ARENA: String = "res://scenes/prototype/islands/duel_arena.tscn"
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
## Just in front of the near crab, which stands at the arena's middle.
const BY_THE_CRAB: Vector3 = Vector3(0, 0.05, 1.4)


func test_you_start_at_the_landing_with_a_knife_a_pan_and_some_food() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	await physics_ticks(runner, 10)
	var player: Player3D = runner.find_child("Player") as Player3D
	var landing: Node3D = runner.find_child("Landing") as Node3D

	assert_float(LockOn.flat_distance(player.global_position, landing.global_position)) \
			.is_less(0.5)
	assert_bool(landing.is_in_group(Duellist.LANDING_GROUP)).is_true()
	assert_object(player.toolbar.selected_tool()).is_same(KNIFE)
	assert_bool(duellist_of(player).has_pan()).is_true()
	assert_int(player.toolbar.size()).is_equal(4)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)


func test_the_lantern_follows_you_here() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	await physics_ticks(runner, 10)
	var player: Player3D = runner.find_child("Player") as Player3D
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit

	assert_object(spirit.home).is_null()
	assert_float(spirit.global_position.distance_to(player.global_position)).is_less(2.5)


func test_the_crabs_at_the_landing_leave_you_alone() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	var player: Player3D = runner.find_child("Player") as Player3D

	await physics_ticks(runner, 240)

	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	assert_int((runner.find_child("FogCrab") as FogCrab).cycle.state).is_equal(
			CrabCycle.State.IDLE)


func test_a_duel_won_parry_then_strike_until_the_fog_clears() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	await physics_ticks(runner, 10)
	var player: Player3D = place_player_3d(runner, BY_THE_CRAB)
	var crab: FogCrab = runner.find_child("FogCrab") as FogCrab
	await physics_ticks(runner, 2)
	await hold(runner, "lock_on")
	assert_object(player.lock_target).is_same(crab)

	# Read the crab as a player would: raise the pan late in its windup, and
	# strike whenever it's open. Up to 20 seconds.
	for tick: int in 1200:
		if crab.is_cleared():
			break
		if crab.cycle.state == CrabCycle.State.WINDUP and crab.cycle.progress > 0.8:
			runner.simulate_action_pressed("parry")
		elif crab.cycle.is_open():
			runner.simulate_action_pressed("use_tool")
		await physics_ticks(runner, 1)

	assert_bool(crab.is_cleared()).is_true()
	# Every hit was parried.
	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	# Lock-on let go by itself, and the lantern came back.
	assert_object(player.lock_target).is_null()
	await release(runner, "lock_on")


func test_a_duel_lost_back_at_the_landing_with_half_your_basket() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	await physics_ticks(runner, 10)
	var player: Player3D = place_player_3d(runner, BY_THE_CRAB)
	var landing: Node3D = runner.find_child("Landing") as Node3D
	var defeats: Array[int] = [0]
	duellist_of(player).defeated.connect(
			func(_lost: Array[ItemInstance]) -> void: defeats[0] += 1)

	# Stand there and take it: six hits, 2.25 s apart. Up to 20 seconds.
	for tick: int in 1200:
		if defeats[0] > 0:
			break
		await physics_ticks(runner, 1)
	await physics_ticks(runner, 5)

	assert_int(defeats[0]).is_equal(1)
	assert_float(LockOn.flat_distance(player.global_position, landing.global_position)) \
			.is_less(0.5)
	assert_int(duellist_of(player).hearts.halves).is_equal(6)
	# Pan, tomato, lettuce, tomato: the last two are gone, the knife is kept.
	assert_object(player.toolbar.get_tool(0)).is_same(KNIFE)
	assert_int(player.toolbar.size()).is_equal(2)
	assert_bool(duellist_of(player).has_pan()).is_true()


func test_a_pan_lost_in_defeat_is_given_back_here() -> void:
	var runner: GdUnitSceneRunner = scene_runner(ARENA)
	await physics_ticks(runner, 10)
	var player: Player3D = runner.find_child("Player") as Player3D
	# Drop everything but the pan, then pick up a tomato before it: the pan
	# is now in the last filled slot, so it's the one a defeat takes.
	for slot: int in range(2, Toolbar.SLOT_COUNT):
		player.toolbar.take_item(slot)
	var pan: ItemInstance = player.toolbar.take_item(1)
	player.toolbar.add(ItemInstance.new(preload("res://data/items/tomato.tres")))
	player.toolbar.add(pan)
	player.toolbar.select(0)

	duellist_of(player).receive_hit(6)
	await physics_ticks(runner, 2)

	assert_bool(duellist_of(player).has_pan()).is_true()
	assert_int(player.toolbar.selected_index).is_equal(0)
