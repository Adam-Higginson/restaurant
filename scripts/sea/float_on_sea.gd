class_name FloatOnSea
extends Node
## Keeps its parent riding the waves: every frame the parent's height is set
## to the sea's surface where it is, plus [member height_above]. Add it as a
## child of anything that should bob (someone in the water) or stay clear of
## the swell (a camera shot at water level, which would otherwise dip under
## the crests, because the ship never rises and the sea does).
##
## Without a [Sea] in the scene the parent is left where it is.

## How far above the surface the parent sits, in metres. Negative is under.
## A clip can move this to lift something out of the water or sink it.
@export var height_above: float = 0.0

var _sea: Sea = null


func _ready() -> void:
	# Moved every drawn frame, so there's nothing to smooth between ticks.
	var floated: Node3D = get_parent() as Node3D
	if floated != null:
		floated.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(_delta: float) -> void:
	var floated: Node3D = get_parent() as Node3D
	if floated == null:
		return
	if not is_instance_valid(_sea):
		_sea = get_tree().get_first_node_in_group(&"sea") as Sea
		if _sea == null:
			return
	floated.global_position.y = surface_height(_sea, floated.global_position) + height_above


## How high the surface of [param sea] is at [param spot] in the world, as
## it's drawn: the sea's own level (it's lowered as the swell passes under
## the ship) plus the wave there.
static func surface_height(sea: Sea, spot: Vector3) -> float:
	return sea.global_position.y + sea.height_at(Vector2(spot.x, spot.z))
