extends GameTestSuite
## Tests for PaintedGlow: a model's bright paint glows, kept through the
## model being dressed again; given a glass, the painted glass round it is
## cut away instead and the model casts shadows (#199).

const STAND_IN_MODEL: String = "res://tests/fixtures/box_model.tscn"


func test_the_models_paint_glows_once_it_shows() -> void:
	var glow: PaintedGlow = _glowing_box(0.5, 4.0)

	var material: ShaderMaterial = _box_material(glow.model) as ShaderMaterial
	assert_object(material).is_not_null()
	assert_object(material.shader).is_same(PaintedGlow.SHADER)
	assert_that(material.get_shader_parameter(&"albedo_color")).is_equal(Color(0.6, 0.4, 0.2))
	var threshold: float = material.get_shader_parameter(&"threshold")
	var energy: float = material.get_shader_parameter(&"energy")
	assert_float(threshold).is_equal_approx(0.5, 0.0001)
	assert_float(energy).is_equal_approx(4.0, 0.0001)


func test_it_still_glows_after_the_model_is_dressed_again() -> void:
	var glow: PaintedGlow = _glowing_box(0.6, 3.0)

	glow.model.dress()

	var material: ShaderMaterial = _box_material(glow.model) as ShaderMaterial
	assert_object(material).is_not_null()
	assert_object(material.shader).is_same(PaintedGlow.SHADER)


func test_with_glass_the_painted_glass_round_it_is_cut_away() -> void:
	var glow: PaintedGlow = _box_with_glass(Vector3(0.2, 0.3, 0.2), 0.05)

	var material: ShaderMaterial = _box_material(glow.model) as ShaderMaterial
	assert_object(material.shader).is_same(PaintedGlow.SEE_THROUGH_SHADER)
	assert_that(material.get_shader_parameter(&"albedo_color")).is_equal(Color(0.6, 0.4, 0.2))
	assert_that(material.get_shader_parameter(&"cut_half")).is_equal(Vector3(0.1, 0.15, 0.1))
	var corner: float = material.get_shader_parameter(&"corner")
	assert_float(corner).is_equal_approx(0.05, 0.0001)


func test_the_cut_is_measured_from_the_glass() -> void:
	var glow: PaintedGlow = _box_with_glass(Vector3(0.2, 0.3, 0.2), 0.0)
	var mesh: MeshInstance3D = glow.model.model.get_node("Mesh") as MeshInstance3D

	var material: ShaderMaterial = _box_material(glow.model) as ShaderMaterial
	var to_glass: Projection = material.get_shader_parameter(&"to_glass")

	# The box's own middle, seen from the glass, is where it really is.
	var middle: Vector3 = mesh.global_transform * Vector3.ZERO
	var expected: Vector3 = glow.glass.global_transform.affine_inverse() * middle
	var seen: Vector4 = to_glass * Vector4(0.0, 0.0, 0.0, 1.0)
	assert_vector(Vector3(seen.x, seen.y, seen.z)).is_equal_approx(expected, Vector3.ONE * 0.0001)


func test_a_cut_away_lantern_casts_shadows_but_a_glowing_one_doesnt() -> void:
	var glowing: PaintedGlow = _glowing_box(0.6, 3.0)
	var see_through: PaintedGlow = _box_with_glass(Vector3(0.2, 0.3, 0.2), 0.0)

	var glowing_mesh: MeshInstance3D = glowing.model.model.get_node("Mesh") as MeshInstance3D
	var cut_mesh: MeshInstance3D = see_through.model.model.get_node("Mesh") as MeshInstance3D
	assert_int(glowing_mesh.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_int(cut_mesh.cast_shadow).is_equal(GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


# A test box with its source material, with a PaintedGlow on it, in the tree.
func _glowing_box(threshold: float, energy: float) -> PaintedGlow:
	var holder: Node3D = Node3D.new()
	auto_free(holder)
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = STAND_IN_MODEL
	holder.add_child(dresser)
	var glow: PaintedGlow = PaintedGlow.new()
	glow.threshold = threshold
	glow.energy = energy
	holder.add_child(glow)
	add_child(holder)
	glow.model = dresser
	return glow


# A test box with a glass inside it, cut [param size] round the glass, the
# posts kept beyond [param corner].
func _box_with_glass(size: Vector3, corner: float) -> PaintedGlow:
	var holder: Node3D = Node3D.new()
	auto_free(holder)
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = STAND_IN_MODEL
	holder.add_child(dresser)
	var glass: Node3D = Node3D.new()
	glass.position = Vector3(0.1, 0.5, -0.2)
	holder.add_child(glass)
	var glow: PaintedGlow = PaintedGlow.new()
	glow.glass = glass
	glow.cut_size = size
	glow.corner = corner
	holder.add_child(glow)
	add_child(holder)
	glow.model = dresser
	return glow


func _box_material(dresser: ThirdPartyModel) -> Material:
	return (dresser.model.get_node("Mesh") as MeshInstance3D).material_override
