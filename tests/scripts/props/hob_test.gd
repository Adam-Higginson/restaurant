extends GameTestSuite
## Tests for the hob on the galley hearth: the pan on it is over the fire, a
## herring fillet in it fries into Pan-fried Herring, a whole herring takes the
## rough shortcut, and lifting the pan off pauses the cooking.

const HOB_SCENE: String = "res://scenes/prototype/props/hob.tscn"


func test_the_pan_on_the_hob_is_over_the_fire() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)

	assert_str(String(hob.heated.item.id)).is_equal("frying_pan")
	assert_bool(hob.heated.contents.has_element(hob.heat)).is_true()


func test_a_fillet_fries_into_pan_fried_herring() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)

	hob.heated.contents.add_item(_food(&"herring_fillet", 2))
	await physics_ticks(runner, 6 * 60 + 5)
	# Off the heat at its golden moment.
	hob.heated.contents.remove_element(hob.heat)

	var food: Array[ItemInstance] = hob.heated.contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_str(String(food[0].item.id)).is_equal("pan_fried_herring")
	# A ★★ fillet, caught at its best: a star up, ★★★.
	assert_int(food[0].quality).is_equal(3)


func test_fried_past_its_golden_moment_it_is_just_done() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)

	hob.heated.contents.add_item(_food(&"herring_fillet", 2))
	await physics_ticks(runner, 6 * 60 + 5 + roundi(hob.heated.item.golden_window * 60) + 5)
	hob.heated.contents.remove_element(hob.heat)

	var food: Array[ItemInstance] = hob.heated.contents.get_contents()
	assert_str(String(food[0].item.id)).is_equal("pan_fried_herring")
	# Done, never burnt: the ★★ fillet stays ★★.
	assert_int(food[0].quality).is_equal(2)


func test_crab_meat_sears_into_pan_seared_crab() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)

	hob.heated.contents.add_item(_food(&"crab_meat", 1))
	await physics_ticks(runner, 5 * 60 + 5)
	hob.heated.contents.remove_element(hob.heat)

	var food: Array[ItemInstance] = hob.heated.contents.get_contents()
	assert_int(food.size()).is_equal(1)
	assert_str(String(food[0].item.id)).is_equal("pan_seared_crab")
	# A level-1 crab's ★ meat, caught at its best: ★★.
	assert_int(food[0].quality).is_equal(2)


func test_a_whole_herring_takes_the_rough_shortcut() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)

	hob.heated.contents.add_item(_food(&"herring", 1))
	await physics_ticks(runner, 9 * 60 + 5)

	var food: Array[ItemInstance] = hob.heated.contents.get_contents()
	assert_str(String(food[0].item.id)).is_equal("pan_fried_herring")
	assert_int(food[0].quality).is_equal(1)


func test_lifting_the_pan_off_pauses_the_cooking() -> void:
	var hob: Hob = _new_hob()
	var runner: GdUnitSceneRunner = scene_runner(hob)
	await physics_ticks(runner, 2)
	var pan: ItemInstance = hob.heated
	pan.contents.add_item(_food(&"herring_fillet", 1))
	await physics_ticks(runner, 60)

	hob.slot.take()
	var progress: float = pan.contents.get_active_reactions()[0].progress
	await physics_ticks(runner, 120)

	assert_bool(pan.contents.has_element(hob.heat)).is_false()
	assert_float(pan.contents.get_active_reactions()[0].progress).is_equal_approx(progress, 0.001)


func test_the_galley_hob_waits_for_you_to_bring_the_pan() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)

	var hob: Hob = ship.get_node("Galley/Hob") as Hob
	assert_object(hob.slot.get_item()).is_null()
	assert_object(hob.heated).is_null()


func test_setting_your_pan_down_on_the_hob_heats_it() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var hob: Hob = ship.get_node("Galley/Hob") as Hob
	player.toolbar.add(ItemInstance.new(Catalog.load_default().find_item(&"frying_pan")))

	hob.slot.exchange_with(player.arms)

	assert_str(String(hob.heated.item.id)).is_equal("frying_pan")
	assert_bool(player.toolbar.has_item(&"frying_pan")).is_false()


func _new_hob() -> Hob:
	var hob: Hob = (load(HOB_SCENE) as PackedScene).instantiate() as Hob
	auto_free(hob)
	return hob


func _food(id: StringName, quality: int) -> ItemInstance:
	return ItemInstance.new(Catalog.load_default().find_item(id), quality)
