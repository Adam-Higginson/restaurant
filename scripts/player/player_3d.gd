class_name Player3D
extends CharacterBody3D
## The player in 3D. Walks relative to the camera, turns to face the way it
## walks, falls under gravity, and rides whatever floor it stands on, so the
## ship's deck carries it along as the ship sails. Carries tools and items on
## its [member toolbar]; the selected item is what it holds.
##
## When the camera switches (walking into or out of a [CameraZone]) while you
## hold a direction, the player keeps walking the same way until you let go
## or change direction. Otherwise "up" would flip with the camera and walk
## you straight back where you came from.
##
## The body itself never rotates: only [code]Model[/code] turns to face the
## way you walk. The camera rig is a child of the body, so a turning body
## would swing the camera round with every step.

## Walking speed in metres per second.
@export var speed: float = 5.0
## How fast the model turns to face the way you walk, in degrees per second.
## Not used yet: see the TODO in [method _face].
@export var turn_speed: float = 720.0
## How far, in degrees, you must swing the stick while walking through a
## camera switch before "up" follows the new camera.
@export var reaim_degrees: float = 45.0
## The tools on the toolbar at the start, from the first slot on.
@export var start_tools: Array[HandTool] = []

## Whether the player walks when you push the stick. Off while asleep or in
## a cutscene: they stand still, but the deck still carries them as it sails.
var controls_enabled: bool = true

## The flat direction the model faces, in world space.
var facing: Vector3:
	get:
		return -_model.global_basis.z

## Whether the player walked on the last physics tick, from your input
## (riding the sailing ship doesn't count).
var is_walking: bool:
	get:
		return _walking

## The player's tools and items, with one slot selected. Created once and
## never replaced, so signal connections to it keep working.
var toolbar: Toolbar = Toolbar.new()
## The [member toolbar], seen as [Arms] by the cooking rules, the pantry and
## the plate rack: its "top" item is the selected one.
var arms: Arms:
	get:
		return toolbar

## The player's camera. Camera zones tell it when to use their fixed shot.
var camera_rig: CameraRig:
	get:
		return _camera_rig

var _walking: bool = false
## The camera yaw movement used last tick.
var _move_yaw: float = 0.0
## Whether movement is held to [member _held_yaw] after a camera switch.
var _holding: bool = false
var _held_yaw: float = 0.0
## The stick direction when the hold started.
var _held_input: Vector2 = Vector2.ZERO
## The camera zone in use when you last weren't walking through a switch.
var _zone_seen: CameraZone

@onready var _model: Node3D = $Model
@onready var _camera_rig: CameraRig = $CameraRig


func _ready() -> void:
	for i: int in mini(start_tools.size(), Toolbar.SLOT_COUNT):
		toolbar.set_tool(i, start_tools[i])


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	if controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = camera_relative(input, _movement_yaw(input))
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Moves and slides along walls. Standing on a moving body (the ship),
	# it also adds that body's velocity, which is how the deck carries us.
	move_and_slide()
	_walking = not direction.is_zero_approx()
	if _walking:
		_face(direction, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select_slot_next"):
		get_viewport().set_input_as_handled()
		toolbar.select_next()
	elif event.is_action_pressed("select_slot_previous"):
		get_viewport().set_input_as_handled()
		toolbar.select_previous()
	else:
		for i: int in Toolbar.SLOT_COUNT:
			if event.is_action_pressed("select_slot_%d" % (i + 1)):
				get_viewport().set_input_as_handled()
				toolbar.select(i)
				return


## Turns stick or WASD [param input] (as from [method Input.get_vector]: x is
## right, y is down) into a flat world direction, for a camera turned
## [param yaw] radians about the up axis. Pushing up walks away from the camera.
static func camera_relative(input: Vector2, yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)


# The camera yaw to walk by this tick. Usually the view's yaw, so in the
# galley's fixed shot up still walks away from the camera you look through.
# But if the camera switches while you hold a direction, keep walking by the
# yaw from before the switch until you let go or swing the stick away.
func _movement_yaw(input: Vector2) -> float:
	var zone: CameraZone = _camera_rig.active_zone
	if _holding and (input.is_zero_approx()
			or absf(input.angle_to(_held_input)) > deg_to_rad(reaim_degrees)):
		_holding = false
	if not _holding:
		if not input.is_zero_approx() and zone != _zone_seen:
			_holding = true
			_held_yaw = _move_yaw
			_held_input = input
		_zone_seen = zone
	_move_yaw = _held_yaw if _holding else _camera_rig.view_yaw
	return _move_yaw


# Turns the model to face [param direction], a flat world direction.
func _face(direction: Vector3, _delta: float) -> void:
	# The yaw that turns the model's forward (-Z) to point along direction.
	var target: float = atan2(-direction.x, -direction.z)
	# TODO(your turn): the model snaps to face the new way instantly. Make it
	# turn smoothly at turn_speed (degrees per second) instead.
	# Hints:
	# - rotate_toward(from, to, step) moves an angle towards another by at most
	#   step radians, going the short way round (it handles wrapping past 180°).
	# - One tick's step is deg_to_rad(turn_speed) * delta. Rename _delta to
	#   delta once you use it (the underscore marks an unused parameter).
	# - Check: walk in circles on deck. Try turn_speed 180 and 1440 to feel it.
	# - Test: test_faces_the_way_it_walks in tests/scripts/player/player_3d_test.gd.
	_model.rotation.y = target
