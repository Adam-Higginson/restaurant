extends GameTestSuite
## Tests for the small life of an island: gulls wheeling (GullFlock) and
## coconuts that roll when you walk into them (Coconut).

const COCONUT: String = "res://scenes/prototype/islands/props/coconut.tscn"


func test_gulls_fly_in_their_band_of_sky() -> void:
	var flock: GullFlock = _new_flock()
	for index: int in flock.count:
		for moment: int in 20:
			var gull: Vector3 = flock.gull_at(index, moment * 1.7).origin
			# Between the lowest and highest they fly, give or take their dip.
			assert_float(gull.y).is_between(flock.height.x - 1.3, flock.height.y + 1.3)
			assert_float(absf(gull.x - flock.centre.x)).is_less(flock.spread.x + flock.circle.y + 0.01)
			assert_float(absf(gull.z - flock.centre.z)).is_less(flock.spread.y + flock.circle.y + 0.01)


func test_gulls_keep_flying_and_face_the_way_they_go() -> void:
	var flock: GullFlock = _new_flock()
	for index: int in flock.count:
		var now: Transform3D = flock.gull_at(index, 3.0)
		var soon: Transform3D = flock.gull_at(index, 3.2)
		var moved: Vector3 = soon.origin - now.origin
		moved.y = 0.0
		assert_float(moved.length()).is_greater(0.5)
		# A gull's beak is towards its own -Z.
		var beak: Vector3 = -now.basis.z
		beak.y = 0.0
		assert_float(beak.normalized().dot(moved.normalized())).is_greater(0.9)


func test_the_same_seed_gives_the_same_flock() -> void:
	var first: GullFlock = _new_flock()
	var second: GullFlock = _new_flock()
	assert_vector(first.gull_at(2, 5.0).origin).is_equal(second.gull_at(2, 5.0).origin)


func test_a_coconut_rolls_when_you_walk_into_it() -> void:
	var coconut: Coconut = _new_coconut()
	var kicks: Dictionary[String, int] = {"count": 0}
	coconut.kicked.connect(func() -> void: kicks["count"] += 1)
	var beside: Vector3 = coconut.global_position + Vector3(-0.3, 0.0, 0.0)
	assert_bool(coconut.try_kick(beside, Vector3(3.0, 0.0, 0.0))).is_true()
	assert_int(kicks["count"]).is_equal(1)
	await get_tree().physics_frame
	await get_tree().physics_frame
	# It goes the way you were going, and hops.
	assert_float(coconut.linear_velocity.x).is_greater(0.5)
	assert_float(coconut.linear_velocity.y).is_greater(0.0)


func test_a_coconut_stays_put_if_youre_far_or_slow() -> void:
	var coconut: Coconut = _new_coconut()
	var far: Vector3 = coconut.global_position + Vector3(-3.0, 0.0, 0.0)
	var beside: Vector3 = coconut.global_position + Vector3(-0.3, 0.0, 0.0)
	assert_bool(coconut.try_kick(far, Vector3(3.0, 0.0, 0.0))).is_false()
	assert_bool(coconut.try_kick(beside, Vector3(0.2, 0.0, 0.0))).is_false()
	# Falling past it doesn't count as walking into it.
	assert_bool(coconut.try_kick(beside, Vector3(0.0, -9.0, 0.0))).is_false()


func test_a_coconut_never_blocks_the_player() -> void:
	var coconut: Coconut = _new_coconut()
	var player: Player3D = new_player_3d_on_floor()
	# Nothing on the player's layer, so the player's body can't run into it.
	assert_int(coconut.collision_layer & player.collision_mask).is_equal(0)
	# But it does rest on the ground, which is on layer 1.
	assert_int(coconut.collision_mask & 1).is_equal(1)


func _new_flock() -> GullFlock:
	var flock: GullFlock = GullFlock.new()
	auto_free(flock)
	flock.count = 6
	flock.flock_seed = 11
	# Tests ask where the gulls are themselves.
	flock.set_process(false)
	add_child(flock)
	return flock


func _new_coconut() -> Coconut:
	var coconut: Coconut = (load(COCONUT) as PackedScene).instantiate() as Coconut
	auto_free(coconut)
	add_child(coconut)
	coconut.global_position = Vector3(0.0, 5.0, 0.0)
	return coconut
