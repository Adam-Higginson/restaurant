extends GameTestSuite
## Tests for the bunk room aft of the galley: bunks down both sides, your own
## bunk, the stern windows, its low ceiling, the stove in the middle, its
## light, and room to walk. The player walks at 5 m/s, so 12 physics ticks a
## metre; up on the stick is towards the bow, down towards the stern, right
## towards starboard.

## Our own pieces that dress the bunk room (#88).
const PIECES: Array[String] = [
	"props/bunk_bay", "props/sea_chest", "props/crate", "dressing/hammock",
	"dressing/hammock_blanket", "dressing/boots", "dressing/sock_line", "dressing/fiddle",
	"dressing/kit_bag", "dressing/book_stack", "dressing/sketchbook",
	"dressing/fishing_tackle", "dressing/your_things", "props/bunk_stove", "dressing/candle",
	"dressing/folded_blankets", "dressing/yarn_basket", "dressing/sheepskin",
	"dressing/playing_cards", "dressing/pinned_drawing", "dressing/pinned_letter",
	"dressing/pressed_flower",
]
## Ship space: the bunk room's floor, and the underside of its ceiling.
const FLOOR_Y: float = 1.0
const CEILING_Y: float = 4.0


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


func test_only_the_stove_and_one_lantern_cast_shadows() -> void:
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
			"Lights casting shadows in the bunk room: %s" % [shadowed]) 			.contains_exactly_in_any_order(["BunkRoom/Stove/FireLight", "Visuals/BunkLantern/Light"])


func test_a_low_ceiling_closes_the_room_except_over_the_ramp() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(-2.72, 1.05, 7.0))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	# Looking straight up from head height: the middle, the port stern corner,
	# beside the hatch, and over your bunk's aisle.
	for spot: Vector3 in [Vector3(0, 2.6, 11.3), Vector3(-4.0, 2.6, 13.0), Vector3(-3.0, 2.6, 8.4),
			Vector3(4.0, 2.6, 13.5)]:
		var hit: float = _ceiling_above(ship, spot)
		assert_float(hit).override_failure_message("Above %s the ceiling is at %.2f" % [spot, hit]) 				.is_between(CEILING_Y - 0.05, CEILING_Y + 0.05)
	# Over the ramp's foot it's open up through the hatch.
	assert_float(_ceiling_above(ship, Vector3(-4.6, 2.6, 8.4))).is_equal(INF)


func test_the_stove_warms_the_middle_of_the_room() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 1.05, 9.3))[0] as Ship
	var stove: Node3D = ship.get_node("BunkRoom/Stove") as Node3D
	assert_float(absf(stove.position.x)).is_less(1.5)
	assert_float(stove.position.z).is_between(10.5, 13.0)
	var fire: Flicker = stove.get_node("FireLight") as Flicker
	assert_object(fire).is_not_null()
	assert_bool(fire.shadow_enabled).is_true()


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


func test_you_can_walk_round_the_stove() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(1.8, 1.05, 9.3))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	await walk(runner, "move_right", 40)
	await walk(runner, "move_down", 50)
	await walk(runner, "move_left", 80)

	# Along the front, down past the starboard bunks, and back across the
	# stern behind the stove, to the door's side of the room.
	var at: Vector3 = _player_on(ship, runner)
	assert_float(at.x).is_less(-1.5)
	assert_float(at.z).is_greater(13.0)


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


## How high (in ship space) a ray going straight up from [param from] first
## hits something, or INF if nothing is there before the deck's top.
func _ceiling_above(ship: Ship, from: Vector3) -> float:
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ship.to_global(from), ship.to_global(Vector3(from.x, 5.6, from.z)))
	var hit: Dictionary = ship.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return INF
	var point: Vector3 = hit["position"]
	return ship.to_local(point).y


func _player_on(ship: Ship, runner: GdUnitSceneRunner) -> Vector3:
	var player: Player3D = runner.find_child("Player") as Player3D
	return ship.to_local(player.global_position)
