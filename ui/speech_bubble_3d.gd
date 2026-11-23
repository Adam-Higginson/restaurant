class_name SpeechBubble3D
extends Node3D
## A speech bubble with a place in the world: it floats beside a speaker's
## head, always turned to face the camera. Walk away and it gets smaller,
## though more gently than other things do, so it can still be read across a
## room. Up close it stops growing, so it never fills the screen. It's drawn
## over whatever is near it, so a low beam never cuts it in half.
##
## The bubble itself is a [SpeechBubble] drawn into a small off-screen
## picture (a [SubViewport]), which is shown on a flat panel in the world.

## How big one of the bubble's pixels is in the world, in metres.
const PIXEL_SIZE: float = 0.017
## The picture is drawn this many times finer than the bubble's pixels, so
## it stays crisp when you're near.
const DETAIL: int = 4
## Nearer than this, in metres, the bubble stops getting bigger on screen.
const NEAR: float = 3.0
## It starts to fade at the first distance, in metres, and is gone by the second.
const FADE_START: float = 9.0
const FADE_END: float = 13.0

## Bubbles are placed after anything with a lower process priority, such as
## the camera rig (0), so they line up with where the camera is this frame.
const PROCESS_PRIORITY: int = 100

## Seconds to fade in and out.
@export var fade_seconds: float = 0.25

## How visible the bubble is, 0 to 1, before distance fades it.
var shown: float = 0.0
## How much of the bubble can be seen past walls, 0 to 1: a [Speaker] lowers
## it when a wall is between you and whoever's speaking.
var sight: float = 1.0

## The words showing, or the last ones shown.
var text: String:
	get:
		return _face.text

var _anchor: Node3D = null
var _face: SpeechBubble = SpeechBubble.new()
var _viewport: SubViewport = SubViewport.new()
var _panel: MeshInstance3D = MeshInstance3D.new()
var _material: StandardMaterial3D = StandardMaterial3D.new()
var _tween: Tween = null


func _init() -> void:
	top_level = true
	# Placed afresh every frame, so it mustn't be smoothed between physics
	# ticks as well: that drags it behind and makes it shake.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	process_priority = PROCESS_PRIORITY
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.size_2d_override_stretch = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.add_child(_face)
	add_child(_viewport)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.disable_fog = true
	_material.no_depth_test = true
	_material.albedo_color = Color(1, 1, 1, 0)
	_material.render_priority = 2
	_panel.mesh = QuadMesh.new()
	_panel.material_override = _material
	_panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_panel)


func _ready() -> void:
	_material.albedo_texture = _viewport.get_texture()


func _process(_delta: float) -> void:
	_follow()


## Shows [param words] beside [param anchor] (a marker at a speaker's head)
## in [param style], fading in.
func say(words: String, anchor: Node3D,
		style: SpeechBubble.Style = SpeechBubble.Style.SPEECH) -> void:
	_anchor = anchor
	_face.show_words(words, style)
	refit()
	_follow()
	_fade_to(1.0)


## Swaps the bubble's face for another kind of bubble: a [CookBubble] over
## a pan. Before it's shown.
func use_face(face: SpeechBubble) -> void:
	_viewport.remove_child(_face)
	_face.queue_free()
	_face = face
	_viewport.add_child(_face)


## The bubble's face, to change what it shows (then [method refit]).
func face() -> SpeechBubble:
	return _face


## Shows the face as it is now beside [param anchor], fading in.
func show_beside(anchor: Node3D) -> void:
	_anchor = anchor
	refit()
	_follow()
	_fade_to(1.0)


## Resizes the picture to the face, after the face has changed size.
func refit() -> void:
	_viewport.size_2d_override = Vector2i(_face.size)
	_viewport.size = Vector2i(_face.size) * DETAIL


## Fades the bubble away.
func hush() -> void:
	_fade_to(0.0)


## How much bigger or smaller than its true size the bubble is drawn when the
## camera is [param distance] metres away. Nearer than [constant NEAR] it
## shrinks in step with the distance, so it looks the same size on screen.
## Further away it grows a little, so it shrinks on screen only half as fast
## as everything else.
static func scale_at(distance: float) -> float:
	var ratio: float = maxf(distance, 0.0) / NEAR
	return ratio if ratio < 1.0 else sqrt(ratio)


## How much distance fades the bubble at [param distance] metres, 1 to 0.
static func fade_at(distance: float) -> float:
	return 1.0 - smoothstep(FADE_START, FADE_END, distance)


# Sits beside the anchor, where it's drawn this frame, turned to the camera,
# with the tail's tip at the anchor.
func _follow() -> void:
	if not is_instance_valid(_anchor) or not is_inside_tree():
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var tip: Vector3 = _anchor.get_global_transform_interpolated().origin
	var distance: float = camera.global_position.distance_to(tip)
	var unit: float = PIXEL_SIZE * scale_at(distance)
	var wide: float = _face.size.x * unit
	var tall: float = _face.size.y * unit
	var view: Basis = camera.global_basis
	var centre: Vector3 = tip + view.x * (wide / 2.0 - SpeechBubble.TAIL_X * unit) \
			+ view.y * (tall / 2.0)
	_panel.global_transform = Transform3D(view.scaled_local(Vector3(wide, tall, 1.0)), centre)
	_material.albedo_color.a = shown * sight * fade_at(distance)


func _fade_to(alpha: float) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "shown", alpha, fade_seconds)
