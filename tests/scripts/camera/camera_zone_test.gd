extends GameTestSuite
## Tests for CameraZone: walking in and out switches the player's camera
## between the zone's fixed shot and the free camera, and a zone on the ship
## sails with it. The galley itself uses the free camera, like the deck.

## Standing on the galley floor, in the ship's own space.
const IN_GALLEY: Vector3 = Vector3(0.0, 1.05, 8.0)
## Standing on the aft deck, above the galley, in the ship's own space.
const ON_DECK: Vector3 = Vector3(1.5, 5.35, 11.0)
const NEAR: Vector3 = Vector3(0.1, 0.1, 0.1)


func test_walking_in_uses_the_zone_shot() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var zone: CameraZone = _add_zone_ahead(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	assert_object(player.camera_rig.active_zone).is_null()

	# The free camera looks along -Z, so up walks into the zone 3 m ahead.
	await walk(runner, "move_up", 60)

	assert_object(player.camera_rig.active_zone).is_same(zone)


func test_walking_out_restores_the_free_camera() -> void:
	var player: Player3D = new_player_3d_on_floor()
	_add_zone_ahead(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.camera_rig.blend_seconds = 0.0
	place_player_3d(runner, Vector3(0, 0, -5))
	await physics_ticks(runner, 5)
	assert_object(player.camera_rig.active_zone).is_not_null()

	# The shot looks along +Z, so up walks out of the zone's near side.
	await walk(runner, "move_up", 90)

	assert_object(player.camera_rig.active_zone).is_null()
	# Out, and still going: holding up didn't flip round with the camera and
	# walk back in (3.5 m/s for a second and a half, from z = -5).
	assert_float(player.global_position.z).is_greater(-1.0)


func test_other_bodies_are_ignored() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var world: Node3D = player.get_parent() as Node3D
	_add_zone_ahead(player)
	# A crate inside the zone: the zone sees it, but it has no camera.
	world.add_child(static_box(Vector3(1, 1, 1), Vector3(0, 0.5, -5)))
	var runner: GdUnitSceneRunner = scene_runner(world)

	await physics_ticks(runner, 5)

	assert_object(player.camera_rig.active_zone).is_null()


func test_the_galley_keeps_the_free_camera() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(IN_GALLEY)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())

	await physics_ticks(runner, 10)

	assert_bool(player.is_on_floor()).is_true()
	assert_object(player.camera_rig.active_zone).is_null()


func test_the_deck_keeps_the_free_camera() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(ON_DECK)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())

	# Long enough to land on the deck.
	await physics_ticks(runner, 10)

	assert_bool(player.is_on_floor()).is_true()
	assert_object(player.camera_rig.active_zone).is_null()


func test_a_zone_on_the_ship_sails_with_it() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(IN_GALLEY)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	# A zone around the player, with its shot up in a corner of the galley.
	var shot_spot: Transform3D = Transform3D(Basis.IDENTITY, Vector3(3, 2.5, 3))
	var zone: CameraZone = new_camera_zone(Vector3(4, 3, 4), IN_GALLEY + Vector3.UP, shot_spot)
	ship.add_child(zone)
	var camera: Camera3D = player.camera_rig.get_node("Camera3D") as Camera3D
	player.camera_rig.blend_seconds = 0.0
	await physics_ticks(runner, 5)
	assert_object(player.camera_rig.active_zone).is_same(zone)
	ship.set_sail()

	await physics_ticks(runner, 60)
	# Stop, then let a few frames draw. The camera moves once per drawn frame,
	# so while sailing it trails by however many ticks a slow machine runs
	# between frames.
	ship.speed = 0.0
	await physics_ticks(runner, 10)

	assert_float(ship.global_position.length()).is_greater(2.0)
	assert_vector(camera.global_position).is_equal_approx(zone.shot.global_position, NEAR)


# A zone 4 m across, from 3 to 7 m ahead of the player (along -Z), whose shot
# is at its far end looking back towards the player (along +Z).
func _add_zone_ahead(player: Player3D) -> CameraZone:
	var shot: Transform3D = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2, -2))
	var zone: CameraZone = new_camera_zone(Vector3(4, 2, 4), Vector3(0, 1, -5), shot)
	player.get_parent().add_child(zone)
	return zone
