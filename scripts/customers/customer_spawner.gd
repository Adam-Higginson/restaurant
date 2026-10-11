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
	# TODO 1:
	#   a. Make `_planner`, an ArrivalPlanner for `arrivals`.
	#   b. Connect the game state's signals to the handlers at the bottom:
	#      `game_state.clock.time_changed` -> `_on_time_changed`,
	#      `game_state.open_changed` -> `_on_open_changed`,
	#      `game_state.day_changed` -> `_on_day_changed`.


## Everyone inside, walking in, waiting or leaving.
func customers() -> Array[Customer]:
	# TODO 2: The customers in `_seated_at` (its values) as an Array[Customer].
	# Like Menu.dishes(), use `assign()` to turn the untyped values() into a
	# typed array.
	return []


## Tables nobody is sitting at (or walking to, or leaving from).
func free_tables() -> Array[Node2D]:
	# TODO 3: Every table is in the "tables" group (see table.tscn), so
	# `get_tree().get_nodes_in_group(&"tables")` finds them all without knowing
	# where they are. Return the ones that aren't keys in `_seated_at`.
	# The group gives you Nodes: cast each one with `as Node2D`.
	return []


## Brings someone in now: a random townsperson who isn't inside and can order
## from the menu, at a random free table. Returns null, bringing nobody, if
## there's no free table or nobody to bring.
func spawn_customer() -> Customer:
	# TODO 5:
	#   a. Get the free tables and `_people_who_could_come()`. If either is
	#      empty, return null.
	#   b. Pick a random person and a random table with
	#      `rng.randi_range(0, size - 1)`. Always use `rng`, never the global
	#      randi(), so tests can seed it.
	#   c. The table's seat is its "Seat" child: `table.get_node("Seat")`, cast
	#      to Marker2D.
	#   d. Make the customer with `CUSTOMER_SCENE.instantiate() as Customer`.
	#      Before adding it to the scene:
	#      - set its `game_state` to ours,
	#      - call `setup()` with the person, their order
	#        (`person.choose_order(menu, rng)`), the seat's global_position
	#        and the door's global_position,
	#      - put it at the door (its `position`),
	#      - connect its `left` signal to `_on_customer_left`.
	#   e. Record it in `_seated_at` under its table, add it as a child of our
	#      parent (`get_parent().add_child(...)`, so it's in the restaurant with
	#      the navigation floor), emit `customer_arrived`, and return it.
	return null


func _people_who_could_come() -> Array[Person]:
	# TODO 4: Everyone in `people` who isn't already inside (no customer in
	# `customers()` has them as its `person`) and can order from `menu`.
	return []


func _check_arrivals() -> void:
	# TODO 6: Ask `_planner.check()` how many are due now (pass the clock's
	# `minutes` and the game state's `is_open`), and spawn that many.
	pass


func _on_time_changed(_minutes: int) -> void:
	# TODO 7: Every clock step might bring someone: check the arrivals.
	pass


func _on_open_changed(_is_open: bool) -> void:
	# TODO 8: Opening late brings a due customer straight away, without waiting
	# for the next step: check the arrivals when it opens (not when it closes).
	# Rename the parameter to `is_open` once you use it.
	pass


func _on_day_changed(_day: int) -> void:
	# TODO 9: A new day, behind the night's black screen:
	#   a. Reset the planner, so lunch and dinner come again.
	#   b. Send everyone home: `queue_free()` each customer and clear
	#      `_seated_at`.
	pass


func _on_customer_left(_customer: Customer) -> void:
	# TODO 10: Free their table: find the key in `_seated_at` whose value is
	# the customer, and `erase()` it. Rename the parameter to `customer`.
	pass
