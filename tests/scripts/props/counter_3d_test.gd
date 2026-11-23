extends GameTestSuite
## Tests for Counter3D: showing what's on it, and the player using it with
## Interact and the knife, on a floor and in the galley of a sailing ship.
## The rules themselves are tested in counter_slot_test.gd.

const COUNTER_SCENE: String = "res://scenes/prototype/props/counter.tscn"
const TOMATO: Item = preload("res://data/items/tomato.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const BOARD: Item = preload("res://data/items/chopping_board.tres")
const CHOPPED_LETTUCE: Item = preload("res://data/items/chopped_lettuce.tres")
const SLICED_TOMATO: Item = preload("res://data/items/sliced_tomato.tres")
const KNIFE: HandTool = preload("res://data/tools/chefs_knife.tres")
## A counter 1.2 m ahead of the player (who faces -Z), within reach.
const AHEAD: Vector3 = Vector3(0, 0, -1.2)
## In front of the galley's BoardCounter, facing it, in the ship's own space.
const AT_BOARD: Vector3 = Vector3(0.55, 1.05, 2.35)


func test_shows_its_start_item() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var counter: Counter3D = _add_counter(player, TOMATO)
	scene_runner(player.get_parent())

	assert_object(counter.slot.get_item().item).is_same(TOMATO)
	assert_int(_item_spot(counter).get_child_count()).is_equal(1)


func test_an_empty_counter_shows_nothing() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var counter: Counter3D = _add_counter(player, null)
	scene_runner(player.get_parent())

	assert_bool(counter.slot.is_empty()).is_true()
	assert_int(_item_spot(counter).get_child_count()).is_equal(0)


func test_interact_picks_up_and_puts_back() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var counter: Counter3D = _add_counter(player, TOMATO)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var tomato: ItemInstance = counter.slot.get_item()
	await physics_ticks(runner, 5)

	await press(runner, "interact")

	assert_object(player.arms.top()).is_same(tomato)
	assert_int(_item_spot(counter).get_child_count()).is_equal(0)

	await press(runner, "interact")

	assert_bool(player.arms.is_empty()).is_true()
	assert_object(counter.slot.get_item()).is_same(tomato)
	assert_int(_item_spot(counter).get_child_count()).is_equal(1)


func test_the_knife_chops_lettuce_on_the_board() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var counter: Counter3D = _add_counter(player, BOARD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.arms.add(ItemInstance.new(LETTUCE))
	await physics_ticks(runner, 5)
	await press(runner, "interact")

	await press(runner, "use_tool")

	# Part way: one of the three cuts it takes is made (the chop meter shows it).
	assert_object(counter.cut_progress()).is_equal(Vector2i(1, 3))

	await press(runner, "use_tool")
	await press(runner, "use_tool")

	var food: Array[ItemInstance] = counter.slot.get_item().contents.get_contents()
	assert_object(food[0].item).is_same(CHOPPED_LETTUCE)


func test_chopping_in_the_galley_while_the_ship_sails() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_BOARD)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var board: Counter3D = ship.get_node("Galley/BoardCounter") as Counter3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 10)
	ship.set_sail()
	await physics_ticks(runner, 30)
	player.arms.add(ItemInstance.new(LETTUCE))

	await press(runner, "interact")
	for i: int in 3:
		await press(runner, "use_tool")

	assert_float(ship.global_position.length()).is_greater(1.0)
	var food: Array[ItemInstance] = board.slot.get_item().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_object(food[0].item).is_same(CHOPPED_LETTUCE)


func test_the_detector_prompts_for_the_board() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_counter(player, BOARD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") 			as InteractionDetector3D
	player.arms.add(ItemInstance.new(LETTUCE))
	await physics_ticks(runner, 5)

	assert_str(detector.interact_prompt()).is_equal("Put Lettuce on Chopping Board")
	assert_str(detector.tool_prompt()).is_empty()

	await press(runner, "interact")

	assert_str(detector.interact_prompt()).is_equal("Take Lettuce")
	assert_str(detector.tool_prompt()).is_equal("Chop")


func _item_spot(counter: Counter3D) -> Node3D:
	return counter.get_node("ItemSpot") as Node3D


func test_facing_a_board_with_food_and_a_knife_puts_the_meter_up() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]

	assert_bool(counter.is_meter_up()).is_true()
	assert_bool(counter.needs_knife()).is_false()


func test_without_a_knife_the_board_says_you_need_one() -> void:
	var setup: Array = await _board_with_tomato(false)
	var counter: Counter3D = setup[0]

	assert_bool(counter.is_meter_up()).is_false()
	assert_bool(counter.needs_knife()).is_true()


func test_perfect_cuts_on_the_meter_slice_cleanly() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]

	for i: int in 2:
		counter.meter.position = counter.meter.centre
		assert_bool(counter.cut_with(player, KNIFE)).is_true()

	var sliced: ItemInstance = counter.slot.get_item().contents.get_contents()[0]
	assert_object(sliced.item).is_same(SLICED_TOMATO)
	# A tomato (1) cut perfectly (3): (1 + 3) / 2 = 2.
	assert_int(sliced.quality).is_equal(2)


func test_ragged_cuts_on_the_meter_slice_badly() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]

	for i: int in 2:
		counter.meter.position = 0.0
		counter.cut_with(player, KNIFE)

	var sliced: ItemInstance = counter.slot.get_item().contents.get_contents()[0]
	assert_int(sliced.quality).is_equal(1)


func test_each_cut_says_how_well_it_was_made() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]
	var grades: Array[int] = []
	counter.chopped.connect(func(grade: int) -> void: grades.append(grade))

	counter.meter.position = counter.meter.centre
	counter.cut_with(player, KNIFE)

	assert_array(grades).contains_exactly([ChopMeter.Grade.PERFECT])


func test_the_board_counts_the_cuts_made_and_needed() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]
	var player: Player3D = setup[1]

	counter.cut_with(player, KNIFE)

	assert_object(counter.cut_progress()).is_equal(Vector2i(1, 2))


func test_the_meter_takes_its_sweet_spot_from_the_knife() -> void:
	var setup: Array = await _board_with_tomato()
	var counter: Counter3D = setup[0]

	assert_float(counter.meter.perfect_width).is_equal(KNIFE.sweet_spot)


# A board with a tomato on it, in front of a player facing it, after the
# meter has had a chance to go up. Returns [counter, player].
func _board_with_tomato(with_knife: bool = true) -> Array:
	var player: Player3D = new_player_3d_on_floor()
	if not with_knife:
		player.start_tools = []
	var counter: Counter3D = _add_counter(player, BOARD)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	counter.slot.get_item().contents.add_item(ItemInstance.new(TOMATO))
	await physics_ticks(runner, 5)
	return [counter, player]


func _add_counter(player: Player3D, start_item: Item) -> Counter3D:
	var counter: Counter3D = (load(COUNTER_SCENE) as PackedScene).instantiate() as Counter3D
	counter.start_item = start_item
	counter.position = AHEAD
	player.get_parent().add_child(counter)
	return counter
