class_name Dodge
extends Node
## Jumping out of the way, as in Ocarina of Time. Interact, with nothing in
## front to use it on, dodges (the [InteractionDetector3D] says when):
##
## - Locked on, the stick picks the move, against the way the player faces
##   the target: left or right sidehops, back (or the stick left alone)
##   backflips, forward rolls in towards it.
## - Not locked on, a roll the way the stick points, if it's pushed.
##
## Not while the knife is mid-cut or charging: charging leaves you open.
## A dodge breaks off the knife's chain. A child of the [Player3D], which
## carries the move out; the moves are [DodgeMove]s in data/combat/.

## Which way of dodging.
enum Kind { NONE, SIDEHOP_LEFT, SIDEHOP_RIGHT, BACKFLIP, ROLL }

const SIDEHOP: DodgeMove = preload("res://data/combat/sidehop.tres")
const BACKFLIP: DodgeMove = preload("res://data/combat/backflip.tres")
const ROLL: DodgeMove = preload("res://data/combat/roll.tres")

## The hop to either side.
@export var sidehop: DodgeMove = SIDEHOP
## The flip away from the target.
@export var backflip: DodgeMove = BACKFLIP
## The roll, in towards the target or the way the stick points.
@export var roll: DodgeMove = ROLL

@onready var _player: Player3D = get_parent() as Player3D
@onready var _detector: InteractionDetector3D = $"../InteractionDetector"
@onready var _duellist: Duellist = get_node_or_null("../Duellist") as Duellist


func _ready() -> void:
	_detector.interact_missed.connect(try_dodge)


## Dodges the way the stick and lock-on say, if the player can. Returns
## whether they dodged.
func try_dodge() -> bool:
	if not can_dodge():
		return false
	var stick: Vector3 = _player.stick_direction()
	var kind: Kind = kind_for(stick, _player.facing, _is_locked())
	if kind == Kind.NONE:
		return false
	if not _player.dodge(move_for(kind), direction_for(kind, stick, _player.facing)):
		return false
	if _duellist != null:
		_duellist.combo.reset()
	return true


## Whether a dodge could start now: the player can move and the knife isn't
## mid-cut or charging.
func can_dodge() -> bool:
	if not _player.can_dodge():
		return false
	return _duellist == null or not (_duellist.is_striking() or _duellist.is_charging())


## What Interact would do with nothing in front of the player, for the action
## prompt: the dodge's name while locked on, otherwise nothing ("").
func prompt() -> String:
	if not _is_locked() or not can_dodge():
		return ""
	var move: DodgeMove = move_for(kind_for(_player.stick_direction(), _player.facing, true))
	return move.display_name if move != null else ""


## The move for [param kind], or null for none.
func move_for(kind: Kind) -> DodgeMove:
	match kind:
		Kind.SIDEHOP_LEFT, Kind.SIDEHOP_RIGHT:
			return sidehop
		Kind.BACKFLIP:
			return backflip
		Kind.ROLL:
			return roll
	return null


## Which dodge the stick, pointing along the flat world direction
## [param stick] (zero when left alone), makes for a player facing
## [param facing]: locked on ([param locked]), the side the stick is
## pushed most towards picks it; not locked on, a roll if it's pushed.
static func kind_for(stick: Vector3, facing: Vector3, locked: bool) -> Kind:
	var pushed: bool = Vector2(stick.x, stick.z).length() > 0.2
	if not locked:
		return Kind.ROLL if pushed else Kind.NONE
	if not pushed:
		return Kind.BACKFLIP
	var ahead: float = stick.dot(facing)
	var aside: float = stick.dot(right_of(facing))
	if absf(aside) > absf(ahead):
		return Kind.SIDEHOP_RIGHT if aside > 0.0 else Kind.SIDEHOP_LEFT
	return Kind.ROLL if ahead > 0.0 else Kind.BACKFLIP


## The flat world direction [param kind] goes in, for a player facing
## [param facing] with the stick along [param stick].
static func direction_for(kind: Kind, stick: Vector3, facing: Vector3) -> Vector3:
	match kind:
		Kind.SIDEHOP_RIGHT:
			return right_of(facing)
		Kind.SIDEHOP_LEFT:
			return -right_of(facing)
		Kind.BACKFLIP:
			return -Vector3(facing.x, 0.0, facing.z).normalized()
		Kind.ROLL:
			# The way the stick points (locked on, that's mostly forward).
			return Vector3(stick.x, 0.0, stick.z).normalized()
	return Vector3.ZERO


## The flat direction to the right of [param facing].
static func right_of(facing: Vector3) -> Vector3:
	var flat: Vector3 = Vector3(facing.x, 0.0, facing.z).normalized()
	return flat.cross(Vector3.UP)


func _is_locked() -> bool:
	return is_instance_valid(_player.lock_target)
