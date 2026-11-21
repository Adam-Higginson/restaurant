extends GameTestSuite
## Tests for Interactable3D and InteractionDetector3D: what's focused, the
## focus arrow, and routing interact and use-tool presses.
##
## The player stands at the origin facing -Z, so its detection zone (0.35 m
## across the middle) sits 0.7 m ahead, around (0, 0.9, -0.7).

const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const AHEAD: Vector3 = Vector3(0, 0.9, -0.8)


func test_focuses_an_interactable_in_front() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	scene_runner(player.get_parent())

	await _settle(player)

	assert_object(_detector(player).focused).is_same(target)


func test_ignores_one_behind() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_interactable(player, Vector3(0, 0.9, 0.8))
	scene_runner(player.get_parent())

	await _settle(player)

	assert_object(_detector(player).focused).is_null()


func test_focuses_the_nearest() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var near: Interactable3D = _add_interactable(player, Vector3(0, 0.9, -0.75))
	_add_interactable(player, Vector3(0.3, 0.9, -0.95))
	scene_runner(player.get_parent())

	await _settle(player)

	assert_object(_detector(player).focused).is_same(near)


func test_ignores_a_disabled_one() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	target.enabled = false
	scene_runner(player.get_parent())

	await _settle(player)

	assert_object(_detector(player).focused).is_null()


func test_turning_round_moves_the_focus() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_interactable(player, AHEAD)
	var right: Interactable3D = _add_interactable(player, Vector3(0.9, 0.9, 0))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await _settle(player)

	# A short step right turns the player to face +X.
	await walk(runner, "move_right", 3)

	assert_object(_detector(player).focused).is_same(right)


func test_freeing_the_focused_one_clears_focus() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	scene_runner(player.get_parent())
	await _settle(player)

	target.queue_free()
	await _settle(player)

	assert_object(_detector(player).focused).is_null()


func test_the_arrow_floats_over_the_focused_one() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	var arrow: Node3D = _detector(player).get_node("FocusArrow") as Node3D
	scene_runner(player.get_parent())

	await _settle(player)

	assert_bool(arrow.visible).is_true()
	var above: Vector3 = target.global_position + Vector3.UP * target.focus_height
	assert_vector(arrow.global_position).is_equal_approx(above, Vector3(0.01, 0.1, 0.01))


func test_the_arrow_hides_with_nothing_focused() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var arrow: Node3D = _detector(player).get_node("FocusArrow") as Node3D
	scene_runner(player.get_parent())

	await _settle(player)

	assert_bool(arrow.visible).is_false()


func test_interact_uses_the_focused_one_once() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var calls: Array[Player3D] = []
	target.interacted.connect(func(p: Player3D) -> void: calls.append(p))
	await _settle(player)

	await press(runner, "interact")

	assert_array(calls).contains_exactly([player])


func test_interact_with_nothing_focused_does_nothing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	await _settle(player)

	assert_bool(_detector(player).try_interact()).is_false()


func test_use_tool_sends_the_selected_knife() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var tools: Array[HandTool] = []
	target.tool_used.connect(func(_p: Player3D, tool: HandTool) -> void: tools.append(tool))
	await _settle(player)

	await press(runner, "use_tool")

	assert_array(tools).contains_exactly([KNIFE])


func test_use_tool_does_nothing_while_carrying() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var tools: Array[HandTool] = []
	target.tool_used.connect(func(_p: Player3D, tool: HandTool) -> void: tools.append(tool))
	player.arms.add(ItemInstance.new(TOMATO))
	await _settle(player)

	await press(runner, "use_tool")

	assert_array(tools).is_empty()


func test_use_tool_with_an_empty_slot_selected_does_nothing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var tools: Array[HandTool] = []
	target.tool_used.connect(func(_p: Player3D, tool: HandTool) -> void: tools.append(tool))
	player.belt.select(1)
	await _settle(player)

	await press(runner, "use_tool")

	assert_array(tools).is_empty()


func test_a_disabled_one_ignores_direct_use() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var target: Interactable3D = _add_interactable(player, AHEAD)
	scene_runner(player.get_parent())
	var calls: Array[int] = [0]
	target.interacted.connect(func(_p: Player3D) -> void: calls[0] += 1)
	target.tool_used.connect(func(_p: Player3D, _t: HandTool) -> void: calls[0] += 1)
	target.enabled = false

	target.interact(player)
	target.use_tool(player, KNIFE)

	assert_int(calls[0]).is_equal(0)


# Waits for the areas to notice each other and the arrow to be placed.
func _settle(player: Player3D) -> void:
	for i: int in 5:
		await player.get_tree().physics_frame
	# process_frame fires just before nodes' _process, so wait for a second
	# one to be sure the arrow has been placed.
	for i: int in 2:
		await player.get_tree().process_frame


func _detector(player: Player3D) -> InteractionDetector3D:
	return player.get_node("InteractionDetector") as InteractionDetector3D


# A 0.4 m interactable box centred at [param pos], in the player's world.
func _add_interactable(player: Player3D, pos: Vector3) -> Interactable3D:
	var area: Interactable3D = Interactable3D.new()
	area.position = pos
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3.ONE * 0.4
	shape.shape = box
	area.add_child(shape)
	player.get_parent().add_child(area)
	return area
