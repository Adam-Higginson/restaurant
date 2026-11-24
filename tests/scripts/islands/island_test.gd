extends GameTestSuite
## Tests for the island scene itself (the cove), its root (Island), the
## jolly boat that takes you ashore (JollyBoat) and the plants' wind
## (PlantSway).

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


func test_the_visit_begins_on_the_ships_deck_facing_the_island() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 40)
	var player: Player3D = runner.find_child("Player") as Player3D
	var start: Node3D = runner.find_child("DeckStart") as Node3D
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	assert_bool(player.is_on_floor()).is_true()
	# On the deck, well above the sea and well out from the shore.
	assert_float(player.global_position.y).is_greater(4.0)
	assert_float(player.global_position.distance_to(start.global_position)).is_less(1.0)
	assert_float(-ground.shape.inland(player.global_position.x, player.global_position.z)).is_greater(40.0)
	# The island is towards -Z, and that's the way the start faces.
	assert_float((-start.global_basis.z).z).is_less(-0.9)


func test_the_jolly_boat_takes_you_ashore_and_back() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 10)
	var player: Player3D = runner.find_child("Player") as Player3D
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	var deck_boat: JollyBoat = runner.find_child("JollyBoat") as JollyBoat
	var beach_boat: JollyBoat = runner.find_child("BeachBoat") as JollyBoat
	var went: bool = await finishes_within(func() -> void: await deck_boat.cross(player), 6.0)
	assert_bool(went).is_true()
	await physics_ticks(runner, 40)
	assert_bool(player.controls_enabled).is_true()
	assert_bool(player.is_on_floor()).is_true()
	var back: float = ground.shape.inland(player.global_position.x, player.global_position.z)
	assert_float(back).is_between(0.5, ground.shape.beach_width)
	assert_float(player.global_position.y).is_greater(0.0)
	var returned: bool = await finishes_within(func() -> void: await beach_boat.cross(player), 6.0)
	assert_bool(returned).is_true()
	await physics_ticks(runner, 40)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_greater(4.0)


func test_the_beach_boat_sits_on_the_sand_and_is_where_defeat_returns_you() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 2)
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	var beach_boat: JollyBoat = runner.find_child("BeachBoat") as JollyBoat
	var at: Vector3 = beach_boat.global_position
	assert_float(at.y).is_equal_approx(ground.shape.height_at(at.x, at.z) - beach_boat.settle_sink, 0.001)
	var landing: Node3D = runner.scene().get_tree().get_first_node_in_group(Duellist.LANDING_GROUP) as Node3D
	assert_object(landing).is_same(runner.find_child("StepOut"))
	var back: float = ground.shape.inland(landing.global_position.x, landing.global_position.z)
	assert_float(back).is_between(0.5, ground.shape.beach_width)


func test_crabs_wait_on_the_beach_and_you_come_with_your_knife() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 60)
	var ground: IslandGround = runner.find_child("Ground") as IslandGround
	var crabs: Array[Node] = runner.scene().find_children("*", "Crab", true, false)
	assert_int(crabs.size()).is_equal(3)
	for node: Node in crabs:
		var crab: Crab = node as Crab
		assert_bool(crab.is_on_floor()).is_true()
		var back: float = ground.shape.inland(crab.global_position.x, crab.global_position.z)
		assert_float(back).is_between(1.0, ground.shape.beach_width)
	var player: Player3D = runner.find_child("Player") as Player3D
	assert_bool(player.toolbar.has_tool(&"chefs_knife")).is_true()
	# The pan's in the chest on the beach (#187).
	assert_bool(duellist_of(player).has_pan()).is_false()


func test_the_frying_pan_waits_in_a_chest_on_the_beach() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 30)
	var chest: TreasureChest = runner.find_child("BeachChest") as TreasureChest
	var landing: Node3D = runner.find_child("StepOut") as Node3D

	assert_str(String(chest.treasure_id())).is_equal("frying_pan")
	assert_bool(chest.is_opened()).is_false()
	# A few steps from where the boat lands you.
	assert_float(chest.global_position.distance_to(landing.global_position)).is_less(6.0)


func test_the_ships_lanterns_are_out_by_day() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 2)
	var lanterns: Array[Node] = runner.scene().get_tree().get_nodes_in_group(Lantern.GROUP)
	assert_int(lanterns.size()).is_greater(5)
	for node: Node in lanterns:
		var lantern: Lantern = node as Lantern
		assert_bool(lantern.lit).is_false()
		assert_bool((lantern.get_node("Light") as Light3D).visible).is_false()
		assert_float(lantern.flame_burning()).is_equal(0.0)
	for node: Node in runner.scene().get_tree().get_nodes_in_group(Island.NIGHT_GLOW_GROUP):
		assert_bool((node as Node3D).visible).is_false()
	# And they can be lit again.
	var island: Island = runner.scene() as Island
	island.light_lanterns(true)
	assert_bool((lanterns[0] as Lantern).lit).is_true()
	assert_float((lanterns[0] as Lantern).flame_burning()).is_equal(1.0)


func test_falling_out_of_the_world_puts_you_back_on_deck() -> void:
	var runner: GdUnitSceneRunner = scene_runner(COVE)
	await physics_ticks(runner, 5)
	var start: Node3D = runner.find_child("DeckStart") as Node3D
	var player: Player3D = place_player_3d(runner, Vector3(150.0, -30.0, 150.0))
	await physics_ticks(runner, 3)
	assert_float(player.global_position.distance_to(start.global_position)).is_less(1.0)


func test_a_jolly_boat_with_nowhere_to_go_stays_put() -> void:
	var boat: JollyBoat = (load("res://scenes/prototype/islands/props/jolly_boat.tscn") as PackedScene).instantiate() as JollyBoat
	auto_free(boat)
	add_child(boat)
	var player: Player3D = new_player_3d_on_floor()
	add_child(player.get_parent())
	var before: Vector3 = player.global_position
	await boat.cross(player)
	assert_vector(player.global_position).is_equal(before)
	assert_bool(boat.is_crossing()).is_false()


func test_a_jolly_boat_without_a_fade_crosses_at_once() -> void:
	var boat: JollyBoat = (load("res://scenes/prototype/islands/props/jolly_boat.tscn") as PackedScene).instantiate() as JollyBoat
	auto_free(boat)
	var spot: Marker3D = Marker3D.new()
	auto_free(spot)
	add_child(spot)
	spot.global_position = Vector3(30.0, 2.0, -12.0)
	boat.destination = spot
	add_child(boat)
	var player: Player3D = new_player_3d_on_floor()
	add_child(player.get_parent())
	var crossings: Dictionary[String, int] = {"count": 0}
	boat.crossed.connect(func(_who: Player3D) -> void: crossings["count"] += 1)
	await boat.cross(player)
	assert_vector(player.global_position).is_equal_approx(spot.global_position, Vector3.ONE * 0.001)
	assert_bool(player.controls_enabled).is_true()
	assert_int(crossings["count"]).is_equal(1)


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
