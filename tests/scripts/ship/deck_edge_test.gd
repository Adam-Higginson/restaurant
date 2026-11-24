extends GameTestSuite
## Tests for the decks' edges following the hull (#196): you can walk out to
## the hull's side, farther than the old square rail amidships and less far
## where the bow narrows, and never off the edge. The player walks at 5 m/s, so
## 12 physics ticks a metre; right on the stick is towards starboard (+x).

const DECK_Y: float = 5.3
const FORECASTLE_Y: float = 6.2


func test_amidships_you_walk_out_to_the_hulls_side() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(4.0, DECK_Y + 0.05, -1.5))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 60)

	var at: Vector3 = _player_on(ship, runner)
	var outline: HullOutline = load("res://data/ship/hull_outline.tres") as HullOutline
	# Past where the old rail stood (5.7), but inside the hull.
	assert_float(at.x).is_greater(5.9)
	assert_float(at.x).is_less(outline.half_width_at(at.z, DECK_Y + 0.5))
	assert_float(at.y).is_equal_approx(DECK_Y, 0.15)


func test_where_the_bow_narrows_the_side_stops_you_sooner() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(1.0, FORECASTLE_Y + 0.05, -15.5))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 60)

	var at: Vector3 = _player_on(ship, runner)
	var outline: HullOutline = load("res://data/ship/hull_outline.tres") as HullOutline
	assert_float(at.x).is_less(outline.half_width_at(at.z, FORECASTLE_Y + 0.3))
	assert_float(at.x).is_less(5.0)
	assert_float(at.y).is_equal_approx(FORECASTLE_Y, 0.15)


func test_the_wall_is_measured_under_a_low_top_edge() -> void:
	# Along the forecastle the hull's top edge is lower than a wall 0.6 m above
	# the deck would be measured at: it's read just under the edge instead.
	var edge: DeckEdge = DeckEdge.new()
	auto_free(edge)
	edge.outline = load("res://data/ship/hull_outline.tres") as HullOutline
	assert_float(edge.wall_at(-12.0, FORECASTLE_Y)).is_greater(4.0)
	assert_float(edge.wall_at(-12.0, FORECASTLE_Y)).is_less(edge.outline.half_width_at(-12.0, 6.3))


func test_the_old_square_decks_are_retired() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0.0, DECK_Y + 0.05, -1.5))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	assert_bool((ship.get_node("Visuals/DeckFore") as Node3D).visible).is_false()


func _player_on(ship: Ship, runner: GdUnitSceneRunner) -> Vector3:
	var player: Player3D = runner.find_child("Player") as Player3D
	return ship.to_local(player.global_position)
