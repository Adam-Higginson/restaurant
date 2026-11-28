class_name RowingGreybox
extends Node3D
## The rowing test ground (#226): a rowboat on a dusk sea, for trying how
## rowing feels and how being swept away by the current feels. Open
## scenes/prototype/intro/rowing_greybox.tscn and press F6.
##
## Row with the stick or WASD. Look round with the mouse (click to capture it,
## Esc to free it) or the right stick; the camera eases back behind the boat.
## Press C to let the current take the boat over
## [member sweep_seconds]; press X to give it back.
##
## The sea's plane is kept centred under the boat, so you can row as far as
## you like.

## What the readout says: the keys, and how much the current has.
const HELP: String = "Row: stick or WASD.\nC: the current takes the boat (%ds). X: give it back." \
		+ "\nThe current has %d%% of the steering."

## The boat.
@export var boat: Rowboat
## The current that sweeps it away.
@export var current: SeaCurrent
## The sea.
@export var sea: Sea
## How long the current takes to take the boat over, in seconds.
@export var sweep_seconds: float = 15.0
## Shows how much the current has, and the keys. Optional.
@export var readout: Label


func _ready() -> void:
	if sea != null:
		# There's no ship here, so move the water's hull cut-out (and the foam
		# drawn round it) far off, where it can't mark the sea round the origin.
		var water: ShaderMaterial = sea.material_override as ShaderMaterial
		if water != null:
			var away: Transform3D = Transform3D(Basis(), Vector3(1.0e6, -1000.0, 1.0e6))
			water.set_shader_parameter("hull_inverse", Projection(away.affine_inverse()))


func _process(_delta: float) -> void:
	_centre_sea()
	if readout != null and current != null:
		readout.text = HELP % [int(sweep_seconds), roundi(current.takeover * 100.0)]


func _unhandled_input(event: InputEvent) -> void:
	# The mouse turns the camera only while it's captured: Esc frees it, and a
	# click captures it again (as in the main prototype's CameraRig).
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo or current == null:
		return
	if key.keycode == KEY_C:
		current.sweep(1.0, sweep_seconds)
	elif key.keycode == KEY_X:
		current.release()


# Keeps the sea's plane under the boat, in the sea's own grid steps so its
# waves never shimmer as it moves.
func _centre_sea() -> void:
	if sea == null or boat == null:
		return
	sea.global_position = Vector3(
		snappedf(boat.global_position.x, sea.grid_step),
		0.0,
		snappedf(boat.global_position.z, sea.grid_step),
	)
