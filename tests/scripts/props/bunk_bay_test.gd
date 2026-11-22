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


# TODO(your turn): write test_open_curtains_leave_the_middle_clear.
# When a bunk's curtains are open you should be able to see in, so neither
# curtain may reach the middle 1.2 m of the bay (x between -0.6 and 0.6).
# Hints:
# - curtain_layout(false, side) gives the curtain's middle (x) and how much of
#   its full 1 m width it's spread to (y), so it covers
#   x - y / 2 to x + y / 2.
# - Check both sides (-1 and 1), like the tests above.
# - Prove it can fail: change the 0.85 in curtain_layout to 0.3, run
#   ./run_tests.sh -a res://tests/scripts/props/bunk_bay_test.gd, then put
#   it back.


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


func test_an_unlit_bay_keeps_its_lantern_dark() -> void:
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	add_child(bay)
	auto_free(bay)
	assert_bool((bay.get_node("Lamp") as Node3D).visible).is_false()


func test_you_cannot_climb_into_a_bunk_by_walking() -> void:
	var bay: BunkBay = (load(SCENE) as PackedScene).instantiate() as BunkBay
	auto_free(bay)
	assert_bool(bay.get_children().any(
			func(child: Node) -> bool: return child is CollisionShape3D)).is_true()
