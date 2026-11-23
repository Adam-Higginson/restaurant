extends GameTestSuite
## Tests for PaintedGlow: a model's bright paint glows, kept through the
## model being dressed again.

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


# A test box dressed as made (no grain), with a PaintedGlow on it, in the tree.
func _glowing_box(threshold: float, energy: float) -> PaintedGlow:
	var holder: Node3D = Node3D.new()
	auto_free(holder)
	var dresser: ThirdPartyModel = ThirdPartyModel.new()
	dresser.path = STAND_IN_MODEL
	dresser.grain = false
	holder.add_child(dresser)
	var glow: PaintedGlow = PaintedGlow.new()
	glow.threshold = threshold
	glow.energy = energy
	holder.add_child(glow)
	add_child(holder)
	glow.model = dresser
	return glow


func _box_material(dresser: ThirdPartyModel) -> Material:
	return (dresser.model.get_node("Mesh") as MeshInstance3D).material_override
