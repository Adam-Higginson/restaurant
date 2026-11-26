class_name Crab
extends CharacterBody3D
## A wild crab on the shore, worth hunting for supper. It fights whoever comes
## near, in a rhythm you can read: it rears up (the tell), lunges, then sags,
## worn out (the opening). Strike it with the knife while it's open, or parry
## its lunge with the pan to stagger it. Every hit that counts takes its
## damage off the crab's health, shown as a number popping up; a hit on a
## crab flipped onto its back is a critical, for double. When its health is
## gone it dies, and leaves its meat behind to pick up. See Combat in
## docs/GDD.md.
##
## Its [member level] sets its health and how good its meat is. "Lv 1" floats
## over its head.
##
## The rules live in its [member cycle] (a [CrabCycle]); this script walks
## it about, lands its hits on the [Duellist], and acts each state out with
## its model: the whole body rears, lunges and sags, and when the real
## crab model is there ([ThirdPartyModel], greybox otherwise) its own idle
## and walk play, and its claws rise through its arm bones.

## Emitted when it dies.
signal died
## Emitted when it's flipped onto its back (a perfect parry, or a fillet
## mid-lunge).
signal flipped
## Emitted for each hit that counts, with the damage it did and whether it
## was a critical.
signal damaged(amount: int, critical: bool)

## Living crabs can be locked on to.
const GROUP: StringName = LockOn.GROUP
## How much health it has for each level.
const HEALTH_PER_LEVEL: int = 80
## How many times the damage a hit on a crab on its back does.
const CRITICAL_FACTOR: int = 2
## The best quality meat there is.
const MAX_MEAT_QUALITY: int = 3
const CRAB_MEAT: Item = preload("res://data/items/crab_meat.tres")
## How long it flashes white when a strike lands, in seconds.
const FLASH_SECONDS: float = 0.12
## The real model's animations: standing and scuttling.
const IDLE_ANIMATION: StringName = &"idle"
const WALK_ANIMATION: StringName = &"walk"
## The real model's upper arm bones, which lift the claws.
const ARM_BONES: PackedStringArray = ["left arm 1.1", "right arm 1.1"]
## How far the claws lift at the height of the rear-up, in radians.
const CLAW_LIFT: float = 0.9
## A model cut into loose parts (the Meshy crab, tools/meshy/split_crab.py)
## has no skeleton: its legs and claws are moved here. How fast the legs
## step as it scuttles (radians a second), how far each swings fore and aft
## and lifts (radians), and how much of that they keep up standing still.
const LEG_RATE: float = 16.0
const LEG_SWING: float = 0.38
const LEG_LIFT: float = 0.3
const LEG_FIDGET: float = 0.18
## How high its model is lifted on its back, in metres, so the shell rests
## on the ground.
const FLIPPED_HEIGHT: float = 0.6
## How long it takes to roll onto its back, or back up, in seconds.
const FLIP_TURN_SECONDS: float = 0.18
## How much faster its legs scrabble on its back than when it walks.
const FLAIL_SPEED: float = 3.0
## How high over its middle a damage number starts, in metres.
const NUMBER_HEIGHT: float = 0.9

## How tough it is. Sets its health ([method health_for]) and its meat's
## quality ([method meat_quality_for]).
@export var level: int = 1
## Its health, if not the one its level gives (0 means from its level). For
## tuning and tests.
@export var health_override: int = 0
## How long it rears up before attacking, in seconds: the tell.
@export var windup_seconds: float = 0.8
## How long, at the end of the tell, it stops turning to follow you, in
## seconds: it lunges where it was aiming, so a dodge gets out of the way.
@export var commit_seconds: float = 0.2
## How long the lunge lasts, in seconds.
@export var attack_seconds: float = 0.25
## How long it's open after an attack, in seconds.
@export var opening_seconds: float = 1.2
## How long a parry staggers it, in seconds.
@export var stagger_seconds: float = 1.5
## How long it lies on its back once flipped, in seconds.
@export var flip_seconds: float = 3.0
## How many half-hearts its hit costs.
@export var damage: int = 1
## How near the player must come before it fights, in metres.
@export var notice_range: float = 7.0
## How far its lunge reaches, in metres. Further away than this as the
## attack lands, and it misses.
@export var attack_reach: float = 2.0
## How wide its lunge is, in degrees, centred on the way it faces. Outside
## it (a sidehop away), the lunge misses.
@export var lunge_arc_degrees: float = 70.0
## How fast it scuttles in while rearing up, in metres per second.
@export var scuttle_speed: float = 2.5
## How fast a knock back dies away, in metres per second, per second.
@export var skid_fade: float = 18.0
## How long its body lies there once dead, in seconds, before it sinks.
@export var linger_seconds: float = 4.0
## How long it takes to sink into the sand, in seconds.
@export var sink_seconds: float = 1.5
## What it leaves behind when it dies.
@export var meat: Item = CRAB_MEAT

## Its fight: which state it's in and the damage it has taken.
var cycle: CrabCycle = CrabCycle.new()
## Whether the last hit that counted was a critical.
var last_hit_critical: bool = false

var _duellist: Duellist = null
## Seconds since it died.
var _dead_for: float = 0.0
## Seconds left of the flinch after a strike that counted.
var _flinch_left: float = 0.0
## The flat velocity a strike knocked it back with, dying away.
var _skid: Vector3 = Vector3.ZERO
## Seconds left of the white flash after a strike that counted.
var _flash_left: float = 0.0
var _time: float = 0.0
## How far the claws are lifted, from 0 to 1, set as it acts each state out.
var _claws: float = 0.0
## Every mesh in its model, which the flash lays white over.
var _meshes: Array[GeometryInstance3D] = []
## The white laid over its meshes as a strike lands. Unshaded, so it shows
## as pure white whatever the light.
var _flash: StandardMaterial3D = StandardMaterial3D.new()
## Whether the flash is laid over the meshes right now.
var _flashing: bool = false
## The real model's animations and skeleton, or null on the greybox.
var _animator: AnimationPlayer = null
var _skeleton: Skeleton3D = null
## The real model's loose legs and claws, if it's made of parts, and how
## each sits at rest.
var _legs: Array[Node3D] = []
var _claw_parts: Array[Node3D] = []
var _rests: Dictionary[Node3D, Transform3D] = {}
## How far through their stepping the legs are, in radians.
var _stride: float = 0.0
## Moves its animation on in steps, if its look says so.

@onready var _model: Node3D = $Model
@onready var _claw_left: Node3D = $Model/ClawLeft
@onready var _claw_right: Node3D = $Model/ClawRight
@onready var _chips: CPUParticles3D = $Chips
@onready var _level_label: Label3D = $LevelLabel
@onready var _shape: CollisionShape3D = $Shape
@onready var _dresser: ThirdPartyModel = get_node_or_null("Model/Crab") as ThirdPartyModel


func _ready() -> void:
	add_to_group(GROUP)
	cycle.windup_seconds = windup_seconds
	cycle.commit_seconds = commit_seconds
	cycle.attack_seconds = attack_seconds
	cycle.opening_seconds = opening_seconds
	cycle.stagger_seconds = stagger_seconds
	cycle.flip_seconds = flip_seconds
	cycle.health = health_override if health_override > 0 else health_for(level)
	cycle.attacked.connect(_on_attacked)
	cycle.died.connect(_on_died)
	cycle.state_changed.connect(func(state: CrabCycle.State) -> void:
		if state == CrabCycle.State.FLIPPED:
			flipped.emit())
	_level_label.text = "Lv %d" % level
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	find_meshes()
	_find_rig()
	if _dresser != null:
		# The model can be dressed again while the game runs (the painted
		# look does): find its meshes, rig and parts afresh.
		_dresser.dressed.connect(func(_shown: bool) -> void:
			find_meshes()
			_find_rig())


func _physics_process(delta: float) -> void:
	_time += delta
	_flinch_left = maxf(_flinch_left - delta, 0.0)
	_flash_left = maxf(_flash_left - delta, 0.0)
	if is_dead():
		# Its shape is off, so it mustn't move: it would fall through the floor.
		_lie_dead(delta)
		return
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity += get_gravity() * delta
	_fight(delta)
	velocity.x += _skid.x
	velocity.z += _skid.z
	_skid = _skid.move_toward(Vector3.ZERO, skid_fade * delta)
	move_and_slide()


func _process(delta: float) -> void:
	_act_out()
	_animate(delta)


## The health a crab of [param of_level] has.
static func health_for(of_level: int) -> int:
	return HEALTH_PER_LEVEL * maxi(of_level, 1)


## How good the meat of a crab of [param of_level] is: its level, from ★ up
## to ★★★.
static func meat_quality_for(of_level: int) -> int:
	return clampi(of_level, ItemInstance.MIN_QUALITY, MAX_MEAT_QUALITY)


## A knife strike doing [param damage_done], knocking it back along
## [param push] (a flat velocity in metres per second, dying away) if it
## counts. Counts only while it's open; returns whether it did. On its back
## it's a critical, doing [constant CRITICAL_FACTOR] times the damage. One
## that counts pops up its damage, makes the crab flash white and throws
## chips of shell off it.
##
## If [param flips_lunging] (the fillet) and it's mid-lunge, it does no damage
## but flips it onto its back instead, which also returns true.
func take_strike(push: Vector3 = Vector3.ZERO, damage_done: int = 1,
		flips_lunging: bool = false) -> bool:
	if is_dead():
		return false
	var critical: bool = is_flipped()
	var flipped_now: bool = flips_lunging and cycle.flip()
	var dealt: int = damage_done * (CRITICAL_FACTOR if critical else 1)
	if not flipped_now:
		if not cycle.take_strike(dealt):
			return false
		last_hit_critical = critical
		DamageNumber.spawn(get_parent(), global_position + Vector3.UP * NUMBER_HEIGHT, dealt,
				critical)
		damaged.emit(dealt, critical)
	_flinch_left = 0.2
	_flash_left = FLASH_SECONDS
	_skid = Vector3(push.x, 0.0, push.z)
	_chips.restart()
	return true


## The real model's animation that should play: walking while it moves
## across the ground, standing otherwise.
static func animation_for(moving: bool) -> StringName:
	return WALK_ANIMATION if moving else IDLE_ANIMATION


## Which animation the real model is playing, or an empty name on the greybox.
func playing() -> StringName:
	if _animator == null:
		return &""
	return StringName(_animator.current_animation)


## How far its claws are lifted now, from 0 (resting) to 1 (reared up).
func claw_lift() -> float:
	return _claws


## Whether it's being knocked back by a strike.
func is_skidding() -> bool:
	return not _skid.is_zero_approx()


## Finds every mesh in its model again, for the flash. Call after the model
## changes.
func find_meshes() -> void:
	_meshes.clear()
	for node: Node in _model.find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(node as GeometryInstance3D)
	_flashing = false


## Whether it's dead.
func is_dead() -> bool:
	return cycle.state == CrabCycle.State.DEAD


## How much health it has left.
func health_left() -> int:
	return maxi(cycle.health - cycle.damage_taken, 0)


## Whether its lunge, landing now, would reach [param point]: within its
## [member attack_reach] and inside the [member lunge_arc_degrees] in front.
func lunge_reaches(point: Vector3) -> bool:
	return Duellist.in_reach(global_position, -global_basis.z, point, attack_reach,
			lunge_arc_degrees)


## Whether it's on its back (alive and flipped; a dead crab lies there too).
func is_flipped() -> bool:
	return cycle.state == CrabCycle.State.FLIPPED


## How far over onto its back it is, from 0 (on its feet) to 1 (on its
## back): it rolls over quickly as it's flipped and back up at the end. Dead,
## it rolls over and stays.
func flipped_amount() -> float:
	if is_dead():
		return smoothstep(0.0, 1.0, clampf(_dead_for / FLIP_TURN_SECONDS, 0.0, 1.0))
	if not is_flipped():
		return 0.0
	var into: float = cycle.time_in_state / FLIP_TURN_SECONDS
	var left: float = (cycle.flip_seconds - cycle.time_in_state) / FLIP_TURN_SECONDS
	return smoothstep(0.0, 1.0, clampf(minf(into, left), 0.0, 1.0))


## How far into the sand its body has sunk, from 0 to 1 (0 while it lingers).
func sunk_amount() -> float:
	if not is_dead() or sink_seconds <= 0.0:
		return 0.0
	return clampf((_dead_for - linger_seconds) / sink_seconds, 0.0, 1.0)


# Fights the duellist while they're near: faces them, creeps in as it rears
# up, and lets the cycle run. With nobody near it stands idle.
func _fight(delta: float) -> void:
	var duellist: Duellist = _find_duellist()
	if duellist == null:
		cycle.disengage()
		return
	var away: Vector3 = duellist.position() - global_position
	away.y = 0.0
	var distance: float = away.length()
	if distance > notice_range:
		cycle.disengage()
		return
	cycle.engage()
	# Committed to its lunge, or on its back, it doesn't turn to follow.
	var turns: bool = not cycle.is_committed() and cycle.state != CrabCycle.State.FLIPPED
	if distance > 0.01 and turns:
		rotation.y = atan2(-away.x, -away.z)
		# Close in during the tell, but stop short of standing on them.
		if cycle.state == CrabCycle.State.WINDUP and distance > attack_reach * 0.85 \
				and not cycle.is_committed():
			var step: Vector3 = away / distance * scuttle_speed
			velocity.x = step.x
			velocity.z = step.z
	cycle.tick(delta)


# Lies on its back, still, then sinks into the sand and is gone.
func _lie_dead(delta: float) -> void:
	_dead_for += delta
	if _dead_for >= linger_seconds + sink_seconds:
		queue_free()


# Its attack landing: a hit on the duellist if they're still in front of it
# and in reach. A parried hit staggers it; a perfectly parried one flips it.
func _on_attacked() -> void:
	var duellist: Duellist = _find_duellist()
	if duellist == null or not lunge_reaches(duellist.position()):
		return
	match duellist.receive_hit(damage, global_position):
		Duellist.Hit.PARRIED:
			cycle.parry()
		Duellist.Hit.PARRIED_PERFECTLY:
			cycle.parry(true)


# Dead: no longer something to lock on to, strike or bump into, and it
# leaves its meat on the ground.
func _on_died() -> void:
	remove_from_group(GROUP)
	_level_label.hide()
	_shape.set_deferred("disabled", true)
	_skid = Vector3.ZERO
	var found: ItemInstance = ItemInstance.new(meat, meat_quality_for(level))
	Pickup3D.spawn(get_parent(), global_position, found)
	died.emit()


# It forgets the damage it did when it wins: the fight starts again.
func _on_duellist_defeated(_lost: Array[ItemInstance]) -> void:
	cycle.reset()


func _find_duellist() -> Duellist:
	if is_instance_valid(_duellist):
		return _duellist
	_duellist = get_tree().get_first_node_in_group(Duellist.GROUP) as Duellist
	if _duellist != null:
		_duellist.defeated.connect(_on_duellist_defeated)
	return _duellist


# Poses the greybox model for the state it's in, so the fight can be read:
# rearing and shaking (windup), thrown forward (attack), sagging (opening),
# reeling (staggered), legs in the air (flipped), still on its back and
# sinking (dead).
func _act_out() -> void:
	var tilt: float = 0.0
	var lunge: float = 0.0
	var squash: float = 1.0
	var roll: float = 0.0
	var claws: float = 0.0
	var through: float = cycle.progress
	match cycle.state:
		CrabCycle.State.WINDUP:
			tilt = lerpf(0.0, 0.55, through)
			claws = lerpf(0.0, 0.5, through)
			roll = sin(_time * 40.0) * 0.06 * through
		CrabCycle.State.ATTACK:
			tilt = -0.3
			lunge = sin(through * PI) * 0.7
			claws = 0.1
		CrabCycle.State.OPENING:
			squash = 0.75 + sin(_time * 9.0) * 0.04
		CrabCycle.State.STAGGERED:
			tilt = 0.35
			roll = sin(_time * 14.0) * 0.3
			squash = 0.85
		CrabCycle.State.FLIPPED:
			# Claws waving helplessly in the air.
			claws = 0.3 + sin(_time * 22.0) * 0.2
		CrabCycle.State.DEAD:
			# A last twitch as it goes over, then still.
			if _dead_for < 0.5:
				claws = 0.3 * (1.0 - _dead_for / 0.5)
	var on_back: float = flipped_amount()
	if _flinch_left > 0.0:
		squash *= 0.8
	# Forward is -Z, so tilting back is a positive turn about X. On its back
	# it's rolled over about its forward axis and lifted by its own height,
	# so its shell rests on the ground. Dead, it sinks below it.
	var sink: float = sunk_amount() * (FLIPPED_HEIGHT + 0.3)
	_model.rotation = Vector3(tilt, 0.0, roll + PI * on_back)
	_model.position = Vector3(0.0, FLIPPED_HEIGHT * on_back - sink, -lunge)
	_model.scale = Vector3(1.0, squash, 1.0)
	_claw_left.position.y = 0.45 + claws
	_claw_right.position.y = 0.45 + claws
	_claws = clampf(claws / 0.5, 0.0, 1.0)
	_show_flash(_flash_left > 0.0)


# Moves a model made of loose parts: its legs step in turn as it scuttles
# (neighbours and opposite sides out of step, as a crab's do), fidget a
# little standing still and scrabble at the air on its back; its claws lift
# as it rears up. Dead, they stop where they are.
func _move_parts(delta: float) -> void:
	if _legs.is_empty() and _claw_parts.is_empty():
		return
	var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.1
	var busy: bool = moving or is_flipped()
	if not is_dead():
		_stride += delta * LEG_RATE * (FLAIL_SPEED if is_flipped() else (1.0 if moving else 0.2))
	var amount: float = 1.0 if busy else LEG_FIDGET
	for index: int in _legs.size():
		var leg: Node3D = _legs[index]
		if not is_instance_valid(leg):
			continue
		var rest: Transform3D = _rests[leg]
		var side: float = 1.0 if rest.origin.x > 0.0 else -1.0
		var phase: float = _stride + PI * float(index % 2) + (PI if side > 0.0 else 0.0)
		var swing: float = sin(phase) * LEG_SWING * amount
		# It lifts as it swings forward and stays down as it pushes back.
		var lift: float = maxf(cos(phase), 0.0) * LEG_LIFT * amount * side
		leg.transform = Transform3D(
				Basis(Vector3.UP, swing) * Basis(Vector3.BACK, lift) * rest.basis, rest.origin)
	for claw: Node3D in _claw_parts:
		if not is_instance_valid(claw):
			continue
		var rest: Transform3D = _rests[claw]
		var side: float = 1.0 if rest.origin.x > 0.0 else -1.0
		# Lifted as it rears up, and spread a little wider as they rise.
		claw.transform = Transform3D(Basis(Vector3.RIGHT, -CLAW_LIFT * 0.7 * _claws)
				* Basis(Vector3.UP, 0.25 * _claws * side) * rest.basis, rest.origin)


# Lays the white flash over every mesh, or takes it off.
func _show_flash(shown: bool) -> void:
	if shown == _flashing:
		return
	_flashing = shown
	for mesh: GeometryInstance3D in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = _flash if shown else null


# Finds the real model's animations and skeleton, if it's showing. The
# animations are moved on by hand ([method _animate]), so the claws can be
# lifted after each frame's animation, not overwritten by it.
func _find_rig() -> void:
	_animator = null
	_skeleton = null
	_legs.clear()
	_claw_parts.clear()
	_rests.clear()
	if _dresser == null or _dresser.model == null:
		return
	for found: Node in _dresser.model.find_children("Leg*", "Node3D", true, false):
		_legs.append(found as Node3D)
	for found: Node in _dresser.model.find_children("Claw*", "Node3D", true, false):
		_claw_parts.append(found as Node3D)
	for part: Node3D in _legs + _claw_parts:
		_rests[part] = part.transform
	var animators: Array[Node] = _dresser.model.find_children("*", "AnimationPlayer", true, false)
	var skeletons: Array[Node] = _dresser.model.find_children("*", "Skeleton3D", true, false)
	if animators.is_empty() or skeletons.is_empty():
		return
	_animator = animators[0] as AnimationPlayer
	_skeleton = skeletons[0] as Skeleton3D
	_animator.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for anim_name: StringName in [IDLE_ANIMATION, WALK_ANIMATION]:
		if _animator.has_animation(anim_name):
			_animator.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


# Plays the real model's idle or walk, then lifts its claws. On its back its
# legs scrabble at the air (the walk, quickly); dead, they stop.
func _animate(delta: float) -> void:
	_move_parts(delta)
	if _animator == null or not is_instance_valid(_animator):
		return
	var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.1
	var wanted: StringName = animation_for(moving or is_flipped())
	if _animator.has_animation(wanted) and _animator.current_animation != String(wanted):
		_animator.play(wanted, 0.15)
	# Dead, time stands still for it, but advancing by nothing still puts the
	# pose back, so the claws below aren't lifted again on top of last frame's.
	var step: float = delta * (FLAIL_SPEED if is_flipped() else 1.0)
	_animator.advance(0.0 if is_dead() else step)
	for bone_name: String in ARM_BONES:
		var bone: int = _skeleton.find_bone(bone_name)
		if bone < 0:
			continue
		var turned: Quaternion = _skeleton.get_bone_pose_rotation(bone)
		_skeleton.set_bone_pose_rotation(bone,
				turned * Quaternion(Vector3.RIGHT, -CLAW_LIFT * _claws))
