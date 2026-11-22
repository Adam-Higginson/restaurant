class_name BunkBay
extends StaticBody3D
## A bay of two bunks, one above the other, built against the hull: posts and
## end boards, a ladder, curtains on rails and a little lantern at the head of
## the lower bunk, and a shelf with a candle at the head of the upper one.
##
## Every bay aboard is the same scene, dressed for whoever sleeps in it: its
## quilts, its curtain cloth, whether its curtains are drawn (someone's asleep
## in there) and whether its lantern and candle are lit. A drawn curtain with
## a light on behind it glows, because the curtain cloth is backlit.

## The lower bunk's quilt. Leave empty to keep the scene's own.
@export var lower_quilt: Material
## The upper bunk's quilt. Leave empty to keep the scene's own.
@export var upper_quilt: Material
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

@onready var _lower_quilt: MeshInstance3D = $LowerQuilt
@onready var _upper_quilt: MeshInstance3D = $UpperQuilt
@onready var _lamp: Node3D = $Lamp
@onready var _upper_candle: Node3D = $UpperCandle


func _ready() -> void:
	if lower_quilt != null:
		_lower_quilt.material_override = lower_quilt
	if upper_quilt != null:
		_upper_quilt.material_override = upper_quilt
	_hang_curtains("Lower", lower_curtains_closed)
	_hang_curtains("Upper", upper_curtains_closed)
	# Hiding a light switches it off.
	_lamp.visible = lamp_lit
	_upper_candle.visible = upper_lamp_lit


## Where one curtain hangs on its rail: x is how far its middle is from the
## bay's middle (towards [param side], -1 or 1), and y is how much of its
## full width it's spread to. Drawn, the two meet in the middle and cover the
## bunk; open, each is bunched up at its end of the rail.
static func curtain_layout(closed: bool, side: int) -> Vector2:
	if closed:
		return Vector2(side * 0.49, 1.0)
	return Vector2(side * 0.85, 0.25)


func _hang_curtains(tier: String, closed: bool) -> void:
	for side: int in [-1, 1]:
		var curtain: Node3D = get_node("%sCurtain%s" % [tier, "Left" if side < 0 else "Right"]) \
				as Node3D
		var layout: Vector2 = curtain_layout(closed, side)
		curtain.position.x = layout.x
		# The cloth is a child of the swinging curtain, so the swing (which
		# keeps the curtain's own turn and scale) doesn't undo the bunching.
		var cloth: MeshInstance3D = curtain.get_node("Cloth") as MeshInstance3D
		cloth.scale.x = layout.y
		if curtain_cloth != null:
			cloth.material_override = curtain_cloth
