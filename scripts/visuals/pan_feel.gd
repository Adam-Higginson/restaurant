class_name PanFeel
extends Node3D
## How cooking over the hob feels (#152). While something cooks in the pan,
## steam rises from it, thicker as it nears done, and it sizzles, rising in
## pitch. When it reaches its golden moment ([GoldenMoment]) it glints with a
## chime and glows gold, pulsing, for as long as the moment lasts: take it off
## the heat then: caught, it sparkles and chimes.
##
## A bubble over the pan, like the crew's speech bubbles, shows how it's
## going ([CookBubble]): a ring filling round a flame as it cooks, gold and
## pulsing with "Now!" at the golden moment, and the dish and its stars for a
## moment once it's done.
##
## A child of a [Hob], placed where the pan sits. It follows whichever pan
## is on the hob and listens to what's cooking in it.

const GOLD: Color = Color(1.0, 0.8, 0.3)
const DONE_COLOUR: Color = Color(0.7, 0.66, 0.6)
## How long the bubble names the dish once it's done, in seconds.
const DONE_SECONDS: float = 3.0
## Where the bubble's tail points, above the pan.
const BUBBLE_HEIGHT: float = 0.3

## The sizzle, looping while something cooks (none yet: a recording is
## still to come), and the chime of the golden moment.
@export var sizzle_sound: AudioStream
@export var chime_sound: AudioStream
## How bright the golden glow gets, at the top of its pulse.
@export var glow_energy: float = 1.6

## The pan on the hob, or null.
var _pan: ItemInstance = null
var _steam: CPUParticles3D
var _glints: CPUParticles3D
var _glow: OmniLight3D
var _sizzle: AudioStreamPlayer3D
var _chime: AudioStreamPlayer3D
var _bubble: SpeechBubble3D
var _bubble_anchor: Node3D
var _bubble_up: bool = false
## What the bubble says once the dish is done, in what colour, and for how
## much longer.
var _done_words: String = ""
var _done_colour: Color = Color.WHITE
var _done_left: float = 0.0

@onready var _hob: Hob = get_parent() as Hob


func _ready() -> void:
	_steam = _make_steam()
	_glints = _make_glints()
	_glow = OmniLight3D.new()
	_glow.name = "Glow"
	_glow.light_color = GOLD
	_glow.omni_range = 1.2
	_glow.light_energy = 0.0
	_glow.position = Vector3.UP * 0.2
	add_child(_glow)
	_sizzle = _sound_player("Sizzle", sizzle_sound)
	_chime = _sound_player("Chime", chime_sound)
	_bubble_anchor = Node3D.new()
	_bubble_anchor.name = "BubbleAnchor"
	_bubble_anchor.position = Vector3.UP * BUBBLE_HEIGHT
	add_child(_bubble_anchor)
	_bubble = SpeechBubble3D.new()
	_bubble.name = "Bubble"
	_bubble.use_face(CookBubble.new())
	add_child(_bubble)
	if _hob == null:
		return
	# A child is ready before its parent, so the hob's slot may not exist yet.
	if _hob.slot == null:
		await _hob.ready
	_hob.slot.item_changed.connect(_follow)
	_follow(_hob.slot.get_item())


func _process(delta: float) -> void:
	_done_left = maxf(_done_left - delta, 0.0)
	var cooking: ActiveReaction = _cooking()
	var through: float = cooking.get_fraction() if cooking != null else 0.0
	_steam.emitting = cooking != null
	_steam.scale_amount_max = 0.9 + 0.7 * through
	if cooking != null and _sizzle.stream != null:
		if not _sizzle.playing:
			_sizzle.play()
		_sizzle.pitch_scale = 0.9 + 0.3 * through
		_sizzle.volume_db = lerpf(-12.0, -3.0, through)
	elif _sizzle.playing:
		_sizzle.stop()
	var moment: GoldenMoment = _moment()
	if moment != null:
		# A pulse that quickens as the moment runs out.
		var left: float = moment.fraction_left()
		var beat: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * lerpf(18.0, 7.0, left))
		_glow.light_energy = glow_energy * (0.4 + 0.6 * beat)
		_show_bubble(1.0, "Now!", GOLD, beat)
	else:
		_glow.light_energy = 0.0
		if cooking != null:
			_show_bubble(through)
		elif _done_left > 0.0:
			_show_bubble(1.0, _done_words, _done_colour)
		elif _bubble_up:
			_bubble.hush()
			_bubble_up = false


## The bubble over the pan.
func bubble() -> SpeechBubble3D:
	return _bubble


## Whether the bubble is up.
func is_bubble_up() -> bool:
	return _bubble_up


## What a done dish is called in the bubble: its name and its stars.
static func dish_words(food: ItemInstance) -> String:
	return "%s %s" % [food.item.display_name, "★".repeat(food.quality)]


## The golden moment in the pan now, or null.
func moment() -> GoldenMoment:
	return _moment()


# Starts following [param item], the pan now on the hob (or null).
func _follow(item: ItemInstance) -> void:
	if _pan != null:
		var old: VesselContents = _pan.contents
		if old.golden_opened.is_connected(_on_opened):
			old.golden_opened.disconnect(_on_opened)
			old.golden_caught.disconnect(_on_caught)
			old.golden_missed.disconnect(_on_missed)
	_pan = item if item != null and item.is_vessel() else null
	if _pan != null:
		_pan.contents.golden_opened.connect(_on_opened)
		_pan.contents.golden_caught.connect(_on_caught)
		_pan.contents.golden_missed.connect(_on_missed)


func _cooking() -> ActiveReaction:
	if _pan == null or _hob.heat == null or not _pan.contents.has_element(_hob.heat):
		return null
	for active: ActiveReaction in _pan.contents.get_active_reactions():
		if active.reaction.driving_element() == _hob.heat:
			return active
	return null


func _moment() -> GoldenMoment:
	if _pan == null:
		return null
	var moments: Array[GoldenMoment] = _pan.contents.get_golden_moments()
	return moments[0] if not moments.is_empty() else null


func _on_opened(_moment_opened: GoldenMoment) -> void:
	_glints.restart()
	_play(_chime, 1.0)


func _on_caught(caught: GoldenMoment) -> void:
	_glints.restart()
	_play(_chime, 1.35)
	_done_words = dish_words(caught.result)
	_done_colour = GOLD
	_done_left = DONE_SECONDS


func _on_missed(missed: GoldenMoment) -> void:
	_done_words = dish_words(missed.result)
	_done_colour = DONE_COLOUR
	_done_left = DONE_SECONDS


# Shows the bubble's ring [param cooked] of the way round, with [param said]
# in [param colour] beside it, pulsing by [param pulse] at the golden moment.
func _show_bubble(cooked: float, said: String = "", colour: Color = CookBubble.WORDS,
		pulse: float = -1.0) -> void:
	var face: CookBubble = _bubble.face() as CookBubble
	face.show_cooking(cooked, said, colour, pulse)
	if not _bubble_up:
		_bubble.show_beside(_bubble_anchor)
		_bubble_up = true
	else:
		_bubble.refit()


func _play(player: AudioStreamPlayer3D, pitch: float) -> void:
	if player.stream == null:
		return
	player.pitch_scale = pitch
	player.play()


func _sound_player(sound_name: String, stream: AudioStream) -> AudioStreamPlayer3D:
	var player: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	player.name = sound_name
	player.stream = stream
	player.unit_size = 4.0
	add_child(player)
	return player


func _make_steam() -> CPUParticles3D:
	var steam: CPUParticles3D = CPUParticles3D.new()
	steam.name = "Steam"
	steam.emitting = false
	# Riding with the pan: the ship sails on, and steam left in the world
	# would stream away behind it.
	steam.local_coords = true
	steam.amount = 18
	steam.lifetime = 1.6
	steam.position = Vector3.UP * 0.08
	steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	steam.emission_sphere_radius = 0.1
	steam.direction = Vector3.UP
	steam.spread = 12.0
	steam.gravity = Vector3(0, 0.15, 0)
	steam.initial_velocity_min = 0.25
	steam.initial_velocity_max = 0.45
	steam.scale_amount_min = 1.0
	steam.scale_amount_max = 2.2
	var grow: Curve = Curve.new()
	grow.add_point(Vector2(0.0, 0.4))
	grow.add_point(Vector2(1.0, 1.0))
	steam.scale_amount_curve = grow
	var fade: Gradient = Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.2, Color(1, 1, 1, 0.22))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	steam.color_ramp = fade
	var puff: QuadMesh = QuadMesh.new()
	puff.size = Vector2(0.09, 0.09)
	var soft: StandardMaterial3D = StandardMaterial3D.new()
	soft.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	soft.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	soft.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soft.vertex_color_use_as_albedo = true
	soft.albedo_texture = _soft_dot()
	puff.material = soft
	steam.mesh = puff
	add_child(steam)
	return steam


func _make_glints() -> CPUParticles3D:
	var glints: CPUParticles3D = CPUParticles3D.new()
	glints.name = "Glints"
	glints.emitting = false
	glints.local_coords = true
	glints.one_shot = true
	glints.explosiveness = 1.0
	glints.amount = 12
	glints.lifetime = 0.6
	glints.position = Vector3.UP * 0.1
	glints.direction = Vector3.UP
	glints.spread = 70.0
	glints.gravity = Vector3.ZERO
	glints.initial_velocity_min = 0.4
	glints.initial_velocity_max = 0.9
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var glow: ShaderMaterial = ShaderMaterial.new()
	glow.shader = preload("res://shaders/sparkle.gdshader")
	quad.material = glow
	glints.mesh = quad
	add_child(glints)
	return glints


# A small soft round spot, for steam puffs.
static func _soft_dot() -> GradientTexture2D:
	var dot: GradientTexture2D = GradientTexture2D.new()
	dot.width = 32
	dot.height = 32
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	var falloff: Gradient = Gradient.new()
	falloff.set_color(0, Color(1, 1, 1, 1))
	falloff.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = falloff
	return dot
