extends GameTestSuite
## Tests for LockOn: picking the nearest target, holding and letting go, and
## what locking on does to the player, the camera and the lantern.
##
## The player stands at the origin facing -Z. Crabs here are told to notice
## nothing (notice_range 0), so they stand still and never hit.

const AHEAD: Vector3 = Vector3(0, 0, -4)


# --- Choosing a target ---------------------------------------------------------

func test_nearest_picks_the_closest_in_reach() -> void:
	var near: Node3D = _marker(Vector3(0, 0, -3))
	var far: Node3D = _marker(Vector3(5, 0, 0))

	assert_object(LockOn.nearest(Vector3.ZERO, [far, near], 9.0)).is_same(near)


func test_nearest_ignores_what_is_out_of_reach() -> void:
	var far: Node3D = _marker(Vector3(0, 0, -20))

	assert_object(LockOn.nearest(Vector3.ZERO, [far], 9.0)).is_null()


func test_distance_ignores_height() -> void:
	assert_float(LockOn.flat_distance(Vector3(0, 5, 0), Vector3(3, -2, 4))).is_equal_approx(
			5.0, 0.001)


# --- Holding the button ---------------------------------------------------------

func test_holding_locks_on_to_the_crab_in_reach() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await hold(runner, "lock_on")

	assert_object(_lock_on(player).target).is_same(crab)
	assert_object(player.lock_target).is_same(crab)
	assert_object(player.camera_rig.look_target).is_same(crab)
	await release(runner, "lock_on")


func test_letting_go_releases_the_target() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")

	await release(runner, "lock_on")

	assert_object(_lock_on(player).target).is_null()
	assert_object(player.lock_target).is_null()
	assert_object(player.camera_rig.look_target).is_null()


func test_it_picks_the_nearer_of_two_crabs() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_passive_crab(player, Vector3(6, 0, 0))
	var near: Crab = _passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await hold(runner, "lock_on")

	assert_object(_lock_on(player).target).is_same(near)
	await release(runner, "lock_on")


func test_with_nothing_in_reach_the_camera_swings_behind_you() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_passive_crab(player, Vector3(0, 0, -30))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	# The camera looks off to the left; the player still faces -Z.
	player.camera_rig.yaw = PI / 2.0

	await hold(runner, "lock_on")

	assert_object(_lock_on(player).target).is_null()
	assert_float(player.camera_rig.yaw).is_equal_approx(0.0, 0.01)
	await release(runner, "lock_on")


func test_lock_on_lets_go_when_the_target_gets_too_far() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")

	crab.global_position = Vector3(0, 0, -(_lock_on(player).release_distance + 2.0))
	await physics_ticks(runner, 3)

	assert_object(_lock_on(player).target).is_null()
	await release(runner, "lock_on")


func test_lock_on_lets_go_when_the_crab_dies() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	crab.health_override = 1
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")

	crab.cycle.engage()
	crab.cycle.tick(crab.windup_seconds + crab.attack_seconds)
	crab.take_strike()
	await physics_ticks(runner, 3)

	assert_bool(crab.is_dead()).is_true()
	assert_object(_lock_on(player).target).is_null()
	await release(runner, "lock_on")


func test_you_cant_lock_on_while_you_cant_act() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	player.controls_enabled = false

	await hold(runner, "lock_on")

	assert_object(_lock_on(player).target).is_null()
	await release(runner, "lock_on")


# --- Toggle mode ---------------------------------------------------------------

func test_in_toggle_mode_a_press_locks_and_a_second_lets_go() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	_lock_on(player).mode = LockOn.Mode.TOGGLE

	await press(runner, "lock_on")
	assert_object(_lock_on(player).target).is_same(crab)

	await press(runner, "lock_on")
	assert_object(_lock_on(player).target).is_null()


# --- What locking on does --------------------------------------------------------

func test_locked_on_you_face_the_target_while_walking_sideways() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")

	await walk(runner, "move_right", 30)

	assert_float(player.global_position.x).is_greater(1.0)
	var to_crab: Vector3 = crab.global_position - player.global_position
	to_crab.y = 0.0
	assert_float(player.facing.dot(to_crab.normalized())).is_greater(0.99)
	await release(runner, "lock_on")


func test_let_go_you_face_the_way_you_walk_again() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_passive_crab(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await hold(runner, "lock_on")
	await release(runner, "lock_on")

	await walk(runner, "move_right", 10)

	assert_float(player.facing.dot(Vector3.RIGHT)).is_greater(0.99)


func test_the_camera_swings_round_to_look_at_the_target() -> void:
	var player: Player3D = new_player_3d_on_floor()
	# Off to the player's right: the camera must turn a quarter turn to see it.
	_passive_crab(player, Vector3(4, 0, 0))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await hold(runner, "lock_on")
	await physics_ticks(runner, 90)

	# Looking along +X is a yaw of minus a quarter turn; the camera sits a
	# little to one side of that, so the player doesn't hide the target.
	var behind: float = -PI / 2.0 + deg_to_rad(player.camera_rig.lock_side_degrees)
	assert_float(angle_difference(player.camera_rig.yaw, behind)).is_equal_approx(0.0, 0.05)
	assert_float(rad_to_deg(player.camera_rig.pitch)).is_equal_approx(
			player.camera_rig.lock_pitch_degrees, 2.0)
	await release(runner, "lock_on")


func test_the_lantern_hovers_over_the_target_and_comes_back() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var crab: Crab = _passive_crab(player, AHEAD)
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await hold(runner, "lock_on")
	await physics_ticks(runner, 90)

	assert_object(spirit.watching()).is_same(crab)
	var over_crab: Vector3 = crab.global_position + Vector3.UP * spirit.hover_height
	assert_float(spirit.global_position.distance_to(over_crab)).is_less(0.6)

	await release(runner, "lock_on")
	await physics_ticks(runner, 90)

	assert_object(spirit.watching()).is_null()
	assert_float(spirit.global_position.distance_to(player.global_position)).is_less(2.5)


func _lock_on(player: Player3D) -> LockOn:
	return player.get_node("LockOn") as LockOn


# A crab that never notices the player: it stands where it's put.
func _passive_crab(player: Player3D, pos: Vector3) -> Crab:
	var crab: Crab = new_crab(player, pos)
	crab.notice_range = 0.0
	return crab


func _marker(pos: Vector3) -> Node3D:
	var marker: Node3D = Node3D.new()
	auto_free(marker)
	marker.position = pos
	# In the tree, so it has a place in the world.
	add_child(marker)
	return marker
