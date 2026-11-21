extends GameTestSuite
## Tests for CarriedStack3D: one model per carried item, stacked bottom
## first, rebuilt when the arms change, and bobbing only while walking.

const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const PLATE: Item = preload("res://data/items/plate.tres")


func test_shows_nothing_with_empty_arms() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	assert_int(_stack(player).get_child_count()).is_equal(0)


func test_shows_one_model_per_item_bottom_first() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	player.arms.add(ItemInstance.new(TOMATO))
	player.arms.add(ItemInstance.new(LETTUCE))

	var models: Array[Node] = _stack(player).get_children()
	assert_int(models.size()).is_equal(2)
	assert_float((models[1] as Node3D).position.y).is_greater((models[0] as Node3D).position.y)


func test_rebuilds_when_an_item_is_taken() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	player.arms.add(ItemInstance.new(TOMATO))
	player.arms.add(ItemInstance.new(LETTUCE))

	player.arms.take_top()

	assert_int(_stack(player).get_child_count()).is_equal(1)


func test_an_item_on_a_full_plate_clears_its_food() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(TOMATO))
	player.arms.add(plate)

	player.arms.add(ItemInstance.new(LETTUCE))

	var top: Node3D = _stack(player).get_child(1) as Node3D
	assert_float(top.position.y).is_greater_equal(ItemModel.height_of(plate))
	assert_float(ItemModel.height_of(plate)).is_greater(ItemModel.vessel_height(PLATE))


func test_bob_starts_at_rest_and_peaks_a_quarter_bob_in() -> void:
	assert_float(CarriedStack3D.bob_offset(0.0, 0.04, 3.0)).is_equal_approx(0.0, 0.0001)
	# At 3 bobs per second, a quarter of a bob is 1/12 s.
	assert_float(CarriedStack3D.bob_offset(1.0 / 12.0, 0.04, 3.0)).is_equal_approx(0.04, 0.0001)


func test_stays_still_while_standing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var rest: float = _stack(player).position.y

	await physics_ticks(runner, 20)

	assert_float(_stack(player).position.y).is_equal_approx(rest, 0.0001)


func test_bobs_while_walking() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var rest: float = _stack(player).position.y
	await physics_ticks(runner, 5)
	runner.simulate_action_press("move_up")

	# A twelfth of a second in, at the top of a bob.
	await physics_ticks(runner, 5)

	assert_float(_stack(player).position.y).is_greater(rest + 0.01)
	runner.simulate_action_release("move_up")


func _stack(player: Player3D) -> CarriedStack3D:
	return player.get_node("CarriedStack") as CarriedStack3D
