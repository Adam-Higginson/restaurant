class_name BowSpray
extends GPUParticles3D
## Spray thrown up at the bow now and then as the ship shoulders into the
## swell: a burst of white droplets that arcs up and falls back into the sea.
## It only happens while the ship is under way; moored, the bow is quiet.
##
## The droplets are left behind in the world as they fly (not carried along
## with the ship), so a burst trails past the bow as the ship sails on.

## Emitted each time a burst of spray is thrown up.
signal burst_thrown

## The ship whose bow this is.
@export var ship: Ship
## The shortest wait between bursts, in seconds.
@export var min_gap: float = 2.5
## The longest wait between bursts, in seconds.
@export var max_gap: float = 6.5

var _wait: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	one_shot = true
	emitting = false
	local_coords = false
	amount = 70
	lifetime = 1.6
	explosiveness = 0.85
	randomness = 0.4
	visibility_aabb = AABB(Vector3(-8, -2, -8), Vector3(16, 8, 16))
	process_material = _spray_motion()
	draw_pass_1 = _droplet()
	_wait = next_gap()


func _physics_process(delta: float) -> void:
	if ship == null or ship.way < 0.5:
		return
	_wait -= delta
	if _wait <= 0.0:
		burst()
		_wait = next_gap()


## Throws up one burst of spray now.
func burst() -> void:
	restart()
	burst_thrown.emit()


## How long to wait before the next burst: somewhere between [member min_gap]
## and [member max_gap] seconds, so the bursts never fall into a rhythm.
func next_gap() -> float:
	return _rng.randf_range(min_gap, max_gap)


# Up and forward off the stem, spread across the bow, then falling back.
func _spray_motion() -> ParticleProcessMaterial:
	var motion: ParticleProcessMaterial = ParticleProcessMaterial.new()
	motion.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	motion.emission_box_extents = Vector3(5.0, 0.2, 0.3)
	motion.direction = Vector3(0.0, 1.0, -0.5)
	motion.spread = 28.0
	motion.initial_velocity_min = 3.5
	motion.initial_velocity_max = 7.0
	motion.gravity = Vector3(0.0, -9.8, 0.0)
	motion.scale_min = 0.6
	motion.scale_max = 1.4
	var shrink: Curve = Curve.new()
	shrink.add_point(Vector2(0.0, 0.6))
	shrink.add_point(Vector2(0.3, 1.0))
	shrink.add_point(Vector2(1.0, 0.3))
	var shrink_texture: CurveTexture = CurveTexture.new()
	shrink_texture.curve = shrink
	motion.scale_curve = shrink_texture
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.85))
	fade.set_color(1, Color(1, 1, 1, 0.0))
	var fade_texture: GradientTexture1D = GradientTexture1D.new()
	fade_texture.gradient = fade
	motion.color_ramp = fade_texture
	return motion


# A small round blob of white water that always faces the camera. It's lit (per
# vertex, cheaply), so the lanterns warm it as it flies past.
func _droplet() -> QuadMesh:
	var mesh: QuadMesh = QuadMesh.new()
	mesh.size = Vector2(0.22, 0.22)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(0.82, 0.88, 0.92)
	material.albedo_texture = _droplet_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.emission_enabled = true
	material.emission = Color(0.22, 0.27, 0.32)
	material.disable_receive_shadows = true
	mesh.material = material
	return mesh


# A round blob of water, its edge fading softly to see-through, smoothly
# smoothly filtered (#137).
func _droplet_texture() -> ImageTexture:
	const SIZE: int = 16
	var image: Image = Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	var middle: float = (SIZE - 1) / 2.0
	for y: int in SIZE:
		for x: int in SIZE:
			var from_centre: float = Vector2(x - middle, y - middle).length() / (SIZE / 2.0)
			var alpha: float = 1.0 - smoothstep(0.55, 0.95, from_centre)
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)
