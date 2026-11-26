extends GameTestSuite
## Tests for the Grave of the Lanterns (scenes/prototype/intro/grave.tscn),
## seen from above the water in the rail scene (#182): a crowd of dead
## lanterns of which only a few still glow, the great chains hanging down
## through them, the thing that passes beneath, and the hand, kept out of
## sight until its moment.

const GRAVE: String = "res://scenes/prototype/intro/grave.tscn"
const CLIPS: Array[StringName] = [&"over_the_grave", &"that_one", &"passes_below",
		&"finds_the_hand"]


func test_a_chain_hangs_from_its_top_to_its_bottom() -> void:
	var chain: HangingChain = _new_chain(Vector3(0, 0, 0), Vector3(0, -10, -4))

	assert_int(chain.link_count()).is_greater(5)
	assert_vector(chain.point_at(0.0)).is_equal_approx(chain.top, Vector3.ONE * 0.001)
	assert_vector(chain.point_at(1.0)).is_equal_approx(chain.bottom, Vector3.ONE * 0.001)
	# It sags: halfway along it's below the straight line between its ends.
	var straight: Vector3 = (chain.top + chain.bottom) * 0.5
	assert_float(chain.point_at(0.5).y).is_less(straight.y)


func test_a_longer_chain_has_more_links_and_follows_its_ends() -> void:
	var chain: HangingChain = _new_chain(Vector3(0, 0, 0), Vector3(0, -5, 0))
	var short: int = chain.link_count()

	chain.bottom = Vector3(0, -20, 0)

	assert_int(chain.link_count()).is_greater(short)
	# (The links' own transforms live in the renderer, which isn't there in
	# a headless run, so it's the curve they're strung along that's checked.)
	assert_float(chain.point_at(0.95).y).is_less(-15.0)


func test_the_grave_is_a_crowd_of_dead_lanterns_and_only_a_few_still_glow() -> void:
	var grave: Node3D = _new_grave()
	var field: LanternField = grave.get_node("Lanterns") as LanternField

	assert_int(field.count()).is_greater(100)
	var glowing: int = 0
	for child: Node in field.get_children():
		var glass: GeometryInstance3D = child.get_node_or_null("Glass") as GeometryInstance3D
		if glass == null:
			continue
		# Most lanterns never set it, and have none.
		if glass.get_instance_shader_parameter(&"ember") == null:
			continue
		var ember: float = glass.get_instance_shader_parameter(&"ember")
		if ember > 0.0:
			glowing += 1
	assert_int(glowing).is_between(3, 12)


func test_its_chains_hang_down_into_the_dark() -> void:
	var grave: Node3D = _new_grave()
	var chains: int = 0
	for child: Node in grave.get_children():
		var chain: HangingChain = child as HangingChain
		if chain == null:
			continue
		chains += 1
		assert_int(chain.link_count()).is_greater(20)
		assert_float(chain.bottom.y).is_less(-30.0)
	assert_int(chains).is_greater_equal(2)


func test_the_hand_is_out_of_sight_until_its_moment() -> void:
	var grave: Node3D = _new_grave()
	var overboard: Node3D = grave.get_node("Overboard") as Node3D
	var clips: AnimationPlayer = grave.get_node("Clips") as AnimationPlayer
	var you: CharacterModel = grave.get_node("Overboard/Figure/Character") as CharacterModel
	assert_bool(overboard.visible).is_false()

	_jump_to_end(clips, &"over_the_grave")
	assert_bool(overboard.visible).is_false()
	_jump_to_end(clips, &"passes_below")
	assert_bool(overboard.visible).is_false()

	_jump_to_end(clips, &"finds_the_hand")
	assert_bool(overboard.visible).is_true()
	assert_bool(you.eyes_shut).is_true()
	assert_float(you.reach).is_equal(0.0)


func test_the_thing_passes_from_one_side_to_the_other_far_below() -> void:
	var grave: Node3D = _new_grave()
	var clips: AnimationPlayer = grave.get_node("Clips") as AnimationPlayer
	var thing: Node3D = grave.get_node("Thing") as Node3D

	clips.play(&"passes_below")
	clips.seek(0.0, true)
	var from: Vector3 = thing.position
	_jump_to_end(clips, &"passes_below")
	var to: Vector3 = thing.position

	assert_float(from.x).is_less(-50.0)
	assert_float(to.x).is_greater(50.0)
	assert_float(to.y).is_less(-20.0)


func test_every_camera_move_the_script_asks_for_is_there() -> void:
	var grave: Node3D = _new_grave()
	var clips: AnimationPlayer = grave.get_node("Clips") as AnimationPlayer
	assert_bool(clips.is_in_group(ClipCues.GROUP)).is_true()
	for clip: StringName in CLIPS:
		assert_bool(clips.has_animation(clip)).override_failure_message(
				"no clip called '%s'" % clip).is_true()


func test_each_camera_move_starts_where_the_one_before_it_ends() -> void:
	var grave: Node3D = _new_grave()
	var clips: AnimationPlayer = grave.get_node("Clips") as AnimationPlayer
	var camera: Camera3D = grave.get_node("Camera") as Camera3D
	# In the script: over_the_grave then that_one; passes_below then
	# finds_the_hand. Neither second move may jump.
	for pair: Array[StringName] in [[&"over_the_grave", &"that_one"] as Array[StringName],
			[&"passes_below", &"finds_the_hand"] as Array[StringName]]:
		_jump_to_end(clips, pair[0])
		var ended: Vector3 = camera.position
		clips.play(pair[1])
		clips.seek(0.0, true)
		assert_vector(camera.position).is_equal_approx(ended, Vector3.ONE * 0.01)


func _jump_to_end(clips: AnimationPlayer, clip: StringName) -> void:
	clips.play(clip)
	clips.seek(clips.get_animation(clip).length, true)
	clips.pause()


func _new_grave() -> Node3D:
	var grave: Node3D = (load(GRAVE) as PackedScene).instantiate() as Node3D
	add_child(grave)
	auto_free(grave)
	return grave


func _new_chain(top: Vector3, bottom: Vector3) -> HangingChain:
	var chain: HangingChain = HangingChain.new()
	chain.top = top
	chain.bottom = bottom
	add_child(chain)
	auto_free(chain)
	return chain
