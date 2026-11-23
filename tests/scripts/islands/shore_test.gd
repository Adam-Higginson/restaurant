extends GameTestSuite
## Tests for Shore: the one place the shore's numbers live, handed to both
## the water and the sand so the wet sand follows the water.

const WATER_SHADER: Shader = preload("res://shaders/shore_water.gdshader")
const SAND_SHADER: Shader = preload("res://shaders/island_sand.gdshader")


func test_the_swash_goes_from_right_back_to_right_up_and_round_again() -> void:
	var lowest: float = INF
	var highest: float = -INF
	for step: int in 200:
		var at: float = Shore.swash(step * 0.03, 6.0)
		lowest = minf(lowest, at)
		highest = maxf(highest, at)
	assert_float(lowest).is_equal_approx(0.0, 0.01)
	assert_float(highest).is_equal_approx(1.0, 0.01)
	assert_float(Shore.swash(1.3, 6.0)).is_equal_approx(Shore.swash(7.3, 6.0), 0.0001)


func test_the_water_level_rises_by_the_swash_height() -> void:
	var shore: Shore = _new_shore()
	shore.sea_level = 0.5
	shore.swash_height = 0.2
	shore.swash_period = 4.0
	# A tenth of the way through its round the water is right up the beach.
	assert_float(shore.water_level(0.4)).is_equal_approx(0.7, 0.0001)
	assert_float(shore.water_level(2.4)).is_equal_approx(0.5, 0.0001)


func test_the_water_and_the_sand_get_the_same_numbers() -> void:
	var shore: Shore = _new_shore()
	shore.sea_level = 0.3
	shore.swash_height = 0.15
	shore.swash_period = 4.5
	var materials: Array[ShaderMaterial] = shore.materials()
	assert_int(materials.size()).is_equal(2)
	for parameter: StringName in [&"sea_level", &"swash_height", &"swash_period"]:
		var in_water: float = materials[0].get_shader_parameter(parameter)
		var in_sand: float = materials[1].get_shader_parameter(parameter)
		assert_float(in_water).is_equal(in_sand)
	var period: float = materials[1].get_shader_parameter(&"swash_period")
	assert_float(period).is_equal(4.5)


func test_the_water_is_given_the_grounds_picture() -> void:
	var shore: Shore = _new_shore()
	var water: ShaderMaterial = shore.water.material_override as ShaderMaterial
	assert_object(water.get_shader_parameter(&"ground_heights")).is_same(shore.ground.height_texture())
	var corner: Vector2 = water.get_shader_parameter(&"ground_corner")
	var size: Vector2 = water.get_shader_parameter(&"ground_size")
	assert_vector(corner).is_equal(shore.ground.height_rect().position)
	assert_vector(size).is_equal(shore.ground.height_rect().size)


func test_the_water_gets_the_new_picture_when_the_ground_is_rebuilt() -> void:
	var shore: Shore = _new_shore()
	var before: ImageTexture = shore.ground.height_texture()
	shore.ground.build()
	var water: ShaderMaterial = shore.water.material_override as ShaderMaterial
	assert_object(shore.ground.height_texture()).is_not_same(before)
	assert_object(water.get_shader_parameter(&"ground_heights")).is_same(shore.ground.height_texture())


func test_does_nothing_without_a_ground_or_water() -> void:
	var shore: Shore = Shore.new()
	auto_free(shore)
	add_child(shore)
	shore.swash_period = 3.0
	assert_int(shore.materials().size()).is_equal(0)


func _new_shore() -> Shore:
	var shape: IslandShape = IslandShape.new()
	shape.size = Vector2(20.0, 20.0)
	var sand: ShaderMaterial = ShaderMaterial.new()
	sand.shader = SAND_SHADER
	var ground: IslandGround = IslandGround.new()
	auto_free(ground)
	ground.shape = shape
	ground.material = sand
	add_child(ground)
	var water_material: ShaderMaterial = ShaderMaterial.new()
	water_material.shader = WATER_SHADER
	var water: MeshInstance3D = MeshInstance3D.new()
	auto_free(water)
	water.mesh = PlaneMesh.new()
	water.material_override = water_material
	add_child(water)
	var shore: Shore = Shore.new()
	auto_free(shore)
	shore.ground = ground
	shore.water = water
	add_child(shore)
	return shore
