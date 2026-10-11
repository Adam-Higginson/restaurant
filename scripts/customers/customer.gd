class_name Customer
extends Node2D
## A townsperson in the dining room. They walk in from the door to their
## table's seat, order, and wait while their patience drains. Served their
## order, they pay, eat for a while and leave with the plate. If nobody serves
## them in time, they leave politely through the door instead.
##
## Walking uses a [NavigationAgent2D], so they find their way around the
## tables and walls. They don't collide with anything, so they walk straight
## through the player and each other (#53).

## Emitted when they reach their seat and order.
signal seated(customer: Customer)
## Emitted when they accept a plate with their order on it, with what they pay.
signal served(customer: Customer, bill: Bill)
## Emitted when their patience runs out, just before they get up to leave.
signal gave_up(customer: Customer)
## Emitted when they get up to leave, fed or not, taking any plate with them.
signal stood_up(customer: Customer)
## Emitted when they've walked out of the door, just before they're freed.
signal left(customer: Customer)

enum State { WALKING_IN, WAITING, EATING, LEAVING }

## Walking speed in pixels per second (the player walks at 80).
const SPEED: float = 40.0
## How long they eat, in real seconds, unless [member eat_seconds] is changed.
const EAT_SECONDS: float = 8.0
const LEAVE_MESSAGE: String = "I'll pop back another time"
const THANKS_MESSAGE: String = "Thank you!"
const BODY_RADIUS: float = 5.0
const OUTLINE_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
## The patience bar, drawn just above the head.
const PATIENCE_RECT: Rect2 = Rect2(-8, -10, 16, 2)
const PATIENCE_BACK_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
const PATIENCE_FULL_COLOR: Color = Color(0.45, 0.85, 0.4, 1)
const PATIENCE_EMPTY_COLOR: Color = Color(0.85, 0.35, 0.3, 1)
## Where the bottom of the speech bubble sits, above the patience bar.
const BUBBLE_BOTTOM: float = -12.0

## Real seconds they spend eating before they leave. Paused with the clock.
@export var eat_seconds: float = EAT_SECONDS

## The state whose clock pauses their patience. Tests set their own before
## adding them; otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null
## Prices what they're served. Defaults to the game's menu.
var menu: Menu = null
var person: Person:
	get:
		return _person
	set(_value):
		push_error("Customer: person is read-only, use setup()")
## The dish they ordered.
var order: Item:
	get:
		return _order
	set(_value):
		push_error("Customer: order is read-only, use setup()")
var state: State:
	get:
		return _state
	set(_value):
		push_error("Customer: state is read-only")
## The plate they were served, which they take with them; null until then.
var plate: ItemInstance:
	get:
		return _plate
	set(_value):
		push_error("Customer: plate is read-only, use serve()")

var _person: Person = null
var _order: Item = null
var _state: State = State.WALKING_IN
var _seat_position: Vector2 = Vector2.ZERO
var _exit_position: Vector2 = Vector2.ZERO
var _patience: PatienceMeter = null
var _plate: ItemInstance = null
## Seconds of eating left.
var _eating_left: float = 0.0

@onready var _agent: NavigationAgent2D = $Agent
@onready var _name_label: Label = $NameLabel
@onready var _bubble: Label = $Bubble


## Sets who they are, what they'll order, where they sit and where they leave
## by. Call it before adding them to the scene; they walk in from wherever
## they're placed.
func setup(who: Person, dish: Item, seat_position: Vector2, exit_position: Vector2) -> void:
	_person = who
	_order = dish
	_seat_position = seat_position
	_exit_position = exit_position


func _ready() -> void:
	if game_state == null:
		game_state = Game
	if menu == null:
		menu = Menu.load_default()
	_patience = PatienceMeter.new(_person.patience_seconds)
	_name_label.text = _person.display_name
	_bubble.visible = false
	_patience.ran_out.connect(_give_up)
	_agent.target_position = _seat_position


func _process(delta: float) -> void:
	if game_state.clock.is_paused():
		return
	match _state:
		State.WAITING:
			_patience.drain(delta)
			queue_redraw()
		State.EATING:
			_eating_left -= delta
			if _eating_left <= 0.0:
				leave()


func _physics_process(delta: float) -> void:
	if _state == State.WAITING or _state == State.EATING:
		return
	if _agent.is_navigation_finished():
		_arrive()
		return
	var next_position: Vector2 = _agent.get_next_path_position()
	global_position = global_position.move_toward(next_position, SPEED * delta)


func _draw() -> void:
	draw_circle(Vector2.ZERO, BODY_RADIUS + 1.0, OUTLINE_COLOR)
	draw_circle(Vector2.ZERO, BODY_RADIUS, _person.color)
	if _state == State.WAITING:
		draw_rect(PATIENCE_RECT, PATIENCE_BACK_COLOR)
		var fill: Rect2 = PATIENCE_RECT
		fill.size.x = roundf(PATIENCE_RECT.size.x * _patience.fraction())
		var color: Color = PATIENCE_EMPTY_COLOR.lerp(PATIENCE_FULL_COLOR, _patience.fraction())
		draw_rect(fill, color)


## How much patience they have left, from 1 (full) to 0 (none).
func patience_fraction() -> float:
	return _patience.fraction()


## Offers them [param offered]. They accept it only while waiting, and only a
## plate or bowl holding exactly the dish they ordered. Accepting, they pay,
## show what they paid and start eating. Returns whether they accepted it.
func serve(offered: ItemInstance) -> bool:
	if _state != State.WAITING or not _is_their_order(offered):
		return false
	_plate = offered
	_state = State.EATING
	_eating_left = eat_seconds
	var dish: ItemInstance = offered.contents.get_contents()[0]
	var bill: Bill = Bill.for_dish(menu, _person, dish)
	_say(_payment_text(bill))
	queue_redraw()
	served.emit(self, bill)
	return true


## Stands up and walks out of the door: thanking you if they ate, otherwise
## saying goodbye. Does nothing if they're already leaving.
func leave() -> void:
	if _state == State.LEAVING:
		return
	_state = State.LEAVING
	if _plate != null:
		_say(THANKS_MESSAGE)
	else:
		_say(LEAVE_MESSAGE)
	_agent.target_position = _exit_position
	queue_redraw()
	stood_up.emit(self)


## Called when the agent has reached its target: the seat or the door.
func _arrive() -> void:
	match _state:
		State.WALKING_IN:
			global_position = _seat_position
			_state = State.WAITING
			_say(_order.display_name)
			queue_redraw()
			seated.emit(self)
		State.LEAVING:
			left.emit(self)
			queue_free()


func _is_their_order(offered: ItemInstance) -> bool:
	# Only a plate or bowl, not loose food or a board or pan.
	if offered == null or not offered.is_vessel() or not offered.item.carried_whole:
		return false
	var food: Array[ItemInstance] = offered.contents.get_contents()
	return food.size() == 1 and food[0].item == _order


func _payment_text(bill: Bill) -> String:
	var text: String = "+{total}G".format({"total": bill.total()})
	if bill.loved:
		text += " ♥"
	return text


func _give_up() -> void:
	gave_up.emit(self)
	leave()


func _say(text: String) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble.size = _bubble.get_minimum_size()
	_bubble.position = Vector2(-_bubble.size.x / 2.0, BUBBLE_BOTTOM - _bubble.size.y).round()
