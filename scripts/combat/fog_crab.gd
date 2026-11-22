class_name FogCrab
extends CharacterBody3D
## A fog-touched crab: the fog has got into it and made it wild. It fights
## whoever comes near, in a rhythm you can read: it rears up (the tell),
## lunges, then sags, worn out (the opening). Strike it with the knife while
## it's open, or parry its lunge with the pan to stagger it, and after enough
## strikes the fog clears: it shakes itself off and wanders away. Combat is
## rescue, never killing. See Combat in docs/GDD.md.
##
## The rules live in its [member cycle] (a [CrabCycle]); this script walks
## it about, lands its hits on the [Duellist], and acts each state out with
## its greybox model.

## Emitted when its fog clears.
signal fog_cleared

## Fog-crabs can be locked on to, until their fog clears.
const GROUP: StringName = LockOn.GROUP
## How long it flashes white when a strike lands, in seconds.
const FLASH_SECONDS: float = 0.12

## How long it rears up before attacking, in seconds: the tell.
@export var windup_seconds: float = 0.8
## How long the lunge lasts, in seconds.
@export var attack_seconds: float = 0.25
## How long it's open after an attack, in seconds.
@export var opening_seconds: float = 1.2
## How long a parry staggers it, in seconds.
@export var stagger_seconds: float = 1.5
## How many strikes, while it's open, clear its fog.
@export var strikes_to_clear: int = 3
## How many half-hearts its hit costs.
@export var damage: int = 1
## How near the player must come before it fights, in metres.
@export var notice_range: float = 7.0
## How far its lunge reaches, in metres. Further away than this as the
## attack lands, and it misses.
@export var attack_reach: float = 2.0
## How fast it scuttles in while rearing up, in metres per second.
@export var scuttle_speed: float = 2.5
## How fast it wanders once its fog has cleared, in metres per second.
@export var wander_speed: float = 0.8
## How fast a knock back dies away, in metres per second, per second.
@export var skid_fade: float = 18.0

## Its fight: which state it's in and the strikes it has taken.
var cycle: CrabCycle = CrabCycle.new()

var _duellist: Duellist = null
## The flat direction it wanders in once cleared.
var _wander_direction: Vector3 = Vector3.FORWARD
## Seconds until it picks a new direction to wander in.
var _wander_left: float = 0.0
## Seconds since its fog cleared.
var _cleared_for: float = 0.0
## Seconds left of the flinch after a strike that counted.
var _flinch_left: float = 0.0
## The flat velocity a strike knocked it back with, dying away.
var _skid: Vector3 = Vector3.ZERO
## Seconds left of the white flash after a strike that counted.
var _flash_left: float = 0.0
var _time: float = 0.0
## Every mesh in its model, which the flash lays white over.
var _meshes: Array[GeometryInstance3D] = []
## The white laid over its meshes as a strike lands. Unshaded, so it shows
## as pure white whatever the light.
var _flash: StandardMaterial3D = StandardMaterial3D.new()
## Whether the flash is laid over the meshes right now.
var _flashing: bool = false

@onready var _model: Node3D = $Model
@onready var _claw_left: Node3D = $Model/ClawLeft
@onready var _claw_right: Node3D = $Model/ClawRight
@onready var _fog: Node3D = $Fog
@onready var _chips: CPUParticles3D = $Chips
@onready var _wisps: CPUParticles3D = $Wisps


func _ready() -> void:
	add_to_group(GROUP)
	cycle.windup_seconds = windup_seconds
	cycle.attack_seconds = attack_seconds
	cycle.opening_seconds = opening_seconds
	cycle.stagger_seconds = stagger_seconds
	cycle.strikes_to_clear = strikes_to_clear
	cycle.attacked.connect(_on_attacked)
	cycle.cleared.connect(_on_cleared)
	_flash.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flash.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash.albedo_color = Color(1.0, 1.0, 1.0, 0.85)
	find_meshes()


func _physics_process(delta: float) -> void:
	_time += delta
	_flinch_left = maxf(_flinch_left - delta, 0.0)
	_flash_left = maxf(_flash_left - delta, 0.0)
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_on_floor():
		velocity += get_gravity() * delta
	if is_cleared():
		_wander(delta)
	else:
		_fight(delta)
	velocity.x += _skid.x
	velocity.z += _skid.z
	_skid = _skid.move_toward(Vector3.ZERO, skid_fade * delta)
	move_and_slide()


func _process(_delta: float) -> void:
	_act_out()


## A knife strike, knocking it back along [param push] (a flat velocity in
## metres per second, dying away) if it counts. Counts only while it's open;
## returns whether it did. One that counts makes it flash white, and chips of
## shell and wisps of fog burst off it.
func take_strike(push: Vector3 = Vector3.ZERO) -> bool:
	if not cycle.take_strike():
		return false
	_flinch_left = 0.2
	_flash_left = FLASH_SECONDS
	_skid = Vector3(push.x, 0.0, push.z)
	_chips.restart()
	_wisps.restart()
	return true


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


## Whether its fog has cleared.
func is_cleared() -> bool:
	return cycle.state == CrabCycle.State.CLEARED


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
	if distance > 0.01:
		rotation.y = atan2(-away.x, -away.z)
		# Close in during the tell, but stop short of standing on them.
		if cycle.state == CrabCycle.State.WINDUP and distance > attack_reach * 0.85:
			var step: Vector3 = away / distance * scuttle_speed
			velocity.x = step.x
			velocity.z = step.z
	cycle.tick(delta)


# Ambles off, turning now and then.
func _wander(delta: float) -> void:
	_cleared_for += delta
	_wander_left -= delta
	if _wander_left <= 0.0:
		_wander_left = 3.0
		_wander_direction = _wander_direction.rotated(Vector3.UP, deg_to_rad(50.0))
	# It shakes itself off first.
	if _cleared_for < 1.0:
		return
	velocity.x = _wander_direction.x * wander_speed
	velocity.z = _wander_direction.z * wander_speed
	rotation.y = atan2(-_wander_direction.x, -_wander_direction.z)


# Its attack landing: a hit on the duellist if they're still in reach. A
# parried hit staggers it.
func _on_attacked() -> void:
	var duellist: Duellist = _find_duellist()
	if duellist == null:
		return
	if LockOn.flat_distance(global_position, duellist.position()) > attack_reach:
		return
	if duellist.receive_hit(damage, global_position) == Duellist.Hit.PARRIED:
		cycle.parry()


func _on_cleared() -> void:
	# No longer something to lock on to or strike.
	remove_from_group(GROUP)
	var duellist: Duellist = _find_duellist()
	if duellist != null:
		# Wander off away from the player.
		var away: Vector3 = global_position - duellist.position()
		away.y = 0.0
		if away.length() > 0.01:
			_wander_direction = away.normalized()
	_wander_left = 3.0
	fog_cleared.emit()


# The fog closes back over it when it wins: the fight starts again.
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
# reeling (staggered).
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
		CrabCycle.State.CLEARED:
			if _cleared_for < 1.0:
				roll = sin(_time * 30.0) * 0.25
	if _flinch_left > 0.0:
		squash *= 0.8
	# Forward is -Z, so tilting back is a positive turn about X.
	_model.rotation = Vector3(tilt, 0.0, roll)
	_model.position = Vector3(0.0, 0.0, -lunge)
	_model.scale = Vector3(1.0, squash, 1.0)
	_claw_left.position.y = 0.45 + claws
	_claw_right.position.y = 0.45 + claws
	_show_flash(_flash_left > 0.0)
	# The fog thins with each strike and is gone when it's cleared.
	_fog.visible = not is_cleared()
	var thin: float = 1.0 - 0.2 * float(cycle.strikes)
	_fog.scale = Vector3.ONE * maxf(thin, 0.3)


# Lays the white flash over every mesh, or takes it off.
func _show_flash(shown: bool) -> void:
	if shown == _flashing:
		return
	_flashing = shown
	for mesh: GeometryInstance3D in _meshes:
		if is_instance_valid(mesh):
			mesh.material_overlay = _flash if shown else null
