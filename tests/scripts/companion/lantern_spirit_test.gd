extends GameTestSuite
## Tests for the lantern spirit: he keeps by your shoulder as you walk and as
## the ship sails, goes to hover over what you've stopped at, comes back, and
## blinks. Held on a spot by a cutscene, he stays there, sailing with it. The player walks at 5 m/s, so 12 physics ticks a metre.

const DECK: Vector3 = Vector3(0, 5.35, 7.5)


func test_he_floats_by_your_shoulder() -> void:
	var spot: Vector3 = LanternSpirit.follow_spot(Vector3.ZERO, Vector3.FORWARD,
			Vector3(0.5, 1.7, 0.4))

	# Facing -z: right is +x, behind is +z.
	assert_vector(spot).is_equal_approx(Vector3(0.5, 1.7, 0.4), Vector3(0.001, 0.001, 0.001))


func test_he_keeps_up_when_you_walk_off() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 36)
	await physics_ticks(runner, 40)

	assert_float(_from_shoulder(spirit, rig)).is_less(0.3)


func test_he_sails_with_the_ship() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	await physics_ticks(runner, 5)

	ship.set_sail()
	await physics_ticks(runner, 120)

	# Two seconds at 3 m/s and he hasn't been left behind.
	assert_float(_from_shoulder(spirit, rig)).is_less(0.3)


func test_held_on_a_spot_he_stays_there_and_sails_with_it() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var spot: Marker3D = Marker3D.new()
	ship.add_child(spot)
	spot.global_position = DECK + Vector3(2.5, 1.5, 0)
	await physics_ticks(runner, 5)

	spirit.hold_at(spot, true)
	assert_float(spirit.global_position.distance_to(spot.global_position)).is_less(0.15)
	ship.set_sail()
	await physics_ticks(runner, 120)
	assert_float(spirit.global_position.distance_to(spot.global_position)).is_less(0.3)

	spirit.let_go()
	await physics_ticks(runner, 60)
	assert_object(spirit.held).is_null()
	assert_float(_from_shoulder(spirit, rig)).is_less(0.3)


func test_he_goes_to_look_at_what_you_stop_at_and_comes_back() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var thing: Interactable3D = _interactable_near(rig[1] as Player3D)
	await physics_ticks(runner, 5)

	spirit._on_focus_changed(thing)
	await physics_ticks(runner, 90)

	assert_object(spirit.attention).is_same(thing)
	var above: Vector3 = thing.global_position + Vector3.UP * spirit.hover_height
	assert_float(spirit.global_position.distance_to(above)).is_less(0.6)

	spirit._on_focus_changed(null)
	await physics_ticks(runner, 60)

	assert_object(spirit.attention).is_null()
	assert_float(_from_shoulder(spirit, rig)).is_less(0.3)


func test_he_does_not_dart_at_things_you_only_walk_past() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var thing: Interactable3D = _interactable_near(rig[1] as Player3D)
	await physics_ticks(runner, 5)

	spirit._on_focus_changed(thing)
	await physics_ticks(runner, 10)
	spirit._on_focus_changed(null)
	await physics_ticks(runner, 30)

	assert_object(spirit.attention).is_null()


func test_he_blinks() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(DECK)
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var spirit: LanternSpirit = _spirit(rig)
	var eyes: Node3D = spirit.get_node("Body/Eyes") as Node3D
	var shut: bool = false
	await runner.simulate_frames(2)

	spirit.blink()
	for i: int in 12:
		await runner.simulate_frames(1)
		shut = shut or eyes.scale.y < 0.5

	assert_bool(shut).is_true()


func _spirit(rig: Array[Node3D]) -> LanternSpirit:
	return lantern_at_shoulder(rig[1])


# How far he is from his place by the player's shoulder, bob aside.
func _from_shoulder(spirit: LanternSpirit, rig: Array[Node3D]) -> float:
	var player: Player3D = rig[1] as Player3D
	var goal: Vector3 = LanternSpirit.follow_spot(player.global_position, player.facing,
			spirit.follow_offset)
	var here: Vector3 = spirit.global_position
	here.y = goal.y
	return here.distance_to(goal)


# Something to look at, 1.5 m ahead of the player.
func _interactable_near(player: Player3D) -> Interactable3D:
	var thing: Interactable3D = Interactable3D.new()
	player.get_parent().add_child(thing)
	thing.global_position = player.global_position + Vector3(0, 0, -1.5)
	return thing
