extends GameTestSuite
## Tests for the shafts of lightning coming down through the water: nothing
## is there between flashes, and during one every shaft is as bright as the
## flash.

const SHADER: Shader = preload("res://shaders/light_shaft.gdshader")


func test_between_flashes_theres_nothing_there() -> void:
	var shafts: LightningShafts = _new_shafts(2)

	assert_bool(shafts.visible).is_false()
	assert_float(shafts.flash).is_equal(0.0)
	assert_bool(shafts.is_in_group(Lightning.LIT_GROUP)).is_true()


func test_in_a_flash_every_shaft_is_as_bright_as_the_flash() -> void:
	var shafts: LightningShafts = _new_shafts(3)

	shafts.set_lightning(0.75)

	assert_bool(shafts.visible).is_true()
	for child: Node in shafts.get_children():
		var material: ShaderMaterial = (child as MeshInstance3D).material_override as ShaderMaterial
		var sent: float = material.get_shader_parameter("flash")
		assert_float(sent).is_equal_approx(0.75, 0.001)


func test_when_the_flash_is_over_theyre_gone_again() -> void:
	var shafts: LightningShafts = _new_shafts(1)
	shafts.set_lightning(1.0)

	shafts.set_lightning(0.0)

	assert_bool(shafts.visible).is_false()


func test_a_flash_is_never_brighter_than_the_brightest() -> void:
	var shafts: LightningShafts = _new_shafts(1)

	shafts.set_lightning(4.0)

	assert_float(shafts.flash).is_equal(1.0)


func _new_shafts(count: int) -> LightningShafts:
	var shafts: LightningShafts = LightningShafts.new()
	auto_free(shafts)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	for index: int in count:
		var shaft: MeshInstance3D = MeshInstance3D.new()
		shaft.mesh = CylinderMesh.new()
		shaft.material_override = material
		shafts.add_child(shaft)
	add_child(shafts)
	return shafts
