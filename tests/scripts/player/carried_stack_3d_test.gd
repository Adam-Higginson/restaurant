extends GameTestSuite
## Tests for CarriedStack3D: a model of the carried item, rebuilt when the
## arms change, and bobbing only while walking.

const TOMATO: Item = preload("res://data/items/tomato.tres")
const PLATE: Item = preload("res://data/items/plate.tres")


func test_shows_nothing_with_empty_arms() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	assert_int(_stack(player).get_child_count()).is_equal(0)


func test_shows_the_carried_item() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	player.arms.add(ItemInstance.new(TOMATO))

	assert_int(_stack(player).get_child_count()).is_equal(1)


func test_clears_when_the_item_is_put_down() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	player.arms.add(ItemInstance.new(TOMATO))

	player.arms.take_top()

	assert_int(_stack(player).get_child_count()).is_equal(0)


func test_a_carried_plate_shows_its_food() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(TOMATO))

	player.arms.add(plate)

	var model: Node3D = _stack(player).get_child(0) as Node3D
	assert_object(model.find_child("Food0", true, false)).is_not_null()


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
