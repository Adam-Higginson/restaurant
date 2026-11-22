class_name Duellist
extends Node
## The player's side of a duel: their [Hearts], the knife strike, the
## frying-pan parry, and what happens when the hearts run out.
##
## A child of the [Player3D]. It holds no rules of its own: [Hearts],
## [ParryWindow], [KnifeCombo] and [DefeatLoss] do the deciding, and this
## connects them to the buttons, the toolbar, the lantern and the little
## knife and pan on the player's model. See Combat in docs/GDD.md.
##
## - Use tool, with nothing here for a tool to work on, cuts with the knife
##   at whatever is in front (the [InteractionDetector3D] says when): taps
##   chain the chop, slice and cleave, and holding on charges a spinning
##   fillet, let go on release. Each cut is a [KnifeCut] in data/combat/.
##   It lands a moment into its swing ([member KnifeCut.hit_at]).
## - Parry raises the pan for a moment, if there's a frying pan anywhere on
##   the toolbar. A hit landing in that moment is turned away.
## - What all of this sounds like is [DuelSounds]' job, which listens to the
##   signals below.
## - With no hearts left, the lantern pulls the player back to the landing
##   (a node in the [constant LANDING_GROUP] group) and half of what they
##   carry is lost.

## Emitted as a cut of the knife starts.
signal cut_started(cut: KnifeCut)
## Emitted when a cut reaches the moment it lands. [param hit] says whether
## it counted on anything.
signal struck(hit: bool)
## Emitted for each crab a cut counts on (or flips). [param cleared] says
## whether it was the cut that cleared its fog.
signal strike_landed(crab: FogCrab, cleared: bool, cut: KnifeCut)
## Emitted when a swing reaches a creature that isn't open, so it doesn't count.
signal glanced
## Emitted when the pan goes up.
signal pan_raised
## Emitted when a hit is turned away by the pan.
signal parried
## Emitted, after [signal parried], when the pan went up just in time: a
## perfect parry.
signal parried_perfectly
## Emitted when a hit lands, with the half-hearts it cost.
signal hurt(halves: int)
## Emitted after a defeat, with the items that were lost.
signal defeated(lost: Array[ItemInstance])

## What became of a blow aimed at the player.
enum Hit {
	## It landed: hearts were lost.
	LANDED,
	## The pan turned it away.
	PARRIED,
	## The pan, raised just in time, turned it away: a perfect parry.
	PARRIED_PERFECTLY,
	## It came while they were still reeling from the last one, and did nothing.
	IGNORED,
}

## The group the duellist is in, so creatures can find who to fight.
const GROUP: StringName = &"duellist"
## A node in this group is where a defeat puts the player back.
const LANDING_GROUP: StringName = &"landing"
## The item that parries.
const PAN_ID: StringName = &"frying_pan"
const CHOP: KnifeCut = preload("res://data/combat/chop.tres")
const SLICE: KnifeCut = preload("res://data/combat/slice.tres")
const CLEAVE: KnifeCut = preload("res://data/combat/cleave.tres")
const FILLET: KnifeCut = preload("res://data/combat/fillet.tres")
const WEAK_SPIN: KnifeCut = preload("res://data/combat/weak_spin.tres")

## How many hearts the player has.
@export var max_hearts: int = 3
@export_group("Knife")
## The cuts that taps of Use tool chain, in order.
@export var chain: Array[KnifeCut] = [CHOP, SLICE, CLEAVE]
## The spin a full charge lets go.
@export var fillet: KnifeCut = FILLET
## The spin a charge let go too early gives.
@export var weak_spin: KnifeCut = WEAK_SPIN
## How long after a cut a tap still carries on the chain, in seconds.
@export var chain_window_seconds: float = 0.4
## How long Use tool must be held before it starts to charge, in seconds.
@export var charge_delay_seconds: float = 0.3
## How long Use tool must be held for a full charge, in seconds.
@export var charge_full_seconds: float = 1.0
## How much of their speed the player walks at while charging.
@export_range(0.0, 1.0) var charge_walk_factor: float = 0.5
@export_group("Pan")
## How long the pan stays up after a press, in seconds: the parry window.
@export var parry_window_seconds: float = 0.3
## How long after the window before the pan can go up again, in seconds.
@export var parry_recovery_seconds: float = 0.4
## How soon after the pan goes up a blow must land to be parried perfectly,
## flipping a crab, in seconds.
@export var parry_perfect_seconds: float = 0.12
@export_group("Blows taken")
## How long after a blow lands before another can, in seconds.
@export var invulnerable_seconds: float = 1.0
## How hard a blow throws the player back, in metres per second.
@export var knockback_speed: float = 7.0
## How long a blow leaves the player stumbling, deaf to the stick, in seconds.
@export var stumble_seconds: float = 0.3
@export_group("In hand")
## Where the knife sits in the character's right hand, when there's a
## character (not the greybox): scaled to fit a hand, the handle through the
## curled fingers and the blade out by the thumb. The hand bone starts at the
## wrist and runs along +Y to the knuckles; the right hand's fingers curl
## round towards -X, so the hole in the fist is up and to that side.
@export var knife_grip: Transform3D = Transform3D(
		Basis(Vector3.UP, PI).scaled(Vector3.ONE * 0.35), Vector3(-0.006, 0.097, -0.16))
## Where the pan sits in the character's left hand, when there's a character:
## the handle through the curled fingers, the pan raised like a shield. The
## left hand mirrors the right: its fingers curl round towards +X.
@export var pan_grip: Transform3D = Transform3D(
		Basis(Vector3.RIGHT, PI).scaled(Vector3.ONE * 0.6), Vector3(0.035, 0.115, 0.36))

## The player's health. Created once and never replaced.
var hearts: Hearts = null
## The timing of the pan. Created once and never replaced.
var parry: ParryWindow = ParryWindow.new()
## Which cut the knife makes. Created once and never replaced.
var combo: KnifeCombo = KnifeCombo.new()

## The cut waiting to land, or null.
var _landing: KnifeCut = null
## Seconds until it lands.
var _land_left: float = 0.0
## Seconds left before another blow can land.
var _invulnerable_left: float = 0.0
## The crab whose fight the lantern is showing, or null.
var _shown: FogCrab = null
## Whether the knife and pan are in the character's hands, rather than
## posed by code in front of the greybox.
var _in_hands: bool = false
## Where the knife and pan sit on the greybox, to put them back.
var _knife_home: Transform3D
var _pan_home: Transform3D

@onready var _player: Player3D = get_parent() as Player3D
@onready var _detector: InteractionDetector3D = $"../InteractionDetector"
@onready var _lock_on: LockOn = $"../LockOn"
@onready var _spirit: LanternSpirit = $"../LanternSpirit"
@onready var _knife: Node3D = $"../Model/Knife"
@onready var _pan: Node3D = $"../Model/Pan"
@onready var _model: Node3D = $"../Model"
@onready var _character: CharacterModel = get_node_or_null("../Model/Character") as CharacterModel


func _ready() -> void:
	add_to_group(GROUP)
	hearts = Hearts.new(max_hearts)
	parry.window_seconds = parry_window_seconds
	parry.recovery_seconds = parry_recovery_seconds
	parry.perfect_seconds = parry_perfect_seconds
	combo.chain = chain
	combo.fillet = fillet
	combo.weak_spin = weak_spin
	combo.chain_window_seconds = chain_window_seconds
	combo.charge_delay_seconds = charge_delay_seconds
	combo.charge_full_seconds = charge_full_seconds
	combo.cut_started.connect(_on_cut_started)
	_detector.tool_missed.connect(press_knife)
	_lock_on.target_changed.connect(_on_target_changed)
	_knife.hide()
	_pan.hide()
	_knife_home = _knife.transform
	_pan_home = _pan.transform
	if _character != null:
		_character.dressed.connect(_hold)
		_hold(_character.character != null)


func _physics_process(delta: float) -> void:
	parry.tick(delta)
	combo.tick(delta)
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	if _landing != null:
		_land_left -= delta
		if _land_left <= 0.0:
			var cut: KnifeCut = _landing
			_landing = null
			_land(cut)
	_player.stride_factor = charge_walk_factor if combo.is_charging() else 1.0


func _process(_delta: float) -> void:
	_pose_knife_and_pan()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("parry"):
		get_viewport().set_input_as_handled()
		raise_pan()
	elif event.is_action_released("use_tool"):
		# The press went to the detector, which says when it's the knife's.
		release_knife()


## Where the player is, for whatever is fighting them.
func position() -> Vector3:
	return _player.global_position


## Use tool going down with nothing here for a tool to work on: the next cut
## of the chain, or if one is being made, the next once it ends. Held on, it
## charges. Returns whether the knife took the press: not without a tool,
## or while the player can't act.
func press_knife() -> bool:
	if not _can_cut():
		return false
	combo.press()
	return true


## Use tool coming up: lets go a charged spin, if it was charging.
func release_knife() -> void:
	if not _can_cut():
		combo.cancel_charge()
		return
	combo.release()


## A tap of the knife: pressed and let go at once. Returns whether a cut
## started now (a tap mid-cut waits for it, and returns false).
func strike() -> bool:
	if not _can_cut():
		return false
	var started: bool = combo.press()
	combo.release()
	return started


## Whether the knife is mid-cut.
func is_striking() -> bool:
	return combo.is_cutting()


## Whether the knife is charging.
func is_charging() -> bool:
	return combo.is_charging()


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
	combo.cancel_charge()
	pan_raised.emit()
	return true


## Whether a blow would do nothing right now, because the last one landed
## too recently.
func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


## A blow of [param halves] half-hearts arriving from [param from], a place in
## the world. Says what became of it (see [enum Hit]). One that lands throws
## the player back away from [param from]; losing the last heart is a defeat.
func receive_hit(halves: int, from: Vector3) -> Hit:
	if parry.is_active() and has_pan():
		var perfect: bool = parry.is_perfect()
		parry.spend()
		_spirit.excite()
		parried.emit()
		if perfect:
			parried_perfectly.emit()
			return Hit.PARRIED_PERFECTLY
		return Hit.PARRIED
	if is_invulnerable():
		return Hit.IGNORED
	hearts.hurt(halves)
	_invulnerable_left = invulnerable_seconds
	# A blow breaks a cut, its chain and a charge.
	combo.reset()
	_landing = null
	_player.knock_back(flat_direction(from, _player.global_position) * knockback_speed,
			stumble_seconds)
	hurt.emit(halves)
	if hearts.is_empty():
		_fall()
	return Hit.LANDED


## The flat direction from [param from] to [param to], ignoring height: the
## way a blow pushes. Zero if they're in the same spot.
static func flat_direction(from: Vector3, to: Vector3) -> Vector3:
	var away: Vector3 = Vector3(to.x - from.x, 0.0, to.z - from.z)
	return away.normalized() if away.length() > 0.001 else Vector3.ZERO


## Whether [param point] is within a swing from [param from], facing
## [param facing]: no further than [param reach] metres along the ground,
## and inside an arc [param arc_degrees] wide centred on the facing.
static func in_reach(from: Vector3, facing: Vector3, point: Vector3, reach: float,
		arc_degrees: float) -> bool:
	var away: Vector2 = Vector2(point.x - from.x, point.z - from.z)
	if away.length() > reach:
		return false
	var ahead: Vector2 = Vector2(facing.x, facing.z)
	# Standing on top of it, or facing nowhere, there's no angle to miss by;
	# and a swing all round misses nothing. (Straight behind is an angle of pi,
	# which in the vectors' single precision comes out a hair over half of 360.)
	if away.length() < 0.01 or ahead.length() < 0.01 or arc_degrees >= 360.0:
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
		_player.knock_back(Vector3.ZERO, 0.0)
		# A jump, not a move: draw them there at once rather than gliding over.
		_player.reset_physics_interpolation()
	hearts.refill()
	_spirit.snap_to_player()
	_spirit.remark(&"pulled_out")
	defeated.emit(lost)


# Whether the player can use the knife now: they're free to act and carry a
# tool.
func _can_cut() -> bool:
	return _player.controls_enabled and not _player.is_dodging() \
			and not _player.toolbar.get_tools().is_empty()


# A cut starting: the step forward with it, and its landing a moment later.
func _on_cut_started(cut: KnifeCut) -> void:
	if cut.step > 0.0:
		_player.lunge(_player.facing * cut.step)
	_landing = cut
	_land_left = cut.hit_at
	cut_started.emit(cut)


# [param cut] meeting every fog-crab in its reach: each that's open takes
# its damage and is knocked back; a fillet flips one that's mid-lunge.
func _land(cut: KnifeCut) -> void:
	var hit: bool = false
	var reached: bool = false
	for crab: FogCrab in _crabs():
		if not in_reach(_player.global_position, _player.facing, crab.global_position,
				cut.reach, cut.arc_degrees):
			continue
		reached = true
		var push: Vector3 = flat_direction(_player.global_position, crab.global_position) \
				* cut.push
		if crab.take_strike(push, cut.damage, cut.flips_lunging):
			hit = true
			strike_landed.emit(crab, crab.is_cleared(), cut)
			if crab.is_cleared():
				_spirit.remark(&"fog_cleared")
	struck.emit(hit)
	if reached and not hit:
		glanced.emit()


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
		CrabCycle.State.OPENING, CrabCycle.State.STAGGERED, CrabCycle.State.FLIPPED:
			return LanternSpirit.Mood.OPEN
	return LanternSpirit.Mood.CALM


# Puts the knife and pan in the character's hands when [param in_hands],
# or back on the greybox.
func _hold(in_hands: bool) -> void:
	_in_hands = in_hands and _character.right_hand != null
	if _in_hands:
		_knife.reparent(_character.right_hand, false)
		_knife.transform = knife_grip
		_pan.reparent(_character.left_hand, false)
		_pan.transform = pan_grip
	else:
		if _knife.get_parent() != _model:
			_knife.reparent(_model, false)
		if _pan.get_parent() != _model:
			_pan.reparent(_model, false)
		_knife.transform = _knife_home
		_pan.transform = _pan_home


# Shows the knife during a swing and the pan held up while a parry would
# work. In the character's hands the animation moves them; on the greybox,
# the knife sweeps across in front.
func _pose_knife_and_pan() -> void:
	_knife.visible = combo.is_cutting() or combo.is_charging()
	if combo.is_cutting() and not _in_hands:
		var through: float = combo.cut_progress()
		_knife.rotation.y = lerpf(deg_to_rad(70.0), deg_to_rad(-70.0), through)
	_pan.visible = parry.is_active()
