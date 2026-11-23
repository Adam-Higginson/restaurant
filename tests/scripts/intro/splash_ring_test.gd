extends GameTestSuite
## Tests for the ring of foam where something goes into the water: nothing
## shows before it begins or once it's spent, and how far it has spread
## reaches the shader that draws it.

const SHADER: Shader = preload("res://shaders/splash_ring.gdshader")


func test_nothing_shows_before_it_begins() -> void:
	var ring: SplashRing = _new_ring()

	assert_bool(ring.is_showing()).is_false()
	assert_bool(ring.visible).is_false()


func test_it_shows_while_its_spreading_and_tells_the_shader_how_far() -> void:
	var ring: SplashRing = _new_ring()

	ring.spread = 0.4

	assert_bool(ring.is_showing()).is_true()
	assert_bool(ring.visible).is_true()
	var sent: float = (ring.material_override as ShaderMaterial).get_shader_parameter("spread")
	assert_float(sent).is_equal_approx(0.4, 0.001)


func test_spent_its_gone_again() -> void:
	var ring: SplashRing = _new_ring()
	ring.spread = 0.5

	ring.spread = 1.0

	assert_bool(ring.is_showing()).is_false()
	assert_bool(ring.visible).is_false()


func test_it_cant_spread_further_than_all_the_way() -> void:
	var ring: SplashRing = _new_ring()

	ring.spread = 7.0

	assert_float(ring.spread).is_equal(1.0)


func _new_ring() -> SplashRing:
	var ring: SplashRing = SplashRing.new()
	auto_free(ring)
	ring.mesh = QuadMesh.new()
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	ring.material_override = material
	add_child(ring)
	return ring
