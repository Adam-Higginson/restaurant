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


func _bar(hud: Hud3D) -> HeartsBar:
	return hud.find_child("HeartsBar") as HeartsBar
