class_name FlameHand
extends MeshInstance3D
## The hand the lantern spirit offers you: fire poured into the shape of an
## arm and a hand (shaders/flame_hand.gdshader), drawn on a flat sheet that
## runs from his door out to the fingertips. A clip moves three things:
## how far it reaches ([member reach]), how well it holds the shape of a
## hand ([member form]), and how far it has closed round yours
## ([member grip]). Its colour follows how strong he is, and it carries a
## small light of its own in its palm, so your hand glows as it gets close.
## When it closes round yours, shafts of light fan out from between the two
## hands ([member rays], drawn by shaders/light_rays.gdshader).

## How far along the sheet from the wrist the palm sits at full reach and
## at none, in sheet heights (the shader draws the hand in those, so it
## keeps its shape however long the sheet is). The same numbers as in the
## shader.
const PALM_AT_FULL_REACH: float = 1.12
const PALM_AT_NO_REACH: float = 0.08

## How far the arm reaches: 0 nothing (the hand's not there), 1 all the way.
@export_range(0.0, 1.0) var reach: float = 0.0:
	set(value):
		reach = clampf(value, 0.0, 1.0)
		_apply()
## How well it holds the shape of a hand: 0 a shapeless wisp, 1 a hand.
@export_range(0.0, 1.0) var form: float = 1.0:
	set(value):
		form = clampf(value, 0.0, 1.0)
		_apply()
## How far the fingers have closed: 0 an open hand, 1 closed round yours.
@export_range(0.0, 1.0) var grip: float = 0.0:
	set(value):
		grip = clampf(value, 0.0, 1.0)
		_apply()
## How strong he is, 0 to 1, when there's no [member face] to ask.
@export_range(0.0, 1.0) var strength: float = 1.0:
	set(value):
		strength = clampf(value, 0.0, 1.0)
		_apply()
## Whose hand it is. Optional: with one, the hand is as strong as he is.
@export var face: LanternFace
## The light in its palm. Optional.
@export var light: OmniLight3D
## How bright [member light] is with the hand fully out, formed and strong.
@export var light_energy: float = 1.2
## The shafts of light between the joined hands: a sheet beside the hand.
## Optional.
@export var rays: MeshInstance3D
## How bright [member rays] are with the hand closed and him at his strongest.
@export var rays_brightness: float = 1.4

var _material: ShaderMaterial = null


func _ready() -> void:
	# Its own copy, so one hand never changes another.
	_material = (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material_override = _material
	_apply()


func _process(_delta: float) -> void:
	if is_instance_valid(face) and not is_equal_approx(face.strength, strength):
		strength = face.strength


## Where the palm is, in this node's own space: part-way along the sheet,
## further the further it reaches. The sheet runs along -X from the wrist.
func palm_position() -> Vector3:
	var quad: QuadMesh = mesh as QuadMesh
	var height: float = quad.size.y if quad != null else 1.0
	return Vector3(-height * lerpf(PALM_AT_NO_REACH, PALM_AT_FULL_REACH, reach), 0.0, 0.0)


## How brightly the palm's light shines right now: nothing with no reach,
## less while it's a wisp, less as he weakens.
func glow_now() -> float:
	return light_energy * reach * lerpf(0.4, 1.0, form) * lerpf(0.25, 1.0, strength)


## How bright the shafts between the hands are right now: nothing until
## the hand closes on yours, faint while he's weak, and strong once he's
## alight again.
func rays_now() -> float:
	return rays_brightness * reach * grip * lerpf(0.1, 1.0, strength)


func _apply() -> void:
	if _material == null:
		return
	visible = reach > 0.001
	# The sheet's shape, so the hand is drawn in proportion on it, its
	# fingertips inside its far end (#203).
	var quad: QuadMesh = mesh as QuadMesh
	if quad != null and quad.size.y > 0.0:
		_material.set_shader_parameter("aspect", quad.size.x / quad.size.y)
	_material.set_shader_parameter("reach", reach)
	_material.set_shader_parameter("form", form)
	_material.set_shader_parameter("grip", grip)
	_material.set_shader_parameter("strength", strength)
	if is_instance_valid(light):
		light.position = position + basis * palm_position()
		light.light_color = LanternFace.colour_for(strength)
		light.light_energy = glow_now()
	if is_instance_valid(rays):
		rays.position = position + basis * palm_position()
		# Drawn from the start, at no brightness, so nothing has to be made
		# ready at the moment the hands meet.
		rays.visible = true
		var fan: ShaderMaterial = rays.material_override as ShaderMaterial
		if fan != null:
			fan.set_shader_parameter("brightness", rays_now())
			fan.set_shader_parameter("colour", LanternFace.colour_for(strength))
