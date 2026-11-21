class_name CameraRig
extends Node3D
## A free third-person camera that orbits its parent (the player). Turn it
## with the mouse or the right stick. Its [SpringArm3D] pulls the camera in
## when something (a wall, the mast) is between the camera and the player.
##
## The rig turns left and right ([member yaw]) and its [code]Pitch[/code]
## child tilts up and down ([member pitch]), so the two never mix.
##
## The rig is [member Node3D.top_level] with physics interpolation off. Every
## rendered frame it moves to where the player is [i]drawn[/i] and applies
## turns straight away, so the camera follows smoothly and looking around
## never waits for a physics tick.

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

@onready var _target: Node3D = get_parent() as Node3D
@onready var _pitch: Node3D = $Pitch


func _ready() -> void:
	# The spring arm needs no exclusion for the player: its cast starts inside
	# the player's capsule and points away from it, and a cast ignores
	# anything it starts inside.
	_follow_target()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	var stick: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up",
			"camera_down")
	# Right turns clockwise seen from above, which is a negative yaw.
	orbit(-stick.x * stick_speed * delta, -stick.y * stick_speed * delta)
	_follow_target()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: Vector2 = (event as InputEventMouseMotion).relative
		orbit(-motion.x * mouse_sensitivity, -motion.y * mouse_sensitivity)


## Turns the camera by [param yaw_degrees] (positive turns left) and tilts it by
## [param pitch_degrees] (positive looks up), keeping the tilt within its limits.
func orbit(yaw_degrees: float, pitch_degrees: float) -> void:
	yaw += deg_to_rad(yaw_degrees)
	pitch += deg_to_rad(pitch_degrees)


# Moves the rig above where the player is drawn this frame. With physics
# interpolation on, that's part-way between the player's last two physics
# positions, so the camera glides instead of stepping 60 times a second.
func _follow_target() -> void:
	if _target == null:
		return
	global_position = _target.get_global_transform_interpolated().origin + Vector3.UP * height
