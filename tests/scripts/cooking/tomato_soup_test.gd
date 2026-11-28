extends GameTestSuite
## Tests for Tomato Soup the way the GDD designs it, with rain from the deck:
## fill the saucepan at the water butt, boil the water on the hearth, add
## diced tomato and chopped onion, boil, and ladle it into a bowl. Dumping it
## all in cold is the rough shortcut.

## By the water butt on deck, facing it (port).
const AT_THE_BUTT: Vector3 = Vector3(-3.9, 5.35, -1.6)


func test_the_water_butt_fills_a_held_saucepan() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_BUTT)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	player.toolbar.add(ItemInstance.new(_item(&"saucepan")))

	await walk(runner, "move_left", 2)
	await press(runner, "use_tool")

	assert_bool(player.toolbar.top().contents.get_contents().is_empty()).is_true()
	assert_bool(player.controls_enabled).is_false()
	assert_float(player.fill_progress).is_greater_equal(0.0)
	await physics_ticks(runner, 60)
	var food: Array[ItemInstance] = player.toolbar.top().contents.get_contents()
	assert_int(food.size()).is_equal(1)
	if not food.is_empty():
		assert_str(String(food[0].item.id)).is_equal("rainwater")
	assert_bool(player.controls_enabled).is_true()
	assert_float(player.fill_progress).is_equal(-1.0)


func test_switching_slots_during_the_dip_leaves_the_pot_empty() -> void:
	Game.dialogue.clear(WaterButt.FETCHED_FLAG)
	var rig: Array[Node3D] = new_moored_ship_with_player(AT_THE_BUTT)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	await physics_ticks(runner, 2)
	var pot: ItemInstance = ItemInstance.new(_item(&"saucepan"))
	player.toolbar.add(pot)
	await walk(runner, "move_left", 2)
	await press(runner, "use_tool")
	assert_bool(player.controls_enabled).is_false()
	player.toolbar.select_next()
	await physics_ticks(runner, 3)
	assert_bool(player.controls_enabled).is_true()
	assert_float(player.fill_progress).is_equal(-1.0)
	assert_bool(pot.contents.get_contents().is_empty()).is_true()
	assert_bool(Game.dialogue.is_set(WaterButt.FETCHED_FLAG)).is_false()


func test_a_pot_only_ever_holds_one_lot_of_water() -> void:
	var butt: WaterButt = _butt()
	var toolbar: Toolbar = Toolbar.new()
	toolbar.add(ItemInstance.new(_item(&"saucepan")))

	assert_bool(butt.fill(toolbar)).is_true()

	assert_bool(butt.can_fill(toolbar)).is_false()
	assert_bool(butt.fill(toolbar)).is_false()
	assert_int(toolbar.top().contents.get_contents().size()).is_equal(1)


func test_boiling_water_counts_as_the_one_lot() -> void:
	var butt: WaterButt = _butt()
	var toolbar: Toolbar = Toolbar.new()
	toolbar.add(ItemInstance.new(_item(&"saucepan")))
	toolbar.top().contents.add_item(ItemInstance.new(_item(&"boiling_water")))

	assert_bool(butt.can_fill(toolbar)).is_false()
	assert_str(butt.prompt(toolbar)).is_equal("Pour out the water")


func test_a_pot_of_water_pours_back_into_the_butt() -> void:
	var butt: WaterButt = _butt()
	var toolbar: Toolbar = Toolbar.new()
	toolbar.add(ItemInstance.new(_item(&"saucepan")))
	butt.fill(toolbar)

	assert_bool(butt.pour(toolbar)).is_true()

	assert_array(toolbar.top().contents.get_contents()).is_empty()
	assert_str(butt.prompt(toolbar)).is_equal("Fill Cooking Pot with rainwater")


func test_soup_isnt_poured_away() -> void:
	var butt: WaterButt = _butt()
	var toolbar: Toolbar = Toolbar.new()
	toolbar.add(ItemInstance.new(_item(&"saucepan")))
	toolbar.top().contents.add_item(ItemInstance.new(_item(&"rainwater")))
	toolbar.top().contents.add_item(ItemInstance.new(_item(&"diced_tomato")))

	assert_bool(butt.can_pour(toolbar)).is_false()
	assert_bool(butt.pour(toolbar)).is_false()
	assert_str(butt.prompt(toolbar)).is_empty()


func test_it_offers_nothing_to_empty_hands() -> void:
	var butt: WaterButt = (load("res://scenes/prototype/props/water_butt.tscn") as PackedScene) \
			.instantiate() as WaterButt
	auto_free(butt)
	var toolbar: Toolbar = Toolbar.new()

	assert_str(butt.prompt(toolbar)).is_empty()
	assert_bool(butt.fill(toolbar)).is_false()


func test_soup_done_properly_is_three_stars() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var pan: VesselContents = _soup_pan(rig[0] as Ship)
	await physics_ticks(runner, 2)

	pan.add_item(ItemInstance.new(_item(&"rainwater")))
	await physics_ticks(runner, 4 * 60 + 5)
	assert_str(String(pan.get_contents()[0].item.id)).is_equal("boiling_water")
	pan.add_item(ItemInstance.new(_item(&"diced_tomato"), 2))
	pan.add_item(ItemInstance.new(_item(&"chopped_onion"), 2))
	await physics_ticks(runner, 8 * 60 + 5)
	# Off the heat at its golden moment, the moment it's done.
	assert_array(pan.get_golden_moments()).has_size(1)
	pan.remove_element(_fire())

	var food: Array[ItemInstance] = pan.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_str(String(food[0].item.id)).is_equal("tomato_soup")
	assert_int(food[0].quality).is_equal(3)


func test_dumping_it_all_in_cold_is_the_rough_shortcut() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())
	var pan: VesselContents = _soup_pan(rig[0] as Ship)
	await physics_ticks(runner, 2)

	pan.add_item(ItemInstance.new(_item(&"rainwater")))
	pan.add_item(ItemInstance.new(_item(&"diced_tomato")))
	pan.add_item(ItemInstance.new(_item(&"chopped_onion")))
	await physics_ticks(runner, 12 * 60 + 5)

	var food: Array[ItemInstance] = pan.get_contents()
	assert_str(String(food[0].item.id)).is_equal("tomato_soup")
	assert_int(food[0].quality).is_equal(1)


func test_the_soup_hob_starts_empty_for_the_captains_pot() -> void:
	var ship: Node = (load("res://scenes/prototype/ship.tscn") as PackedScene).instantiate()
	auto_free(ship)
	var hob: Hob = ship.get_node("Galley/SoupHob") as Hob

	# The captain gives you the pot at the helm (#186).
	assert_object(hob.start_item).is_null()


func test_soup_ladles_into_a_bowl_from_the_stack() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var hob: Hob = ship.get_node("Galley/SoupHob") as Hob
	_soup_pan(ship).add_item(ItemInstance.new(_item(&"tomato_soup")))
	var bowls: Dispenser3D = ship.get_node("Galley/BowlStack") as Dispenser3D

	assert_bool(bowls.dispense(player.arms)).is_true()
	assert_bool(hob.slot.exchange_with(player.arms)).is_true()

	var bowl: ItemInstance = player.arms.top()
	assert_str(String(bowl.item.id)).is_equal("bowl")
	assert_str(String(bowl.contents.get_contents()[0].item.id)).is_equal("tomato_soup")
	assert_bool(hob.heated.contents.get_contents().is_empty()).is_true()


# The pot on the soup hob. The captain gives it to you now (#186), so the hob
# starts empty: set one down there first.
func _soup_pan(ship: Ship) -> VesselContents:
	var hob: Hob = ship.get_node("Galley/SoupHob") as Hob
	if hob.heated == null:
		hob.slot.place(ItemInstance.new(_item(&"saucepan")))
	return hob.heated.contents


func _item(id: StringName) -> Item:
	return Catalog.load_default().find_item(id)


func _butt() -> WaterButt:
	var butt: WaterButt = (load("res://scenes/prototype/props/water_butt.tscn") as PackedScene) \
			.instantiate() as WaterButt
	auto_free(butt)
	return butt


func _fire() -> Element:
	return Catalog.load_default().find_element(&"fire")
