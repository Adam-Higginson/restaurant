extends GameTestSuite
## Tests for CharacterModel: the player built from pack files when they're
## there, the greybox when they aren't, the head cut off a whole body, the
## animations copied over without stretching our proportions, the pose
## following what the player does, the knife and pan in the character's
## hands, and a new look when who you are changes.
##
## Built from small stand-ins in tests/fixtures/character/ (the real packs
## aren't in the repo): an outfit with the pack skeleton's key bones, a head,
## hair and an animation file with one short animation per pose.

const FIXTURES: String = "res://tests/fixtures/character/"


func after_test() -> void:
	CharacterModel.packs_enabled = false
	Game.set_look(PlayerLook.Body.BOY)


# --- Building it -----------------------------------------------------------------

func test_without_the_pack_files_the_greybox_stays() -> void:
	CharacterModel.packs_enabled = true
	var player: Player3D = new_player_3d_on_floor()
	var model: CharacterModel = _model(player)
	var missing: CharacterParts = _parts()
	missing.outfit = "res://assets/third_party/not_here.gltf"
	model.boy = missing
	scene_runner(player.get_parent())

	assert_object(model.character).is_null()
	for stand_in: VisualInstance3D in model.stand_ins:
		assert_bool(stand_in.visible).is_true()


func test_with_packs_turned_off_the_greybox_stays() -> void:
	var player: Player3D = new_player_3d_on_floor()
	var model: CharacterModel = _model(player)
	model.boy = _parts()
	scene_runner(player.get_parent())

	assert_object(model.character).is_null()


func test_with_the_files_the_character_replaces_the_greybox() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	scene_runner(player.get_parent())

	assert_object(model.character).is_not_null()
	assert_object(model.skeleton).is_not_null()
	for stand_in: VisualInstance3D in model.stand_ins:
		assert_bool(stand_in.visible).is_false()
	# The head and hair are on the outfit's skeleton.
	for part: String in ["Head", "Eyes", "Hair"]:
		assert_object(model.skeleton.get_node_or_null(part)).override_failure_message(
				"no %s on the skeleton" % part).is_not_null()
	assert_object(model.right_hand).is_not_null()
	assert_object(model.left_hand).is_not_null()


func test_it_is_younger_a_bigger_head_on_a_shorter_body() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	scene_runner(player.get_parent())

	var head: int = model.skeleton.find_bone("Head")
	assert_vector(model.skeleton.get_bone_pose_scale(head)) \
			.is_equal_approx(Vector3.ONE * model.head_scale, Vector3.ONE * 0.001)
	assert_vector(model.character.scale) \
			.is_equal_approx(Vector3.ONE * model.body_scale, Vector3.ONE * 0.001)


func test_a_new_look_rebuilds_the_character() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	var girl: CharacterParts = _parts()
	girl.hair = ""
	model.girl = girl
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	assert_object(model.skeleton.get_node_or_null("Hair")).is_not_null()

	Game.set_look(PlayerLook.Body.GIRL)
	await physics_ticks(runner, 2)

	assert_object(model.character).is_not_null()
	assert_object(model.skeleton.get_node_or_null("Hair")).is_null()


# --- Moving ----------------------------------------------------------------------

func test_it_stands_idle_then_walks_when_you_walk() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)
	assert_int(model.pose).is_equal(CharacterModel.Pose.IDLE)

	runner.simulate_action_press("move_up")
	await physics_ticks(runner, 6)

	assert_int(model.pose).is_equal(CharacterModel.Pose.WALK)
	runner.simulate_action_release("move_up")


func test_a_strike_plays_the_strike() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	await physics_ticks(runner, 2)

	duellist_of(player).strike()
	await physics_ticks(runner, 2)

	assert_int(model.pose).is_equal(CharacterModel.Pose.STRIKE)


func test_the_pose_is_a_strike_or_parry_first_then_walking() -> void:
	assert_int(CharacterModel.pose_for(false, false, false)).is_equal(CharacterModel.Pose.IDLE)
	assert_int(CharacterModel.pose_for(true, false, false)).is_equal(CharacterModel.Pose.WALK)
	assert_int(CharacterModel.pose_for(true, false, true)).is_equal(CharacterModel.Pose.PARRY)
	assert_int(CharacterModel.pose_for(true, true, true)).is_equal(CharacterModel.Pose.STRIKE)


func test_animations_turn_our_bones_without_stretching_them() -> void:
	var moves: Node = (load(FIXTURES + "moves.tscn") as PackedScene).instantiate()
	auto_free(moves)
	var source: Animation = (moves.get_node("AnimationPlayer") as AnimationPlayer) \
			.get_animation(&"Idle_Lantern")

	var copy: Animation = CharacterModel.retarget(source, NodePath("Body/Skeleton3D"))

	var kept: Array[String] = []
	for track: int in copy.get_track_count():
		kept.append("%s %d" % [copy.track_get_path(track), copy.track_get_type(track)])
	# The head's turn and the pelvis's sway stay, on our skeleton; the hand's
	# move (which would stretch the arm) and the head's scale go.
	assert_array(kept).contains_exactly_in_any_order([
		"Body/Skeleton3D:Head %d" % Animation.TYPE_ROTATION_3D,
		"Body/Skeleton3D:pelvis %d" % Animation.TYPE_POSITION_3D,
	])


func test_the_hips_move_by_our_height_so_feet_stay_on_the_floor() -> void:
	var source: Animation = Animation.new()
	var hips: int = source.add_track(Animation.TYPE_POSITION_3D)
	source.track_set_path(hips, NodePath("Armature/Skeleton3D:pelvis"))
	source.position_track_insert_key(hips, 0.0, Vector3(0.1, 0.9, 0.0))

	# Our hips stand 1.1 times as high as the animated skeleton's.
	var copy: Animation = CharacterModel.retarget(source, NodePath("Skeleton3D"), 1.1)

	var at: Vector3 = copy.track_get_key_value(0, 0)
	assert_vector(at).is_equal_approx(Vector3(0.11, 0.99, 0.0), Vector3.ONE * 0.0001)


func test_its_feet_are_planted_on_the_floor() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())

	await physics_ticks(runner, 5)

	# The stand-in animation drops the hips 10 cm, which would sink the
	# feet; the character is lifted to keep the soles on the floor.
	assert_float(model.sole_height()).is_equal_approx(0.0, 0.005)
	assert_float(model.character.position.y).is_greater(0.05)


func test_only_the_head_is_cut_from_a_whole_body() -> void:
	var skin: Skin = Skin.new()
	skin.add_named_bind(&"pelvis", Transform3D.IDENTITY)
	skin.add_named_bind(&"Head", Transform3D.IDENTITY)
	# Two triangles: the first moved by the pelvis (bind 0), the second by
	# the head (bind 1), each corner fully by its one bone.
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0),
			Vector3(0, 1, 0), Vector3(0, 2, 0), Vector3(1, 2, 0), Vector3(0, 3, 0)])
	var bones: PackedInt32Array = []
	var weights: PackedFloat32Array = []
	for vertex: int in 6:
		bones.append_array([0 if vertex < 3 else 1, 0, 0, 0])
		weights.append_array([1.0, 0.0, 0.0, 0.0])
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 3, 4, 5])
	var body: ArrayMesh = ArrayMesh.new()
	body.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var head: ArrayMesh = CharacterModel.cut_out(body, skin, CharacterModel.HEAD_BONES)

	var kept: PackedInt32Array = head.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	assert_array(Array(kept)).is_equal([3, 4, 5])


# --- Knife and pan ---------------------------------------------------------------

func test_the_knife_and_pan_go_in_the_characters_hands() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	scene_runner(player.get_parent())

	var knife: Node3D = player.find_child("Knife", true, false) as Node3D
	var pan: Node3D = player.find_child("Pan", true, false) as Node3D
	assert_object(knife.get_parent()).is_same(model.right_hand)
	assert_object(pan.get_parent()).is_same(model.left_hand)


func test_without_a_character_they_stay_with_the_greybox() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	assert_object(player.get_node_or_null("Model/Knife")).is_not_null()
	assert_object(player.get_node_or_null("Model/Pan")).is_not_null()


func test_losing_the_character_puts_them_back_with_the_greybox() -> void:
	var player: Player3D = _new_dressed_player()
	var model: CharacterModel = _model(player)
	var runner: GdUnitSceneRunner = scene_runner(player.get_parent())
	var girl: CharacterParts = _parts()
	girl.outfit = "res://assets/third_party/not_here.gltf"
	model.girl = girl

	Game.set_look(PlayerLook.Body.GIRL)
	await physics_ticks(runner, 2)

	assert_object(model.character).is_null()
	assert_object(player.get_node_or_null("Model/Knife")).is_not_null()
	assert_object(player.get_node_or_null("Model/Pan")).is_not_null()


# --- The real looks --------------------------------------------------------------

func test_the_boy_and_girl_wear_the_peasant_outfit() -> void:
	var boy: CharacterParts = load("res://data/characters/boy.tres") as CharacterParts
	var girl: CharacterParts = load("res://data/characters/girl.tres") as CharacterParts

	assert_str(boy.outfit).ends_with("Outfits/Male_Peasant.gltf")
	assert_str(girl.outfit).ends_with("Outfits/Female_Peasant.gltf")
	for parts: CharacterParts in [boy, girl] as Array[CharacterParts]:
		for path: String in parts.files():
			assert_str(path).starts_with("res://assets/third_party/")


# A player whose character is built from the stand-in files.
func _new_dressed_player() -> Player3D:
	CharacterModel.packs_enabled = true
	var player: Player3D = new_player_3d_on_floor()
	var model: CharacterModel = _model(player)
	model.boy = _parts()
	model.animation_files = PackedStringArray([FIXTURES + "moves.tscn"])
	return player


# The stand-in parts: every file there.
func _parts() -> CharacterParts:
	var parts: CharacterParts = CharacterParts.new()
	parts.outfit = FIXTURES + "outfit.tscn"
	parts.head_from = FIXTURES + "head.tscn"
	parts.hair = FIXTURES + "hair.tscn"
	parts.eyebrows = ""
	return parts


func _model(player: Player3D) -> CharacterModel:
	return player.get_node("Model/Character") as CharacterModel
