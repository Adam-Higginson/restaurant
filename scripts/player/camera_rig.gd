class_name CameraRig
extends Node3D
## A free third-person camera that orbits its parent (the player). Turn it
## with the mouse or the right stick. Its [SpringArm3D] pulls the camera in
## when something (a wall, the mast) is between the camera and the player.
##
## The rig turns left and right ([member yaw]) and its [code]Pitch[/code]
## child tilts up and down ([member pitch]), so the two never mix. The mouse
## wheel zooms in and out ([member zoom]), easing the arm to the new length.
##
## Inside a [CameraZone] (the galley), the camera glides to the zone's fixed
## shot instead, and glides back when the player leaves. A cutscene can ask
## for a shot of its own with [method hold_shot], which wins over any zone
## until [method release_shot]. The spring arm only
## moves a [code]FreeSpot[/code] marker, where the free camera would be; the
## rig places the real [Camera3D] somewhere between that spot and the shot.
##
## The rig is [member Node3D.top_level] with physics interpolation off. Every
## rendered frame it moves to where the player is [i]drawn[/i] and applies
## turns straight away, so the camera follows smoothly and looking around
## never waits for a physics tick. It also turns with the floor the player
## stands on, so a turning ship doesn't swing the view round.

## How far the camera can tilt down, in degrees.
const PITCH_MIN_DEGREES: float = -70.0
## How far the camera can tilt up, in degrees.
const PITCH_MAX_DEGREES: float = 15.0

## Degrees turned per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.2
## Degrees per second turned with the right stick pushed all the way.
@export var stick_speed: float = 150.0
## How high above the player's feet the camera orbits, in metres.
@export var height: float = 1.5
## Seconds to glide between the free camera and a zone's fixed shot.
@export var blend_seconds: float = 0.6
## The closest the free camera zooms in, in metres from the player.
@export var zoom_min: float = 2.5
## The furthest the free camera zooms out, in metres from the player.
@export var zoom_max: float = 9.0
## How far one notch of the mouse wheel zooms, in metres.
@export var zoom_step: float = 0.75
## How quickly the arm eases to a new zoom: higher is snappier.
@export var zoom_ease: float = 10.0

## Left/right turn in radians. 0 looks along -Z (Godot's forward).
var yaw: float:
	get:
		return rotation.y
	set(value):
		rotation.y = wrapf(value, -PI, PI)

## Up/down tilt in radians, clamped to the pitch limits. Negative looks down.
var pitch: float:
	get:
		return _pitch.rotation.x
	set(value):
		_pitch.rotation.x = clampf(value, deg_to_rad(PITCH_MIN_DEGREES),
				deg_to_rad(PITCH_MAX_DEGREES))

## The zone whose fixed shot the camera is using, or null on the free camera.
var active_zone: CameraZone:
	get:
		_forget_freed_zones()
		if _zones.is_empty():
			return null
		return _zones[_zones.size() - 1]

## How far the camera has glided from the free camera (0) to the fixed
## shot (1). Goes up while in a zone and back down after leaving.
var blend: float:
	get:
		return _blend

## The yaw of the view you actually see, in radians: the free [member yaw]
## outside zones, the shot's yaw inside one, and in between while gliding.
## Movement follows this, so "up" always walks away from the camera.
var view_yaw: float:
	get:
		var shot: Marker3D = _current_shot()
		if shot == null:
			return yaw
		return lerp_angle(yaw, yaw_of(shot.global_basis), blend_curve(_blend))

## How far the free camera wants to be from the player, in metres, within
## [member zoom_min] and [member zoom_max]. The arm eases towards it.
var zoom: float = 5.0:
	set(value):
		zoom = clampf(value, zoom_min, zoom_max)

## Whether the camera is on a fixed shot (a zone's, or one being held), so
## it can't be turned.
var is_fixed: bool:
	get:
		return is_instance_valid(_held) or active_zone != null

## Zones the player is inside, in the order they entered. The last one wins.
var _zones: Array[CameraZone] = []
## A shot asked for by a cutscene, or null.
var _held: Marker3D = null
## The shot being glided to, or back from after leaving its zone.
var _last_shot: Marker3D
var _blend: float = 0.0

@onready var _target: Node3D = get_parent() as Node3D
@onready var _pitch: Node3D = $Pitch
@onready var _arm: SpringArm3D = $Pitch/SpringArm3D
@onready var _free_spot: Marker3D = $Pitch/SpringArm3D/FreeSpot
@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	# The spring arm needs no exclusion for the player: its cast starts inside
	# the player's capsule and points away from it, and a cast ignores
	# anything it starts inside.
	zoom = _arm.spring_length
	_follow_target()
	_place_camera()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	# Fixed shots are framed by hand, so the camera can't be turned in them.
	if not is_fixed:
		var stick: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up",
				"camera_down")
		# Right turns clockwise seen from above, which is a negative yaw.
		orbit(-stick.x * stick_speed * delta, -stick.y * stick_speed * delta)
	_turn_with_platform(delta)
	# Ease towards the chosen zoom; the same each frame however fast the game
	# runs, because the step is 1 - e^(-ease * delta).
	_arm.spring_length = lerpf(_arm.spring_length, zoom, 1.0 - exp(-zoom_ease * delta))
	_follow_target()
	_update_blend(delta)
	_place_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		zoom -= zoom_step
	elif event.is_action_pressed("zoom_out"):
		zoom += zoom_step
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED \
			and not is_fixed:
		var motion: Vector2 = (event as InputEventMouseMotion).relative
		orbit(-motion.x * mouse_sensitivity, -motion.y * mouse_sensitivity)


## Turns the camera by [param yaw_degrees] (positive turns left) and tilts it by
## [param pitch_degrees] (positive looks up), keeping the tilt within its limits.
func orbit(yaw_degrees: float, pitch_degrees: float) -> void:
	yaw += deg_to_rad(yaw_degrees)
	pitch += deg_to_rad(pitch_degrees)


## Starts gliding to [param zone]'s fixed shot. Called by the zone when the
## player walks in.
func enter_zone(zone: CameraZone) -> void:
	_zones.erase(zone)
	_zones.append(zone)
	_last_shot = zone.shot


## Glides back to the previous zone's shot, or to the free camera if there
## isn't one. Called by the zone when the player walks out.
func leave_zone(zone: CameraZone) -> void:
	_zones.erase(zone)
	var still_in: CameraZone = active_zone
	if still_in != null:
		_last_shot = still_in.shot


## Glides to [param shot] and stays there, whatever zone the player is in,
## until [method release_shot]. From the free camera it glides; from another
## shot it cuts, as a film would.
func hold_shot(shot: Marker3D) -> void:
	_held = shot
	_last_shot = shot


## Lets go of a held shot: the camera glides back to the free camera, or to
## the shot of the zone the player is standing in.
func release_shot() -> void:
	if _held == null:
		return
	_held = null
	var still_in: CameraZone = active_zone
	if still_in != null:
		_last_shot = still_in.shot


## The yaw of something rotated by [param rotation_basis] (a camera or
## marker), looking along its -Z: the turn about the up axis that points
## Godot's forward the same way, ignoring any tilt.
static func yaw_of(rotation_basis: Basis) -> float:
	var forward: Vector3 = -rotation_basis.z
	# Looking straight down, forward has no flat part: use the top of the
	# view instead, which points the way "up" on screen does.
	if Vector2(forward.x, forward.z).is_zero_approx():
		forward = rotation_basis.y
	return atan2(-forward.x, -forward.z)


## Shapes the glide: [param t] runs steadily from 0 to 1 over
## [member blend_seconds], and this says how far along the camera is at each
## point. It must give 0 at the start and 1 at the end.
static func blend_curve(t: float) -> float:
	# Slow at both ends and quicker between, so it neither lurches off nor
	# stops dead.
	return smoothstep(0.0, 1.0, t)


# Moves the rig above where the player is drawn this frame. With physics
# interpolation on, that's part-way between the player's last two physics
# positions, so the camera glides instead of stepping 60 times a second.
# Turns with whatever the player stands on (the ship as it sails its loop),
# so the view stays put relative to the deck instead of slowly swinging round.
func _turn_with_platform(delta: float) -> void:
	var body: CharacterBody3D = _target as CharacterBody3D
	if body == null or not body.is_on_floor():
		return
	yaw += body.get_platform_angular_velocity().y * delta


func _follow_target() -> void:
	if _target == null:
		return
	global_position = _target.get_global_transform_interpolated().origin + Vector3.UP * height


func _update_blend(delta: float) -> void:
	var goal: float = 1.0 if is_fixed else 0.0
	if blend_seconds <= 0.0:
		_blend = goal
	else:
		# move_toward never overshoots, and if the player turns back half way
		# the glide simply reverses from where it had got to.
		_blend = move_toward(_blend, goal, delta / blend_seconds)


# Puts the camera between the free spot and the current shot, by the blend.
func _place_camera() -> void:
	var free: Transform3D = _free_spot.global_transform
	var shot: Marker3D = _current_shot()
	if shot == null:
		_camera.global_transform = free
		return
	# The shot rides the ship, so read where it's drawn this frame.
	var fixed: Transform3D = shot.get_global_transform_interpolated()
	_camera.global_transform = free.interpolate_with(fixed, blend_curve(_blend))


# The shot being used or glided back from, or null on the free camera.
func _current_shot() -> Marker3D:
	if _blend <= 0.0 and not is_fixed:
		return null
	if not is_instance_valid(_last_shot):
		return null
	return _last_shot


# Drops zones that were freed without the player walking out (a scene change).
func _forget_freed_zones() -> void:
	for i: int in range(_zones.size() - 1, -1, -1):
		if not is_instance_valid(_zones[i]):
			_zones.remove_at(i)
