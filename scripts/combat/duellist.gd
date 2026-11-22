class_name Duellist
extends Node
## The player's side of a duel: their [Hearts], the knife strike, the
## frying-pan parry, and what happens when the hearts run out.
##
## A child of the [Player3D]. It holds no rules of its own: [Hearts],
## [ParryWindow] and [DefeatLoss] do the deciding, and this connects them to
## the buttons, the toolbar, the lantern and the little knife and pan on the
## player's model. See Combat in docs/GDD.md.
##
## - Use tool, with nothing here for a tool to work on, swings the knife at
##   whatever is in front (the [InteractionDetector3D] says when).
## - Parry raises the pan for a moment, if there's a frying pan anywhere on
##   the toolbar. A hit landing in that moment is turned away.
## - What all of this sounds like is [DuelSounds]' job, which listens to the
##   signals below.
## - With no hearts left, the lantern pulls the player back to the landing
##   (a node in the [constant LANDING_GROUP] group) and half of what they
##   carry is lost.

## Emitted when the knife is swung. [param hit] says whether it counted on
## anything.
signal struck(hit: bool)
## Emitted when a swing reaches a creature that isn't open, so it doesn't count.
signal glanced
## Emitted when the pan goes up.
signal pan_raised
## Emitted when a hit is turned away by the pan.
signal parried
## Emitted when a hit lands, with the half-hearts it cost.
signal hurt(halves: int)
## Emitted after a defeat, with the items that were lost.
signal defeated(lost: Array[ItemInstance])

## The group the duellist is in, so creatures can find who to fight.
const GROUP: StringName = &"duellist"
## A node in this group is where a defeat puts the player back.
const LANDING_GROUP: StringName = &"landing"
## The item that parries.
const PAN_ID: StringName = &"frying_pan"

## How many hearts the player has.
@export var max_hearts: int = 3
## How far the knife reaches, in metres from the player's centre.
@export var strike_reach: float = 2.0
## How wide the swing is, in degrees, centred on the way the player faces.
@export var strike_arc_degrees: float = 120.0
## How long a swing takes, in seconds. Another can't start until it's done.
@export var strike_seconds: float = 0.5
## How long the pan stays up after a press, in seconds: the parry window.
@export var parry_window_seconds: float = 0.3
## How long after the window before the pan can go up again, in seconds.
@export var parry_recovery_seconds: float = 0.4

## The player's health. Created once and never replaced.
var hearts: Hearts = null
## The timing of the pan. Created once and never replaced.
var parry: ParryWindow = ParryWindow.new()

## Seconds left of the current swing.
var _strike_left: float = 0.0
## The crab whose fight the lantern is showing, or null.
var _shown: FogCrab = null

@onready var _player: Player3D = get_parent() as Player3D
@onready var _detector: InteractionDetector3D = $"../InteractionDetector"
@onready var _lock_on: LockOn = $"../LockOn"
@onready var _spirit: LanternSpirit = $"../LanternSpirit"
@onready var _knife: Node3D = $"../Model/Knife"
@onready var _pan: Node3D = $"../Model/Pan"


func _ready() -> void:
	add_to_group(GROUP)
	hearts = Hearts.new(max_hearts)
	parry.window_seconds = parry_window_seconds
	parry.recovery_seconds = parry_recovery_seconds
	_detector.tool_missed.connect(strike)
	_lock_on.target_changed.connect(_on_target_changed)
	_knife.hide()
	_pan.hide()


func _physics_process(delta: float) -> void:
	parry.tick(delta)
	_strike_left = maxf(_strike_left - delta, 0.0)


func _process(_delta: float) -> void:
	_pose_knife_and_pan()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("parry"):
		get_viewport().set_input_as_handled()
		raise_pan()


## Where the player is, for whatever is fighting them.
func position() -> Vector3:
	return _player.global_position


## Swings the knife at every fog-crab in reach in front of the player.
## Returns whether it swung: not mid-swing, without a tool, or while the
## player can't act.
func strike() -> bool:
	if not _player.controls_enabled or _strike_left > 0.0:
		return false
	if _player.toolbar.get_tools().is_empty():
		return false
	_strike_left = strike_seconds
	var hit: bool = false
	var reached: bool = false
	for crab: FogCrab in _crabs():
		if not in_reach(_player.global_position, _player.facing, crab.global_position,
				strike_reach, strike_arc_degrees):
			continue
		reached = true
		if crab.take_strike():
			hit = true
			if crab.is_cleared():
				_spirit.remark(&"fog_cleared")
	struck.emit(hit)
	if reached and not hit:
		glanced.emit()
	return true


## Whether the knife is mid-swing.
func is_striking() -> bool:
	return _strike_left > 0.0


## Whether a frying pan is anywhere on the toolbar, so a parry can work.
func has_pan() -> bool:
	return _player.toolbar.has_item(PAN_ID)


## Raises the pan to parry. Returns whether it went up: not without a pan,
## too soon after the last time, or while the player can't act.
func raise_pan() -> bool:
	if not _player.controls_enabled or not has_pan():
		return false
	if not parry.press():
		return false
	pan_raised.emit()
	return true


## A hit of [param halves] half-hearts arriving. Returns whether it landed:
## false if the pan turned it away. Losing the last heart is a defeat.
func receive_hit(halves: int) -> bool:
	if parry.is_active() and has_pan():
		parry.spend()
		_spirit.excite()
		parried.emit()
		return false
	hearts.hurt(halves)
	hurt.emit(halves)
	if hearts.is_empty():
		_fall()
	return true


## Whether [param point] is within a swing from [param from], facing
## [param facing]: no further than [param reach] metres along the ground,
## and inside an arc [param arc_degrees] wide centred on the facing.
static func in_reach(from: Vector3, facing: Vector3, point: Vector3, reach: float,
		arc_degrees: float) -> bool:
	var away: Vector2 = Vector2(point.x - from.x, point.z - from.z)
	if away.length() > reach:
		return false
	var ahead: Vector2 = Vector2(facing.x, facing.z)
	# Standing on top of it, or facing nowhere, there's no angle to miss by.
	if away.length() < 0.01 or ahead.length() < 0.01:
		return true
	return absf(ahead.angle_to(away)) <= deg_to_rad(arc_degrees) / 2.0


# The defeat: half the items go, the lantern pulls the player back to the
# landing, and their hearts are full again.
func _fall() -> void:
	var lost: Array[ItemInstance] = DefeatLoss.take_half(_player.toolbar)
	_lock_on.release()
	var landing: Node3D = get_tree().get_first_node_in_group(LANDING_GROUP) as Node3D
	if landing != null:
		_player.global_position = landing.global_position
		_player.velocity = Vector3.ZERO
		# A jump, not a move: draw them there at once rather than gliding over.
		_player.reset_physics_interpolation()
	hearts.refill()
	_spirit.snap_to_player()
	_spirit.remark(&"pulled_out")
	defeated.emit(lost)


func _crabs() -> Array[FogCrab]:
	var found: Array[FogCrab] = []
	for node: Node in get_tree().get_nodes_in_group(FogCrab.GROUP):
		var crab: FogCrab = node as FogCrab
		if crab != null:
			found.append(crab)
	return found


# Sends the lantern to hover over what's locked on to, and has his light
# follow that crab's fight: flickering as it rears up, bright when it's open.
func _on_target_changed(target: Node3D) -> void:
	if is_instance_valid(_shown):
		_shown.cycle.state_changed.disconnect(_on_crab_state_changed)
	_shown = target as FogCrab
	_spirit.watch(target)
	if _shown == null:
		_spirit.set_mood(LanternSpirit.Mood.CALM)
		return
	_shown.cycle.state_changed.connect(_on_crab_state_changed)
	_on_crab_state_changed(_shown.cycle.state)


func _on_crab_state_changed(state: CrabCycle.State) -> void:
	_spirit.set_mood(mood_for(state))


## What the lantern's light should say while a crab is in [param state].
static func mood_for(state: CrabCycle.State) -> LanternSpirit.Mood:
	match state:
		CrabCycle.State.WINDUP:
			return LanternSpirit.Mood.WARNING
		CrabCycle.State.OPENING, CrabCycle.State.STAGGERED:
			return LanternSpirit.Mood.OPEN
	return LanternSpirit.Mood.CALM


# Shows the knife sweeping across in front during a swing, and the pan held
# up while a parry would work.
func _pose_knife_and_pan() -> void:
	_knife.visible = _strike_left > 0.0
	if _knife.visible:
		var through: float = 1.0 - _strike_left / strike_seconds
		_knife.rotation.y = lerpf(deg_to_rad(70.0), deg_to_rad(-70.0), through)
	_pan.visible = parry.is_active()
