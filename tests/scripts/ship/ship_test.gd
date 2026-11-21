extends GameTestSuite
## Tests for Ship: sailing along a route, mooring at its end, and rocking
## only its visuals.

const SHIP_SCENE: String = "res://scenes/prototype/ship.tscn"
## How close positions must be, in metres. One physics tick at 3 m/s is 0.05 m.
const CLOSE: Vector3 = Vector3(0.11, 0.11, 0.11)


# --- Sailing ------------------------------------------------------------------

func test_sails_at_its_set_speed() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -100)], 3.0)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var start: Vector3 = ship.global_position
	ship.set_sail()

	# 60 physics ticks is one second.
	await physics_ticks(runner, 60)

	assert_float(ship.global_position.distance_to(start)).is_equal_approx(3.0, 0.11)


func test_faces_along_the_route() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(50, 0, 0)])
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()

	await physics_ticks(runner, 10)

	# Godot's forward is -Z.
	var forward: Vector3 = -ship.global_basis.z
	assert_vector(forward).is_equal_approx(Vector3(1, 0, 0), Vector3(0.01, 0.01, 0.01))


func test_starts_at_the_beginning_of_its_route() -> void:
	var ship: Ship = _new_ship([Vector3(10, 0, 20), Vector3(10, 0, -20)])
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	# A synced AnimatableBody3D moves on the next physics tick, not at once.
	await physics_ticks(runner, 2)

	assert_vector(ship.global_position).is_equal_approx(Vector3(10, 0, 20), CLOSE)


func test_is_sailing_only_after_setting_sail() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -100)])
	scene_runner(ship.get_parent())
	assert_bool(ship.is_sailing).is_false()

	ship.set_sail()

	assert_bool(ship.is_sailing).is_true()


func test_sail_on_ready_sets_sail_at_the_start() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -100)], 3.0, true)
	scene_runner(ship.get_parent())

	assert_bool(ship.is_sailing).is_true()


# --- Mooring ------------------------------------------------------------------

func test_moors_exactly_at_the_end_of_its_route() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -3)], 3.0)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var moorings: Array[int] = [0]
	ship.moored.connect(func() -> void: moorings[0] += 1)
	ship.set_sail()

	# Three metres at 3 m/s takes 60 ticks; wait half as long again.
	await physics_ticks(runner, 90)

	assert_vector(ship.global_position).is_equal(Vector3(0, 0, -3))
	assert_bool(ship.is_sailing).is_false()
	assert_int(moorings[0]).is_equal(1)

	await physics_ticks(runner, 30)

	assert_vector(ship.global_position).is_equal(Vector3(0, 0, -3))
	assert_int(moorings[0]).is_equal(1)


func test_a_big_step_stops_at_the_end_instead_of_overshooting() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -10)], 1000.0)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()

	await physics_ticks(runner, 3)

	assert_vector(ship.global_position).is_equal(Vector3(0, 0, -10))


func test_setting_sail_once_moored_does_nothing() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -10)], 1000.0)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()
	await physics_ticks(runner, 3)

	ship.set_sail()

	assert_bool(ship.is_sailing).is_false()


# --- Edge cases ---------------------------------------------------------------

func test_does_not_move_at_zero_speed() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -100)], 0.0)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()

	await physics_ticks(runner, 30)

	assert_vector(ship.global_position).is_equal(Vector3.ZERO)


func test_stays_put_with_an_empty_route() -> void:
	var ship: Ship = _new_ship([])
	ship.position = Vector3(5, 0, 5)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	ship.set_sail()
	await physics_ticks(runner, 30)

	assert_bool(ship.is_sailing).is_false()
	assert_vector(ship.global_position).is_equal(Vector3(5, 0, 5))


func test_stays_put_without_a_route() -> void:
	var ship: Ship = _new_ship([])
	ship.route = null
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	ship.set_sail()
	await physics_ticks(runner, 30)

	assert_bool(ship.is_sailing).is_false()
	assert_vector(ship.global_position).is_equal(Vector3.ZERO)


# --- Rocking ------------------------------------------------------------------

func test_rocking_tilts_the_visuals_but_never_the_body() -> void:
	var ship: Ship = _new_ship([Vector3.ZERO, Vector3(0, 0, -100)])
	ship.rock_degrees = 2.0
	ship.rock_period = 1.0
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var visuals: Node3D = ship.get_node("Visuals") as Node3D
	ship.set_sail()

	# A quarter of a roll, when the tilt is near its largest.
	await physics_ticks(runner, 15)

	var tilt: float = absf(rad_to_deg(visuals.rotation.z))
	assert_float(tilt).is_greater(0.5)
	assert_float(tilt).is_less_equal(2.0)
	# The body stays level: its up is straight up, and its side is flat.
	assert_vector(ship.global_basis.y).is_equal_approx(Vector3.UP, Vector3(0.001, 0.001, 0.001))
	assert_float(ship.global_basis.x.y).is_equal_approx(0.0, 0.001)


# A ship in a small world with a straight route through [param points],
# not yet sailing unless [param sail_on_ready]. Hand it to scene_runner via
# its parent to start it.
func _new_ship(points: Array[Vector3], speed: float = 3.0, sail_on_ready: bool = false) -> Ship:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var route: Path3D = Path3D.new()
	route.curve = Curve3D.new()
	for point: Vector3 in points:
		route.curve.add_point(point)
	world.add_child(route)
	var ship: Ship = (load(SHIP_SCENE) as PackedScene).instantiate() as Ship
	ship.route = route
	ship.speed = speed
	ship.sail_on_ready = sail_on_ready
	world.add_child(ship)
	return ship
