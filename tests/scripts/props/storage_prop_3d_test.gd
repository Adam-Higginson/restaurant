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


func test_starts_with_lettuce_and_tomatoes_in_twelve_slots() -> void:
	var pantry: StorageProp3D = _new_pantry()
	assert_int(pantry.contents.count(LETTUCE, ItemInstance.MIN_QUALITY)).is_equal(3)
	assert_int(pantry.contents.count(TOMATO, ItemInstance.MIN_QUALITY)).is_equal(3)
	assert_int(pantry.contents.capacity).is_equal(12)
	assert_int(pantry.contents.kind).is_equal(Item.StorageKind.PANTRY)


func test_puts_away_food_of_any_kind() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var arms: Arms = Arms.new()
	var onion: ItemInstance = ItemInstance.new(ONION)
	var sliced: ItemInstance = ItemInstance.new(SLICED_TOMATO, 2)
	arms.add(onion)
	arms.add(sliced)

	pantry.act(arms)
	pantry.act(arms)

	assert_bool(arms.is_empty()).is_true()
	assert_array(pantry.contents.get_items()).contains([onion, sliced])
	assert_int(pantry.contents.count(SLICED_TOMATO, 2)).is_equal(1)
	assert_bool(_panel(pantry).is_open()).is_false()


func test_empty_arms_open_the_panel() -> void:
	var pantry: StorageProp3D = _new_pantry()
	pantry.act(Arms.new())
	assert_bool(_panel(pantry).is_open()).is_true()
	assert_str((_panel(pantry).find_child("Title") as Label).text).is_equal("Pantry")


func test_holding_a_plate_opens_the_panel_and_keeps_the_plate() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var arms: Arms = Arms.new()
	arms.add(ItemInstance.new(PLATE))

	pantry.act(arms)

	assert_bool(_panel(pantry).is_open()).is_true()
	assert_int(arms.size()).is_equal(1)
	assert_int(pantry.contents.size()).is_equal(6)


func test_a_full_pantry_opens_the_panel() -> void:
	var pantry: StorageProp3D = _new_pantry()
	while not pantry.contents.is_full():
		pantry.contents.add(ItemInstance.new(ONION))
	var arms: Arms = Arms.new()
	arms.add(ItemInstance.new(TOMATO))

	pantry.act(arms)

	assert_bool(_panel(pantry).is_open()).is_true()
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


func test_prompt_says_put_away_or_open() -> void:
	var pantry: StorageProp3D = _new_pantry()
	var hand: Toolbar = Toolbar.new()
	assert_str(pantry.interact_prompt(hand)).is_equal("Open Pantry")
	hand.add(ItemInstance.new(TOMATO))
	assert_str(pantry.interact_prompt(hand)).is_equal("Put away Tomato")
	hand.take_top()
	hand.add(ItemInstance.new(PLATE))
	assert_str(pantry.interact_prompt(hand)).is_equal("Open Pantry")


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
