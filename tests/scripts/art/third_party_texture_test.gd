extends GameTestSuite
## Tests for ThirdPartyTexture: swapping a texture in only when its file is
## there, so scenes still load on a fresh clone without third-party art.

const GRID: String = "res://assets/placeholder/greybox_grid.png"


func test_swaps_the_texture_in_when_the_file_is_there() -> void:
	var dresser: ThirdPartyTexture = _new_dresser(GRID)
	assert_bool(dresser.apply()).is_true()
	assert_object(dresser.material.get_shader_parameter(&"albedo_texture")).is_same(load(GRID))


func test_leaves_the_material_alone_when_the_file_is_missing() -> void:
	var dresser: ThirdPartyTexture = _new_dresser("res://assets/third_party/no_such_texture.png")
	assert_bool(dresser.apply()).is_false()
	assert_object(dresser.material.get_shader_parameter(&"albedo_texture")).is_null()


func test_does_nothing_without_a_material_or_path() -> void:
	var dresser: ThirdPartyTexture = _new_dresser("")
	assert_bool(dresser.apply()).is_false()
	dresser.material = null
	dresser.path = GRID
	assert_bool(dresser.apply()).is_false()


func test_can_give_the_texture_mipmaps() -> void:
	var dresser: ThirdPartyTexture = _new_dresser(GRID)
	dresser.mipmaps = true
	assert_bool(dresser.apply()).is_true()
	var swapped: Texture2D = dresser.material.get_shader_parameter(&"albedo_texture")
	assert_bool(swapped.get_image().has_mipmaps()).is_true()
	assert_int(swapped.get_width()).is_equal((load(GRID) as Texture2D).get_width())


func _new_dresser(path: String) -> ThirdPartyTexture:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/wet_surface.gdshader") as Shader
	var dresser: ThirdPartyTexture = ThirdPartyTexture.new()
	dresser.material = material
	dresser.path = path
	auto_free(dresser)
	return dresser
