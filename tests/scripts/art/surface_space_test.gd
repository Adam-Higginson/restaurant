extends GameTestSuite
## Tests for SurfaceSpace: patterns on the ship's wet surfaces ride with the
## ship rather than sliding across it as it sails.


func test_hands_materials_the_body_transform() -> void:
	var body: Node3D = Node3D.new()
	body.position = Vector3(3, 0, -7)
	body.rotation.y = 0.4
	add_child(body)
	auto_free(body)
	var material: ShaderMaterial = _wet_material()
	var space: SurfaceSpace = SurfaceSpace.new()
	space.body = body
	space.materials = [material]
	auto_free(space)

	space.apply()

	var expected: Transform3D = body.global_transform.affine_inverse()
	var handed: Projection = material.get_shader_parameter(SurfaceSpace.PARAMETER)
	assert_vector(Transform3D(handed).origin).is_equal_approx(expected.origin, Vector3.ONE * 0.0001)
	assert_vector(Transform3D(handed).basis.x).is_equal_approx(expected.basis.x, Vector3.ONE * 0.0001)


func test_the_deck_pattern_sails_with_the_ship() -> void:
	var ship: Ship = new_moored_ship_with_player(Vector3(0, 5.35, 11))[0] as Ship
	var runner: GdUnitSceneRunner = scene_runner(ship.get_parent())
	ship.set_sail()
	await physics_ticks(runner, 20)
	# Stop it before checking, so how many frames the machine draws between
	# ticks can't put the ship somewhere other than where it was last drawn.
	ship.speed = 0.0
	await physics_ticks(runner, 3)
	(ship.get_node("SurfaceSpace") as SurfaceSpace).apply()
	assert_vector(ship.global_position).is_not_equal(Vector3.ZERO)

	var deck: ShaderMaterial = (ship.get_node("Visuals/DeckAft") as MeshInstance3D) \
			.material_override as ShaderMaterial
	var handed: Projection = deck.get_shader_parameter(SurfaceSpace.PARAMETER)
	# A spot on the deck maps to the same place in the pattern wherever the
	# ship has got to.
	var spot_on_deck: Vector3 = Vector3(1, 5.3, 12)
	var in_pattern: Vector3 = Transform3D(handed) * ship.to_global(spot_on_deck)
	assert_vector(in_pattern).is_equal_approx(spot_on_deck, Vector3.ONE * 0.01)


func _wet_material() -> ShaderMaterial:
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/wet_surface.gdshader") as Shader
	return material
