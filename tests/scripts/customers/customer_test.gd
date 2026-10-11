extends GameTestSuite
## Tests for Customer: walking in to a seat, waiting with patience that drains,
## and leaving through the door. Runs in the main scene so customers have the
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


func before_test() -> void:
	_salad = Catalog.load_default().find_item(&"garden_salad")


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


# --- Helpers --------------------------------------------------------------------

## The main scene, once its navigation map is ready.
func _main() -> GdUnitSceneRunner:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	return runner


func _add_customer(runner: GdUnitSceneRunner, person: Person, seat: Vector2) -> Customer:
	var customer: Customer = (load(CUSTOMER_SCENE) as PackedScene).instantiate() as Customer
	customer.setup(person, _salad, seat, DOOR)
	customer.position = DOOR
	runner.scene().add_child(customer)
	return customer


func _seated_customer(runner: GdUnitSceneRunner, person: Person) -> Customer:
	var customer: Customer = _add_customer(runner, person, NEAR_SEAT)
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
