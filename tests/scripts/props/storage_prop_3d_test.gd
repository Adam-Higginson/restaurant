extends GameTestSuite
## Tests for StorageProp3D (the galley pantry): its starting stock, putting
## food away, and opening its panel to take food out.

const PANTRY_SCENE: String = "res://scenes/prototype/props/pantry.tscn"
const LETTUCE: Item = preload("res://data/items/lettuce.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const ONION: Item = preload("res://data/items/onion.tres")
const SLICED_TOMATO: Item = preload("res://data/items/sliced_tomato.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
## A pantry 1.2 m ahead of the player (who faces -Z), within reach.
const AHEAD: Vector3 = Vector3(0, 0, -1.2)


func after_test() -> void:
	# A failing test could leave the game paused, which would stall later suites.
	get_tree().paused = false


func test_starts_stocked_for_the_soups_in_sixteen_slots() -> void:
	var pantry: StorageProp3D = _new_pantry()
	assert_int(pantry.contents.count(LETTUCE, ItemInstance.MIN_QUALITY)).is_equal(3)
	assert_int(pantry.contents.count(TOMATO, ItemInstance.MIN_QUALITY)).is_equal(3)
	# Until islands join the ship (#67), as if brought back from the shore.
	var crab_meat: Item = load("res://data/items/crab_meat.tres") as Item
	assert_int(pantry.contents.count(crab_meat, ItemInstance.MIN_QUALITY)).is_equal(1)
	# For Tomato Soup, and the first quest's Spicy Tomato Soup (#154).
	var chilli: Item = load("res://data/items/chilli.tres") as Item
	assert_int(pantry.contents.count(ONION, ItemInstance.MIN_QUALITY)).is_equal(2)
	assert_int(pantry.contents.count(chilli, ItemInstance.MIN_QUALITY)).is_equal(2)
	assert_int(pantry.contents.capacity).is_equal(16)
	assert_int(pantry.contents.kind).is_equal(Item.StorageKind.PANTRY)


func test_puts_away_food_of_any_kind() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var arms: Arms = Arms.new()
	var onion: ItemInstance = ItemInstance.new(ONION)
	var sliced: ItemInstance = ItemInstance.new(SLICED_TOMATO, 2)
	arms.add(onion)
	arms.add(sliced)

	assert_bool(pantry.put_away(arms)).is_true()
	assert_bool(pantry.put_away(arms)).is_true()

	assert_bool(arms.is_empty()).is_true()
	assert_array(pantry.contents.get_items()).contains([onion, sliced])
	assert_int(pantry.contents.count(SLICED_TOMATO, 2)).is_equal(1)
	assert_bool(_panel(pantry).is_open()).is_false()


func test_open_shows_the_panel() -> void:
	var pantry: StorageProp3D = _new_pantry()
	pantry.open(Arms.new())
	assert_bool(_panel(pantry).is_open()).is_true()
	assert_str((_panel(pantry).find_child("Title") as Label).text).is_equal("Pantry")


func test_a_plate_isnt_put_away() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var arms: Arms = Arms.new()
	arms.add(ItemInstance.new(PLATE))

	assert_bool(pantry.put_away(arms)).is_false()

	assert_int(arms.size()).is_equal(1)
	assert_int(pantry.contents.size()).is_equal(11)


func test_a_full_pantry_takes_nothing_more() -> void:
	var pantry: StorageProp3D = _new_pantry()
	while not pantry.contents.is_full():
		pantry.contents.add(ItemInstance.new(ONION))
	var arms: Arms = Arms.new()
	arms.add(ItemInstance.new(TOMATO))

	assert_bool(pantry.put_away(arms)).is_false()

	assert_int(arms.size()).is_equal(1)


func test_interact_takes_a_tomato_out_through_the_panel() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var pantry: StorageProp3D = _instantiate()
	pantry.position = AHEAD
	player.get_parent().add_child(pantry)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	await press(runner, "interact")

	var panel: ContainerPanel = _panel(pantry)
	assert_bool(panel.is_open()).is_true()
	assert_bool(get_tree().paused).is_true()
	_row(panel, "Tomato").pressed.emit()
	await press(runner, "ui_cancel")

	assert_bool(panel.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_object(player.arms.top().item).is_same(TOMATO)
	assert_int(pantry.contents.count(TOMATO, ItemInstance.MIN_QUALITY)).is_equal(2)


func test_interact_opens_and_use_puts_away() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var hand: Toolbar = Toolbar.new()
	assert_str(pantry.interact_prompt()).is_equal("Open Pantry")
	assert_str(pantry.use_prompt(hand)).is_empty()
	hand.add(ItemInstance.new(TOMATO))
	assert_str(pantry.use_prompt(hand)).is_equal("Put away Tomato")
	hand.take_top()
	hand.add(ItemInstance.new(PLATE))
	assert_str(pantry.use_prompt(hand)).is_empty()


func _instantiate() -> StorageProp3D:
	return (load(PANTRY_SCENE) as PackedScene).instantiate() as StorageProp3D


func _new_pantry() -> StorageProp3D:
	var pantry: StorageProp3D = _instantiate()
	add_child(pantry)
	auto_free(pantry)
	return pantry


func _panel(pantry: StorageProp3D) -> ContainerPanel:
	return pantry.get_node("ContainerPanel") as ContainerPanel


func _row(panel: ContainerPanel, prefix: String) -> Button:
	for button: Button in panel.get_rows():
		if button.text.begins_with(prefix):
			return button
	return null
