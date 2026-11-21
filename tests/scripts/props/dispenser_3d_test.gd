extends GameTestSuite
## Tests for Dispenser3D (the galley's plate rack).

const RACK_SCENE: String = "res://scenes/prototype/props/plate_rack.tscn"
const PLATE: Item = preload("res://data/items/plate.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
## A rack 1.2 m ahead of the player (who faces -Z), within reach.
const AHEAD: Vector3 = Vector3(0, 0, -1.2)


func test_gives_a_fresh_clean_plate_each_time() -> void:
	var rack: Dispenser3D = _new_rack()
	var arms: Arms = Arms.new()

	assert_bool(rack.dispense(arms)).is_true()
	assert_bool(rack.dispense(arms)).is_true()

	var items: Array[ItemInstance] = arms.get_items()
	assert_int(items.size()).is_equal(2)
	assert_object(items[0]).is_not_same(items[1])
	for instance: ItemInstance in items:
		assert_object(instance.item).is_same(PLATE)
		assert_int(instance.quality).is_equal(ItemInstance.MIN_QUALITY)
		assert_array(instance.contents.get_contents()).is_empty()


func test_announces_what_it_gave() -> void:
	var rack: Dispenser3D = _new_rack()
	var arms: Arms = Arms.new()
	var given: Array[ItemInstance] = []
	rack.dispensed.connect(func(instance: ItemInstance) -> void: given.append(instance))

	rack.dispense(arms)

	assert_array(given).contains_exactly([arms.top()])


func test_full_arms_get_nothing() -> void:
	var rack: Dispenser3D = _new_rack()
	var arms: Arms = Arms.new()
	for i: int in Arms.CAPACITY:
		arms.add(ItemInstance.new(TOMATO))
	var given: Array[ItemInstance] = []
	rack.dispensed.connect(func(instance: ItemInstance) -> void: given.append(instance))

	assert_bool(rack.dispense(arms)).is_false()
	assert_object(arms.top().item).is_same(TOMATO)
	assert_array(given).is_empty()


func test_gives_nothing_without_an_item() -> void:
	var rack: Dispenser3D = (load(RACK_SCENE) as PackedScene).instantiate() as Dispenser3D
	rack.item = null
	add_child(rack)
	auto_free(rack)
	var arms: Arms = Arms.new()
	assert_bool(rack.dispense(arms)).is_false()
	assert_bool(arms.is_empty()).is_true()
	assert_int(_item_spot(rack).get_child_count()).is_equal(0)


func test_never_runs_out() -> void:
	var rack: Dispenser3D = _new_rack()
	var arms: Arms = Arms.new()
	for i: int in 3:
		while rack.dispense(arms):
			pass
		assert_int(arms.size()).is_equal(Arms.CAPACITY)
		while not arms.is_empty():
			arms.take_top()


func test_shows_a_plate_on_top() -> void:
	var rack: Dispenser3D = _new_rack()
	assert_int(_item_spot(rack).get_child_count()).is_equal(1)


func test_interact_hands_the_player_a_plate() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var rack: Dispenser3D = (load(RACK_SCENE) as PackedScene).instantiate() as Dispenser3D
	rack.position = AHEAD
	player.get_parent().add_child(rack)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await press(runner, "interact")

	assert_object(player.arms.top().item).is_same(PLATE)


func test_prompt_offers_a_plate_until_the_toolbar_is_full() -> void:
	var rack: Dispenser3D = _new_rack()
	var hand: Toolbar = Toolbar.new()
	hand.add(ItemInstance.new(TOMATO))
	assert_str(rack.interact_prompt(hand)).is_equal("Take Plate")
	while not hand.is_full():
		hand.add(ItemInstance.new(TOMATO))
	assert_str(rack.interact_prompt(hand)).is_empty()


func _new_rack() -> Dispenser3D:
	var rack: Dispenser3D = (load(RACK_SCENE) as PackedScene).instantiate() as Dispenser3D
	add_child(rack)
	auto_free(rack)
	return rack


func _item_spot(rack: Dispenser3D) -> Node3D:
	return rack.get_node("ItemSpot") as Node3D
