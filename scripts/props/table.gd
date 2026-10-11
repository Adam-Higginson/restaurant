class_name Table
extends StaticBody2D
## A dining table with one seat. Pick up / put down at the table offers the top
## of the player's stack to whoever is sitting there, and their plate sits on
## the table while they eat. See Serving in docs/GDD.md.

## Where the plate sits, on the half of the table nearest the seat.
const PLATE_RECT: Rect2 = Rect2(-5, -3, 10, 10)
## Plates are nearly the table's colour, so they get a dark rim.
const PLATE_OUTLINE_COLOR: Color = Color(0.15, 0.12, 0.12, 1)

## Who is sitting here, or on their way here; null when the table is free.
var diner: Customer:
	get:
		return _diner
	set(_value):
		push_error("Table: diner is read-only, use seat()")

var _diner: Customer = null

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	_interactable.pick_up_pressed.connect(_on_pick_up_pressed)


func _draw() -> void:
	if _diner != null and _diner.state == Customer.State.EATING:
		ItemDraw.draw_item(self, _diner.plate, PLATE_RECT)
		PixelDraw.outline(self, PLATE_RECT.grow(1.0), PLATE_OUTLINE_COLOR)


## Makes [param customer] this table's diner, until they leave the scene.
func seat(customer: Customer) -> void:
	_diner = customer
	_diner.served.connect(_on_diner_served)
	_diner.stood_up.connect(_on_diner_stood_up)
	_diner.tree_exiting.connect(_on_diner_gone)
	queue_redraw()


## Offers the top of [param arms] to the diner. If they accept it, it leaves
## the arms. Returns whether they accepted it.
func serve_from(arms: Arms) -> bool:
	if _diner == null or not _diner.serve(arms.top()):
		return false
	arms.take_top()
	return true


func _on_pick_up_pressed(player: Player) -> void:
	serve_from(player.arms)


# Their plate arrives on the table.
func _on_diner_served(_customer: Customer, _bill: Bill) -> void:
	queue_redraw()


# They take the plate with them.
func _on_diner_stood_up(_customer: Customer) -> void:
	queue_redraw()


func _on_diner_gone() -> void:
	_diner = null
	queue_redraw()
