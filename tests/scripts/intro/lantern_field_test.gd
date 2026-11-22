extends GameTestSuite
## Tests for the dead lanterns on the seabed: the flare's light reaches the
## nearer ones first, each glints once and its glow fades, one keeps its
## glow, the thing passing is a gap in which they go dark and come back,
## they rock in its wake and settle, and lightning reaches the ones outside
## the gap.

const LANTERN: PackedScene = preload("res://scenes/prototype/intro/dead_lantern.tscn")
const SEABED: Shader = preload("res://shaders/seabed.gdshader")


func test_a_glint_then_a_glow_that_fades_away() -> void:
	var at_first: float = LanternField.glow_after(0.0, 5.0)
	var just_after: float = LanternField.glow_after(LanternField.GLINT_SECONDS, 5.0)
	var later: float = LanternField.glow_after(3.0, 5.0)

	assert_float(at_first).is_greater(LanternField.GLINT_BRIGHTNESS)
	assert_float(just_after).is_less(LanternField.AFTERGLOW + 0.001)
	assert_float(later).is_between(0.001, just_after)
	assert_float(LanternField.glow_after(5.0, 5.0)).is_equal(0.0)
	assert_float(LanternField.glow_after(-1.0, 5.0)).is_equal(0.0)


func test_the_light_reaches_the_nearer_lanterns_first() -> void:
	var field: LanternField = _new_field([Vector3(2, 0, 0), Vector3(9, 0, 0)])
	field.light_origin = field.to_global(Vector3.ZERO)

	field.front = 5.0
	field.advance(0.1)
	assert_bool(field.is_lit(0)).is_true()
	assert_bool(field.is_lit(1)).is_false()
	assert_float(field.glow_of(0)).is_greater(1.0)
	assert_float(field.glow_of(1)).is_equal(0.0)

	field.front = 12.0
	field.advance(0.1)
	assert_bool(field.is_lit(1)).is_true()


func test_a_lantern_glints_once_and_then_only_fades() -> void:
	var field: LanternField = _new_field([Vector3(2, 0, 0)])
	field.glow_seconds = 4.0
	field.front = 5.0
	field.advance(0.1)

	field.advance(1.0)
	var after_a_second: float = field.glow_of(0)
	field.advance(1.0)
	var after_two: float = field.glow_of(0)
	field.advance(5.0)

	assert_float(after_a_second).is_less(LanternField.AFTERGLOW)
	assert_float(after_two).is_less(after_a_second)
	assert_float(field.glow_of(0)).is_equal(0.0)
	assert_bool(field.is_lit(0)).is_true()


func test_one_lantern_keeps_its_glow_long_after_the_rest() -> void:
	var field: LanternField = _new_field([Vector3(2, 0, 0), Vector3(3, 0, 0)])
	field.keeper = field.get_child(1) as Node3D
	field.glow_seconds = 4.0
	field.keeper_seconds = 60.0
	field.front = 5.0
	field.advance(0.1)

	field.advance(10.0)

	assert_float(field.glow_of(0)).is_equal(0.0)
	assert_float(field.glow_of(1)).is_greater(0.2)


func test_each_lanterns_glow_reaches_its_own_glass() -> void:
	var field: LanternField = _new_field([Vector3(2, 0, 0), Vector3(9, 0, 0)])
	field.front = 5.0
	field.advance(0.1)

	assert_float(_sent(field, 0, &"glow")).is_equal_approx(field.glow_of(0), 0.001)
	assert_float(_sent(field, 1, &"glow")).is_equal(0.0)


func test_inside_the_thing_is_dark_and_outside_is_not() -> void:
	var centre: Vector3 = Vector3(0, 0, 0)

	# Twenty long, four wide, lying along X.
	assert_float(LanternField.in_gap(Vector3(0, 0, 0), centre, 0.0, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(7, 5, 0.5), centre, 0.0, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(0, 0, 3), centre, 0.0, 20.0, 4.0)).is_equal(0.0)
	assert_float(LanternField.in_gap(Vector3(13, 0, 0), centre, 0.0, 20.0, 4.0)).is_equal(0.0)
	# Turned a quarter, it lies along Z instead.
	assert_float(LanternField.in_gap(Vector3(0, 0, 7), centre, PI * 0.5, 20.0, 4.0)).is_equal(1.0)
	assert_float(LanternField.in_gap(Vector3(7, 0, 0), centre, PI * 0.5, 20.0, 4.0)).is_equal(0.0)


func test_lanterns_wink_out_as_it_passes_and_come_back() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0), Vector3(0, 0, 8)])
	field.keeper = field.get_child(0) as Node3D
	field.front = 20.0
	field.advance(0.1)
	field.advance(1.0)
	var lit: float = field.glow_of(0)
	assert_float(lit).is_greater(0.0)

	# It arrives over the first lantern.
	field.gap = 1.0
	field.gap_length = 20.0
	field.gap_width = 4.0
	field.gap_centre = Vector3(0, 0, 0)
	field.advance(0.1)
	assert_float(field.darkness_of(0)).is_equal(1.0)
	assert_float(field.glow_of(0)).is_equal(0.0)
	assert_float(field.darkness_of(1)).is_equal(0.0)

	# And moves on.
	field.gap_centre = Vector3(40, 0, 0)
	field.advance(0.1)
	assert_float(field.darkness_of(0)).is_equal(0.0)
	assert_float(field.glow_of(0)).is_greater(0.0)


func test_while_its_not_there_nothing_goes_dark() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])
	field.gap = 0.0
	field.gap_centre = Vector3(0, 0, 0)

	field.advance(0.1)

	assert_float(field.darkness_of(0)).is_equal(0.0)


func test_a_lantern_rocks_in_its_wake_and_settles_where_it_was() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0)])
	var lantern: Node3D = field.get_child(0) as Node3D
	var at_rest: Basis = lantern.transform.basis
	field.rock_seconds = 2.0
	field.rock_angle = 0.5
	field.gap = 1.0
	field.gap_centre = Vector3(0, 0, 0)

	field.advance(0.01)
	field.advance(0.25)
	assert_float(absf(field.tilt_of(0))).is_greater(0.05)
	assert_bool(lantern.transform.basis.is_equal_approx(at_rest)).is_false()

	field.advance(3.0)
	assert_float(field.tilt_of(0)).is_equal(0.0)
	assert_bool(lantern.transform.basis.is_equal_approx(at_rest)).is_true()


func test_the_rocking_swings_both_ways_and_dies_down() -> void:
	var early: float = LanternField.rock_after(0.125, 1.0)
	var back: float = LanternField.rock_after(0.375, 1.0)
	var late: float = LanternField.rock_after(0.875, 1.0)

	assert_float(early).is_greater(0.3)
	assert_float(back).is_less(-0.1)
	assert_float(absf(late)).is_less(absf(back))
	assert_float(LanternField.rock_after(1.0, 1.0)).is_equal(0.0)


func test_lightning_reaches_the_lanterns_outside_it_and_the_seabed() -> void:
	var field: LanternField = _new_field([Vector3(0, 0, 0), Vector3(0, 0, 9)])
	var floor_mesh: MeshInstance3D = MeshInstance3D.new()
	var sand: ShaderMaterial = ShaderMaterial.new()
	sand.shader = SEABED
	floor_mesh.material_override = sand
	field.get_parent().add_child(floor_mesh)
	field.floor_mesh = floor_mesh
	field.gap = 1.0
	field.gap_width = 4.0
	field.gap_length = 20.0
	field.gap_centre = Vector3(0, 0, 0)
	field.advance(0.1)

	field.set_lightning(0.8)

	assert_bool(field.is_in_group(Lightning.LIT_GROUP)).is_true()
	assert_float(_sent(field, 0, &"cold")).is_equal(0.0)
	assert_float(_sent(field, 1, &"cold")).is_equal_approx(0.8, 0.001)
	var flash: float = sand.get_shader_parameter("flash")
	var there: float = sand.get_shader_parameter("gap")
	assert_float(flash).is_equal_approx(0.8, 0.001)
	assert_float(there).is_equal(1.0)


func test_the_seabed_is_told_where_its_two_ends_are() -> void:
	var field: LanternField = _new_field([])
	field.position = Vector3(10, -7, 0)
	field.gap_length = 20.0
	field.gap_width = 4.0
	field.gap_centre = Vector3(1, 0, 2)

	var ends: Array[Vector2] = field.gap_ends()

	# Eight either side of the middle (its rounded ends take up the rest).
	assert_vector(ends[0]).is_equal_approx(Vector2(3, 2), Vector2(0.001, 0.001))
	assert_vector(ends[1]).is_equal_approx(Vector2(19, 2), Vector2(0.001, 0.001))


func test_starting_again_puts_every_lantern_out() -> void:
	var field: LanternField = _new_field([Vector3(2, 0, 0)])
	field.front = 5.0
	field.advance(0.1)
	assert_bool(field.is_lit(0)).is_true()

	field.reset()

	assert_bool(field.is_lit(0)).is_false()
	assert_float(field.glow_of(0)).is_equal(0.0)


func test_the_dunes_are_low_and_rolling() -> void:
	var highest: float = 0.0
	for step: int in 200:
		highest = maxf(highest, absf(LanternField.dune_height(step * 0.37, step * 0.53)))

	assert_float(highest).is_between(0.2, 0.5)


# A number lantern [param index]'s glass has been given.
func _sent(field: LanternField, index: int, parameter: StringName) -> float:
	var glass: GeometryInstance3D = field.get_child(index).get_node("Glass") as GeometryInstance3D
	var value: float = glass.get_instance_shader_parameter(parameter)
	return value


# A field with a dead lantern at each of [param places], in its own space.
func _new_field(places: Array[Vector3]) -> LanternField:
	var world: Node3D = Node3D.new()
	auto_free(world)
	add_child(world)
	var field: LanternField = LanternField.new()
	for place: Vector3 in places:
		var lantern: Node3D = LANTERN.instantiate() as Node3D
		lantern.position = place
		field.add_child(lantern)
	world.add_child(field)
	return field
