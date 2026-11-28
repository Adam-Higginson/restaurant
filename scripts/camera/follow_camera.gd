class_name FollowCamera
extends Camera3D
## A camera that follows behind something as it moves and turns, like a
## chase camera: it stays [member distance] behind and [member height] above,
## swinging round after it a little late so turns feel smooth. It never rolls
## or pitches with what it follows, so a boat rocking on the swell doesn't
## rock the picture.
##
## The player can look around it: the mouse (while it's captured) and the
## right stick orbit the camera about the point it looks at, by a yaw and a
## pitch kept apart from the chase (see [member look_yaw] and
## [member look_pitch]). A moment after the player stops looking, the look
## eases back to zero, so the camera ends up behind the target again, which
## is the way it is steered. The mouse wheel zooms between [member zoom_min]
## and [member zoom_max], keeping the same angle by scaling the height with
## the distance.

## How far the camera can tilt down, in degrees. Matches [CameraRig].
const PITCH_MIN_DEGREES: float = CameraRig.PITCH_MIN_DEGREES
## How far the camera can tilt up, in degrees. Matches [CameraRig].
const PITCH_MAX_DEGREES: float = CameraRig.PITCH_MAX_DEGREES
## The steepest the camera may look down from above, in radians, so it never
## looks straight down (where "up" on screen has no meaning).
const MAX_ELEVATION: float = 1.5

## What it follows.
@export var target: Node3D
## How far behind, in metres. The mouse wheel changes this.
@export var distance: float = 6.5
## How high above, in metres, at the starting [member distance]. It scales with
## the distance when zooming.
@export var height: float = 2.6
## How high above the target's origin it looks, in metres.
@export var look_height: float = 0.6
## How quickly it swings round after the target: higher keeps up sooner.
@export var follow_response: float = 2.5
## Degrees turned per pixel of mouse movement.
@export var mouse_sensitivity: float = 0.2
## Degrees per second turned with the right stick pushed all the way.
@export var stick_speed: float = 150.0
## Seconds after the last look input before the camera eases back behind.
@export var return_delay: float = 1.5
## How quickly the look eases back to behind the target: higher is snappier.
@export var return_response: float = 2.0
## The closest the camera zooms in, in metres.
@export var zoom_min: float = 3.0
## The furthest the camera zooms out, in metres.
@export var zoom_max: float = 14.0
## How far one notch of the mouse wheel zooms, in metres.
@export var zoom_step: float = 1.0
## How quickly the distance eases to a new zoom: higher is snappier.
@export var zoom_ease: float = 10.0

## How far the player has turned the camera round the target, in radians.
## Positive looks left, as in [CameraRig]. Zero is straight behind.
var look_yaw: float:
	get:
		return _look_yaw

## How far the player has tilted the camera, in radians. Positive looks up
## (the camera drops lower), negative looks down (it rises). Zero is the usual
## chase angle.
var look_pitch: float:
	get:
		return _look_pitch

var _yaw: float = 0.0
var _look_yaw: float = 0.0
var _look_pitch: float = 0.0
## Seconds since the player last looked around.
var _idle_seconds: float = 0.0
## The distance the zoom is easing to.
var _zoom_goal: float = 6.5
## Height per metre of distance, so zooming keeps the camera's angle.
var _height_ratio: float = 0.4


func _ready() -> void:
	# It places itself every rendered frame from where the target is drawn,
	# which is already smoothed between physics ticks. Smoothing it again
	# would make it lag a tick behind and jitter against the target.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_zoom_goal = clampf(distance, zoom_min, zoom_max)
	if distance > 0.0:
		_height_ratio = height / distance
	if target != null:
		_yaw = _yaw_of(target.global_basis)
		_place(1.0)


# On rendered frames, following where the target is drawn (it moves on
# physics ticks and is smoothed between them).
func _process(delta: float) -> void:
	if target == null:
		return
	_idle_seconds += delta
	var stick: Vector2 = Input.get_vector("camera_left", "camera_right", "camera_up",
			"camera_down")
	if not stick.is_zero_approx():
		# Right turns clockwise seen from above, which is a negative yaw.
		look(-stick.x * stick_speed * delta, -stick.y * stick_speed * delta)
	_ease_look_back(delta)
	# The same each frame however fast the game runs, because the step is
	# 1 - e^(-rate * delta).
	distance = lerpf(distance, _zoom_goal, 1.0 - exp(-zoom_ease * delta))
	_place(1.0 - exp(-follow_response * delta))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in"):
		_zoom_goal = clampf(_zoom_goal - zoom_step, zoom_min, zoom_max)
	elif event.is_action_pressed("zoom_out"):
		_zoom_goal = clampf(_zoom_goal + zoom_step, zoom_min, zoom_max)
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion: Vector2 = (event as InputEventMouseMotion).relative
		look(-motion.x * mouse_sensitivity, -motion.y * mouse_sensitivity)


## Turns the camera round the target by [param yaw_degrees] (positive turns
## the view left) and tilts it by [param pitch_degrees] (positive looks up),
## keeping the tilt within its limits. Any turn restarts the wait before the
## camera eases back behind the target.
func look(yaw_degrees: float, pitch_degrees: float) -> void:
	if is_zero_approx(yaw_degrees) and is_zero_approx(pitch_degrees):
		return
	_idle_seconds = 0.0
	_look_yaw = wrapf(_look_yaw + deg_to_rad(yaw_degrees), -PI, PI)
	_look_pitch = clampf(_look_pitch + deg_to_rad(pitch_degrees),
			deg_to_rad(PITCH_MIN_DEGREES), deg_to_rad(PITCH_MAX_DEGREES))


# Once the player has stopped looking for return_delay, eases the look back
# to zero. lerp_angle takes the short way round.
func _ease_look_back(delta: float) -> void:
	if _idle_seconds < return_delay:
		return
	var step: float = 1.0 - exp(-return_response * delta)
	_look_yaw = lerp_angle(_look_yaw, 0.0, step)
	_look_pitch = lerpf(_look_pitch, 0.0, step)


# Swings [param blend] of the way round to behind the target, and frames it.
func _place(blend: float) -> void:
	var at: Transform3D = target.get_global_transform_interpolated()
	_yaw = lerp_angle(_yaw, _yaw_of(at.basis), blend)
	var around: float = _yaw + _look_yaw
	var behind: Vector3 = Vector3(sin(around), 0.0, cos(around))
	var focus: Vector3 = at.origin + Vector3.UP * look_height
	# Orbit the focus: the usual chase puts the camera `rise` above it and
	# `distance` back, and looking up or down swings it along that circle.
	var rise: float = _height_ratio * distance - look_height
	var radius: float = Vector2(distance, rise).length()
	var elevation: float = minf(atan2(rise, distance) - _look_pitch, MAX_ELEVATION)
	global_position = focus + (behind * cos(elevation) + Vector3.UP * sin(elevation)) * radius
	look_at(focus, Vector3.UP)


# Which way [param basis] faces, as radians about Y (0 faces -Z), ignoring
# any pitch or roll.
func _yaw_of(basis_now: Basis) -> float:
	var forward: Vector3 = -basis_now.z
	return atan2(-forward.x, -forward.z)
