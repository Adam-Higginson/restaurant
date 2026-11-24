extends GameTestSuite
## Tests for the galley's hearth and mood: the stove's fire, steam and embers,
## the swinging lanterns, the crew's table and a galley that stays dry
## whatever the weather.

const STOVE_SCENE: String = "res://scenes/prototype/props/galley_stove.tscn"


func test_the_stove_flickers_and_sparks() -> void:
	var stove: GalleyStove = (load(STOVE_SCENE) as PackedScene).instantiate() as GalleyStove
	add_child(stove)
	auto_free(stove)

	assert_object(stove.get_node("FireLight") as Flicker).is_not_null()
	assert_bool(stove.embers().emitting).is_true()
	# They belong to the stove, so they rise straight up on a sailing ship.
	assert_bool(stove.embers().local_coords).is_true()


func test_no_steam_rises_from_an_empty_hob() -> void:
	# Steam comes from a pan cooking on a hob (#204), never the hearth itself.
	var stove: GalleyStove = (load(STOVE_SCENE) as PackedScene).instantiate() as GalleyStove
	add_child(stove)
	auto_free(stove)
	assert_array(stove.find_children("Steam", "GPUParticles3D", true, false)).is_empty()


func test_the_fire_burns_in_the_hearth_s_mouth() -> void:
	# Flames dance over the Meshy hearth's painted fire (#204), low in its
	# mouth, at the front, and sail with the ship.
	var stove: GalleyStove = (load(STOVE_SCENE) as PackedScene).instantiate() as GalleyStove
	add_child(stove)
	auto_free(stove)
	assert_int(stove.flames().get_child_count()).is_equal(GalleyStove.TONGUES.size())
	# A child of the stove, so it sails with the ship.
	assert_bool(stove.is_ancestor_of(stove.flames())).is_true()
	var at: Vector3 = stove.to_local(stove.flames().global_position)
	assert_float(at.y).is_between(0.1, 0.4)
	assert_float(absf(at.x)).is_less(0.1)


func test_the_chimney_runs_from_the_flue_up_through_the_deck() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var stove: GalleyStove = ship.get_node("Galley/Stove") as GalleyStove
	var chimney: MeshInstance3D = stove.get_node("Chimney") as MeshInstance3D
	var pipe: CylinderMesh = chimney.mesh as CylinderMesh
	# The galley sits at the ship's origin, so the stove's position is in ship
	# space, and the chimney's is in the stove's.
	var middle: float = stove.position.y + chimney.position.y
	var foot: float = middle - pipe.height / 2.0
	var top: float = middle + pipe.height / 2.0
	var hearth: ThirdPartyModel = stove.get_node("Meshy") as ThirdPartyModel
	# From the top of the stone flue (the hearth's full height), through the
	# galley's ceiling (3.6 m up the ship), to above the deck (5.3 m).
	var flue_top: float = stove.position.y + hearth.fit_size.y
	assert_float(foot).is_between(flue_top - 0.1, flue_top + 0.05)
	assert_float(top).is_greater(5.3)


func test_there_is_one_kettle_aboard() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var kettles: Array[Node] = ship.find_children("*", "", true, false).filter(
			func(node: Node) -> bool:
				return node.scene_file_path.ends_with("dressing/kettle.tscn"))
	assert_int(kettles.size()).is_equal(1)


func test_the_crew_table_is_cleared() -> void:
	# Only the table, its benches and the bowls you serve from (#204).
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var table: Node3D = ship.get_node("Galley/CrewTable") as Node3D
	for name: String in ["Runner", "BreadBoard", "Bowl1", "Tankard1", "Jug", "Loaf"]:
		assert_object(table.get_node_or_null(name)).override_failure_message(
				"%s is still on the table" % name).is_null()
	for name: String in ["Mug1", "Mug2", "GreenBottle", "Kettle"]:
		assert_object(ship.get_node_or_null("Galley/" + name)).override_failure_message(
				"%s is still in the galley" % name).is_null()
	assert_object(ship.get_node("Galley/BowlStack") as Dispenser3D).is_not_null()


func test_the_chimney_smokes_up_on_deck_leaning_astern() -> void:
	var stove: GalleyStove = (load(STOVE_SCENE) as PackedScene).instantiate() as GalleyStove
	add_child(stove)
	auto_free(stove)
	assert_bool(stove.smoke().emitting).is_true()
	# It comes out of the chimney top, above the deck (5.3 m up the ship, so
	# 4.3 m above the galley floor the stove stands on).
	assert_float(stove.to_local(stove.smoke().global_position).y).is_greater(4.3)
	# It sails with the ship, and the wind leans it astern (+z) as it rises.
	assert_bool(stove.smoke().local_coords).is_true()
	var process: ParticleProcessMaterial = stove.smoke().process_material \
			as ParticleProcessMaterial
	assert_float(process.gravity.y).is_greater(0.0)
	assert_float(process.gravity.z).is_greater(0.0)


func test_the_galley_has_its_hearth_table_and_lanterns() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	assert_object(ship.get_node("Galley/Stove") as GalleyStove).is_not_null()
	assert_object(ship.get_node("Galley/CrewTable") as StaticBody3D).is_not_null()
	for lantern: String in ["Galley/GalleyLanternFore", "Galley/GalleyLanternAft"]:
		assert_object(ship.get_node(lantern) as Swinging).is_not_null()


func test_you_cannot_walk_through_the_stove_or_the_table() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	for path: String in ["Galley/Stove", "Galley/CrewTable"]:
		var body: StaticBody3D = ship.get_node(path) as StaticBody3D
		assert_bool(body.get_children().any(
				func(child: Node) -> bool: return child is CollisionShape3D)).is_true()


func test_the_galley_stays_dry_in_the_rain() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	# The bulkhead is three pieces round the navigation room's door (#185),
	# and the room is dry too.
	for path: String in ["Visuals/GalleyFloor", "Visuals/WallPort", "Visuals/BulkheadPort",
			"Visuals/BulkheadStarboard", "Visuals/BulkheadLintel", "NavigationRoom/Forward",
			"NavigationRoom/Floor"]:
		var mesh: MeshInstance3D = ship.get_node(path) as MeshInstance3D
		var material: ShaderMaterial = mesh.material_override as ShaderMaterial
		var exposure: float = material.get_shader_parameter(&"exposure")
		assert_float(exposure).override_failure_message("%s gets wet" % path).is_equal(0.0)
	# The deck above is out in it.
	var deck: ShaderMaterial = (ship.get_node("Visuals/DeckAft") as MeshInstance3D) \
			.material_override as ShaderMaterial
	var deck_exposure: Variant = deck.get_shader_parameter(&"exposure")
	# Unset means the shader's default, which is fully out in the weather.
	assert_bool(deck_exposure == null or deck_exposure == 1.0).is_true()


func test_the_lanterns_glow_as_bright_as_set() -> void:
	var lantern: Lantern = (load("res://scenes/prototype/props/lantern.tscn") as PackedScene) \
			.instantiate() as Lantern
	lantern.light_energy = 0.7
	lantern.light_range = 3.0
	add_child(lantern)
	auto_free(lantern)
	var light: OmniLight3D = lantern.get_node("Light") as OmniLight3D
	assert_float(light.light_energy).is_equal_approx(0.7, 0.0001)
	assert_float(light.omni_range).is_equal_approx(3.0, 0.0001)


func test_a_lantern_can_be_set_not_to_cast_shadows() -> void:
	var lantern: Lantern = (load("res://scenes/prototype/props/lantern.tscn") as PackedScene) \
			.instantiate() as Lantern
	lantern.casts_shadows = false
	add_child(lantern)
	auto_free(lantern)
	assert_bool((lantern.get_node("Light") as OmniLight3D).shadow_enabled).is_false()


func test_no_more_than_three_galley_lights_cast_shadows() -> void:
	# Shadows from point lights are costly: only the hearth and the two
	# lanterns over the table cast them.
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	# Running it calls each lantern's _ready, which sets its shadows.
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var galley: AABB = AABB(Vector3(-3.4, 1.0, 1.15), Vector3(9.1, 2.6, 6.65))
	var shadowed: Array[String] = []
	for node: Node in ship.find_children("*", "Light3D", true, false):
		var light: Light3D = node as Light3D
		if light.shadow_enabled and galley.has_point(ship.to_local(light.global_position)):
			shadowed.append(str(ship.get_path_to(light)))
	assert_array(shadowed).override_failure_message(
			"Lights casting shadows in the galley: %s" % [shadowed]).has_size(3)


func test_the_galley_walls_reach_the_deck() -> void:
	# No gap between the galley's walls and the deck above (5 m up the ship)
	# to see into from the bunk room or the ramp.
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	# The corridor's wall is the ship's; the partition is the galley's own (#196).
	for name: String in ["Visuals/CorridorWall", "Galley/PartitionStarboard",
			"Galley/PartitionLintel"]:
		var wall: MeshInstance3D = ship.get_node(name) as MeshInstance3D
		var top: float = wall.position.y + (wall.mesh as BoxMesh).size.y / 2.0
		assert_float(top).override_failure_message("%s stops at %.2f" % [name, top]) \
				.is_greater_equal(4.99)
		var shape_path: String = name.replace("Visuals/", "") + "Shape"
		var shape: CollisionShape3D = ship.get_node(shape_path) as CollisionShape3D
		var shape_top: float = shape.position.y + (shape.shape as BoxShape3D).size.y / 2.0
		assert_float(shape_top).is_greater_equal(4.99)


func test_the_galley_has_its_own_dim_ambient_light() -> void:
	# Inside, the dark warm ambient of the galley's probe replaces the night
	# sky's, so the corners stay dark.
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var probe: ReflectionProbe = ship.get_node("Galley/GalleyProbe") as ReflectionProbe
	assert_bool(probe.interior).is_true()
	assert_int(probe.ambient_mode).is_equal(ReflectionProbe.AMBIENT_COLOR)
	assert_float(probe.ambient_color_energy).is_less(0.5)


func test_golden_motes_drift_with_the_ship() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	scene_runner(ship.get_parent())
	var motes: Motes = ship.get_node("Galley/Motes") as Motes
	assert_bool(motes.local_coords).is_true()
	assert_bool(motes.emitting).is_true()


func test_you_walk_in_through_the_doorway_from_the_bunks() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-2.72, 1.05, 8.6))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	# Up on the stick walks away from the camera, towards the bow.
	await walk(runner, "move_up", 60)

	var player: Player3D = runner.find_child("Player") as Player3D
	assert_float(ship.to_local(player.global_position).z).is_less(7.0)


func test_the_portholes_are_cut_through_the_wall() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var wall: CSGBox3D = ship.get_node("Visuals/WallStarboard") as CSGBox3D
	var holes: int = 0
	for child: Node in wall.get_children():
		var cut: CSGCylinder3D = child as CSGCylinder3D
		if cut != null and cut.operation == CSGShape3D.OPERATION_SUBTRACTION:
			holes += 1
	assert_int(holes).is_equal(2)
