extends GameTestSuite
## Tests for the bunk room aft of the galley: bunks down both sides, your own
## bunk, the stern windows, its light, and room to walk. The player walks at
## 5 m/s, so 12 physics ticks a metre; up on the stick is towards the bow,
## down towards the stern, right towards starboard.

## Our own pieces that dress the bunk room (#88).
const PIECES: Array[String] = [
	"props/bunk_bay", "props/sea_chest", "props/crate", "dressing/hammock",
	"dressing/hammock_blanket", "dressing/boots", "dressing/sock_line", "dressing/fiddle",
	"dressing/kit_bag", "dressing/book_stack", "dressing/sketchbook",
	"dressing/fishing_tackle", "dressing/your_things",
]


func test_bunks_line_both_sides() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var port: int = 0
	var starboard: int = 0
	for node: Node in ship.get_node("BunkRoom").get_children():
		var bay: BunkBay = node as BunkBay
		if bay == null:
			continue
		if bay.position.x < 0.0:
			port += 1
		else:
			starboard += 1
	assert_int(port).is_greater_equal(2)
	assert_int(starboard).is_greater_equal(3)


func test_your_bunk_has_its_own_quilt_and_a_lit_lantern() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var yours: BunkBay = ship.get_node("BunkRoom/YourBunk") as BunkBay
	assert_str(yours.lower_quilt.resource_path).contains("quilt_gold")
	assert_bool(yours.lamp_lit).is_true()
	assert_object(ship.get_node("BunkRoom/YourThings")).is_not_null()


func test_the_stern_has_two_windows_through_it() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var wall: CSGBox3D = ship.get_node("Visuals/WallStern") as CSGBox3D
	var holes: int = 0
	for child: Node in wall.get_children():
		var cut: CSGCylinder3D = child as CSGCylinder3D
		if cut != null and cut.operation == CSGShape3D.OPERATION_SUBTRACTION:
			holes += 1
	assert_int(holes).is_equal(2)
	for side: String in ["Port", "Starboard"]:
		assert_object(ship.get_node("Visuals/PortholeStern" + side) as Porthole).is_not_null()


func test_only_the_two_aisle_lanterns_cast_shadows() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	var room: AABB = AABB(Vector3(-5.7, 1.0, 7.9), Vector3(11.4, 4.0, 6.8))
	var shadowed: Array[String] = []
	for node: Node in ship.find_children("*", "Light3D", true, false):
		var light: Light3D = node as Light3D
		if light.is_visible_in_tree() and light.shadow_enabled \
				and room.has_point(ship.to_local(light.global_position)):
			shadowed.append(str(ship.get_path_to(light)))
	assert_array(shadowed).override_failure_message(
			"Lights casting shadows in the bunk room: %s" % [shadowed]).has_size(2)


func test_the_bunk_room_has_its_own_dim_ambient_light() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var probe: ReflectionProbe = ship.get_node("Visuals/BunkProbe") as ReflectionProbe
	assert_bool(probe.interior).is_true()
	assert_int(probe.ambient_mode).is_equal(ReflectionProbe.AMBIENT_COLOR)


func test_the_hammocks_hang_above_your_head() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 11))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	for name: String in ["HammockPort", "HammockStarboard"]:
		var hammock: Node3D = ship.get_node("BunkRoom/" + name) as Node3D
		for node: Node in hammock.find_children("*", "MeshInstance3D", true, false):
			var mesh: MeshInstance3D = node as MeshInstance3D
			var bottom: float = ship.to_local(mesh.global_position).y
			# The floor is 1 m up the ship and the player is 1.8 m tall.
			assert_float(bottom).override_failure_message("%s/%s hangs at %.2f" % [name,
					mesh.name, bottom]).is_greater(3.0)


func test_its_pieces_load_on_their_own() -> void:
	for piece: String in PIECES:
		var path: String = "res://scenes/prototype/%s.tscn" % piece
		var scene: PackedScene = load(path) as PackedScene
		assert_object(scene).override_failure_message("%s won't load" % path).is_not_null()
		var node: Node3D = scene.instantiate() as Node3D
		add_child(node)
		auto_free(node)


func test_you_can_walk_from_the_galley_door_to_the_stern() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-2.72, 1.05, 7.0))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_down", 90)

	# Through the door, past the hammocks and the chest, to the stern chests.
	assert_float(_player_on(ship, runner).z).is_greater(13.0)


func test_you_can_walk_from_the_ramp_foot_to_your_bunk() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-4.0, 1.05, 9.2))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 100)
	await walk(runner, "move_down", 60)

	# Along the aisle in front of the starboard bunks, to yours at the stern end.
	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.x).is_greater(3.6)
	assert_float(at.z).is_greater(12.8)


func _player_on(ship: Ship, runner: GdUnitSceneRunner) -> Vector3:
	var player: Player3D = runner.find_child("Player") as Player3D
	return ship.to_local(player.global_position)
