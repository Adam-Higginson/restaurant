extends GameTestSuite
## Tests for Player3D: walking relative to the camera, facing, gravity,
## walls, and riding the sailing ship's deck.

const PLAYER_SCENE: String = "res://scenes/prototype/player.tscn"
const SHIP_SCENE: String = "res://scenes/prototype/ship.tscn"
## Where the player stands on the ship's aft deck, in the ship's own space.
const ON_DECK: Vector3 = Vector3(1.5, 4.05, 8.0)
const NEAR: Vector3 = Vector3(0.05, 0.05, 0.05)


# --- Camera-relative directions -----------------------------------------------

func test_up_walks_the_way_the_camera_faces() -> void:
	# Yaw 0 looks along -Z.
	assert_vector(Player3D.camera_relative(Vector2.UP, 0.0)).is_equal_approx(
			Vector3.FORWARD, NEAR)
	# A quarter turn left looks along -X.
	assert_vector(Player3D.camera_relative(Vector2.UP, PI / 2.0)).is_equal_approx(
			Vector3.LEFT, NEAR)
	# Half a turn looks along +Z.
	assert_vector(Player3D.camera_relative(Vector2.UP, PI)).is_equal_approx(
			Vector3.BACK, NEAR)


func test_right_and_down_are_relative_to_the_camera_too() -> void:
	assert_vector(Player3D.camera_relative(Vector2.RIGHT, 0.0)).is_equal_approx(
			Vector3.RIGHT, NEAR)
	assert_vector(Player3D.camera_relative(Vector2.DOWN, 0.0)).is_equal_approx(
			Vector3.BACK, NEAR)
	assert_vector(Player3D.camera_relative(Vector2.RIGHT, PI / 2.0)).is_equal_approx(
			Vector3.FORWARD, NEAR)


func test_directions_stay_flat_and_keep_their_length() -> void:
	var input: Vector2 = Vector2(0.6, -0.8)

	var direction: Vector3 = Player3D.camera_relative(input, 1.234)

	assert_float(direction.y).is_equal(0.0)
	assert_float(direction.length()).is_equal_approx(1.0, 0.001)


func test_no_input_means_no_direction() -> void:
	assert_vector(Player3D.camera_relative(Vector2.ZERO, 2.0)).is_equal(Vector3.ZERO)


# --- Walking ------------------------------------------------------------------

func test_forward_walks_the_way_the_camera_faces() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	# Turn the camera a quarter turn left, so it looks along -X.
	(player.get_node("CameraRig") as CameraRig).yaw = PI / 2.0
	var start: Vector3 = player.global_position

	await walk(runner, "move_up", 30)

	var moved: Vector3 = player.global_position - start
	assert_float(moved.length()).is_greater(1.0)
	assert_vector(moved.normalized()).is_equal_approx(Vector3.LEFT, NEAR)


func test_up_walks_away_from_a_fixed_camera() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var zone: CameraZone = _add_far_zone(player)
	player.camera_rig.enter_zone(zone)
	await physics_ticks(runner, 5)
	var start: Vector3 = player.global_position

	await walk(runner, "move_up", 30)

	var moved: Vector3 = player.global_position - start
	assert_float(moved.length()).is_greater(1.0)
	assert_vector(moved.normalized()).is_equal_approx(Vector3.LEFT, NEAR)


func test_keeps_its_heading_when_the_camera_switches_mid_walk() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var zone: CameraZone = _add_far_zone(player)
	await physics_ticks(runner, 5)
	runner.simulate_action_press("move_up")
	await physics_ticks(runner, 10)

	# The camera switches to the shot looking along -X while up is held.
	player.camera_rig.enter_zone(zone)
	var switched_at: Vector3 = player.global_position
	await physics_ticks(runner, 20)
	runner.simulate_action_release("move_up")
	await physics_ticks(runner, 2)

	# Still walking along -Z, the way the free camera looked.
	var moved: Vector3 = player.global_position - switched_at
	assert_float(moved.length()).is_greater(1.0)
	assert_vector(moved.normalized()).is_equal_approx(Vector3.FORWARD, NEAR)


func test_follows_the_new_camera_after_letting_go() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var zone: CameraZone = _add_far_zone(player)
	await physics_ticks(runner, 5)
	runner.simulate_action_press("move_up")
	await physics_ticks(runner, 5)
	player.camera_rig.enter_zone(zone)
	# walk() presses again, then lets go.
	await walk(runner, "move_up", 5)
	var start: Vector3 = player.global_position

	await walk(runner, "move_up", 30)

	var moved: Vector3 = player.global_position - start
	assert_vector(moved.normalized()).is_equal_approx(Vector3.LEFT, NEAR)


func test_turning_the_free_camera_mid_walk_still_steers() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	runner.simulate_action_press("move_up")
	await physics_ticks(runner, 5)

	# Turn the free camera a quarter turn left without letting go.
	player.camera_rig.yaw = PI / 2.0
	await physics_ticks(runner, 1)
	var turned_at: Vector3 = player.global_position
	await physics_ticks(runner, 20)
	runner.simulate_action_release("move_up")
	await physics_ticks(runner, 2)

	var moved: Vector3 = player.global_position - turned_at
	assert_vector(moved.normalized()).is_equal_approx(Vector3.LEFT, NEAR)


func test_faces_the_way_it_walks() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 30)

	assert_vector(player.facing).is_equal_approx(Vector3.RIGHT, NEAR)


func test_keeps_facing_the_same_way_after_stopping() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await walk(runner, "move_down", 30)

	await physics_ticks(runner, 30)

	assert_vector(player.facing).is_equal_approx(Vector3.BACK, NEAR)


func test_stops_when_the_input_is_released() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	await walk(runner, "move_up", 20)
	var stopped_at: Vector3 = player.global_position

	await physics_ticks(runner, 20)

	assert_vector(player.global_position).is_equal_approx(stopped_at, NEAR)


func test_falls_onto_the_floor() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	place_player_3d(runner, Vector3(0, 3, 0))

	# A 3 m fall takes under a second.
	await physics_ticks(runner, 60)

	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(0.0, 0.05)


func test_a_wall_stops_it() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var world: Node3D = player.get_parent() as Node3D
	# A wall whose near face is 2 m in front of the player (along -Z).
	world.add_child(static_box(Vector3(10, 4, 1), Vector3(0, 2, -2.5)))
	var runner: GdUnitSceneRunner = scene_runner(world)
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 60)

	# Stopped by the wall: the capsule's 0.4 m radius away from its face.
	assert_float(player.global_position.z).is_equal_approx(-1.6, 0.05)


# --- Riding the ship ----------------------------------------------------------

func test_stays_on_the_deck_while_the_ship_sails_straight() -> void:
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO)
	curve.add_point(Vector3(0, 0, -200))
	var rig: Array[Node3D] = _new_ship_with_player(curve)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	# Let the player land on deck first.
	await physics_ticks(runner, 10)
	var on_deck: Vector3 = ship.to_local(player.global_position)
	ship.set_sail()

	await physics_ticks(runner, 120)

	assert_float(ship.global_position.length()).is_greater(5.0)
	assert_bool(player.is_on_floor()).is_true()
	assert_vector(ship.to_local(player.global_position)).is_equal_approx(
			on_deck, Vector3(0.1, 0.1, 0.1))


func test_stays_on_the_deck_while_the_ship_turns() -> void:
	# A quarter circle to the left, about 40 m long.
	var curve: Curve3D = Curve3D.new()
	curve.add_point(Vector3.ZERO, Vector3.ZERO, Vector3(0, 0, -15))
	curve.add_point(Vector3(-25, 0, -25), Vector3(15, 0, 0), Vector3.ZERO)
	var rig: Array[Node3D] = _new_ship_with_player(curve, 6.0)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 10)
	var on_deck: Vector3 = ship.to_local(player.global_position)
	ship.set_sail()

	await physics_ticks(runner, 240)

	# The ship has turned well round, and the player turned with it.
	assert_float(-ship.global_basis.z.x).is_less(-0.5)
	assert_bool(player.is_on_floor()).is_true()
	assert_vector(ship.to_local(player.global_position)).is_equal_approx(
			on_deck, Vector3(0.2, 0.1, 0.2))


# A camera zone far from the player, so only direct enter_zone calls use it,
# with an instant glide. Its shot looks along -X (a quarter turn left).
func _add_far_zone(player: Player3D) -> CameraZone:
	var shot: Transform3D = Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(0, 3, 0))
	var zone: CameraZone = new_camera_zone(Vector3(2, 2, 2), Vector3(15, 1, 15), shot)
	player.get_parent().add_child(zone)
	player.camera_rig.blend_seconds = 0.0
	return zone


# A ship moored at the start of [param curve], and a player on its aft deck.
# Returns [ship, player]. Hand the ship's parent to scene_runner to start it.
func _new_ship_with_player(curve: Curve3D, speed: float = 3.0) -> Array[Node3D]:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var route: Path3D = Path3D.new()
	route.curve = curve
	world.add_child(route)
	var ship: Ship = (load(SHIP_SCENE) as PackedScene).instantiate() as Ship
	ship.route = route
	ship.speed = speed
	ship.sail_on_ready = false
	world.add_child(ship)
	var player: Player3D = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player3D
	# The ship starts at the origin facing -Z, so ship space is world space here.
	player.position = ON_DECK
	world.add_child(player)
	return [ship, player]
