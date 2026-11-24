class_name BunkBay
extends StaticBody3D
## A bay of two bunks, one above the other, built against the hull: posts and
## end boards, a ladder, curtains on rails and a little lantern at the head of
## the lower bunk, and a shelf with a candle at the head of the upper one.
##
## Every bay aboard is the same scene, dressed for whoever sleeps in it: its
## quilts, its curtain cloth, whether its curtains are drawn (someone's asleep
## in there), whether each bed is made or slept in, and whether its lantern
## and candle are lit. A drawn curtain with a light on behind it glows,
## because the curtain cloth is backlit.

## How a bed looks: neatly made (quilt smooth and turned back, two pillows, a
## blanket folded at the foot) or slept in (quilt thrown back in a heap).
enum Bedding { MADE, SLEPT_IN }

## How far in front of the left curtain the right one hangs when both are
## bunched open at the head of the bed.
const OPEN_STAGGER: float = 0.025

## The lower bunk's quilt. Leave empty to keep the scene's own.
@export var lower_quilt: Material
## The upper bunk's quilt. Leave empty to keep the scene's own.
@export var upper_quilt: Material
## How the lower bed is left.
@export var lower_bedding: Bedding = Bedding.MADE
## How the upper bed is left.
@export var upper_bedding: Bedding = Bedding.MADE
## The cloth all four curtains are made of. Leave empty to keep the scene's own.
@export var curtain_cloth: Material
## Whether the lower bunk's curtains are drawn across.
@export var lower_curtains_closed: bool = false
## Whether the upper bunk's curtains are drawn across.
@export var upper_curtains_closed: bool = false
## Whether the little lantern at the head of the lower bunk is lit.
@export var lamp_lit: bool = false
## Whether the candle on the shelf at the head of the upper bunk is lit.
@export var upper_lamp_lit: bool = false

@onready var _lamp: Node3D = $Lamp
@onready var _upper_candle: Node3D = $UpperCandle


func _ready() -> void:
	_make_bed("Lower", lower_bedding, lower_quilt)
	_make_bed("Upper", upper_bedding, upper_quilt)
	_hang_curtains("Lower", lower_curtains_closed)
	_hang_curtains("Upper", upper_curtains_closed)
	# Hiding a light switches it off.
	_lamp.visible = lamp_lit
	_upper_candle.visible = upper_lamp_lit


## Where one curtain hangs on its rail: x is how far its middle is from the
## bay's middle (the left curtain [param side] -1, the right one 1), and y is
## how much of its full width it's spread to. Drawn, the two meet in the
## middle and cover the bunk; open, both are bunched up together at the left
## end of the rail, the head of the bed, clear of the ladder at the right
## end (#204: bunched there, they hung through it).
static func curtain_layout(closed: bool, side: int) -> Vector2:
	if closed:
		return Vector2(side * 0.49, 1.0)
	return Vector2(-0.85 if side < 0 else -0.74, 0.25)


## Which of a bed's pieces show for [param bedding]: the neat ones (the
## smooth quilt, its turned-back fold and front edge, a second pillow and a
## blanket folded at the foot) when made, the heap when slept in.
static func shows_when_made(piece: String) -> bool:
	return piece in ["Quilt", "QuiltFold", "QuiltDrape", "PillowSmall", "FootBlanket"]


func _make_bed(tier: String, bedding: Bedding, quilt: Material) -> void:
	var made: bool = bedding == Bedding.MADE
	for piece: String in ["Quilt", "QuiltFold", "QuiltDrape", "PillowSmall", "FootBlanket",
			"QuiltHeap"]:
		(get_node(tier + piece) as Node3D).visible = made == shows_when_made(piece)
	if quilt == null:
		return
	# Everything cut from the quilt takes its cloth, made or heaped.
	var cloth: Array[Node] = [get_node(tier + "Quilt"), get_node(tier + "QuiltFold"),
			get_node(tier + "QuiltDrape")]
	cloth.append_array(get_node(tier + "QuiltHeap").get_children())
	for node: Node in cloth:
		(node as MeshInstance3D).material_override = quilt


func _hang_curtains(tier: String, closed: bool) -> void:
	for side: int in [-1, 1]:
		var curtain: Node3D = get_node("%sCurtain%s" % [tier, "Left" if side < 0 else "Right"]) \
				as Node3D
		var layout: Vector2 = curtain_layout(closed, side)
		curtain.position.x = layout.x
		if not closed and side > 0:
			# Bunched in front of the left one, so the two cloths don't
			# share a plane and flicker.
			curtain.position.z += OPEN_STAGGER
		# The cloth is a child of the swinging curtain, so the swing (which
		# keeps the curtain's own turn and scale) doesn't undo the bunching.
		var cloth: MeshInstance3D = curtain.get_node("Cloth") as MeshInstance3D
		cloth.scale.x = layout.y
		if curtain_cloth != null:
			cloth.material_override = curtain_cloth
