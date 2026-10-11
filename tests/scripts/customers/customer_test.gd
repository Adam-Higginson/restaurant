extends GameTestSuite
## Tests for Customer: walking in to a seat, waiting with patience that drains,
## being served and eating, and leaving through the door. Runs in the main scene so customers have the
## restaurant's navigation floor to walk on.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const CUSTOMER_SCENE: String = "res://scenes/customer.tscn"
## The restaurant's Door marker.
const DOOR: Vector2 = Vector2(320, 248)
## Table3's seat: the nearest to the door, about 2 seconds' walk.
const NEAR_SEAT: Vector2 = Vector2(256, 184)
## Table1's seat, past Table3, so the way there goes around a table.
const FAR_SEAT: Vector2 = Vector2(256, 88)

var _salad: Item
var _tomato: Item
var _plate: Item
## Garden Salad at 12, so tests don't depend on the game's menu.
var _menu: Menu


func before_test() -> void:
	var catalog: Catalog = Catalog.load_default()
	_salad = catalog.find_item(&"garden_salad")
	_tomato = catalog.find_item(&"tomato")
	_plate = catalog.find_item(&"plate")
	_menu = Menu.new()
	_menu.prices[_salad] = 12


func after_test() -> void:
	# The customers use the real Game autoload, so put it back afterwards.
	Game.new_game()


# --- Walking in -----------------------------------------------------------------

func test_starts_walking_in_from_where_its_placed() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), NEAR_SEAT)
	assert_int(customer.state).is_equal(Customer.State.WALKING_IN)
	assert_vector(customer.position).is_equal(DOOR)


func test_walks_from_the_door_to_their_seat() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), NEAR_SEAT)

	assert_bool(await wait_for_signal(customer.seated, 6.0)).override_failure_message(
		"Never reached the seat").is_true()
	assert_vector(customer.global_position).is_equal(NEAR_SEAT)
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_finds_the_way_around_a_table() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), FAR_SEAT)
	assert_bool(await wait_for_signal(customer.seated, 10.0)).override_failure_message(
		"Never reached the far seat").is_true()
	assert_vector(customer.global_position).is_equal(FAR_SEAT)


func test_keeps_their_order() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var person: Person = _person(120.0)
	var customer: Customer = _add_customer(runner, person, NEAR_SEAT)
	assert_object(customer.person).is_same(person)
	assert_object(customer.order).is_same(_salad)


# --- Waiting ----------------------------------------------------------------------

func test_patience_is_full_until_they_sit() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), NEAR_SEAT)
	await physics_ticks(runner, 30)
	assert_float(customer.patience_fraction()).is_equal(1.0)


func test_patience_drains_while_they_wait() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	await get_tree().create_timer(0.5).timeout
	assert_float(customer.patience_fraction()).is_less(1.0)


func test_keeps_waiting_until_served_or_out_of_patience() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	await get_tree().create_timer(0.5).timeout
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_patience_stops_while_the_clock_is_paused() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	Game.clock.pause(self)
	var before: float = customer.patience_fraction()
	await get_tree().create_timer(0.5).timeout
	assert_float(customer.patience_fraction()).is_equal(before)
	Game.clock.resume(self)


# --- Leaving --------------------------------------------------------------------

func test_leaves_when_patience_runs_out() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(0.3))
	await get_tree().create_timer(0.6).timeout
	assert_int(customer.state).is_equal(Customer.State.LEAVING)


func test_walks_out_of_the_door_and_is_gone() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(0.3))
	assert_bool(await wait_for_signal(customer.left, 6.0)).override_failure_message(
		"Never walked out of the door").is_true()
	await physics_ticks(runner, 1)
	assert_bool(is_instance_valid(customer)).is_false()


func test_leave_sends_them_out_even_on_the_way_in() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), FAR_SEAT)
	await physics_ticks(runner, 20)
	customer.leave()
	assert_int(customer.state).is_equal(Customer.State.LEAVING)
	assert_bool(await wait_for_signal(customer.left, 6.0)).is_true()


func test_leaving_twice_changes_nothing() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	customer.leave()
	customer.leave()
	assert_int(customer.state).is_equal(Customer.State.LEAVING)


func test_announces_standing_up_once() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	var counter: Dictionary[String, int] = {"stood_up": 0}
	customer.stood_up.connect(func(_who: Customer) -> void: counter["stood_up"] += 1)
	customer.leave()
	customer.leave()
	assert_int(counter["stood_up"]).is_equal(1)


func test_running_out_of_patience_means_giving_up() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(0.3))
	assert_bool(await wait_for_signal(customer.gave_up, 2.0)).override_failure_message(
		"Never gave up").is_true()


# --- Being served -----------------------------------------------------------------

func test_accepts_a_plate_with_their_order_and_starts_eating() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	var plate: ItemInstance = _plate_with([ItemInstance.new(_salad)])
	assert_bool(customer.serve(plate)).is_true()
	assert_int(customer.state).is_equal(Customer.State.EATING)
	assert_object(customer.plate).is_same(plate)


func test_being_served_sends_the_bill() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	var bills: Array[Bill] = []
	customer.served.connect(func(_who: Customer, bill: Bill) -> void: bills.append(bill))
	customer.serve(_plate_with([ItemInstance.new(_salad, 3)]))
	assert_int(bills.size()).is_equal(1)
	# 12 + 6 (★★★), and the test person loves nothing.
	assert_int(bills[0].total()).is_equal(18)
	assert_bool(bills[0].loved).is_false()


func test_a_loved_dish_is_on_the_bill() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var person: Person = _person(120.0)
	person.loved = [_salad]
	var customer: Customer = await _seated_customer(runner, person)
	var bills: Array[Bill] = []
	customer.served.connect(func(_who: Customer, bill: Bill) -> void: bills.append(bill))
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	assert_bool(bills[0].loved).is_true()
	assert_int(bills[0].total()).is_equal(15)


func test_refuses_the_wrong_dish() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	assert_bool(customer.serve(_plate_with([ItemInstance.new(_tomato)]))).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)
	assert_object(customer.plate).is_null()


func test_refuses_an_empty_plate() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	assert_bool(customer.serve(_plate_with([]))).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_refuses_their_order_with_something_else_on_the_plate() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	var plate: ItemInstance = _plate_with([ItemInstance.new(_salad), ItemInstance.new(_tomato)])
	assert_bool(customer.serve(plate)).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_refuses_their_order_without_a_plate() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	assert_bool(customer.serve(ItemInstance.new(_salad))).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_refuses_nothing() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	assert_bool(customer.serve(null)).is_false()
	assert_int(customer.state).is_equal(Customer.State.WAITING)


func test_refuses_a_plate_on_the_way_in() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = _add_customer(runner, _person(120.0), NEAR_SEAT)
	assert_bool(customer.serve(_plate_with([ItemInstance.new(_salad)]))).is_false()
	assert_int(customer.state).is_equal(Customer.State.WALKING_IN)


func test_refuses_a_second_plate_while_eating() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	var first: ItemInstance = _plate_with([ItemInstance.new(_salad)])
	customer.serve(first)
	assert_bool(customer.serve(_plate_with([ItemInstance.new(_salad)]))).is_false()
	assert_object(customer.plate).is_same(first)


func test_refuses_a_plate_once_leaving() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0))
	customer.leave()
	assert_bool(customer.serve(_plate_with([ItemInstance.new(_salad)]))).is_false()
	assert_int(customer.state).is_equal(Customer.State.LEAVING)


# --- Eating -------------------------------------------------------------------------

func test_patience_stops_once_served() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(0.5))
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	var before: float = customer.patience_fraction()
	await get_tree().create_timer(0.7).timeout
	assert_float(customer.patience_fraction()).is_equal(before)
	assert_int(customer.state).is_equal(Customer.State.EATING)


func test_eats_for_eat_seconds() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0), 1.0)
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	await get_tree().create_timer(0.5).timeout
	assert_int(customer.state).is_equal(Customer.State.EATING)


func test_leaves_once_theyve_eaten() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0), 0.3)
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	await get_tree().create_timer(0.6).timeout
	assert_int(customer.state).is_equal(Customer.State.LEAVING)
	assert_bool(await wait_for_signal(customer.left, 6.0)).override_failure_message(
		"Never walked out after eating").is_true()


func test_eating_stops_while_the_clock_is_paused() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0), 0.3)
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	Game.clock.pause(self)
	await get_tree().create_timer(0.6).timeout
	assert_int(customer.state).is_equal(Customer.State.EATING)
	Game.clock.resume(self)


func test_a_customer_who_ate_doesnt_give_up() -> void:
	var runner: GdUnitSceneRunner = await _main()
	var customer: Customer = await _seated_customer(runner, _person(120.0), 0.2)
	var counter: Dictionary[String, int] = {"gave_up": 0}
	customer.gave_up.connect(func(_who: Customer) -> void: counter["gave_up"] += 1)
	customer.serve(_plate_with([ItemInstance.new(_salad)]))
	assert_bool(await wait_for_signal(customer.left, 6.0)).is_true()
	assert_int(counter["gave_up"]).is_equal(0)


# --- Helpers --------------------------------------------------------------------

## The main scene, once its navigation map is ready.
func _main() -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	return runner


func _add_customer(runner: GdUnitSceneRunner, person: Person, seat: Vector2,
		eat_seconds: float = Customer.EAT_SECONDS) -> Customer:
	var customer: Customer = (load(CUSTOMER_SCENE) as PackedScene).instantiate() as Customer
	customer.menu = _menu
	customer.eat_seconds = eat_seconds
	customer.setup(person, _salad, seat, DOOR)
	customer.position = DOOR
	runner.scene().add_child(customer)
	return customer


func _seated_customer(runner: GdUnitSceneRunner, person: Person,
		eat_seconds: float = Customer.EAT_SECONDS) -> Customer:
	var customer: Customer = _add_customer(runner, person, NEAR_SEAT, eat_seconds)
	assert_bool(await wait_for_signal(customer.seated, 6.0)).override_failure_message(
		"Never reached the seat").is_true()
	return customer


func _person(patience: float) -> Person:
	var person: Person = Person.new()
	person.id = &"test_person"
	person.display_name = "Test"
	person.color = Color.CORAL
	person.patience_seconds = patience
	return person


## A plate holding [param food]. Nothing here reacts, so it stays as given.
func _plate_with(food: Array[ItemInstance]) -> ItemInstance:
	var plate: ItemInstance = ItemInstance.new(_plate)
	for piece: ItemInstance in food:
		plate.contents.add_item(piece)
	return plate
