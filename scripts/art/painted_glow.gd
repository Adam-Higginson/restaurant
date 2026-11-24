@tool
class_name PaintedGlow
extends Node
## Makes the bright painted parts of a [ThirdPartyModel] glow, like the glass
## of a Meshy lantern, whose flame is painted into its texture (#168). Each
## time the model is dressed, its surfaces get the painted-glow material with
## their own texture. Put a light beside it for the glow to light the room.
##
## Given a [member glass], it cuts the painted glass away instead (#199):
## every part of the model inside a box ([member cut_size]) round the glass
## isn't drawn, so the glass, a box with a real flame burning in it
## (lantern_flame.gdshader), shows in its place, framed by the model.

const SHADER: Shader = preload("res://shaders/painted_glow.gdshader")
const SEE_THROUGH_SHADER: Shader = preload("res://shaders/glass_cutout.gdshader")

## The model whose paint glows.
@export var model: ThirdPartyModel:
	set(value):
		if model != null and model.dressed.is_connected(_on_dressed):
			model.dressed.disconnect(_on_dressed)
		model = value
		if model != null:
			model.dressed.connect(_on_dressed)
			if model.model != null:
				_on_dressed(true)
## How bright the paint must be (0 to 1) before it glows.
@export_range(0.0, 1.0) var threshold: float = 0.6
## How strongly it glows: above 1 it blooms.
@export_range(0.0, 16.0) var energy: float = 3.0
## The lantern's own glass, drawn inside the model. Set, the model's painted
## glass round it is cut away rather than made to glow.
@export var glass: Node3D
## The size of the box cut out of the model, centred on [member glass] and
## turned with it, a little bigger than the painted panes. It's measured in
## the glass's own space: metres, unless the glass node is scaled, so a
## lantern scaled up as a whole keeps the same numbers.
@export var cut_size: Vector3 = Vector3.ZERO
## How far from the glass's middle the corner posts begin, in the same
## space: the cut leaves anything further out than this on both sides. Zero
## cuts the whole box.
@export var corner: float = 0.0


## The material for a surface of [param mesh_node] painted with
## [param source]: glowing, or with its glass cut away if there's a
## [member glass].
func material_for(source: BaseMaterial3D, mesh_node: Node3D = null) -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.set_shader_parameter(&"albedo_color", source.albedo_color)
	if source.albedo_texture != null:
		material.set_shader_parameter(&"albedo_texture", source.albedo_texture)
	if glass == null:
		material.shader = SHADER
		material.set_shader_parameter(&"threshold", threshold)
		material.set_shader_parameter(&"energy", energy)
		return material
	material.shader = SEE_THROUGH_SHADER
	material.set_shader_parameter(&"cut_half", cut_size * 0.5)
	material.set_shader_parameter(&"corner", corner)
	if mesh_node != null:
		# Both hang from the same lantern, so this never changes as it swings.
		var to_glass: Transform3D = glass.global_transform.affine_inverse() \
				* mesh_node.global_transform
		material.set_shader_parameter(&"to_glass", Projection(to_glass))
	return material


func _on_dressed(shown: bool) -> void:
	if shown and model.model != null:
		_glow(model.model)


func _glow(node: Node) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	var whole: BaseMaterial3D = null
	if mesh_node != null:
		whole = mesh_node.material_override as BaseMaterial3D
		# A lamp whose glass is painted on would hide the light inside it, so
		# it casts no shadow. With its glass cut away, its frame does: the
		# light pours out through the panes and nowhere else.
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
				if glass == null else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	if whole != null:
		# One material over the whole mesh: that's the paint.
		mesh_node.material_override = material_for(whole, mesh_node)
	elif mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if source != null:
				mesh_node.set_surface_override_material(surface, material_for(source, mesh_node))
	for child: Node in node.get_children():
		_glow(child)
