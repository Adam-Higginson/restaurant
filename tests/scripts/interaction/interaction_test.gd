extends GameTestSuite
## Tests for Interactable and InteractionDetector.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const PLAYER_SCENE: String = "res://scenes/player.tscn"
## Just below the stove (centred at 56, 24), facing down by default.
const BELOW_STOVE: Vector2 = Vector2(56, 44)


# --- In the real restaurant ------------------------------------------------------

func test_facing_stove_and_pressing_interact_uses_it_once() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Player] = []
	stove.interacted.connect(func(p: Player) -> void: calls.append(p))

	await walk(runner, "move_up", 20)
	runner.simulate_action_pressed("interact")
	await physics_ticks(runner, 2)

	assert_int(calls.size()).is_equal(1)
	assert_object(calls[0]).is_same(player)


func test_facing_away_from_stove_does_nothing() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Player] = []
	stove.interacted.connect(func(p: Player) -> void: calls.append(p))

	await physics_ticks(runner, 5)
	runner.simulate_action_pressed("interact")
	await physics_ticks(runner, 2)

	assert_int(calls.size()).is_equal(0)


func test_highlight_follows_focus() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable

	await walk(runner, "move_up", 20)
	assert_bool(stove.is_highlighted()).is_true()

	await walk(runner, "move_down", 30)
	assert_bool(stove.is_highlighted()).is_false()


# --- In a small test rig -------------------------------------------------------
# The player faces down by default; its detection zone is centred 12px below it.

func test_nearest_interactable_is_focused() -> void:
	var rig: Node2D = _make_rig()
	var near: Interactable = _add_interactable(rig, Vector2(100, 116))
	_add_interactable(rig, Vector2(106, 122))
	var runner: GdUnitSceneRunner = scene_runner(rig)

	await physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_same(near)
	assert_bool(near.is_highlighted()).is_true()


func test_disabled_interactable_is_ignored() -> void:
	var rig: Node2D = _make_rig()
	var near: Interactable = _add_interactable(rig, Vector2(100, 116))
	var far: Interactable = _add_interactable(rig, Vector2(106, 122))
	near.enabled = false
	var runner: GdUnitSceneRunner = scene_runner(rig)

	await physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_same(far)
	assert_bool(near.is_highlighted()).is_false()


func test_removing_focused_interactable_clears_focus() -> void:
	var rig: Node2D = _make_rig()
	var only: Interactable = _add_interactable(rig, Vector2(100, 116))
	var runner: GdUnitSceneRunner = scene_runner(rig)
	await physics_ticks(runner, 5)
	assert_object(_detector(rig).focused).is_same(only)

	only.queue_free()
	await physics_ticks(runner, 5)

	assert_object(_detector(rig).focused).is_null()
	assert_bool(_detector(rig).try_interact()).is_false()


# --- Use tool -------------------------------------------------------------------

func test_use_tool_sends_the_selected_tool_to_the_stove() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Array] = _record_tool_uses(stove)

	await walk(runner, "move_up", 20)
	await press(runner, "use_tool")

	assert_int(calls.size()).is_equal(1)
	assert_object(calls[0][0]).is_same(player)
	assert_object(calls[0][1]).is_same(player.belt.get_tool(0))


func test_use_tool_does_nothing_while_carrying() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Array] = _record_tool_uses(stove)
	player.arms.add(ItemInstance.new(Item.new()))

	await walk(runner, "move_up", 20)
	await press(runner, "use_tool")

	assert_int(calls.size()).is_equal(0)


func test_use_tool_with_an_empty_slot_selected_does_nothing() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_STOVE)
	var stove: Interactable = runner.find_child("Stove").get_node("Interactable") as Interactable
	var calls: Array[Array] = _record_tool_uses(stove)
	player.belt.select(1)

	await walk(runner, "move_up", 20)
	await press(runner, "use_tool")

	assert_int(calls.size()).is_equal(0)


func test_use_tool_facing_nothing_does_nothing() -> void:
	var rig: Node2D = _make_rig()
	var runner: GdUnitSceneRunner = scene_runner(rig)
	await physics_ticks(runner, 5)

	assert_bool(_detector(rig).try_use_tool()).is_false()


func test_use_tool_on_a_disabled_interactable_does_nothing() -> void:
	var rig: Node2D = _make_rig()
	var target: Interactable = _add_interactable(rig, Vector2(100, 116))
	var calls: Array[Array] = _record_tool_uses(target)
	var runner: GdUnitSceneRunner = scene_runner(rig)
	await physics_ticks(runner, 5)

	target.enabled = false
	target.use_tool(rig.get_node("Player") as Player, HandTool.new())

	assert_int(calls.size()).is_equal(0)


# --- Helpers -------------------------------------------------------------------

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


## Records each tool_used emission as [player, tool].
func _record_tool_uses(interactable: Interactable) -> Array[Array]:
	var calls: Array[Array] = []
	interactable.tool_used.connect(
		func(p: Player, tool: HandTool) -> void: calls.append([p, tool])
	)
	return calls
