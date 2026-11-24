extends GameTestSuite
## Tests for the galley's hearth and mood: the stove's fire, steam and embers,
## the swinging lanterns, the crew's table and a galley that stays dry
## whatever the weather.

const STOVE_SCENE: String = "res://scenes/prototype/props/galley_stove.tscn"


func test_the_stove_flickers_steams_and_sparks() -> void:
	var stove: GalleyStove = (load(STOVE_SCENE) as PackedScene).instantiate() as GalleyStove
	add_child(stove)
	auto_free(stove)

	assert_object(stove.get_node("FireLight") as Flicker).is_not_null()
	assert_bool(stove.steam().emitting).is_true()
	assert_bool(stove.embers().emitting).is_true()
	# They belong to the stove, so they rise straight up on a sailing ship.
	assert_bool(stove.steam().local_coords).is_true()
	assert_bool(stove.embers().local_coords).is_true()


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
	var process: ParticleProcessMaterial = stove.smoke().process_material 			as ParticleProcessMaterial
	assert_float(process.gravity.y).is_greater(0.0)
	assert_float(process.gravity.z).is_greater(0.0)


func test_the_galley_has_its_hearth_table_and_lanterns() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	assert_object(ship.get_node("Galley/Stove") as GalleyStove).is_not_null()
	assert_object(ship.get_node("Galley/CrewTable") as StaticBody3D).is_not_null()
	for lantern: String in ["Visuals/GalleyLanternFore", "Visuals/GalleyLanternAft"]:
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
	var lantern: Lantern = (load("res://scenes/prototype/props/lantern.tscn") as PackedScene) 			.instantiate() as Lantern
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
	for name: String in ["CorridorWall", "PartitionStarboard", "PartitionLintel"]:
		var wall: MeshInstance3D = ship.get_node("Visuals/" + name) as MeshInstance3D
		var top: float = wall.position.y + (wall.mesh as BoxMesh).size.y / 2.0
		assert_float(top).override_failure_message("%s stops at %.2f" % [name, top]) \
				.is_greater_equal(4.99)
		var shape: CollisionShape3D = ship.get_node(name + "Shape") as CollisionShape3D
		var shape_top: float = shape.position.y + (shape.shape as BoxShape3D).size.y / 2.0
		assert_float(shape_top).is_greater_equal(4.99)


func test_the_galley_has_its_own_dim_ambient_light() -> void:
	# Inside, the dark warm ambient of the galley's probe replaces the night
	# sky's, so the corners stay dark.
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var probe: ReflectionProbe = ship.get_node("Visuals/GalleyProbe") as ReflectionProbe
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
