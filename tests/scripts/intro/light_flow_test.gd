extends GameTestSuite
## Tests for LightFlow: the lantern's light pouring out of his hand into you
## in the rescue (#183). Motes stream from his palm to your chest while it
## flows, and a glow grows in you as you fill.


func test_with_nothing_flowing_nothing_streams_and_nothing_glows() -> void:
	var flow: LightFlow = _new_flow(Vector3.ZERO, Vector3(2, 0, 0))
	await get_tree().process_frame

	assert_bool(_motes(flow).emitting).is_false()
	assert_float(_glow(flow).light_energy).is_equal(0.0)


func test_flowing_the_motes_stream_and_you_glow_as_you_fill() -> void:
	var flow: LightFlow = _new_flow(Vector3.ZERO, Vector3(2, 0, 0))
	flow.glow_energy = 4.0

	flow.flow = 1.0
	flow.filled = 0.5

	assert_bool(_motes(flow).emitting).is_true()
	assert_float(_glow(flow).light_energy).is_equal_approx(2.0, 0.001)
	flow.filled = 1.0
	assert_float(_glow(flow).light_energy).is_equal_approx(4.0, 0.001)
	# Easing off, the stream thins before it stops.
	flow.flow = 0.3
	assert_bool(_motes(flow).emitting).is_true()
	assert_float(_motes(flow).color.a).is_equal_approx(0.3, 0.001)


func test_the_motes_leave_his_palm_aimed_at_you_and_arrive_in_their_time() -> void:
	var flow: LightFlow = _new_flow(Vector3(1, 2, 0), Vector3(1, 2, 3))
	flow.travel_seconds = 1.5
	flow.flow = 1.0
	await get_tree().process_frame

	var motes: CPUParticles3D = _motes(flow)
	assert_vector(motes.global_position).is_equal_approx(Vector3(1, 2, 0), Vector3.ONE * 0.001)
	assert_vector(motes.global_basis * motes.direction).is_equal_approx(Vector3(0, 0, 1),
			Vector3.ONE * 0.001)
	# Three metres in a second and a half.
	assert_float(flow.mote_speed()).is_equal_approx(2.0, 0.001)
	assert_float(motes.initial_velocity_min).is_less_equal(2.0)
	assert_float(motes.initial_velocity_max).is_greater_equal(2.0)
	# The glow sits in you, not in his hand.
	assert_vector(_glow(flow).global_position).is_equal_approx(Vector3(1, 2, 3),
			Vector3.ONE * 0.001)


func test_amounts_are_kept_between_nothing_and_all() -> void:
	var flow: LightFlow = _new_flow(Vector3.ZERO, Vector3(2, 0, 0))
	flow.flow = 3.0
	flow.filled = -1.0
	assert_float(flow.flow).is_equal(1.0)
	assert_float(flow.filled).is_equal(0.0)


func _motes(flow: LightFlow) -> CPUParticles3D:
	return flow.get_node("Motes") as CPUParticles3D


func _glow(flow: LightFlow) -> OmniLight3D:
	return flow.get_node("Glow") as OmniLight3D


# A light flow from a marker at [param from] to one at [param to], with the
# children the scene gives it.
func _new_flow(from: Vector3, to: Vector3) -> LightFlow:
	var world: Node3D = Node3D.new()
	auto_free(world)
	add_child(world)
	var start: Marker3D = Marker3D.new()
	start.position = from
	world.add_child(start)
	var end: Marker3D = Marker3D.new()
	end.position = to
	world.add_child(end)
	var flow: LightFlow = LightFlow.new()
	flow.from = start
	flow.to = end
	var motes: CPUParticles3D = CPUParticles3D.new()
	motes.name = "Motes"
	flow.add_child(motes)
	var glow: OmniLight3D = OmniLight3D.new()
	glow.name = "Glow"
	flow.add_child(glow)
	world.add_child(flow)
	return flow
