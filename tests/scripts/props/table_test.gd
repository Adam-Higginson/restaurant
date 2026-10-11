extends GameTestSuite
## Tests for Table: serving its diner from the player's arms. Runs in the main
## scene, so the diner can walk in to the table's seat.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const SALAD: Item = preload("res://data/items/garden_salad.tres")
const TOMATO: Item = preload("res://data/items/tomato.tres")
const PLATE: Item = preload("res://data/items/plate.tres")
## Just above Table3 (centred at 256, 168), the side away from its seat.
const ABOVE_TABLE_3: Vector2 = Vector2(256, 140)

var _arms: Arms
var _menu: Menu


func before_test() -> void:
	_arms = Arms.new()
	_menu = Menu.new()
	_menu.prices[SALAD] = 12


func after_test() -> void:
	# Customers and the player use the real Game autoload.
	Game.new_game()


# --- Seating ----------------------------------------------------------------------

func test_starts_with_no_diner() -> void:
	var runner: GdUnitSceneRunner = await _main()
	assert_object(_table(runner).diner).is_null()


func test_seat_gives_the_table_its_diner() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	assert_object(_table(runner).diner).is_same(customer)


func test_the_diner_is_gone_once_theyve_walked_out() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	customer.leave()
	assert_bool(await wait_for_signal(customer.left, 6.0)).is_true()
	await physics_ticks(runner, 2)
	assert_object(_table(runner).diner).is_null()


func test_the_diner_is_gone_if_theyre_sent_home() -> void:
	# A new day frees everyone inside without them walking out.
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	customer.queue_free()
	await physics_ticks(runner, 2)
	assert_object(_table(runner).diner).is_null()


# --- Serving ------------------------------------------------------------------------

func test_serve_from_hands_the_plate_to_the_diner() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	var plate: ItemInstance = _salad_plate()
	_arms.add(plate)

	assert_bool(_table(runner).serve_from(_arms)).is_true()
	assert_bool(_arms.is_empty()).is_true()
	assert_object(customer.plate).is_same(plate)
	assert_int(customer.state).is_equal(Customer.State.EATING)


func test_serve_from_keeps_the_wrong_dish_in_the_arms() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(TOMATO))
	_arms.add(plate)

	assert_bool(_table(runner).serve_from(_arms)).is_false()
	assert_object(_arms.top()).is_same(plate)
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_serve_from_only_offers_the_top_of_the_stack() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	_arms.add(_salad_plate())
	_arms.add(ItemInstance.new(TOMATO))

	assert_bool(_table(runner).serve_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(2)
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_serve_from_with_empty_arms_does_nothing() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	assert_bool(_table(runner).serve_from(_arms)).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_serve_from_with_no_diner_does_nothing() -> void:
	var runner: GdUnitSceneRunner = await _main()
	_arms.add(_salad_plate())
	assert_bool(_table(runner).serve_from(_arms)).is_false()
	assert_int(_arms.size()).is_equal(1)


# --- With the player --------------------------------------------------------------

func test_pressing_pick_up_at_the_table_serves_the_diner() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seat(runner)
	var player: Player = place_player(runner, ABOVE_TABLE_3)
	var plate: ItemInstance = _salad_plate()
	player.arms.add(plate)

	await walk(runner, "move_down", 20)
	await press(runner, "pick_up")

	assert_bool(player.arms.is_empty()).is_true()
	assert_object(customer.plate).is_same(plate)


func test_every_table_can_be_served_at() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var tables: Array[Node] = runner.scene().get_tree().get_nodes_in_group(&"tables")
	assert_int(tables.size()).is_equal(4)
	for node: Node in tables:
		assert_bool(node is Table).is_true()
		assert_object(node.get_node_or_null(^"Interactable") as Interactable).is_not_null()


# --- Helpers --------------------------------------------------------------------

## The main scene, once its navigation map is ready.
func _main() -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	return runner


func _table(runner: GdUnitSceneRunner) -> Table:
	return runner.find_child("Table3") as Table


## Someone who wants a salad, seated at Table3.
func _seat(runner: GdUnitSceneRunner) -> Customer:
	var person: Person = Person.new()
	person.id = &"test_person"
	person.display_name = "Test"
	person.patience_seconds = 120.0
	var customer: Customer = await seat_customer(runner, _table(runner), person, SALAD, _menu)
	assert_int(customer.state).override_failure_message("Never sat down").is_equal(
		Customer.State.WAITING)
	return customer


func _salad_plate() -> ItemInstance:
	var plate: ItemInstance = ItemInstance.new(PLATE)
	plate.contents.add_item(ItemInstance.new(SALAD))
	return plate
