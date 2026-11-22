extends GameTestSuite
## Tests for HeartsBar: the HUD shows the player's hearts and follows them.
## (How the hearts are drawn isn't tested.)


func test_it_shows_the_players_hearts() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: HeartsBar = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())

	assert_bool(bar.visible).is_true()
	assert_int(bar.shown_halves).is_equal(6)


func test_it_follows_hits_and_refills() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: HeartsBar = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())
	var hearts: Hearts = duellist_of(player).hearts
	assert_bool(hearts.changed.is_connected(bar._on_hearts_changed)).is_true()

	hearts.hurt()
	assert_int(bar.shown_halves).is_equal(5)

	hearts.refill()
	assert_int(bar.shown_halves).is_equal(6)


func test_the_heart_a_blow_takes_from_cracks_for_a_moment() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: HeartsBar = _bar(new_hud_3d(player))
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	assert_int(bar.cracked_heart).is_equal(-1)

	duellist_of(player).hearts.hurt()
	assert_int(bar.cracked_heart).is_equal(2)
	await physics_ticks(runner, 60)

	assert_int(bar.cracked_heart).is_equal(-1)


func test_refilling_mends_the_crack() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var bar: HeartsBar = _bar(new_hud_3d(player))
	scene_runner(player.get_parent())
	var hearts: Hearts = duellist_of(player).hearts
	hearts.hurt()

	hearts.refill()

	assert_int(bar.cracked_heart).is_equal(-1)


func test_the_cracked_heart_is_the_one_holding_the_half_lost() -> void:
	# Full to half: the third heart.
	assert_int(HeartsBar.heart_hit(6, 5)).is_equal(2)
	# Half to empty: still the third.
	assert_int(HeartsBar.heart_hit(5, 4)).is_equal(2)
	# A whole heart from full, then into the second.
	assert_int(HeartsBar.heart_hit(6, 4)).is_equal(2)
	assert_int(HeartsBar.heart_hit(4, 3)).is_equal(1)
	# Going up is no blow.
	assert_int(HeartsBar.heart_hit(3, 6)).is_equal(-1)


func _bar(hud: Hud3D) -> HeartsBar:
	return hud.find_child("HeartsBar") as HeartsBar
