extends GameTestSuite
## Tests for BunkBay: how its curtains hang, and dressing a bay for whoever
## sleeps in it.

const SCENE: String = "res://scenes/prototype/props/bunk_bay.tscn"


func test_drawn_curtains_meet_in_the_middle_and_cover_the_rail() -> void:
	for side: int in [-1, 1]:
		var layout: Vector2 = BunkBay.curtain_layout(true, side)
		# A full-width (1 m) curtain whose middle is half a metre out reaches
		# from the bay's middle to the end of the rail.
		assert_float(layout.y).is_equal(1.0)
		assert_float(absf(layout.x)).is_equal_approx(0.49, 0.001)
		assert_float(signf(layout.x)).is_equal(float(side))


func test_open_curtains_are_bunched_at_the_ends() -> void:
	for side: int in [-1, 1]:
		var layout: Vector2 = BunkBay.curtain_layout(false, side)
		assert_float(layout.y).is_less(0.5)
		assert_float(absf(layout.x)).is_greater(0.7)


func test_open_curtains_leave_the_middle_clear() -> void:
	# Open, you can see in: neither curtain reaches the middle 1.2 m of the bay.
	for side: int in [-1, 1]:
		var layout: Vector2 = BunkBay.curtain_layout(false, side)
		var near_edge: float = absf(layout.x) - layout.y / 2.0
		assert_float(near_edge).override_failure_message(
				"The %s curtain reaches %.2f m from the middle" % [
				"left" if side < 0 else "right", near_edge]).is_greater_equal(0.6)


func test_a_bay_is_dressed_for_whoever_sleeps_there() -> void:
	var quilt: Material = load("res://assets/placeholder/materials/quilt_gold.tres") as Material
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	bay.lower_quilt = quilt
	bay.lower_curtains_closed = true
	bay.lamp_lit = true
	add_child(bay)
	auto_free(bay)

	assert_object((bay.get_node("LowerQuilt") as MeshInstance3D).material_override) \
			.is_same(quilt)
	var left: Node3D = bay.get_node("LowerCurtainLeft") as Node3D
	assert_float(left.position.x).is_equal_approx(BunkBay.curtain_layout(true, -1).x, 0.001)
	assert_bool((bay.get_node("Lamp") as Node3D).visible).is_true()


func test_an_unlit_bay_keeps_its_lantern_and_candle_dark() -> void:
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	add_child(bay)
	auto_free(bay)
	assert_bool((bay.get_node("Lamp") as Node3D).visible).is_false()
	assert_bool((bay.get_node("UpperCandle") as Node3D).visible).is_false()


func test_a_reader_up_top_lights_the_candle() -> void:
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	bay.upper_lamp_lit = true
	add_child(bay)
	auto_free(bay)
	assert_bool((bay.get_node("UpperCandle") as Node3D).visible).is_true()
	assert_bool((bay.get_node("Lamp") as Node3D).visible).is_false()


func test_all_four_curtains_are_cut_from_the_bay_s_cloth() -> void:
	var cloth: Material = load("res://assets/placeholder/materials/curtain_mustard.tres") 			as Material
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	bay.curtain_cloth = cloth
	add_child(bay)
	auto_free(bay)
	for tier: String in ["Lower", "Upper"]:
		for side: String in ["Left", "Right"]:
			var mesh: MeshInstance3D = bay.get_node("%sCurtain%s/Cloth" % [tier, side]) 					as MeshInstance3D
			assert_object(mesh.material_override).is_same(cloth)


func test_curtain_cloth_lets_a_lamp_glow_through() -> void:
	for name: String in ["curtain", "curtain_mustard", "curtain_rust"]:
		var cloth: StandardMaterial3D = load("res://assets/placeholder/materials/%s.tres" % name) 				as StandardMaterial3D
		assert_bool(cloth.backlight_enabled).override_failure_message(
				"%s isn't backlit" % name).is_true()


func test_you_cannot_climb_into_a_bunk_by_walking() -> void:
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	auto_free(bay)
	assert_bool(bay.get_children().any(
			func(child: Node) -> bool: return child is CollisionShape3D)).is_true()
