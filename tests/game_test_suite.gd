class_name GameTestSuite
extends GdUnitTestSuite
## Base class for this project's test suites, with shared helpers.
##
## Movement, collisions and areas update on physics ticks, so tests wait on an
## exact number of ticks. Waiting on rendered frames would depend on machine
## speed and can pass locally but fail in CI.

## Where tests keep a voyage when something saves (sleeping), so they never
## touch the real save. run_tests.sh runs several copies of Godot at once and
## gives each a TEST_SHARD number, so each copy has a save file of its own.
static var test_save: String = "user://test_voyage%s.save" % OS.get_environment("TEST_SHARD")


func _init() -> void:
	SaveGame.path = test_save


## Waits for exactly [param ticks] physics ticks.
func physics_ticks(runner: GdUnitSceneRunner, ticks: int) -> void:
	var tree: SceneTree = runner.scene().get_tree()
	for i: int in ticks:
		await tree.physics_frame


## Waits until [param emitted] fires or [param seconds] of real time pass,
## and returns whether it fired. Keeps counting while the game is paused,
## unlike gdUnit's own waits, which stall then.
func wait_for_signal(emitted: Signal, seconds: float = 2.0) -> bool:
	# A Dictionary, because a lambda gets a copy of a plain bool.
	var state: Dictionary[String, bool] = {"fired": false}
	var on_emitted: Callable = func(..._args: Array) -> void:
		state["fired"] = true
	emitted.connect(on_emitted)
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not state["fired"] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	# The emitter may have freed itself after emitting (a customer leaving).
	if is_instance_valid(emitted.get_object()) and emitted.is_connected(on_emitted):
		emitted.disconnect(on_emitted)
	return state["fired"]


## Runs [param work] (which may [code]await[/code]) and returns whether it
## finished within [param seconds] of real time, so a test fails rather than
## hangs if it never does. Keeps counting while the game is paused.
func finishes_within(work: Callable, seconds: float = 2.0) -> bool:
	var state: Dictionary[String, bool] = {"done": false}
	var run: Callable = func() -> void:
		await work.call()
		state["done"] = true
	run.call()
	var deadline: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while not state["done"] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return state["done"]


## Waits until every navigation region in the running scene is on its map,
## so paths can be found, and returns whether that happened within
## [param max_ticks] physics ticks. Maps update in the background: a new
## region first joins the map empty, and its floor arrives a tick or two later.
func wait_for_navigation(runner: GdUnitSceneRunner, max_ticks: int = 60) -> bool:
	var regions: Array[NavigationRegion2D] = []
	for node: Node in runner.scene().find_children("*", "NavigationRegion2D", true, false):
		regions.append(node as NavigationRegion2D)
	var tree: SceneTree = runner.scene().get_tree()
	for i: int in max_ticks:
		if _regions_are_on_their_maps(regions):
			return true
		await tree.physics_frame
	return _regions_are_on_their_maps(regions)


## Holds [param action] for [param ticks] physics ticks, then releases it and
## waits two more ticks so the player has stopped.
func walk(runner: GdUnitSceneRunner, action: String, ticks: int) -> void:
	runner.simulate_action_press(action)
	await physics_ticks(runner, ticks)
	runner.simulate_action_release(action)
	await physics_ticks(runner, 2)


## Presses and releases [param action] once, then waits two physics ticks so
## the scene has handled it.
func press(runner: GdUnitSceneRunner, action: String) -> void:
	runner.simulate_action_pressed(action)
	await physics_ticks(runner, 2)


## Brings [param person] in through the restaurant's door to [param table]'s
## seat, ordering [param order] priced from [param menu], and waits until they
## sit down. Needs the main scene with its navigation ready.
func seat_customer(runner: GdUnitSceneRunner, table: Table, person: Person, order: Item,
		menu: Menu, eat_seconds: float = Customer.EAT_SECONDS) -> Customer:
	var door: Marker2D = runner.find_child("Door") as Marker2D
	var seat: Marker2D = table.get_node("Seat") as Marker2D
	var scene: PackedScene = load("res://scenes/customer.tscn") as PackedScene
	var customer: Customer = scene.instantiate() as Customer
	customer.menu = menu
	customer.eat_seconds = eat_seconds
	customer.setup(person, order, seat.global_position, door.global_position)
	customer.position = door.global_position
	table.seat(customer)
	runner.scene().add_child(customer)
	await wait_for_signal(customer.seated, 6.0)
	return customer


## Finds the node named "Player" in the running scene and moves it to [param pos].
func place_player(runner: GdUnitSceneRunner, pos: Vector2) -> Player:
	var player: Player = runner.find_child("Player") as Player
	player.position = pos
	return player


## Finds the 3D player (the node named "Player") in the running scene, stops
## it, and puts it at [param pos] in world space.
func place_player_3d(runner: GdUnitSceneRunner, pos: Vector3) -> Player3D:
	var player: Player3D = runner.find_child("Player") as Player3D
	player.global_position = pos
	player.velocity = Vector3.ZERO
	# A jump, not a move: draw it there at once rather than gliding over.
	player.reset_physics_interpolation()
	return player


## A 3D player standing at the origin on a big flat floor, in a small world
## that's freed after the test. Hand the world (its parent) to scene_runner.
func new_player_3d_on_floor() -> Player3D:
	var world: Node3D = Node3D.new()
	auto_free(world)
	world.add_child(static_box(Vector3(40, 1, 40), Vector3(0, -0.5, 0)))
	var scene: PackedScene = load("res://scenes/prototype/player.tscn") as PackedScene
	var player: Player3D = scene.instantiate() as Player3D
	world.add_child(player)
	return player


## A moored ship at the origin facing -Z (so ship space is world space here),
## with the 3D player at [param pos], in a world that's freed after the test.
## Returns [ship, player]. Hand the ship's parent to scene_runner to start it;
## call [method Ship.set_sail] to sail 200 m straight ahead.
func new_moored_ship_with_player(pos: Vector3) -> Array[Node3D]:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var route: Path3D = Path3D.new()
	route.curve = Curve3D.new()
	route.curve.add_point(Vector3.ZERO)
	route.curve.add_point(Vector3(0, 0, -200))
	world.add_child(route)
	var ship_scene: PackedScene = load("res://scenes/prototype/ship.tscn") as PackedScene
	var ship: Ship = ship_scene.instantiate() as Ship
	ship.route = route
	ship.sail_on_ready = false
	world.add_child(ship)
	var player_scene: PackedScene = load("res://scenes/prototype/player.tscn") as PackedScene
	var player: Player3D = player_scene.instantiate() as Player3D
	player.position = pos
	world.add_child(player)
	return [ship, player]


## [param player]'s lantern, told to follow at their shoulder rather than
## stay at his home on the ship, for tests of how he follows and what he
## says when he's beside you.
func lantern_at_shoulder(player: Node3D) -> LanternSpirit:
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	spirit.leave_home()
	return spirit


## A [FogCrab] at [param pos] in [param player]'s world, so it's freed with
## it. Add it before the scene runs.
func new_fog_crab(player: Player3D, pos: Vector3) -> FogCrab:
	var scene: PackedScene = load("res://scenes/prototype/creatures/fog_crab.tscn") as PackedScene
	var crab: FogCrab = scene.instantiate() as FogCrab
	crab.position = pos
	player.get_parent().add_child(crab)
	return crab


## [param player]'s [Duellist]: their hearts, knife strike and pan parry.
func duellist_of(player: Player3D) -> Duellist:
	return player.get_node("Duellist") as Duellist


## Holds [param action] down and waits two physics ticks, without letting go
## (for buttons that are held, like lock-on). Let go with [method release].
func hold(runner: GdUnitSceneRunner, action: String) -> void:
	runner.simulate_action_press(action)
	await physics_ticks(runner, 2)


## Lets go of [param action] and waits two physics ticks.
func release(runner: GdUnitSceneRunner, action: String) -> void:
	runner.simulate_action_release(action)
	await physics_ticks(runner, 2)


## A [Hud3D] for [param player], added to the player's world, so it's freed
## with it. Add it before the scene runs.
func new_hud_3d(player: Player3D) -> Hud3D:
	var hud: Hud3D = (load("res://ui/hud_3d.tscn") as PackedScene).instantiate() as Hud3D
	hud.player = player
	player.get_parent().add_child(hud)
	return hud


## A [CameraZone] filling a box of [param size] centred at [param pos], with
## its fixed shot at [param shot] (in the zone's own space). Add it to the
## test world before the scene runs.
func new_camera_zone(size: Vector3, pos: Vector3, shot: Transform3D) -> CameraZone:
	var zone: CameraZone = CameraZone.new()
	zone.position = pos
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	zone.add_child(shape)
	var marker: Marker3D = Marker3D.new()
	marker.name = "Shot"
	marker.transform = shot
	zone.add_child(marker)
	return zone


## A solid, unmoving box of [param size] centred at [param pos], for test worlds.
func static_box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.position = pos
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	return body


# Whether each region's floor is on its map: the map's nearest polygon to one
# of the region's own vertices belongs to the region.
func _regions_are_on_their_maps(regions: Array[NavigationRegion2D]) -> bool:
	for region: NavigationRegion2D in regions:
		var vertices: PackedVector2Array = region.navigation_polygon.get_vertices()
		if vertices.is_empty():
			return false
		var point: Vector2 = region.to_global(vertices[0])
		var map: RID = region.get_navigation_map()
		# Querying a map that has never updated is an error.
		if NavigationServer2D.map_get_iteration_id(map) == 0:
			return false
		if NavigationServer2D.map_get_closest_point_owner(map, point) != region.get_rid():
			return false
	return true
