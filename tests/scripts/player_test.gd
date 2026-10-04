extends GdUnitTestSuite
## Tests for scripts/player.gd.

const PLAYER_SCENE: String = "res://scenes/player.tscn"


func _new_player() -> Player:
	return auto_free((load(PLAYER_SCENE) as PackedScene).instantiate()) as Player


# --- Facing direction ---------------------------------------------------------

func test_faces_dominant_horizontal_direction() -> void:
	var player: Player = _new_player()
	assert_vector(player._to_cardinal(Vector2(0.9, 0.3))).is_equal(Vector2.RIGHT)
	assert_vector(player._to_cardinal(Vector2(-0.9, -0.3))).is_equal(Vector2.LEFT)


func test_faces_dominant_vertical_direction() -> void:
	var player: Player = _new_player()
	assert_vector(player._to_cardinal(Vector2(0.3, -0.9))).is_equal(Vector2.UP)
	assert_vector(player._to_cardinal(Vector2(-0.3, 0.9))).is_equal(Vector2.DOWN)


func test_exact_diagonal_keeps_current_facing_when_it_is_held() -> void:
	var player: Player = _new_player()
	player.facing = Vector2.RIGHT
	assert_vector(player._to_cardinal(Vector2(1, -1).normalized())).is_equal(Vector2.RIGHT)


func test_exact_diagonal_falls_back_to_vertical() -> void:
	var player: Player = _new_player()
	player.facing = Vector2.RIGHT
	assert_vector(player._to_cardinal(Vector2(-1, -1).normalized())).is_equal(Vector2.UP)


# --- Movement in a running scene -------------------------------------------------

func test_moves_right_and_faces_right() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player
	var start: Vector2 = player.position

	runner.simulate_action_press("move_right")
	await runner.simulate_frames(20)

	assert_float(player.position.x).is_greater(start.x)
	assert_float(player.position.y).is_equal_approx(start.y, 0.01)
	assert_vector(player.facing).is_equal(Vector2.RIGHT)


func test_diagonal_is_not_faster_than_straight() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player

	runner.simulate_action_press("move_up")
	runner.simulate_action_press("move_left")
	await runner.simulate_frames(5)

	assert_float(player.velocity.length()).is_equal_approx(player.speed, 0.01)


func test_stops_when_input_released() -> void:
	var runner: GdUnitSceneRunner = scene_runner(PLAYER_SCENE)
	var player: Player = runner.scene() as Player

	runner.simulate_action_press("move_down")
	await runner.simulate_frames(5)
	runner.simulate_action_release("move_down")
	await runner.simulate_frames(5)

	assert_vector(player.velocity).is_equal(Vector2.ZERO)
	assert_vector(player.facing).is_equal(Vector2.DOWN)
