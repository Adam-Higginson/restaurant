class_name SurfaceSpace
extends Node
## Pins shader patterns (planks, puddles, rain rings) to a moving body, so
## they travel with it instead of sliding across it as it moves.
##
## Every rendered frame it hands each material the body's world-to-local
## transform as [code]to_surface_space[/code]. Shaders that place patterns by
## position (shaders/wet_surface.gdshader) then work in the body's space.

## The parameter the materials take the transform in.
const PARAMETER: StringName = &"to_surface_space"

## The body the patterns ride on. Defaults to this node's parent.
@export var body: Node3D
## The materials to pin.
@export var materials: Array[ShaderMaterial] = []


func _ready() -> void:
	if body == null:
		body = get_parent() as Node3D
	apply()


# Every rendered frame, using where the body is drawn (physics interpolation
# included), so the pattern never lags behind the planks.
func _process(_delta: float) -> void:
	apply()


## Hands every material the body's current transform.
func apply() -> void:
	if not is_instance_valid(body):
		return
	var to_body: Projection = Projection(body.get_global_transform_interpolated().affine_inverse())
	for material: ShaderMaterial in materials:
		if material != null:
			material.set_shader_parameter(PARAMETER, to_body)
