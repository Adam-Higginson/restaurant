class_name GameTestSuite
extends GdUnitTestSuite
## Base class for this project's test suites, with shared helpers.
##
## Movement, collisions and areas update on physics ticks, so tests wait on an
## exact number of ticks. Waiting on rendered frames would depend on machine
## speed and can pass locally but fail in CI.


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
