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
	for path: String in ["Visuals/GalleyFloor", "Visuals/WallPort", "Visuals/Bulkhead"]:
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


func test_the_portholes_are_cut_through_the_wall() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 6))[0] as Ship
	var wall: CSGBox3D = ship.get_node("Visuals/WallStarboard") as CSGBox3D
	var holes: int = 0
	for child: Node in wall.get_children():
		var cut: CSGCylinder3D = child as CSGCylinder3D
		if cut != null and cut.operation == CSGShape3D.OPERATION_SUBTRACTION:
			holes += 1
	assert_int(holes).is_equal(2)
