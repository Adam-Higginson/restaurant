extends GameTestSuite
## Tests for the player's models: the knife and pan are dressed with the pack
## models when their files are there, and fall back to our greybox shapes
## when they aren't (a fresh clone, or CI). Gameplay never depends on them.

const BOX_MODEL: String = "res://tests/fixtures/box_model.tscn"
const MISSING: String = "res://assets/third_party/not_here.gltf"


func test_without_their_files_the_knife_and_pan_are_greybox() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	for holder: String in ["KnifeModel", "PanModel"]:
		var dresser: ThirdPartyModel = player.find_child(holder, true, false) as ThirdPartyModel
		dresser.path = MISSING

		assert_object(dresser.model).is_null()
		assert_bool(dresser.stand_ins[0].visible).override_failure_message(
				"%s's greybox is hidden" % holder).is_true()


func test_with_their_files_the_models_replace_the_greybox() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	for holder: String in ["KnifeModel", "PanModel"]:
		var dresser: ThirdPartyModel = player.find_child(holder, true, false) as ThirdPartyModel
		dresser.path = BOX_MODEL

		assert_object(dresser.model).is_not_null()
		assert_bool(dresser.stand_ins[0].visible).override_failure_message(
				"%s's greybox still shows" % holder).is_false()


func test_the_knife_and_pan_name_the_meshy_models() -> void:
	var player: Player3D = new_player_3d_on_floor()
	scene_runner(player.get_parent())

	var knife: ThirdPartyModel = player.find_child("KnifeModel", true, false) as ThirdPartyModel
	var pan: ThirdPartyModel = player.find_child("PanModel", true, false) as ThirdPartyModel
	assert_str(knife.path).ends_with("meshy/kitchen_knife/model/model.glb")
	assert_str(pan.path).ends_with("meshy/frying_pan/model/model.glb")
