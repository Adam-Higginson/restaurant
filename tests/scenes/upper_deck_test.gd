extends GameTestSuite
## Tests for the upper deck (#90): the stairs up to the quarterdeck and the
## forecastle, the hatch still leading below, the rails that stop you falling,
## room to walk between the deck's clutter, and the lights' shadow budget.
## The player walks at 5 m/s, so 12 physics ticks a metre; up on the stick is
## towards the bow, down towards the stern, right towards starboard.

## Ship space: the main deck, the quarterdeck and the forecastle (their tops).
const DECK_Y: float = 5.3
const QUARTERDECK_Y: float = 7.3
const FORECASTLE_Y: float = 6.2
## Where the quarterdeck's front wall stands, and where the stairs reach the top.
const QUARTERDECK_FRONT: float = 10.3
const STAIRS_TOP: float = 13.1
## Spots that must stay clear to walk through (feet on the deck), with a
## player-sized capsule: round the mast, along both waists, past the hatch,
## to the foot of each stair, round the windlass and round the wheel.
const WALKWAYS: Array[Vector3] = [
	Vector3(1.6, DECK_Y, -4.0), Vector3(-1.6, DECK_Y, -4.0),
	Vector3(2.5, DECK_Y, -8.0), Vector3(-2.4, DECK_Y, -8.0),
	Vector3(3.6, DECK_Y, -1.0), Vector3(-3.0, DECK_Y, -1.5),
	Vector3(-2.4, DECK_Y, 4.6), Vector3(-4.6, DECK_Y, 0.3),
	Vector3(-4.6, DECK_Y, 9.7), Vector3(5.2, DECK_Y, 9.5),
	Vector3(0.0, DECK_Y, -9.0),
	Vector3(2.6, FORECASTLE_Y, -12.4), Vector3(-2.6, FORECASTLE_Y, -12.4),
	Vector3(1.6, QUARTERDECK_Y, 11.8), Vector3(-1.6, QUARTERDECK_Y, 11.8),
	Vector3(2.5, QUARTERDECK_Y, 14.0), Vector3(-2.5, QUARTERDECK_Y, 14.0),
]
## Point lights casting shadows are costly: at most this many on deck.
const SHADOW_BUDGET: int = 3


func test_the_port_stairs_lead_up_to_the_quarterdeck() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-5.2, DECK_Y + 0.05, 9.6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 60)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_greater(STAIRS_TOP)
	assert_float(at.y).is_equal_approx(QUARTERDECK_Y, 0.15)


func test_the_starboard_stairs_lead_up_to_the_quarterdeck() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(5.2, DECK_Y + 0.05, 9.6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 60)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_greater(STAIRS_TOP)
	assert_float(at.y).is_equal_approx(QUARTERDECK_Y, 0.15)


func test_you_can_walk_back_down_from_the_quarterdeck() -> void:
	var start: Vector3 = Vector3(5.2, QUARTERDECK_Y + 0.05, 14.0)
	var ship: Ship = new_moored_ship_with_player(start)[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 72)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_less(QUARTERDECK_FRONT)
	assert_float(at.y).is_equal_approx(DECK_Y, 0.15)


func test_the_forecastle_stairs_lead_up_to_the_bow() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, DECK_Y + 0.05, -8.6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 36)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_less(-11.0)
	assert_float(at.y).is_equal_approx(FORECASTLE_Y, 0.15)


func test_the_hatch_still_leads_below() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-4.6, DECK_Y + 0.05, 0.3))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 110)

	# Down the ramp to the bunk room's floor.
	assert_float(_player_on(ship, runner).y).is_less(1.5)


func test_the_hatch_rail_stops_you_stepping_into_the_hatch() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-2.6, DECK_Y + 0.05, 6.0))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_left", 30)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.x).is_greater(-3.42)
	assert_float(at.y).is_equal_approx(DECK_Y, 0.1)


func test_the_quarterdeck_rail_stops_you_walking_off_its_front() -> void:
	var start: Vector3 = Vector3(-2.0, QUARTERDECK_Y + 0.05, 11.2)
	var ship: Ship = new_moored_ship_with_player(start)[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_up", 30)

	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.z).is_greater(QUARTERDECK_FRONT)
	assert_float(at.y).is_equal_approx(QUARTERDECK_Y, 0.1)


func test_the_walkways_stay_clear() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)
	var player: Player3D = runner.find_child("Player") as Player3D

	for spot: Vector3 in WALKWAYS:
		var blocked: Array[String] = _blocking(ship, spot, player)
		assert_array(blocked).override_failure_message(
				"Walkway at %s is blocked by %s" % [spot, blocked]).is_empty()


func test_the_deck_keeps_to_its_shadow_budget() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)

	var shadowed: int = 0
	var lights: int = 0
	for found: Node in ship.get_node("Visuals/UpperDeck").find_children("*", "OmniLight3D"):
		var light: OmniLight3D = found as OmniLight3D
		lights += 1
		if light.shadow_enabled:
			shadowed += 1

	assert_int(lights).is_greater(6)
	assert_int(shadowed).is_between(1, SHADOW_BUDGET)


# Names of whatever a player-sized capsule standing at [param feet] (ship
# space) would bump into, leaving out the floor under it and the player.
func _blocking(ship: Ship, feet: Vector3, player: Player3D) -> Array[String]:
	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(ship.global_basis, ship.to_global(feet + Vector3(0, 0.92, 0)))
	query.exclude = [player.get_rid()]
	query.collide_with_areas = false
	var names: Array[String] = []
	for hit: Dictionary in ship.get_world_3d().direct_space_state.intersect_shape(query, 8):
		var shape_index: int = hit["shape"]
		var collider: Object = hit["collider"]
		var body: CollisionObject3D = collider as CollisionObject3D
		var owner_id: int = body.shape_find_owner(shape_index)
		var shape_node: Node = body.shape_owner_get_owner(owner_id) as Node
		names.append(String(shape_node.name) if shape_node != null else String(body.name))
	return names


func _player_on(ship: Ship, runner: GdUnitSceneRunner) -> Vector3:
	var player: Player3D = runner.find_child("Player") as Player3D
	return ship.to_local(player.global_position)
