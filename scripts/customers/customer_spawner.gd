class_name CustomerSpawner
extends Node
## Brings townsfolk into the restaurant on schedule: one at lunch and one at
## dinner, if it's open (see [ArrivalPlanner]). Each is someone who isn't
## already inside and can order something, sat at a free table.
##
## Customers are added as siblings of the spawner, so they share the
## restaurant's navigation map. Anyone still inside when a new day starts is
## sent home behind the night's black screen.

## Emitted when a customer walks in through the door.
signal customer_arrived(customer: Customer)

const CUSTOMER_SCENE: PackedScene = preload("res://scenes/customer.tscn")

## Today's scheduled arrivals.
@export var arrivals: Array[Arrival] = []
## Where customers walk in and leave.
@export var door: Marker2D = null

## The state whose clock and sign it follows. Tests set their own before adding
## it; otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null
## What customers order from. Defaults to the game's menu.
var menu: Menu = null
## Who can visit. Defaults to everyone in the catalog.
var people: Array[Person] = []
## Rolls who comes, where they sit and what they order. Tests seed their own.
var rng: RandomNumberGenerator = null

var _planner: ArrivalPlanner = null
## Each taken table and who's sitting there.
var _seated_at: Dictionary[Node2D, Customer] = {}


func _ready() -> void:
	if game_state == null:
		game_state = Game
	if menu == null:
		menu = Menu.load_default()
	if people.is_empty():
		people = Catalog.load_default().people
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	_planner = ArrivalPlanner.new(arrivals)
	game_state.clock.time_changed.connect(_on_time_changed)
	game_state.open_changed.connect(_on_open_changed)
	game_state.day_changed.connect(_on_day_changed)


## Everyone inside, walking in, waiting or leaving.
func customers() -> Array[Customer]:
	var result: Array[Customer] = []
	result.assign(_seated_at.values())
	return result


## Tables nobody is sitting at (or walking to, or leaving from).
func free_tables() -> Array[Node2D]:
	var tables: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group(&"tables"):
		var table: Node2D = node as Node2D
		if table != null and not _seated_at.has(table):
			tables.append(table)
	return tables


## Brings someone in now: a random townsperson who isn't inside and can order
## from the menu, at a random free table. Returns null, bringing nobody, if
## there's no free table or nobody to bring.
func spawn_customer() -> Customer:
	var tables: Array[Node2D] = free_tables()
	var candidates: Array[Person] = _people_who_could_come()
	if tables.is_empty() or candidates.is_empty():
		return null

	var table: Node2D = tables[rng.randi_range(0, tables.size() - 1)]
	var person: Person = candidates[rng.randi_range(0, candidates.size() - 1)]
	var seat: Marker2D = table.get_node("Seat") as Marker2D

	var customer: Customer = CUSTOMER_SCENE.instantiate() as Customer
	customer.game_state = game_state
	# Global positions: the seat's own position is relative to its table.
	customer.setup(person, person.choose_order(menu, rng), seat.global_position,
		door.global_position)
	customer.position = door.global_position
	customer.left.connect(_on_customer_left)

	_seated_at[table] = customer
	get_parent().add_child(customer)
	customer_arrived.emit(customer)

	return customer


func _people_who_could_come() -> Array[Person]:
	var inside: Array[Person] = []
	for customer: Customer in customers():
		inside.append(customer.person)
	var candidates: Array[Person] = []
	for person: Person in people:
		if not inside.has(person) and person.can_order_from(menu):
			candidates.append(person)
	return candidates


func _check_arrivals() -> void:
	var due: int = _planner.check(game_state.clock.minutes, game_state.is_open)
	for i: int in due:
		spawn_customer()


func _on_time_changed(_minutes: int) -> void:
	_check_arrivals()


func _on_open_changed(is_open: bool) -> void:
	if is_open:
		_check_arrivals()


func _on_day_changed(_day: int) -> void:
	_planner.reset()
	for customer: Customer in customers():
		customer.queue_free()
	_seated_at.clear()


func _on_customer_left(customer: Customer) -> void:
	var customer_table: Node2D = _seated_at.find_key(customer)
	if customer_table != null:
		_seated_at.erase(customer_table)
