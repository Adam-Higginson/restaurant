class_name Player
extends CharacterBody2D
## The player character: top-down movement with a 4-way facing direction, and
## arms that carry a stack of items, and a tool belt.

## Walk speed in pixels per second (16px tiles, so 5 tiles per second).
@export var speed: float = 80.0
## The tools on the belt at the start, from the first slot on.
@export var start_tools: Array[HandTool] = []

## The cardinal direction the player is facing. Used later to pick what to interact with.
var facing: Vector2 = Vector2.DOWN
## What the player is carrying. Created once and never replaced, so signal
## connections to it keep working.
var arms: Arms = Arms.new()
## The player's hand tools. Created once and never replaced, like [member arms].
var belt: ToolBelt = ToolBelt.new()

@onready var _facing_marker: Node2D = $FacingMarker


func _ready() -> void:
	for i: int in mini(start_tools.size(), ToolBelt.SLOT_COUNT):
		belt.set_tool(i, start_tools[i])


func _physics_process(_delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed
	if input != Vector2.ZERO:
		facing = _to_cardinal(input)
	move_and_slide()
	_facing_marker.position = facing * 6.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("rotate_stack"):
		get_viewport().set_input_as_handled()
		arms.rotate()
	elif event.is_action_pressed("select_slot_next"):
		get_viewport().set_input_as_handled()
		belt.select_next()
	elif event.is_action_pressed("select_slot_previous"):
		get_viewport().set_input_as_handled()
		belt.select_previous()
	else:
		for i: int in ToolBelt.SLOT_COUNT:
			if event.is_action_pressed("select_slot_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				belt.select(i)
				return


## Turns a movement vector into one of the four cardinal directions.
## For an exact diagonal, keeps the current facing if it's one of the two held directions.
func _to_cardinal(dir: Vector2) -> Vector2:
	if absf(dir.x) > absf(dir.y):
		return Vector2(signf(dir.x), 0.0)
	if absf(dir.y) > absf(dir.x):
		return Vector2(0.0, signf(dir.y))
	var keeps_x: bool = facing.x != 0.0 and signf(facing.x) == signf(dir.x)
	var keeps_y: bool = facing.y != 0.0 and signf(facing.y) == signf(dir.y)
	if keeps_x or keeps_y:
		return facing
	return Vector2(0.0, signf(dir.y))
