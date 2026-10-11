extends GameTestSuite
## Tests for StorageProp: the fridge, the cupboard and the delivery crate.

const FRIDGE_SCENE: String = "res://scenes/props/fridge.tscn"
const CUPBOARD_SCENE: String = "res://scenes/props/cupboard.tscn"
const CRATE_SCENE: String = "res://scenes/props/crate.tscn"
const MAIN_SCENE: String = "res://scenes/main.tscn"
## Just right of the fridge (centred at 24, 72), on the kitchen floor.
const BESIDE_FRIDGE: Vector2 = Vector2(48, 72)
## Just above the crate (centred at 288, 232).
const ABOVE_CRATE: Vector2 = Vector2(288, 208)

var _catalog: Catalog
var _arms: Arms


func before_test() -> void:
	_catalog = Catalog.load_default()
	_arms = Arms.new()


func after_test() -> void:
	get_tree().paused = false


# --- Putting away -------------------------------------------------------------

func test_put_down_puts_food_of_its_kind_away() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	var tomato: ItemInstance = _hold(&"tomato", 3)
	assert_bool(fridge.put_away_from(_arms)).is_true()
	assert_bool(_arms.is_empty()).is_true()
	assert_array(fridge.contents.get_items()).contains_exactly([tomato])
	assert_int(fridge.contents.get_items()[0].quality).is_equal(3)


func test_prepared_food_goes_in_the_fridge() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	_hold(&"sliced_tomato")
	assert_bool(fridge.put_away_from(_arms)).is_true()


func test_dry_food_goes_in_the_cupboard_not_the_fridge() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	var cupboard: StorageProp = _new_prop(CUPBOARD_SCENE)
	_hold(&"onion")
	assert_bool(fridge.put_away_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(1)
	assert_bool(cupboard.put_away_from(_arms)).is_true()


func test_only_the_top_item_is_put_away() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	var tomato: ItemInstance = _hold(&"tomato")
	_hold(&"plate")
	assert_bool(fridge.put_away_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(2)
	_arms.rotate()
	assert_bool(fridge.put_away_from(_arms)).is_true()
	assert_array(fridge.contents.get_items()).contains_exactly([tomato])


func test_nothing_to_put_away_with_empty_arms() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	assert_bool(fridge.put_away_from(_arms)).is_false()


func test_fridge_and_cupboard_hold_twelve() -> void:
	for scene: String in [FRIDGE_SCENE, CUPBOARD_SCENE]:
		var prop: StorageProp = _new_prop(scene)
		assert_int(prop.contents.capacity).is_equal(12)
		assert_bool(prop.contents.is_empty()).is_true()


func test_a_full_fridge_refuses_more() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	for i: int in 12:
		fridge.contents.add(ItemInstance.new(_catalog.find_item(&"tomato")))
	_hold(&"tomato")
	assert_bool(fridge.put_away_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(1)


# --- The crate ----------------------------------------------------------------

func test_crate_starts_with_two_of_each_ingredient() -> void:
	var crate: StorageProp = _new_prop(CRATE_SCENE)
	for id: StringName in [&"lettuce", &"tomato", &"onion", &"bread", &"cheese"]:
		assert_int(crate.contents.count(_catalog.find_item(id), 1)).override_failure_message(
			"The crate should start with 2 %s" % id
		).is_equal(2)
	assert_int(crate.contents.size()).is_equal(10)


func test_nothing_can_be_put_in_the_crate() -> void:
	var crate: StorageProp = _new_prop(CRATE_SCENE)
	_hold(&"tomato")
	assert_bool(crate.put_away_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(1)
	assert_int(crate.contents.size()).is_equal(10)


func test_contents_cant_be_replaced() -> void:
	var fridge: StorageProp = _new_prop(FRIDGE_SCENE)
	var contents: StorageContents = fridge.contents
	await assert_error(
		func() -> void: fridge.contents = StorageContents.new(Item.StorageKind.FRIDGE)
	).is_push_error("StorageProp: contents can't be replaced")
	assert_object(fridge.contents).is_same(contents)


# --- Opening ------------------------------------------------------------------

func test_interact_opens_the_panel() -> void:
	var crate: StorageProp = _new_prop(CRATE_SCENE)
	var panel: ContainerPanel = crate.get_node("ContainerPanel") as ContainerPanel
	crate.open_for(_arms)
	assert_bool(panel.is_open()).is_true()
	assert_str((panel.find_child("Title") as Label).text).is_equal("Delivery crate")


# --- In the game --------------------------------------------------------------

func test_putting_away_and_taking_out_in_the_game() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, BESIDE_FRIDGE)
	var fridge: StorageProp = runner.find_child("Fridge") as StorageProp
	await walk(runner, "move_left", 10)
	var tomato: ItemInstance = ItemInstance.new(_catalog.find_item(&"tomato"), 2)
	player.arms.add(tomato)

	await press(runner, "pick_up")
	assert_bool(player.arms.is_empty()).is_true()
	assert_array(fridge.contents.get_items()).contains_exactly([tomato])

	await press(runner, "interact")
	assert_bool(get_tree().paused).is_true()
	runner.simulate_action_pressed("ui_accept")
	await runner.await_input_processed()
	assert_object(player.arms.top()).is_same(tomato)
	assert_bool(fridge.contents.is_empty()).is_true()

	runner.simulate_action_pressed("ui_cancel")
	await runner.await_input_processed()
	assert_bool(get_tree().paused).is_false()


func test_taking_from_the_crate_in_the_game() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var player: Player = place_player(runner, ABOVE_CRATE)
	var crate: StorageProp = runner.find_child("Crate") as StorageProp
	await walk(runner, "move_down", 10)

	await press(runner, "interact")
	runner.simulate_action_pressed("ui_accept")
	await runner.await_input_processed()

	assert_int(player.arms.size()).is_equal(1)
	assert_object(player.arms.top().item).is_same(_catalog.find_item(&"lettuce"))
	assert_int(crate.contents.size()).is_equal(9)


func test_the_clock_stops_while_the_panel_is_open() -> void:
	Game.clock.seconds_per_step = 0.05
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	place_player(runner, ABOVE_CRATE)
	await walk(runner, "move_down", 10)
	await press(runner, "interact")

	var opened_at: int = Game.clock.minutes
	# gdUnit's await_millis would wait forever: its timer pauses with the game.
	await get_tree().create_timer(0.3, true).timeout
	assert_int(Game.clock.minutes).is_equal(opened_at)
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


func _new_prop(path: String) -> StorageProp:
	var prop: StorageProp = (load(path) as PackedScene).instantiate() as StorageProp
	add_child(prop)
	auto_free(prop)
	return prop


func _hold(id: StringName, quality: int = 1) -> ItemInstance:
	var instance: ItemInstance = ItemInstance.new(_catalog.find_item(id), quality)
	_arms.add(instance)
	return instance
