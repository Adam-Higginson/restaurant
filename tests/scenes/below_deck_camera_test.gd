extends GameTestSuite
## Tests that the free camera stays inside the rooms below deck: the galley's
## and the bunk room's ceilings (and their beams) stop its spring arm, so
## zooming right out never lifts it into the dark space under the deck.

## Ship space: the underside of each room's ceiling planks.
const GALLEY_CEILING_Y: float = 3.6
const BUNK_CEILING_Y: float = 4.0


func test_zoomed_out_in_the_galley_the_camera_stays_under_its_ceiling() -> void:
	var camera_y: float = await _camera_height_zoomed_out(Vector3(0.0, 1.05, 3.0), 120.0)
	assert_float(camera_y).is_less(GALLEY_CEILING_Y)


func test_zoomed_out_in_the_bunk_room_the_camera_stays_under_its_ceiling() -> void:
	var camera_y: float = await _camera_height_zoomed_out(Vector3(-4.0, 1.05, 11.3), 90.0)
	assert_float(camera_y).is_less(BUNK_CEILING_Y)


## Stands the player at [param pos], zooms the camera all the way out looking
## down from above and behind, and returns how high (in ship space) it ends up.
func _camera_height_zoomed_out(pos: Vector3, yaw_degrees: float) -> float:
	var pair: Array[Node3D] = new_moored_ship_with_player(pos)
	var ship: Ship = pair[0] as Ship
	var player: Player3D = pair[1] as Player3D
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)
	var rig: CameraRig = player.camera_rig
	rig.yaw = deg_to_rad(yaw_degrees)
	rig.pitch = deg_to_rad(-30.0)
	rig.zoom = rig.zoom_max
	# The arm eases out to its new length over about half a second.
	await physics_ticks(runner, 90)
	var camera: Camera3D = rig.get_node("Camera3D") as Camera3D
	return ship.to_local(camera.global_position).y
