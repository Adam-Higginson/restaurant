extends GameTestSuite
## Tests that fire and small effects are drawn with soft edges (#137): the
## flame shaders blend their texels by default, and the motes and the bow's
## spray are soft round specks, smoothly filtered, not squares.

const FIRE_SHADERS: Array[String] = [
	"res://shaders/pixel_fire.gdshader",
	"res://shaders/flame_hand.gdshader",
]


func test_every_flame_is_soft_unless_asked_otherwise() -> void:
	# Read from the shader's own code: headless test runs don't compile shaders.
	for path: String in FIRE_SHADERS:
		var shader: Shader = load(path) as Shader
		assert_str(shader.code).override_failure_message(path) \
				.contains("uniform bool soft = true;")


func test_motes_are_soft_round_glints() -> void:
	var motes: Motes = Motes.new()
	add_child(motes)
	auto_free(motes)
	var material: StandardMaterial3D = (motes.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	assert_int(material.texture_filter).is_equal(BaseMaterial3D.TEXTURE_FILTER_LINEAR)
	assert_int(material.albedo_texture.get_width()).is_greater_equal(16)


func test_spray_droplets_are_soft_round_blobs() -> void:
	var spray: BowSpray = BowSpray.new()
	add_child(spray)
	auto_free(spray)
	var material: StandardMaterial3D = (spray.draw_pass_1 as QuadMesh).material as StandardMaterial3D
	assert_int(material.texture_filter).is_equal(BaseMaterial3D.TEXTURE_FILTER_LINEAR)
	var image: Image = material.albedo_texture.get_image()
	# Its edge fades: there are see-through steps between solid and clear.
	var fades: Dictionary = {}
	for x: int in image.get_width():
		fades[snappedf(image.get_pixel(x, image.get_height() / 2).a, 0.01)] = true
	assert_int(fades.size()).is_greater(4)
