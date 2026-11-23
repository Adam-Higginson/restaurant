extends GameTestSuite
## Tests for the island scene itself (the cove), its root (Island) and the
## plants' wind (PlantSway).

const COVE: String = "res://scenes/prototype/islands/cove.tscn"


func test_an_island_smooths_edges_while_it_shows_and_puts_it_back() -> void:
	var viewport: Viewport = get_viewport()
	var before: Viewport.MSAA = viewport.msaa_3d
	var island: Island = Island.new()
	island.edge_smoothing = Viewport.MSAA_2X
	add_child(island)
	assert_int(viewport.msaa_3d).is_equal(Viewport.MSAA_2X)
	remove_child(island)
	island.free()
	assert_int(viewport.msaa_3d).is_equal(before)


func test_plants_get_the_swaying_material_with_their_own_texture() -> void:
	var texture: Texture2D = load("res://assets/placeholder/greybox_grid.png") as Texture2D
	var plant: ThirdPartyModel = _new_dressed_plant(texture)
	var sway: PlantSway = PlantSway.new()
	auto_free(sway)
	sway.model = plant
	sway.sway = 0.07
	add_child(sway)
	var mesh: MeshInstance3D = plant.model.get_child(0) as MeshInstance3D
	var swapped: ShaderMaterial = mesh.get_surface_override_material(0) as ShaderMaterial
	assert_object(swapped).is_not_null()
	assert_object(swapped.shader).is_same(PlantSway.SHADER)
	assert_object(swapped.get_shader_parameter(&"albedo_texture")).is_same(texture)
	var swing: float = swapped.get_shader_parameter(&"sway")
	assert_float(swing).is_equal_approx(0.07, 0.0001)


func test_plants_that_share_a_model_share_the_swaying_material() -> void:
	var texture: Texture2D = load("res://assets/placeholder/greybox_grid.png") as Texture2D
	var first: ThirdPartyModel = _new_dressed_plant(texture)
	var second: ThirdPartyModel = _new_dressed_plant(texture)
	# Two copies of one model share its material, as instances of a scene do.
	var second_mesh: MeshInstance3D = second.model.get_child(0) as MeshInstance3D
	var first_mesh: MeshInstance3D = first.model.get_child(0) as MeshInstance3D
	second_mesh.mesh = first_mesh.mesh
	for plant: ThirdPartyModel in [first, second]:
		var sway: PlantSway = PlantSway.new()
		auto_free(sway)
		sway.model = plant
		add_child(sway)
	assert_object(second_mesh.get_surface_override_material(0)).is_same(
			first_mesh.get_surface_override_material(0))


func test_the_cove_loads_and_you_stand_on_its_beach() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 40)
	var player: Player3D = runner.find_child("Player") as Player3D
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	assert_bool(player.is_on_floor()).is_true()
	var under: float = ground.shape.height_at(player.global_position.x, player.global_position.z)
	assert_float(under).is_greater(0.0)
	assert_float(player.global_position.y).is_equal_approx(under, 0.25)


func test_you_can_wade_into_the_cove_but_not_under() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 10)
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	# Dropped in well out past the drop-off, where the seabed is far below.
	var out_z: float = ground.shape.shore_line(-10.0) + 12.0
	assert_float(ground.shape.height_at(-10.0, out_z)).is_less(-2.0)
	var player: Player3D = place_player_3d(runner, Vector3(-10.0, 1.0, out_z))
	await physics_ticks(runner, 60)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_equal_approx(-ground.wade_depth, 0.15)


func test_the_coves_water_and_sand_share_the_shores_numbers() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 2)
	var shore: Shore = runner.find_child("Shore") as Shore
	var materials: Array[ShaderMaterial] = shore.materials()
	assert_int(materials.size()).is_equal(2)
	var in_water: float = materials[0].get_shader_parameter(&"swash_period")
	var in_sand: float = materials[1].get_shader_parameter(&"swash_period")
	assert_float(in_water).is_equal(shore.swash_period)
	assert_float(in_sand).is_equal(shore.swash_period)
	assert_object(materials[0].get_shader_parameter(&"ground_heights")).is_not_null()


# A ThirdPartyModel showing a one-quad "plant" painted with [param texture],
# as if its file had been there to load.
func _new_dressed_plant(texture: Texture2D) -> ThirdPartyModel:
	var plant: ThirdPartyModel = ThirdPartyModel.new()
	auto_free(plant)
	add_child(plant)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_texture = texture
	var quad: QuadMesh = QuadMesh.new()
	quad.material = material
	var mesh: MeshInstance3D = MeshInstance3D.new()
	mesh.mesh = quad
	var model: Node3D = Node3D.new()
	model.add_child(mesh)
	plant.add_child(model)
	plant.model = model
	return plant
