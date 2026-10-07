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
