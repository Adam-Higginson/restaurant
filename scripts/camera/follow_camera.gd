class_name FollowCamera
extends Camera3D
## A camera that follows behind something as it moves and turns, like a
## chase camera: it stays [member distance] behind and [member height] above,
## swinging round after it a little late so turns feel smooth. It never rolls
## or pitches with what it follows, so a boat rocking on the swell doesn't
## rock the picture.

## What it follows.
@export var target: Node3D
## How far behind, in metres.
@export var distance: float = 6.5
## How high above, in metres.
@export var height: float = 2.6
## How high above the target's origin it looks, in metres.
@export var look_height: float = 0.6
## How quickly it swings round after the target: higher keeps up sooner.
@export var follow_response: float = 2.5

var _yaw: float = 0.0


func _ready() -> void:
	# It places itself every rendered frame from where the target is drawn,
	# which is already smoothed between physics ticks. Smoothing it again
	# would make it lag a tick behind and jitter against the target.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if target != null:
		_yaw = _yaw_of(target.global_basis)
		_place(1.0)


# On rendered frames, following where the target is drawn (it moves on
# physics ticks and is smoothed between them).
func _process(delta: float) -> void:
	if target == null:
		return
	_place(1.0 - exp(-follow_response * delta))


# Swings [param blend] of the way round to behind the target, and frames it.
func _place(blend: float) -> void:
	var at: Transform3D = target.get_global_transform_interpolated()
	_yaw = lerp_angle(_yaw, _yaw_of(at.basis), blend)
	var behind: Vector3 = Vector3(sin(_yaw), 0.0, cos(_yaw))
	var focus: Vector3 = at.origin + Vector3.UP * look_height
	global_position = at.origin + behind * distance + Vector3.UP * height
	look_at(focus, Vector3.UP)


# Which way [param basis] faces, as radians about Y (0 faces -Z), ignoring
# any pitch or roll.
func _yaw_of(basis_now: Basis) -> float:
	var forward: Vector3 = -basis_now.z
	return atan2(-forward.x, -forward.z)
