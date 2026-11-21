class_name Player3D
extends CharacterBody3D
## The player in 3D. Walks relative to the camera, turns to face the way it
## walks, falls under gravity, and rides whatever floor it stands on, so the
## ship's deck carries it along as the ship sails.
##
## The body itself never rotates: only [code]Model[/code] turns to face the
## way you walk. The camera rig is a child of the body, so a turning body
## would swing the camera round with every step.

## Walking speed in metres per second.
@export var speed: float = 5.0
## How fast the model turns to face the way you walk, in degrees per second.
## Not used yet: see the TODO in [method _face].
@export var turn_speed: float = 720.0

## The flat direction the model faces, in world space.
var facing: Vector3:
	get:
		return -_model.global_basis.z

@onready var _model: Node3D = $Model
@onready var _camera_rig: CameraRig = $CameraRig


func _physics_process(delta: float) -> void:
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction: Vector3 = camera_relative(input, _camera_rig.yaw)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Moves and slides along walls. Standing on a moving body (the ship),
	# it also adds that body's velocity, which is how the deck carries us.
	move_and_slide()
	if not direction.is_zero_approx():
		_face(direction, delta)


## Turns stick or WASD [param input] (as from [method Input.get_vector]: x is
## right, y is down) into a flat world direction, for a camera turned
## [param yaw] radians about the up axis. Pushing up walks away from the camera.
static func camera_relative(input: Vector2, yaw: float) -> Vector3:
	return Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, yaw)


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
