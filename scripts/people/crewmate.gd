class_name Crewmate
extends StaticBody3D
## Somebody aboard you can talk to. Stand in front of them and Interact, and
## the conversation named in [member talk] begins; they turn to face you
## while you talk, and back to what they were doing after.
##
## Who they are is data: a [Person] for their name, and a dialogue script
## for what they say. Nothing about any one character lives here.

## The group every crewmate joins, so a cutscene can find them by name.
const GROUP: StringName = &"crew"

## Who this is: their name shows on the prompt and in the dialogue box.
@export var person: Person
## The conversation Interact starts: a file in [code]data/dialogue[/code].
@export var talk: StringName = &""
## How fast they turn to face you, in degrees a second.
@export var turn_speed: float = 240.0

## Their head, where their words come from: what they say in passing floats
## up beside it in a speech bubble (see [Speaker] and [Chatter]).
var head: Speaker:
	get:
		return _head

## The way the model is turning to face, as a turn about the up axis in the
## body's own space. 0 is the way they stand when left alone.
var _facing: float = 0.0

@onready var _model: Node3D = $Model
@onready var _reach: Interactable3D = $Reach
@onready var _head: Speaker = $Head


func _ready() -> void:
	add_to_group(GROUP)
	_reach.interacted.connect(start_talking)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()


func _process(delta: float) -> void:
	_model.rotation.y = rotate_toward(_model.rotation.y, _facing,
			deg_to_rad(turn_speed) * delta)


## What Interact would do, for the HUD: "Talk to Captain".
func prompt() -> String:
	if talk == &"" or person == null:
		return ""
	return "Talk to %s" % person.display_name


## Starts this crewmate's conversation with [param player]. Returns whether
## it started.
func start_talking(player: Player3D) -> bool:
	var conversation: Conversation = Conversation.find(self)
	if conversation == null or talk == &"":
		return false
	return conversation.begin(talk, player, self)


## Turns to face [param point], a place in the world.
func face_towards(point: Vector3) -> void:
	var away: Vector3 = to_local(point)
	if Vector2(away.x, away.z).length() < 0.01:
		return
	_facing = atan2(-away.x, -away.z)


## Turns back to how they stand when left alone.
func rest() -> void:
	_facing = 0.0


## Whether they're about. Away, they can't be seen, bumped into or talked
## to, as if they'd left the room: a cutscene uses this to bring someone in.
func set_present(present: bool) -> void:
	visible = present
	# A disabled body is also taken out of the physics world.
	process_mode = Node.PROCESS_MODE_INHERIT if present else Node.PROCESS_MODE_DISABLED


## Whether they're about (see [method set_present]).
func is_present() -> bool:
	return visible and process_mode != Node.PROCESS_MODE_DISABLED
