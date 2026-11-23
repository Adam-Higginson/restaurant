class_name KnifeTrail
extends MeshInstance3D
## A pale ribbon left behind the knife as it swings, fading within a moment,
## so the arc of the cut reads even though the swing is quick.
##
## Each frame the knife is out, it remembers where the blade's [member heel]
## and [member tip] are, and draws a strip of triangles through the last few
## of those places, fading the older ones. The mesh is rebuilt every frame
## with an [ImmediateMesh], Godot's mesh for shapes that change constantly.
## It's [member Node3D.top_level], so it stays where the knife has been in the
## world rather than turning with the player.

## Where the blade meets the handle.
@export var heel: Node3D
## The blade's point.
@export var tip: Node3D
## How long a piece of the ribbon lasts, in seconds.
@export var fade_seconds: float = 0.12

## While true the knife leaves no ribbon, even when it's out: a cut at the
## chopping board is small and close, and a ribbon there would fill the
## screen. Set by the [Duellist].
var quiet: bool = false

## Each remembered place: the heel and tip in the world, and its age.
var _heels: PackedVector3Array = []
var _tips: PackedVector3Array = []
var _ages: PackedFloat32Array = []
var _mesh: ImmediateMesh = ImmediateMesh.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	global_transform = Transform3D.IDENTITY
	mesh = _mesh
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.vertex_color_use_as_albedo = true


func _process(delta: float) -> void:
	for i: int in _ages.size():
		_ages[i] += delta
	# Forget the places that have faded away (the oldest are first).
	while not _ages.is_empty() and _ages[0] >= fade_seconds:
		_heels.remove_at(0)
		_tips.remove_at(0)
		_ages.remove_at(0)
	if heel != null and tip != null and heel.is_visible_in_tree() and not quiet:
		_heels.append(heel.global_position)
		_tips.append(tip.global_position)
		_ages.append(0.0)
	_rebuild()


## How many places along the swing the ribbon passes through right now.
func length() -> int:
	return _ages.size()


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if _ages.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, _material)
	for i: int in _ages.size():
		var alpha: float = (1.0 - _ages[i] / fade_seconds) * 0.6
		_mesh.surface_set_color(Color(1.0, 0.97, 0.9, alpha))
		_mesh.surface_add_vertex(_heels[i])
		_mesh.surface_set_color(Color(1.0, 0.97, 0.9, alpha))
		_mesh.surface_add_vertex(_tips[i])
	_mesh.surface_end()
