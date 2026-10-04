extends GdUnitTestSuite
## Tests for Interactable and InteractionDetector.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const PLAYER_SCENE: String = "res://scenes/player.tscn"
## Just below the stove (centred at 56, 24), facing down by default.
const BELOW_STOVE: Vector2 = Vector2(56, 44)


# --- In the real restaurant ------------------------------------------------------

func test_facing_stove_and_pressing_interact_uses_it_once() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = _place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Player] = []
	stove.interacted.connect(func(p: Player) -> void: calls.append(p))

	await _walk(runner, "move_up", 20)
	runner.simulate_action_pressed("interact")
	await _physics_ticks(runner, 2)

	assert_int(calls.size()).is_equal(1)
	assert_object(calls[0]).is_same(player)


func test_facing_away_from_stove_does_nothing() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	_place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Player] = []
	stove.interacted.connect(func(p: Player) -> void: calls.append(p))

	await _physics_ticks(runner, 5)
	runner.simulate_action_pressed("interact")
	await _physics_ticks(runner, 2)

	assert_int(calls.size()).is_equal(0)


func test_highlight_follows_focus() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	_place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable

	await _walk(runner, "move_up", 20)
	assert_bool(stove.is_highlighted()).is_true()

	await _walk(runner, "move_down", 30)
	assert_bool(stove.is_highlighted()).is_false()


# --- In a small test rig -------------------------------------------------------
# The player faces down by default; its detection zone is centred 12px below it.

func test_nearest_interactable_is_focused() -> void:
	var rig: Node2D = _make_rig()
	var near: Interactable = _add_interactable(rig, Vector2(100, 116))
	_add_interactable(rig, Vector2(106, 122))
	var runner: GdUnitSceneRunner = scene_runner(rig)

	await _physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_same(near)
	assert_bool(near.is_highlighted()).is_true()


func test_disabled_interactable_is_ignored() -> void:
	var rig: Node2D = _make_rig()
	var near: Interactable = _add_interactable(rig, Vector2(100, 116))
	var far: Interactable = _add_interactable(rig, Vector2(106, 122))
	near.enabled = false
	var runner: GdUnitSceneRunner = scene_runner(rig)

	await _physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_same(far)
	assert_bool(near.is_highlighted()).is_false()


func test_removing_focused_interactable_clears_focus() -> void:
	var rig: Node2D = _make_rig()
	var only: Interactable = _add_interactable(rig, Vector2(100, 116))
	var runner: GdUnitSceneRunner = scene_runner(rig)
	await _physics_ticks(runner, 5)
	assert_object(_detector(rig).focused).is_same(only)

	only.queue_free()
	await _physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_null()
	assert_bool(_detector(rig).try_interact()).is_false()


# --- Helpers -------------------------------------------------------------------

## Waits for an exact number of physics ticks. The detector and movement update on
## physics ticks, so waiting on rendered frames would depend on machine speed.
func _physics_ticks(runner: GdUnitSceneRunner, ticks: int) -> void:
	var tree: SceneTree = runner.scene().get_tree()
	for i: int in ticks:
		await tree.physics_frame


func _place_player(runner: GdUnitSceneRunner, pos: Vector2) -> Player:
	var player: Player = runner.find_child("Player") as Player
	player.position = pos
	return player


func _walk(runner: GdUnitSceneRunner, action: String, frames: int) -> void:
	runner.simulate_action_press(action)
	await _physics_ticks(runner, frames)
	runner.simulate_action_release(action)
	await _physics_ticks(runner, 2)


func _make_rig() -> Node2D:
	var rig: Node2D = Node2D.new()
	auto_free(rig)
	var player: Player = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player
	player.name = "Player"
	player.position = Vector2(100, 100)
	rig.add_child(player)
	return rig


func _add_interactable(rig: Node2D, pos: Vector2) -> Interactable:
	var interactable: Interactable = Interactable.new()
	interactable.position = pos
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	shape.shape = rect
	interactable.add_child(shape)
	rig.add_child(interactable)
	return interactable


func _detector(rig: Node2D) -> InteractionDetector:
	return rig.get_node("Player/InteractionDetector") as InteractionDetector
