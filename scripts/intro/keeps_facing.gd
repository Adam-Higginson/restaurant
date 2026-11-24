class_name KeepsFacing
extends Node
## Keeps a node ([member turned]) turned to face another ([member target])
## about the up axis, whatever its clips do (#203): in the underwater rescue
## the lantern never takes his eyes off you, while he circles you, heaves,
## reaches and lets go. The clips still tip and rock him (his pitch and
## roll); only which way he faces is this node's.
##
## His front is his -Z, the way Godot faces. It turns him after the clips
## have moved him each frame ([member clips]' mixer_applied), so a clip
## can't turn him away again.

## The node kept facing: the lantern.
@export var turned: Node3D
## What it faces: you (a marker at your chest).
@export var target: Node3D
## The clips that move [member turned]. It faces after they've played each
## frame; without them, at the end of its own frame instead.
@export var clips: AnimationMixer:
	set(value):
		if clips != null and clips.mixer_applied.is_connected(face_now):
			clips.mixer_applied.disconnect(face_now)
		clips = value
		if clips != null:
			clips.mixer_applied.connect(face_now)
## Whether it keeps him facing. Off, the clips alone turn him.
@export var enabled: bool = true


func _ready() -> void:
	# After everything else this frame, as a fallback to the clips' signal.
	process_priority = 1000


func _process(_delta: float) -> void:
	face_now()


## The turn about the up axis, in [param turned]'s parent's space, that
## points its -Z at [param target]; or its turn now if they're one above
## the other.
static func yaw_towards(turned: Node3D, target: Node3D) -> float:
	var parent: Node3D = turned.get_parent() as Node3D
	var to_target: Vector3 = target.global_position - turned.global_position
	if parent != null:
		to_target = parent.global_basis.inverse() * to_target
	if Vector2(to_target.x, to_target.z).length() < 0.001:
		return turned.rotation.y
	return atan2(-to_target.x, -to_target.z)


## Turns [member turned] to face [member target] now.
func face_now() -> void:
	if not enabled or not is_instance_valid(turned) or not is_instance_valid(target):
		return
	turned.rotation.y = yaw_towards(turned, target)
