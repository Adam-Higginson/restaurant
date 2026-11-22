class_name UnderwaterLens
extends MeshInstance3D
## What being under water does to the picture in the underwater set: far
## things lose their colour to the sea, and the water near the lantern
## shimmers with his heat (drawn by shaders/underwater_lens.gdshader on a
## sheet covering the screen). This works out, every frame, where the
## lantern is on screen and tells the shader.
##
## Put it under the set's [Camera3D].

## What's hot: the lantern. Optional: without one nothing shimmers.
@export var heat_source: Node3D
## How strongly the water near him shimmers: 0 not at all.
@export_range(0.0, 2.0) var heat: float = 1.0
## How far the shimmer spreads from him, in metres.
@export var heat_metres: float = 1.3
## The whole picture's brightness: above 1 for a moment of glare. A clip
## moves it.
@export_range(0.0, 4.0) var exposure: float = 1.0:
	set(value):
		exposure = value
		if _material != null:
			_material.set_shader_parameter("exposure", exposure)

var _material: ShaderMaterial = null


func _ready() -> void:
	_material = material_override as ShaderMaterial
	if _material != null:
		_material.set_shader_parameter("exposure", exposure)


func _process(_delta: float) -> void:
	var camera: Camera3D = get_parent() as Camera3D
	if _material == null or camera == null:
		return
	if not is_instance_valid(heat_source):
		_material.set_shader_parameter("heat", 0.0)
		return
	var size: Vector2 = Vector2(get_viewport().get_visible_rect().size)
	var seen: Vector3 = spot_on_screen(camera, heat_source.global_position, size)
	_material.set_shader_parameter("heat_spot", Vector2(seen.x, seen.y))
	_material.set_shader_parameter("heat_reach", reach_on_screen(camera, seen.z))
	_material.set_shader_parameter("heat", heat if seen.z > 0.0 else 0.0)


## Where [param place] is on a screen of [param size] pixels as
## [param camera] sees it: x and y from 0 to 1 across and down, and z how
## far in front of the camera it is in metres (negative: behind it).
static func spot_on_screen(camera: Camera3D, place: Vector3, size: Vector2) -> Vector3:
	var ahead: float = -(camera.global_transform.affine_inverse() * place).z
	if ahead <= 0.0 or size.x <= 0.0 or size.y <= 0.0:
		return Vector3(0.5, 0.5, ahead)
	var pixel: Vector2 = camera.unproject_position(place)
	return Vector3(pixel.x / size.x, pixel.y / size.y, ahead)


## How wide the shimmer is on screen, as a share of the screen's height,
## for a lantern [param ahead] metres in front of [param camera]: the
## nearer he is, the more of the screen it covers.
func reach_on_screen(camera: Camera3D, ahead: float) -> float:
	if ahead <= 0.0:
		return 0.0
	var screen_metres: float = 2.0 * ahead * tan(deg_to_rad(camera.fov) * 0.5)
	return clampf(heat_metres / screen_metres, 0.0, 1.0)
