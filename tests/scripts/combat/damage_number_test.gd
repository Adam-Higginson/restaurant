extends GameTestSuite
## Tests for DamageNumber: a hit's damage popping up, rising, fading and
## going, bigger and gold for a critical. (How it looks isn't tested.)


func test_it_shows_the_damage_and_rises() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var number: DamageNumber = DamageNumber.spawn(player.get_parent(), Vector3(0, 1, 0), 10,
			false)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	assert_str(number.text).is_equal("10")
	await physics_ticks(runner, 20)
	assert_float(number.global_position.y).is_greater(1.2)


func test_it_fades_and_goes() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var number: DamageNumber = DamageNumber.spawn(player.get_parent(), Vector3(0, 1, 0), 10,
			false)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 40)
	assert_float(number.modulate.a).is_less(1.0)

	await physics_ticks(runner, 20)

	assert_bool(is_instance_valid(number)).is_false()


func test_a_critical_is_bigger_and_gold() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var plain: DamageNumber = DamageNumber.spawn(player.get_parent(), Vector3.ZERO, 10, false)
	var critical: DamageNumber = DamageNumber.spawn(player.get_parent(), Vector3.ZERO, 20, true)
	scene_runner(player.get_parent())

	assert_int(critical.font_size).is_greater(plain.font_size)
	assert_object(critical.modulate).is_equal(DamageNumber.CRITICAL_COLOUR)
	assert_object(plain.modulate).is_equal(DamageNumber.NORMAL_COLOUR)


func test_it_faces_the_camera_and_shows_through() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var number: DamageNumber = DamageNumber.spawn(player.get_parent(), Vector3.ZERO, 10, false)
	scene_runner(player.get_parent())

	assert_int(number.billboard).is_equal(BaseMaterial3D.BILLBOARD_ENABLED)
	assert_bool(number.no_depth_test).is_true()


func test_in_a_running_world_it_rises_from_where_it_was_made() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var world: Node3D = player.get_parent() as Node3D
	world.position = Vector3(5, 0, 0)
	var runner: GdUnitSceneRunner = scene_runner(world)
	await physics_ticks(runner, 1)

	var number: DamageNumber = DamageNumber.spawn(world, Vector3(2, 1, 3), 10, false)
	await physics_ticks(runner, 2)

	assert_float(number.global_position.x).is_equal_approx(2.0, 0.3)
	assert_float(number.global_position.z).is_equal_approx(3.0, 0.15)


func test_it_can_say_words_instead() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var label: DamageNumber = DamageNumber.spawn_words(player.get_parent(), Vector3(0, 1, 0),
			"Perfect!", Color.GOLD, true)
	scene_runner(player.get_parent())

	assert_str(label.text).is_equal("Perfect!")
	assert_object(label.modulate).is_equal(Color.GOLD)
