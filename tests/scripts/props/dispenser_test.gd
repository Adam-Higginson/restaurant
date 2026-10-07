extends GameTestSuite
## Tests for Dispenser (the plate rack and the temporary food bins).

const DISPENSER_SCENE: String = "res://scenes/props/dispenser.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
const PLATE: Item = preload("res://data/items/plate.tres")
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
## Just below the plate rack (centred at 152, 24).
const BELOW_PLATE_RACK: Vector2 = Vector2(152, 44)

var _arms: Arms


func before_test() -> void:
	_arms = Arms.new()


func test_gives_a_fresh_normal_quality_item_each_time() -> void:
	var rack: Dispenser = _new_dispenser(PLATE)

	assert_bool(rack.dispense(_arms)).is_true()
	assert_bool(rack.dispense(_arms)).is_true()

	var items: Array[ItemInstance] = _arms.get_items()
	assert_int(items.size()).is_equal(2)
	assert_object(items[0]).is_not_same(items[1])
	for instance: ItemInstance in items:
		assert_object(instance.item).is_same(PLATE)
		assert_int(instance.quality).is_equal(ItemInstance.MIN_QUALITY)


func test_plates_from_the_rack_are_clean() -> void:
	var rack: Dispenser = _new_dispenser(PLATE)
	rack.dispense(_arms)
	assert_array(_arms.top().contents.get_contents()).is_empty()


func test_full_arms_get_nothing() -> void:
	var rack: Dispenser = _new_dispenser(PLATE)
	for i: int in Arms.CAPACITY:
		rack.dispense(_arms)

	assert_bool(rack.dispense(_arms)).is_false()
	assert_int(_arms.size()).is_equal(Arms.CAPACITY)


func test_dispenser_without_an_item_gives_nothing() -> void:
	assert_bool(_new_dispenser(null).dispense(_arms)).is_false()
	assert_bool(_arms.is_empty()).is_true()


func test_restaurant_has_a_plate_rack_and_lettuce_and_tomato_bins() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_object((runner.find_child("PlateRack") as Dispenser).item).is_same(PLATE)
	assert_object((runner.find_child("LettuceBin") as Dispenser).item).is_same(LETTUCE)
	assert_object((runner.find_child("TomatoBin") as Dispenser).item).is_same(TOMATO)


func test_pressing_interact_at_the_plate_rack_gives_a_plate() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BELOW_PLATE_RACK)

	await walk(runner, "move_up", 20)
	await press(runner, "interact")

	assert_int(player.arms.size()).is_equal(1)
	assert_object(player.arms.top().item).is_same(PLATE)


func _new_dispenser(item: Item) -> Dispenser:
	var dispenser: Dispenser = (
		(load(DISPENSER_SCENE) as PackedScene).instantiate() as Dispenser
	)
	dispenser.item = item
	add_child(dispenser)
	auto_free(dispenser)
	return dispenser
