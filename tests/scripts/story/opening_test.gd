extends GameTestSuite
## Tests for how the game begins: black and a title, then you wake by your
## bunk, unable to move until the fade's done, and the lantern says his first
## words. Skipped, you start where you stand.


func test_you_wake_by_your_bunk_and_the_lantern_speaks() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var opening: Opening = _opening(ship, player, false)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 3)

	assert_bool(opening.is_playing).is_true()
	assert_bool(player.controls_enabled).is_false()
	var at: Vector3 = ship.to_local(player.global_position)
	assert_float(at.distance_to(opening.wake_spot)).is_less(0.3)

	await physics_ticks(runner, 40)

	assert_bool(opening.is_playing).is_false()
	assert_bool(player.controls_enabled).is_true()
	var spirit: LanternSpirit = player.get_node("LanternSpirit") as LanternSpirit
	assert_str(spirit.saying()).is_equal(Opening.FIRST_WORDS[0])


func test_you_stay_aboard_while_the_ship_sails_on() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var opening: Opening = _opening(ship, player, false)
	opening.title_seconds = 1.0
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()

	await physics_ticks(runner, 90)

	# Still by the bunk, give or take settling onto the floor; left behind, the
	# ship would have sailed metres away.
	var at: Vector3 = ship.to_local(player.global_position)
	assert_float(at.distance_to(opening.wake_spot)).is_less(0.6)


func test_skipped_you_start_where_you_stand() -> void:
	var rig: Array[Node3D] = new_moored_ship_with_player(Vector3(0, 5.35, 7.5))
	var ship: Ship = rig[0] as Ship
	var player: Player3D = rig[1] as Player3D
	var opening: Opening = _opening(ship, player, true)
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	await physics_ticks(runner, 5)

	assert_bool(opening.is_playing).is_false()
	assert_float(ship.to_local(player.global_position).y).is_greater(5.0)


# An opening with a quick title and fades, added to the ship's world.
func _opening(ship: Ship, player: Player3D, skip: bool) -> Opening:
	var opening: Opening = Opening.new()
	opening.skip = skip
	opening.player = player
	opening.ship = ship
	opening.title_seconds = 0.1
	var fade: ScreenFade = (load("res://ui/screen_fade.tscn") as PackedScene).instantiate() \
			as ScreenFade
	fade.name = "ScreenFade"
	fade.fade_seconds = 0.1
	opening.add_child(fade)
	ship.get_parent().add_child(opening)
	return opening
