extends GameTestSuite
## Tests for the navigation room (#185), forward of the galley's port side:
## its doors (from the galley, #204, and at the forward end of the hatch
## corridor) are open and the rest of the bulkhead isn't, its own walls close
## it in, you can walk in from the galley to the old book on its shelf (no
## longer in the galley), and you can look at the chart.

## Where things are, in ship space.
const CORRIDOR: Vector3 = Vector3(-4.55, 1.6, 2.6)
const IN_THE_ROOM: Vector3 = Vector3(-4.55, 1.6, -1.0)
const BY_THE_TABLE: Vector3 = Vector3(-1.2, 1.05, -1.45)
const TABLE: Vector3 = Vector3(-2.5, 1.5, -1.45)
## In the galley, in front of the door to the navigation room.
const GALLEY_BY_THE_DOOR: Vector3 = Vector3(-2.835, 1.05, 2.3)


func before_test() -> void:
	Game.dialogue.reset()


func after_test() -> void:
	Game.dialogue.reset()


func test_the_door_at_the_end_of_the_corridor_is_open() -> void:
	var ship: Ship = await _ship()

	assert_bool(_blocked(ship, CORRIDOR, IN_THE_ROOM)).is_false()


func test_the_rest_of_the_bulkhead_is_still_a_wall() -> void:
	var ship: Ship = await _ship()

	# Beside the door, and across the galley's forward wall.
	for x: float in [-3.4, -2.0, 1.0, 4.0]:
		assert_bool(_blocked(ship, Vector3(x, 1.6, 2.4), Vector3(x, 1.6, -0.5))) \
				.override_failure_message("open at x %.1f" % x).is_true()


func test_the_rooms_own_walls_close_it_in() -> void:
	var ship: Ship = await _ship()

	# Forward, and to starboard: the rest of the bow is shut away.
	assert_bool(_blocked(ship, Vector3(-2.0, 1.6, -3.0), Vector3(-2.0, 1.6, -4.5))).is_true()
	assert_bool(_blocked(ship, Vector3(-0.6, 1.6, -1.0), Vector3(0.8, 1.6, -1.0))).is_true()
	# And a ceiling over it, as over the galley.
	assert_bool(_blocked(ship, Vector3(-3.0, 2.0, -1.0), Vector3(-3.0, 4.6, -1.0))).is_true()


func test_the_old_book_is_on_its_shelf_and_not_in_the_galley() -> void:
	var ship: Ship = await _ship()

	var book: ReadableBook = ship.get_node_or_null("NavigationRoom/OldBook") as ReadableBook
	assert_object(book).is_not_null()
	assert_str(String(book.read_flag)).is_equal("read_fire_spirits")
	assert_object(ship.find_child("OldBook", true, false)).is_same(book)


func test_you_can_look_at_the_chart() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(BY_THE_TABLE)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var conversation: Conversation = new_conversation(player)
	var said: Array[String] = []
	conversation.line_said.connect(func(_speaker: Person) -> void:
		said.append(conversation.box.line_text() if conversation.box != null else ""))
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 2)
	player.face_towards(ship.to_global(TABLE))
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	await physics_ticks(runner, 3)
	assert_str(detector.interact_prompt()).is_equal("Look at the chart")

	await press(runner, "interact")

	assert_bool(conversation.is_active()).is_true()
	assert_int(said.size()).is_equal(1)


# The ship, with a player aboard, after a few ticks so its shapes are placed.
func _ship() -> Ship:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 1.05, 6))
	var ship: Ship = rig[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)
	return ship


# Whether anything solid of the ship's lies between [param from] and
# [param to], both in ship space.
func _blocked(ship: Ship, from: Vector3, to: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = ship.get_world_3d().direct_space_state
	var ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
			ship.to_global(from), ship.to_global(to))
	return not space.intersect_ray(ray).is_empty()


func test_you_walk_in_from_the_galley_and_reach_the_old_book() -> void:
	# The corridor's door is shut in under the hatch stairs, so the room's way
	# in is a door from the galley (#204), port of the pantry.
	var rig: Array[Node3D] = new_moored_ship_with_player(GALLEY_BY_THE_DOOR)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)

	# Forward through the door, to port across the room, and forward again to
	# the shelf.
	await walk(runner, "move_up", 30)
	assert_float(ship.to_local(player.global_position).z).override_failure_message(
			"Stopped at %s, short of the room" % ship.to_local(player.global_position)) \
			.is_less(0.0)
	await walk(runner, "move_left", 18)
	await walk(runner, "move_up", 22)
	var at: Vector3 = ship.to_local(player.global_position)
	assert_bool(at.x < -4.0 and at.z < -1.5).override_failure_message(
			"Stopped at %s, short of the shelf" % at).is_true()

	var book: ReadableBook = ship.get_node("NavigationRoom/OldBook") as ReadableBook
	player.face_towards(book.global_position)
	await physics_ticks(runner, 3)
	var detector: InteractionDetector3D = player.get_node("InteractionDetector") \
			as InteractionDetector3D
	assert_str(detector.interact_prompt()).override_failure_message(
			"At %s the prompt is '%s'" % [ship.to_local(player.global_position),
			detector.interact_prompt()]).contains("Read the old book")
