extends GameTestSuite
const MATERIALS: String = "res://assets/placeholder/materials"
const GRAIN: String = "res://assets/placeholder/materials/soft_grain.tres"


func test_no_greybox_material_draws_sharp_pixels() -> void:
	for file: String in DirAccess.get_files_at(MATERIALS):
		if not file.ends_with(".tres"):
			continue
		var material: BaseMaterial3D = load(MATERIALS.path_join(file)) as BaseMaterial3D
		if material == null or material.albedo_texture == null:
			continue
		assert_bool(material.texture_filter in [BaseMaterial3D.TEXTURE_FILTER_LINEAR,
				BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
				BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC]) \
				.override_failure_message("%s draws sharp pixels" % file).is_true()


func test_the_shared_grain_is_gentle_mottling() -> void:
	var grain: NoiseTexture2D = load(GRAIN) as NoiseTexture2D
	assert_object(grain.color_ramp).is_not_null()
	# Its darkest is a light grey: a mottle, not black specks.
	assert_float(grain.color_ramp.get_color(0).v).is_greater(0.6)
	var noise: FastNoiseLite = grain.noise as FastNoiseLite
	assert_float(noise.frequency).is_less_equal(0.08)
