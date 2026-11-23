class_name DamageNumber
extends Label3D
## The damage a hit did, popping up from where it landed: it rises, drifts
## and fades, then frees itself. A critical hit's number is bigger and gold.
##
## A [Label3D] is text placed in the 3D world. With billboarding on it always
## turns to face the camera, and with depth testing off it's drawn over
## whatever is in front of it, so a number is never hidden by the crab.
## [Crab] makes one for each hit that counts ([method spawn]).

const FONT: Font = preload("res://assets/fonts/dialogue_font.tres")
## The colour of an ordinary hit's number, and of a critical's.
const NORMAL_COLOUR: Color = Color(1.0, 0.98, 0.94)
const CRITICAL_COLOUR: Color = Color(1.0, 0.78, 0.25)

## How long a number lasts, in seconds.
@export var lifetime: float = 0.8
## How far it rises over its life, in metres.
@export var rise: float = 0.7

## The damage it shows.
var amount: int = 0
## Words to show instead of a number ("Perfect!" over the chopping board),
## or "" for the [member amount].
var words: String = ""
## The words' colour, when there are words.
var words_colour: Color = NORMAL_COLOUR
## Whether it was a critical hit.
var critical: bool = false

var _age: float = 0.0
var _start: Vector3 = Vector3.ZERO
## Which way it drifts sideways as it rises, in metres over its life.
var _drift: Vector3 = Vector3.ZERO


## Makes a number for [param damage] at [param at] in the world, as a child of
## [param parent] (so it stays put if whatever was hit moves or is freed).
## [param is_critical] makes it bigger and gold.
static func spawn(parent: Node, at: Vector3, damage: int, is_critical: bool) -> DamageNumber:
	var number: DamageNumber = DamageNumber.new()
	number.amount = damage
	number.critical = is_critical
	_place(number, parent, at)
	return number


## Makes a pop-up of [param said] instead of a number, in [param colour]:
## how a cut on the chopping board went. [param big] pops it in large, as a
## critical's number does.
static func spawn_words(parent: Node, at: Vector3, said: String, colour: Color,
		big: bool = false) -> DamageNumber:
	var label: DamageNumber = DamageNumber.new()
	label.words = said
	label.words_colour = colour
	label.critical = big
	label.rise = 0.22
	_place(label, parent, at)
	return label


# Puts [param label] at [param at] in the world, as a child of [param parent].
# It's placed before it joins the tree, so it rises from there: it notes
# where it starts as it becomes ready.
static func _place(label: DamageNumber, parent: Node, at: Vector3) -> void:
	var space: Node3D = parent as Node3D
	label.position = space.global_transform.affine_inverse() * at \
			if space != null and space.is_inside_tree() else at
	parent.add_child(label)


func _ready() -> void:
	text = words if not words.is_empty() else str(amount)
	font = FONT
	font_size = 128 if critical else 84
	pixel_size = 0.004
	outline_size = 18
	outline_modulate = Color(0.12, 0.08, 0.06, 1.0)
	modulate = CRITICAL_COLOUR if critical else NORMAL_COLOUR
	if not words.is_empty():
		modulate = words_colour
		font_size = 30 if critical else 24
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	# Drawn after the world, over the crab and its particles.
	render_priority = 10
	outline_render_priority = 9
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_start = position
	_drift = Vector3(randf_range(-0.25, 0.25), 0.0, randf_range(-0.1, 0.1))


func _process(delta: float) -> void:
	_age += delta
	var through: float = clampf(_age / lifetime, 0.0, 1.0)
	# Quick up, then slowing: an ease out.
	var lift: float = 1.0 - pow(1.0 - through, 3.0)
	position = _start + Vector3.UP * rise * lift + _drift * through
	# A critical pops in large and settles.
	var pop: float = 1.0 + (0.5 * (1.0 - minf(through * 5.0, 1.0)) if critical else 0.0)
	scale = Vector3.ONE * pop
	# Fades over its last half.
	var alpha: float = clampf(2.0 - through * 2.0, 0.0, 1.0)
	modulate.a = alpha
	outline_modulate.a = alpha
	if _age >= lifetime:
		queue_free()
