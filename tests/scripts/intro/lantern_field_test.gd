extends GameTestSuite
## Tests for the dead lanterns hanging in the deep: each sinks slowly at its
## own pace, they give no light of their own, lightning shows on their
## glass, and they rock in the wake of the thing passing beneath them and
## settle again.

const LANTERN: PackedScene = preload("res://scenes/prototype/intro/dead_lantern.tscn")


func test_each_lantern_sinks_slowly_at_its_own_pace() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0), Vector3(3, -9, 0), Vector3(-4, -20, 2)])
	field.sink_slowest = 0.05
	field.sink_fastest = 0.15
	var first: Node3D = field.get_child(0) as Node3D
	var began_at: float = first.position.y

	field.advance(10.0)

	for index: int in field.count():
		assert_float(field.sunk_of(index)).is_between(0.5, 1.5)
	assert_float(first.position.y).is_equal_approx(began_at - field.sunk_of(0), 0.001)
	assert_bool(is_equal_approx(field.sunk_of(0), field.sunk_of(1))).is_false()


func test_every_lantern_has_a_share_of_its_own_between_nothing_and_all() -> void:
	var seen: Array[float] = []
	for index: int in 40:
		var share: float = LanternField.share_of(index)
		assert_float(share).is_between(0.0, 1.0)
		assert_float(LanternField.share_of(index)).is_equal(share)
		seen.append(share)
	seen.sort()

	# Spread out, not bunched at one pace.
	assert_float(seen[0]).is_less(0.2)
	assert_float(seen[39]).is_greater(0.8)


func test_between_flashes_they_show_nothing_of_their_own() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0)])

	field.advance(1.0)

	assert_float(field.sheen()).is_equal(0.0)
	assert_float(_sent(field, 0, &"cold")).is_equal(0.0)


func test_lightning_shows_on_every_lanterns_glass() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0), Vector3(0, -30, 9)])

	field.set_lightning(0.8)

	assert_bool(field.is_in_group(Lightning.LIT_GROUP)).is_true()
	assert_float(field.sheen()).is_equal_approx(0.8, 0.001)
	assert_float(_sent(field, 0, &"cold")).is_equal_approx(0.8, 0.001)
	assert_float(_sent(field, 1, &"cold")).is_equal_approx(0.8, 0.001)

	field.set_lightning(0.0)
	assert_float(_sent(field, 0, &"cold")).is_equal(0.0)


func test_how_far_the_thing_is_is_measured_from_along_its_whole_length() -> void:
	var field: LanternField = _new_field([])
	var thing: Node3D = _new_thing(field, Vector3(0, -30, 0))
	field.thing_length = 40.0

	# Beside its middle, beside its far end, and off beyond that end.
	assert_float(field.distance_to_thing(Vector3(0, -30, 6))).is_equal_approx(6.0, 0.001)
	assert_float(field.distance_to_thing(Vector3(18, -30, 6))).is_equal_approx(6.0, 0.001)
	assert_float(field.distance_to_thing(Vector3(26, -30, 0))).is_equal_approx(6.0, 0.001)
	# Turned a quarter, it lies along Z instead.
	thing.rotation.y = PI * 0.5
	assert_float(field.distance_to_thing(Vector3(0, -30, 18))).is_less(0.01)


func test_with_no_thing_nothing_is_near_it() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0)])

	field.advance(1.0)

	assert_float(field.distance_to_thing(Vector3.ZERO)).is_equal(INF)
	assert_float(field.tilt_of(0)).is_equal(0.0)


func test_a_lantern_rocks_as_the_thing_comes_near_and_settles() -> void:
	var field: LanternField = _new_field([Vector3(0, -20, 0), Vector3(0, -20, 60)])
	var thing: Node3D = _new_thing(field, Vector3(-200, -28, 0))
	field.thing_length = 40.0
	field.wake_reach = 10.0
	field.rock_seconds = 2.0
	field.rock_angle = 0.5
	field.sink_slowest = 0.0
	field.sink_fastest = 0.0
	field.turn_speed = 0.0
	var lantern: Node3D = field.get_child(0) as Node3D
	var at_rest: Basis = lantern.transform.basis
	field.advance(0.1)
	assert_float(field.tilt_of(0)).is_equal(0.0)

	# It arrives beneath the first lantern.
	thing.position = Vector3(0, -28, 0)
	field.advance(0.01)
	field.advance(0.25)
	assert_float(absf(field.tilt_of(0))).is_greater(0.05)
	assert_bool(lantern.transform.basis.is_equal_approx(at_rest)).is_false()
	# The far one isn't touched.
	assert_float(field.tilt_of(1)).is_equal(0.0)

	# Still there, it doesn't keep rocking: once, and it settles.
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


func test_not_flickering_the_dead_lanterns_have_no_glow() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0), Vector3(2, -8, 0)])
	field.advance(3.0)
	assert_float(field.ember_of(0)).is_equal(0.0)
	assert_float(_sent(field, 1, &"ember")).is_equal(0.0)


func test_flickering_they_sputter_unevenly_each_to_its_own_rhythm() -> void:
	var places: Array[Vector3] = []
	for index: int in 12:
		places.append(Vector3(index, -5, 0))
	var field: LanternField = _new_field(places)
	field.flicker = 1.0
	var lit: int = 0
	var dark: int = 0
	var brightest: float = 0.0
	for step: int in 60:
		field.advance(0.05)
		for index: int in field.count():
			var ember: float = field.ember_of(index)
			brightest = maxf(brightest, ember)
			if ember > 0.05:
				lit += 1
			else:
				dark += 1
	# Some flicker up, but they're out more often than in.
	assert_float(brightest).is_greater(0.3)
	assert_int(lit).is_greater(0)
	assert_int(dark).is_greater(lit)
	# What the glass is told matches.
	assert_float(_sent(field, 3, &"ember")).is_equal_approx(field.ember_of(3), 0.0001)
	# And no two keep the same beat: over a couple of seconds they differ.
	var apart: float = 0.0
	for step: int in 40:
		apart += absf(LanternField.sputter(0, step * 0.05) - LanternField.sputter(1, step * 0.05))
	assert_float(apart).is_greater(0.5)


func test_a_lantern_that_glows_of_its_own_keeps_its_glow_while_they_flicker() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0)], [0.6])
	assert_float(field.ember_of(0)).is_equal_approx(0.6, 0.001)
	field.flicker = 1.0
	for step: int in 40:
		field.advance(0.05)
		assert_float(field.ember_of(0)).is_greater_equal(0.6)


func test_starting_again_puts_every_lantern_back_where_it_began() -> void:
	var field: LanternField = _new_field([Vector3(0, -5, 0)])
	var lantern: Node3D = field.get_child(0) as Node3D
	var began: Transform3D = lantern.transform
	field.advance(20.0)
	assert_float(field.sunk_of(0)).is_greater(0.0)

	field.reset()

	assert_float(field.sunk_of(0)).is_equal(0.0)
	assert_bool(lantern.transform.is_equal_approx(began)).is_true()


# A number lantern [param index]'s glass has been given.
func _sent(field: LanternField, index: int, parameter: StringName) -> float:
	var glass: GeometryInstance3D = field.get_child(index).get_node("Glass") as GeometryInstance3D
	var value: float = glass.get_instance_shader_parameter(parameter)
	return value


# Something long for the lanterns to rock in the wake of, lying along X.
func _new_thing(field: LanternField, at: Vector3) -> Node3D:
	var thing: Node3D = Node3D.new()
	thing.position = at
	field.get_parent().add_child(thing)
	field.thing = thing
	return thing


# A field with a dead lantern at each of [param places], in its own space.
func _new_field(places: Array[Vector3], embers: Array[float] = []) -> LanternField:
	var world: Node3D = Node3D.new()
	auto_free(world)
	add_child(world)
	var field: LanternField = LanternField.new()
	for index: int in places.size():
		var lantern: Node3D = LANTERN.instantiate() as Node3D
		lantern.position = places[index]
		if index < embers.size():
			var glass: GeometryInstance3D = lantern.get_node("Glass") as GeometryInstance3D
			glass.set_instance_shader_parameter(&"ember", embers[index])
		field.add_child(lantern)
	world.add_child(field)
	return field
