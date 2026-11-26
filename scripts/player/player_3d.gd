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

## Emitted as a dodge (a sidehop, backflip or roll) starts.
signal dodged(move: DodgeMove)

## The group the player is in, so others can find them.
const GROUP: StringName = &"player"

## Moving speed in metres per second: a gentle jog, the same aboard and
## ashore. A half-pushed stick goes at half of it.
@export var speed: float = 3.5
## How many times faster you go while holding sprint (Shift, or clicking the
## left stick in).
@export var sprint_factor: float = 1.6
## How fast the model turns to face the way you walk, in degrees per second.
## Not used yet: the model turns at once.
@export var turn_speed: float = 720.0
## How far, in degrees, you must swing the stick while walking through a
## camera switch before "up" follows the new camera.
@export var reaim_degrees: float = 45.0
## How fast a knock back dies away, in metres per second, per second.
@export var knockback_fade: float = 20.0
## The tools on the toolbar at the start, from the first slot on.
@export var start_tools: Array[HandTool] = []
## The items on the toolbar at the start, after the tools: the frying pan
## you cook with and parry with.
@export var start_items: Array[Item] = []

## Whether the player walks when you push the stick. Off while asleep or in
## a cutscene: they stand still, but the deck still carries them as it sails.
var controls_enabled: bool = true

## The flat direction the model faces, in world space.
var facing: Vector3:
	get:
		return -_model.global_basis.z

## How much of their speed the player walks at: 1 normally, less while
## something slows them (charging the knife). Set by whatever slows them.
var stride_factor: float = 1.0

## How fast the player moves when they walk, in metres per second: their
## [member speed], or faster while sprinting, times the [member stride_factor].
var move_speed: float:
	get:
		return (speed * sprint_factor if is_sprinting() else speed) * stride_factor

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

## What the player is locked on to, or null. While it's set the model keeps
## facing it, so walking sideways circles it. Set by [LockOn].
var lock_target: Node3D = null

## The player's camera. Camera zones tell it when to use their fixed shot.
var camera_rig: CameraRig:
	get:
		return _camera_rig

## The dodge being made, or null.
var dodge_move: DodgeMove:
	get:
		return _dodge if is_dodging() else null

var _walking: bool = false
## The flat velocity a blow threw the player back with, dying away.
var _push: Vector3 = Vector3.ZERO
## Seconds left of stumbling after a blow, while the stick is ignored.
var _stumble_left: float = 0.0
## The dodge being made, the flat direction it goes in, and its seconds left.
var _dodge: DodgeMove = null
var _dodge_direction: Vector3 = Vector3.ZERO
var _dodge_left: float = 0.0
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


## Progress through the water dip, 0 to 1, or -1 outside the interaction.
var fill_progress: float = -1.0


func _ready() -> void:
	add_to_group(GROUP)
	for i: int in mini(start_tools.size(), Toolbar.SLOT_COUNT):
		toolbar.set_tool(i, start_tools[i])
	for item: Item in start_items:
		toolbar.add(ItemInstance.new(item))
	toolbar.select(0)
	# Tools you've found are kept as flags, so they come back with a saved
	# voyage (restored after we're ready) and arrive the moment one is set.
	give_owned_tools()
	Game.dialogue.flag_changed.connect(_on_flag_changed)


func _physics_process(delta: float) -> void:
	var input: Vector2 = Vector2.ZERO
	_stumble_left = maxf(_stumble_left - delta, 0.0)
	_dodge_left = maxf(_dodge_left - delta, 0.0)
	if controls_enabled and not is_stumbling() and not is_dodging():
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = camera_relative(input, _movement_yaw(input))
	velocity.x = direction.x * move_speed + _push.x
	velocity.z = direction.z * move_speed + _push.z
	if is_dodging():
		# Mid-dodge the stick does nothing: the dodge carries them.
		velocity.x = _dodge_direction.x * _dodge.speed
		velocity.z = _dodge_direction.z * _dodge.speed
	_push = _push.move_toward(Vector3.ZERO, knockback_fade * delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Moves and slides along walls. Standing on a moving body (the ship),
	# it also adds that body's velocity, which is how the deck carries us.
	move_and_slide()
	_walking = not direction.is_zero_approx()
	if is_instance_valid(lock_target):
		face_towards(lock_target.global_position)
	elif is_dodging():
		_face(_dodge_direction, delta)
	elif _walking:
		_face(direction, delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal") and controls_enabled \
			and Game.dialogue.is_set(RecipeBook.OWNED_FLAG):
		get_viewport().set_input_as_handled()
		RecipeBook.open_journal(self)
	elif event.is_action_pressed("select_slot_next"):
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


## Puts every tool and item the voyage owns on the toolbar, if it isn't there
## already: a tool or item is owned when its conversation flag
## [code]has_<id>[/code] is set (see [member HandTool.owned_flag]), which a
## chest or a gift sets. The selected slot doesn't change. Called as the
## player arrives (a saved voyage's flags are back by then).
func give_owned_tools() -> void:
	for tool: HandTool in Catalog.load_default().tools:
		_give(tool.owned_flag)
	for item: Item in Catalog.load_default().items:
		_give(StringName("has_%s" % item.id))


## Throws the player along [param push], a flat velocity in metres per second
## that dies away (see [member knockback_fade]), and has them stumble, deaf to
## the stick, for [param stumble_seconds]. A zero push stops any knock back.
func knock_back(push: Vector3, stumble_seconds: float) -> void:
	_push = Vector3(push.x, 0.0, push.z)
	_stumble_left = stumble_seconds
	# Knocked out of any dodge.
	_dodge_left = 0.0


## Sends the player along [param push], a flat velocity in metres per second
## that dies away like a knock back, without taking the stick from them: a
## step into a cut.
func lunge(push: Vector3) -> void:
	_push = Vector3(push.x, 0.0, push.z)


## Makes [param move] (a sidehop, backflip or roll) along [param direction],
## a flat world direction. Returns whether it started: not mid-air, mid-dodge,
## stumbling, or while they can't act.
func dodge(move: DodgeMove, direction: Vector3) -> bool:
	if not can_dodge() or move == null:
		return false
	var flat: Vector3 = Vector3(direction.x, 0.0, direction.z)
	if flat.length() < 0.01:
		return false
	_dodge = move
	_dodge_direction = flat.normalized()
	_dodge_left = move.seconds
	_push = Vector3.ZERO
	velocity.y = move.hop
	dodged.emit(move)
	return true


## Whether the player could dodge right now: free to act, on the ground,
## and not already dodging or stumbling.
func can_dodge() -> bool:
	return controls_enabled and is_on_floor() and not is_dodging() and not is_stumbling()


## Whether the player is mid-dodge.
func is_dodging() -> bool:
	return _dodge_left > 0.0


## How far through the dodge being made they are, from 0 to 1 (0 with none).
func dodge_progress() -> float:
	if not is_dodging():
		return 0.0
	return clampf(1.0 - _dodge_left / maxf(_dodge.seconds, 0.001), 0.0, 1.0)


## Where the stick (or WASD) points right now, as a flat world direction
## relative to the camera, as long as the stick is pushed; zero otherwise.
func stick_direction() -> Vector3:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	return camera_relative(input, _camera_rig.view_yaw)


## Whether the player is sprinting: holding sprint while they can move.
func is_sprinting() -> bool:
	return controls_enabled and not is_stumbling() and Input.is_action_pressed("sprint")


## Whether the player is stumbling after a blow, so the stick does nothing.
func is_stumbling() -> bool:
	return _stumble_left > 0.0


## Turns the model to face [param point], a place in the world, at once
## (to face whoever you're talking to).
func face_towards(point: Vector3) -> void:
	var away: Vector3 = point - global_position
	away.y = 0.0
	if away.length() < 0.01:
		return
	_model.global_rotation.y = atan2(-away.x, -away.z)


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


# Turns the model to face [param direction], a flat world direction, at
# once. (Turning smoothly at turn_speed is still to do.)
func _face(direction: Vector3, _delta: float) -> void:
	# The yaw that turns the model's forward (-Z) to point along direction.
	_model.rotation.y = atan2(-direction.x, -direction.z)


# Gives the tool or item that the flag [param flag] ([code]has_<id>[/code])
# says you own, if it's set and you haven't got it on the toolbar.
func _give(flag: StringName) -> void:
	if flag == RecipeBook.OWNED_FLAG or not Game.dialogue.is_set(flag) \
			or not String(flag).begins_with("has_"):
		return
	var id: StringName = StringName(String(flag).trim_prefix("has_"))
	var catalog: Catalog = Catalog.load_default()
	var selected: int = toolbar.selected_index
	var tool: HandTool = catalog.find_tool(id)
	var item: Item = catalog.find_item(id)
	if tool != null:
		toolbar.add_tool(tool)
	elif item != null and not toolbar.has_item(id):
		toolbar.add(ItemInstance.new(item))
	toolbar.select(selected)


# Just this flag's: a pan you've already put down on the hob isn't handed to
# you again because some other flag was set.
func _on_flag_changed(flag: StringName, value: int) -> void:
	if value > 0:
		_give(flag)
