extends GameTestSuite
## Tests for CustomerSpawner: who comes in, when, and where they sit.
##
## Most tests use a small rig (a door, some tables and the spawner) with their
## own GameState, and move its clock on by hand at one second per step.

const MAIN_SCENE: String = "res://scenes/main.tscn"
const LUNCH_DUE: int = 12 * 60 + 30
const LUNCH_UNTIL: int = 14 * 60
const DOOR_POSITION: Vector2 = Vector2(0, 100)

var _state: GameState
var _salad: Item
var _menu: Menu
## Loves salad.
var _fan: Person
## Likes salad.
var _friend: Person
## Dislikes salad, so can't order from a salad-only menu.
var _hater: Person
var _door: Marker2D


func before_test() -> void:
	_state = GameState.new()
	auto_free(_state)
	_state.clock.seconds_per_step = 1.0
	_salad = Catalog.load_default().find_item(&"garden_salad")
	_menu = Menu.new()
	_menu.prices[_salad] = 12
	_fan = _person(&"fan", [_salad], [])
	_friend = _person(&"friend", [], [])
	_friend.liked.append(_salad)
	_hater = _person(&"hater", [], [_salad])


func after_test() -> void:
	# The scene test uses the real Game autoload, so put it back afterwards.
	Game.clock.seconds_per_step = GameClock.DEFAULT_SECONDS_PER_STEP
	Game.new_game()


# --- When ----------------------------------------------------------------------

func test_someone_arrives_at_lunch_while_open() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_state.set_open(true)
	_tick_to(LUNCH_DUE)
	assert_int(spawner.customers().size()).is_equal(1)


func test_nobody_arrives_before_lunch() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_state.set_open(true)
	_tick_to(LUNCH_DUE - 10)
	assert_array(spawner.customers()).is_empty()


func test_nobody_arrives_while_closed() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_tick_to(LUNCH_DUE + 30)
	assert_array(spawner.customers()).is_empty()


func test_opening_late_brings_them_straight_away() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_tick_to(13 * 60 + 10)
	_state.set_open(true)
	assert_int(spawner.customers().size()).is_equal(1)


func test_opening_after_lunch_brings_nobody() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan, _friend], 2)
	_tick_to(LUNCH_UNTIL + 10)
	_state.set_open(true)
	_tick_to(LUNCH_UNTIL + 60)
	assert_array(spawner.customers()).is_empty()


func test_lunch_brings_only_one_customer() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan, _friend], 2)
	_state.set_open(true)
	_tick_to(LUNCH_UNTIL - 10)
	assert_int(spawner.customers().size()).is_equal(1)


# --- Who --------------------------------------------------------------------------

func test_a_customer_is_one_of_the_townsfolk() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan, _friend], 1)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	assert_array([_fan, _friend]).contains([customer.person])


func test_orders_from_the_menu() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 1)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	assert_object(customer.order).is_same(_salad)


func test_the_same_person_is_never_inside_twice() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 2)
	spawner.spawn_customer()
	assert_object(spawner.spawn_customer()).is_null()
	assert_int(spawner.customers().size()).is_equal(1)


func test_two_customers_are_two_different_people() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan, _friend], 2)
	var first: Customer = _spawn(spawner)
	var second: Customer = _spawn(spawner)
	if first == null or second == null:
		return
	assert_object(second.person).is_not_same(first.person)


func test_skips_someone_who_dislikes_everything_on_the_menu() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_hater, _fan], 2)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	assert_object(customer.person).is_same(_fan)
	assert_object(spawner.spawn_customer()).is_null()


func test_nobody_comes_if_nobody_can_order() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_hater], 1)
	_state.set_open(true)
	_tick_to(LUNCH_DUE)
	assert_array(spawner.customers()).is_empty()


# --- Where ------------------------------------------------------------------------

func test_walks_in_from_the_door() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 1)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	assert_vector(customer.global_position).is_equal(DOOR_POSITION)


func test_takes_a_free_table() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 2)
	spawner.spawn_customer()
	assert_int(spawner.free_tables().size()).is_equal(1)


func test_nobody_comes_when_every_table_is_taken() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan, _friend], 1)
	spawner.spawn_customer()
	assert_object(spawner.spawn_customer()).is_null()
	assert_int(spawner.customers().size()).is_equal(1)


func test_a_customer_leaving_frees_their_table() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 1)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	customer.left.emit(customer)
	assert_int(spawner.free_tables().size()).is_equal(1)
	assert_array(spawner.customers()).is_empty()


func test_announces_each_arrival() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 1)
	var seen: Array[Customer] = []
	spawner.customer_arrived.connect(func(customer: Customer) -> void: seen.append(customer))
	var customer: Customer = spawner.spawn_customer()
	assert_array(seen).contains_exactly([customer])


# --- Closing and the night --------------------------------------------------------

func test_seated_customers_stay_after_closing() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_state.set_open(true)
	_tick_to(LUNCH_DUE)
	_state.set_open(false)
	assert_int(spawner.customers().size()).is_equal(1)


func test_a_new_day_sends_everyone_home() -> void:
	var spawner: CustomerSpawner = _new_spawner([], [_fan], 1)
	var customer: Customer = _spawn(spawner)
	if customer == null:
		return
	_state.end_day()
	_state.start_next_day()
	assert_array(spawner.customers()).is_empty()
	assert_int(spawner.free_tables().size()).is_equal(1)
	assert_bool(customer.is_queued_for_deletion()).is_true()


func test_lunch_comes_again_the_next_day() -> void:
	var spawner: CustomerSpawner = _new_spawner([_lunch()], [_fan], 1)
	_state.set_open(true)
	_tick_to(LUNCH_DUE)
	_state.end_day()
	_state.start_next_day()
	_state.set_open(true)
	_tick_to(LUNCH_DUE)
	assert_int(spawner.customers().size()).is_equal(1)


# --- In the restaurant --------------------------------------------------------------

func test_restaurant_has_a_spawner_at_the_door_with_lunch_and_dinner() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var spawner: CustomerSpawner = runner.find_child("CustomerSpawner") as CustomerSpawner
	assert_object(spawner).is_not_null()
	assert_object(spawner.door).is_same(runner.find_child("Door"))
	var times: Array[Vector2i] = []
	for arrival: Arrival in spawner.arrivals:
		times.append(Vector2i(arrival.due_minutes, arrival.until_minutes))
	assert_array(times).contains_exactly_in_any_order([
		Vector2i(LUNCH_DUE, LUNCH_UNTIL), Vector2i(19 * 60, 21 * 60),
	])


func test_restaurant_uses_the_game_menu_and_cast() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	var spawner: CustomerSpawner = runner.find_child("CustomerSpawner") as CustomerSpawner
	assert_object(spawner.game_state).is_same(Game)
	assert_array(spawner.menu.dishes()).contains_exactly([_salad])
	assert_int(spawner.people.size()).is_equal(6)


func test_a_lunch_customer_sits_at_a_table_in_the_restaurant() -> void:
	var runner: GdUnitSceneRunner = scene_runner(MAIN_SCENE)
	assert_bool(await wait_for_navigation(runner)).is_true()
	var spawner: CustomerSpawner = runner.find_child("CustomerSpawner") as CustomerSpawner
	Game.clock.seconds_per_step = 1.0
	Game.set_open(true)
	Game.clock.tick((LUNCH_DUE - Game.clock.minutes) / 10.0)

	assert_int(spawner.customers().size()).is_equal(1)
	if spawner.customers().is_empty():
		return
	var customer: Customer = spawner.customers()[0]
	assert_bool(await wait_for_signal(customer.seated, 10.0)).override_failure_message(
		"The lunch customer never sat down").is_true()
	assert_int(spawner.free_tables().size()).is_equal(3)
	# At a real seat in the dining room, not a seat's position relative to its table.
	var seats: Array[Vector2] = []
	for table: Node in runner.scene().get_tree().get_nodes_in_group(&"tables"):
		seats.append((table.get_node("Seat") as Node2D).global_position)
	assert_array(seats).contains([customer.global_position])


# --- Helpers ----------------------------------------------------------------------

func _new_spawner(arrivals: Array[Arrival], people: Array[Person], tables: int) -> CustomerSpawner:
	var rig: Node2D = Node2D.new()
	auto_free(rig)
	add_child(rig)
	_door = Marker2D.new()
	_door.position = DOOR_POSITION
	rig.add_child(_door)
	for i: int in tables:
		var table: Node2D = Node2D.new()
		table.position = Vector2(40 * i, 0)
		table.add_to_group(&"tables")
		var seat: Marker2D = Marker2D.new()
		seat.name = "Seat"
		seat.position = Vector2(0, 16)
		table.add_child(seat)
		rig.add_child(table)

	var spawner: CustomerSpawner = CustomerSpawner.new()
	# Before add_child, so _ready keeps them instead of the game's own.
	spawner.game_state = _state
	spawner.menu = _menu
	spawner.people = people
	spawner.rng = RandomNumberGenerator.new()
	spawner.rng.seed = 12345
	spawner.arrivals = arrivals
	spawner.door = _door
	rig.add_child(spawner)
	return spawner


## Spawns a customer, failing the test (and returning null) if nobody came.
func _spawn(spawner: CustomerSpawner) -> Customer:
	var customer: Customer = spawner.spawn_customer()
	assert_object(customer).override_failure_message(
		"spawn_customer() brought nobody").is_not_null()
	return customer


## Moves the test clock on, one step at a time, until it's [param minutes].
func _tick_to(minutes: int) -> void:
	while _state.clock.minutes < minutes:
		_state.clock.tick(_state.clock.seconds_per_step)


func _lunch() -> Arrival:
	var arrival: Arrival = Arrival.new()
	arrival.due_minutes = LUNCH_DUE
	arrival.until_minutes = LUNCH_UNTIL
	return arrival


func _person(id: StringName, loved: Array[Item], disliked: Array[Item]) -> Person:
	var person: Person = Person.new()
	person.id = id
	person.display_name = String(id).capitalize()
	person.loved = loved
	person.disliked = disliked
	return person
