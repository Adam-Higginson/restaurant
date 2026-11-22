extends GameTestSuite
## Tests for HurtOverlay: a blow landing flashes the screen and brings the
## fog in at its edges, both fading, and the colour drains away while the
## player is on their last heart. (How it looks isn't tested.)


func test_it_shows_nothing_until_a_blow_lands() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var overlay: HurtOverlay = _overlay(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 5)

	assert_bool(overlay.visible).is_false()
	assert_float(overlay.flash).is_equal(0.0)
	assert_float(overlay.fog).is_equal(0.0)


func test_a_blow_flashes_and_fogs_the_screen_then_it_clears() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var overlay: HurtOverlay = _overlay(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(1, Vector3(0, 0, -1))

	assert_bool(overlay.visible).is_true()
	assert_float(overlay.flash).is_equal(1.0)
	assert_float(overlay.fog).is_equal(1.0)
	# The freeze, then the fog's 1.2 s.
	await physics_ticks(runner, HitStop.HURT_TICKS + 80)
	assert_float(overlay.flash).is_equal(0.0)
	assert_float(overlay.fog).is_equal(0.0)
	assert_bool(overlay.visible).is_false()


func test_on_the_last_heart_the_colour_drains_and_comes_back_on_refill() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var overlay: HurtOverlay = _overlay(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var hearts: Hearts = duellist_of(player).hearts

	hearts.hurt(4)
	await physics_ticks(runner, 60)
	assert_float(overlay.drain).is_equal(1.0)
	assert_bool(overlay.visible).is_true()

	hearts.refill()
	await physics_ticks(runner, 60)
	assert_float(overlay.drain).is_equal(0.0)


func test_it_sits_under_the_rest_of_the_hud() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var overlay: HurtOverlay = _overlay(new_hud_3d(player))
	scene_runner(player.get_parent())

	# Drawn first, so the hearts and toolbar draw over it, untouched.
	assert_int(overlay.get_index()).is_equal(0)
	assert_int(overlay.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func _overlay(hud: Hud3D) -> HurtOverlay:
	return hud.find_child("HurtOverlay") as HurtOverlay
