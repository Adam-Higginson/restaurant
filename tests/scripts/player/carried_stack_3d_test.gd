extends GameTestSuite
## Tests for CarriedStack3D: a model of the carried item, rebuilt when the
## arms change, held in the hand and never floated over the head (#206).

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


func test_nothing_floats_over_the_head() -> void:
	# The greybox body has no hands to hold it: the item isn't shown at all,
	# rather than hovering over the hero's head as it used to (#206).
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.arms.add(ItemInstance.new(TOMATO))

	await physics_ticks(runner, 3)

	assert_object(_stack(player).held_in()).is_null()
	assert_bool(_stack(player).visible).is_false()


func _stack(player: Player3D) -> CarriedStack3D:
	return player.get_node("CarriedStack") as CarriedStack3D
