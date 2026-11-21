extends GameTestSuite
## Tests for CameraZone: walking in and out switches the player's camera
## between the zone's fixed shot and the free camera, and the galley on the
## ship has a zone that covers the room below deck but not the deck.

const SHIP_SCENE: String = "res://scenes/prototype/ship.tscn"
const PLAYER_SCENE: String = "res://scenes/prototype/player.tscn"
## Standing on the galley floor, in the ship's own space.
const IN_GALLEY: Vector3 = Vector3(0.0, 1.05, 8.0)
## Standing on the aft deck, above the galley, in the ship's own space.
const ON_DECK: Vector3 = Vector3(1.5, 4.05, 8.0)
const NEAR: Vector3 = Vector3(0.1, 0.1, 0.1)


func test_walking_in_uses_the_zone_shot() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var zone: CameraZone = _add_zone_ahead(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)
	assert_object(player.camera_rig.active_zone).is_null()

	# The free camera looks along -Z, so up walks into the zone 3 m ahead.
	await walk(runner, "move_up", 40)

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
	await walk(runner, "move_up", 60)

	assert_object(player.camera_rig.active_zone).is_null()
	# Out, and still going: holding up didn't flip round with the camera and
	# walk back in (5 m/s for a second, from z = -5).
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


func test_the_galley_has_a_fixed_shot() -> void:
	var rig: Array[Node3D] = _new_ship_with_player(IN_GALLEY)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())

	await physics_ticks(runner, 5)

	assert_object(player.camera_rig.active_zone).is_same(ship.get_node("GalleyCameraZone"))


func test_the_deck_keeps_the_free_camera() -> void:
	var rig: Array[Node3D] = _new_ship_with_player(ON_DECK)
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(rig[0].get_parent())

	# Long enough to land on the deck.
	await physics_ticks(runner, 10)

	assert_bool(player.is_on_floor()).is_true()
	assert_object(player.camera_rig.active_zone).is_null()


func test_the_galley_shot_sails_with_the_ship() -> void:
	var rig: Array[Node3D] = _new_ship_with_player(IN_GALLEY)
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	var camera: Camera3D = player.camera_rig.get_node("Camera3D") as Camera3D
	var shot: Marker3D = ship.get_node("GalleyCameraZone/Shot") as Marker3D
	player.camera_rig.blend_seconds = 0.0
	await physics_ticks(runner, 5)
	ship.set_sail()

	await physics_ticks(runner, 60)

	assert_float(ship.global_position.length()).is_greater(2.0)
	assert_vector(camera.global_position).is_equal_approx(shot.global_position, NEAR)


# A zone 4 m across, from 3 to 7 m ahead of the player (along -Z), whose shot
# is at its far end looking back towards the player (along +Z).
func _add_zone_ahead(player: Player3D) -> CameraZone:
	var shot: Transform3D = Transform3D(Basis(Vector3.UP, PI), Vector3(0, 2, -2))
	var zone: CameraZone = new_camera_zone(Vector3(4, 2, 4), Vector3(0, 1, -5), shot)
	player.get_parent().add_child(zone)
	return zone


# A moored ship at the origin facing -Z (so ship space is world space), with
# the player at [param pos]. Returns [ship, player]. Hand the ship's parent to
# scene_runner to start it.
func _new_ship_with_player(pos: Vector3) -> Array[Node3D]:
	var world: Node3D = Node3D.new()
	auto_free(world)
	var route: Path3D = Path3D.new()
	route.curve = Curve3D.new()
	route.curve.add_point(Vector3.ZERO)
	route.curve.add_point(Vector3(0, 0, -200))
	world.add_child(route)
	var ship: Ship = (load(SHIP_SCENE) as PackedScene).instantiate() as Ship
	ship.route = route
	ship.sail_on_ready = false
	world.add_child(ship)
	var player: Player3D = (load(PLAYER_SCENE) as PackedScene).instantiate() as Player3D
	player.position = pos
	world.add_child(player)
	return [ship, player]
