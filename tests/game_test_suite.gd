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
	if emitted.is_connected(on_emitted):
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


## Finds the node named "Player" in the running scene and moves it to [param pos].
func place_player(runner: GdUnitSceneRunner, pos: Vector2) -> Player:
	var player: Player = runner.find_child("Player") as Player
	player.position = pos
	return player
