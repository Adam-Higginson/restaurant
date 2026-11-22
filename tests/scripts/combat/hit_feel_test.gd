extends GameTestSuite
## Tests for HitFeel: each kind of blow freezes the game for its own length,
## shakes the camera, and a blow landing on the player muffles the sound for
## a moment.
##
## The player stands at the origin facing -Z with the crab just ahead. The
## crab is open from about tick 64 (see duellist_test.gd).

const PAN: Item = preload("res://data/items/frying_pan.tres")
const CLOSE: Vector3 = Vector3(0, 0, -1.3)
## Ticks until the crab is open after its first attack: its blow lands
## about tick 49 and freezes the game for a moment.
const FIRST_OPENING: int = 70 + HitStop.HURT_TICKS


func after_test() -> void:
	Engine.time_scale = 1.0


func test_a_strike_that_counts_freezes_the_game_briefly() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)

	duellist_of(player).strike()

	assert_int(_hit_stop(player).ticks_left).is_equal(HitStop.STRIKE_TICKS)
	assert_float(player.camera_rig.shake_amount()).is_greater(0.0)


func test_the_strike_that_clears_the_fog_freezes_longer() -> void:
	var player: Player3D = new_player_3d_on_floor()
	stand_firm(player)
	var crab: FogCrab = new_fog_crab(player, CLOSE)
	crab.strikes_to_clear = 1
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, FIRST_OPENING)

	duellist_of(player).strike()

	assert_bool(crab.is_cleared()).is_true()
	assert_int(_hit_stop(player).ticks_left).is_equal(HitStop.CLEARING_TICKS)


func test_a_strike_that_doesnt_count_doesnt_freeze() -> void:
	var player: Player3D = new_player_3d_on_floor()
	new_fog_crab(player, CLOSE)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	# Still rearing up: not open.
	await physics_ticks(runner, 10)

	duellist_of(player).strike()

	assert_bool(_hit_stop(player).is_frozen()).is_false()


func test_a_blow_landing_freezes_the_game_and_shakes_hardest() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(1, CLOSE)

	assert_int(_hit_stop(player).ticks_left).is_equal(HitStop.HURT_TICKS)
	assert_float(player.camera_rig.shake_amount()).is_equal(_feel(player).hurt_shake)


func test_a_parry_freezes_the_game() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	player.toolbar.add(ItemInstance.new(PAN))
	await physics_ticks(runner, 2)
	duellist_of(player).raise_pan()

	duellist_of(player).receive_hit(1, CLOSE)

	assert_int(_hit_stop(player).ticks_left).is_equal(HitStop.PARRY_TICKS)


func test_the_camera_shake_fades_once_the_freeze_ends() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).receive_hit(1, CLOSE)
	await physics_ticks(runner, 60)

	assert_float(player.camera_rig.shake_amount()).is_equal(0.0)


func test_a_blow_landing_muffles_the_sound_then_it_clears() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	var master: int = AudioServer.get_bus_index(&"Master")

	duellist_of(player).receive_hit(1, CLOSE)

	assert_bool(AudioServer.is_bus_effect_enabled(master, 0)).is_true()
	assert_float(_feel(player).muffle).is_greater(0.5)
	# The freeze, then the muffle's 0.8 s.
	await physics_ticks(runner, HitStop.HURT_TICKS + 60)
	assert_float(_feel(player).muffle).is_equal(0.0)
	assert_bool(AudioServer.is_bus_effect_enabled(master, 0)).is_false()


func test_the_master_bus_has_the_muffle_switched_off() -> void:
	var master: int = AudioServer.get_bus_index(&"Master")

	var effect: AudioEffect = AudioServer.get_bus_effect(master, 0)

	assert_object(effect).is_instanceof(AudioEffectLowPassFilter)
	assert_str(effect.resource_name).is_equal(String(HitFeel.MUFFLE_EFFECT))
	assert_bool(AudioServer.is_bus_effect_enabled(master, 0)).is_false()


func test_the_muffle_falls_evenly_through_the_octaves() -> void:
	assert_float(HitFeel.muffle_hz(0.0)).is_equal_approx(HitFeel.CLEAR_HZ, 0.1)
	assert_float(HitFeel.muffle_hz(1.0)).is_equal_approx(HitFeel.MUFFLED_HZ, 0.1)
	# Halfway is the geometric middle: sqrt(20000 * 500).
	assert_float(HitFeel.muffle_hz(0.5)).is_equal_approx(3162.3, 0.5)


func _hit_stop(player: Player3D) -> HitStop:
	return player.get_node("HitStop") as HitStop


func _feel(player: Player3D) -> HitFeel:
	return player.get_node("HitFeel") as HitFeel
