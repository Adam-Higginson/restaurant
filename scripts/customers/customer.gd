class_name Customer
extends Node2D
## A townsperson in the dining room. They walk in from the door to their
## table's seat, order, wait while their patience drains, and leave politely
## through the door if nobody serves them.
##
## Walking uses a [NavigationAgent2D], so they find their way around the
## tables and walls. They don't collide with anything, so they walk straight
## through the player and each other (#53).

## Emitted when they reach their seat and order.
signal seated(customer: Customer)
## Emitted when they've walked out of the door, just before they're freed.
signal left(customer: Customer)

enum State { WALKING_IN, WAITING, LEAVING }

## Walking speed in pixels per second (the player walks at 80).
const SPEED: float = 40.0
const LEAVE_MESSAGE: String = "I'll pop back another time"
const BODY_RADIUS: float = 5.0
const OUTLINE_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
## The patience bar, drawn just above the head.
const PATIENCE_RECT: Rect2 = Rect2(-8, -10, 16, 2)
const PATIENCE_BACK_COLOR: Color = Color(0.15, 0.12, 0.12, 1)
const PATIENCE_FULL_COLOR: Color = Color(0.45, 0.85, 0.4, 1)
const PATIENCE_EMPTY_COLOR: Color = Color(0.85, 0.35, 0.3, 1)
## Where the bottom of the speech bubble sits, above the patience bar.
const BUBBLE_BOTTOM: float = -12.0

## The state whose clock pauses their patience. Tests set their own before
## adding them; otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null
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

var _person: Person = null
var _order: Item = null
var _state: State = State.WALKING_IN
var _seat_position: Vector2 = Vector2.ZERO
var _exit_position: Vector2 = Vector2.ZERO
var _patience: PatienceMeter = null

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
	_patience = PatienceMeter.new(_person.patience_seconds)
	_name_label.text = _person.display_name
	_bubble.visible = false
	_patience.ran_out.connect(leave)
	_agent.target_position = _seat_position


func _process(delta: float) -> void:
	if game_state.clock.is_paused() or _state != State.WAITING:
		return
	_patience.drain(delta)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _state == State.WAITING:
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


## Stands up and walks out of the door, saying goodbye. Does nothing if
## they're already leaving.
func leave() -> void:
	if _state == State.LEAVING:
		return
	_state = State.LEAVING
	_say(LEAVE_MESSAGE)
	_agent.target_position = _exit_position
	queue_redraw()


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


func _say(text: String) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble.size = _bubble.get_minimum_size()
	_bubble.position = Vector2(-_bubble.size.x / 2.0, BUBBLE_BOTTOM - _bubble.size.y).round()
