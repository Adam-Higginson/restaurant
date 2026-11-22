class_name CrabCycle
extends RefCounted
## A fog-crab's fight, as a state machine: it is always in exactly one
## [enum State], and moves to the next when that state's time runs out.
##
## Engaged, it loops: windup (the tell you read), attack (the hit lands as
## this starts), opening (it's tired: strike now), and round again. For the
## last moment of the windup it's committed: it stops turning, so it lunges
## where it was aiming and a dodge gets out of the way. A parried hit
## staggers it instead, which is a longer opening; a perfect parry, or a
## fillet as it lunges, flips it onto its back, the longest opening of all.
## Strikes while it's open wear its fog away, and when the fog is gone it's
## done fighting for good.
##
## Plain data with no node: [method tick] moves time on, so tests can step it
## exactly. [FogCrab] owns one and acts it out.

## Emitted when the crab moves to a new state.
signal state_changed(state: State)
## Emitted at the moment its attack lands (as ATTACK starts).
signal attacked
## Emitted once, when the last strike clears its fog.
signal cleared

enum State {
	## Not fighting: nobody is near.
	IDLE,
	## Rearing up: the tell before the attack.
	WINDUP,
	## Lunging. The hit landed as this started.
	ATTACK,
	## Worn out after attacking: strikes count.
	OPENING,
	## Knocked back by a parry: strikes count, for longer.
	STAGGERED,
	## Its fog is gone. It never fights again.
	CLEARED,
	## On its back, legs flailing: strikes count, for longest.
	FLIPPED,
}

## How long it rears up before attacking, in seconds.
var windup_seconds: float = 0.8
## How long, at the end of the windup, it's committed to where it's aiming,
## in seconds.
var commit_seconds: float = 0.2
## How long the lunge lasts before it tires, in seconds.
var attack_seconds: float = 0.25
## How long it stays open after an attack, in seconds.
var opening_seconds: float = 1.2
## How long a parry staggers it, in seconds.
var stagger_seconds: float = 1.5
## How long it lies on its back once flipped, in seconds.
var flip_seconds: float = 3.0
## How much fog it has: the damage that clears it, from strikes while it's open.
var fog: int = 8

## The state it's in now.
var state: State:
	get:
		return _state

## How much damage strikes have done so far.
var damage_taken: int:
	get:
		return _damage

## How far through the current state it is, from 0 to 1 (0 in states that
## don't end by themselves).
var progress: float:
	get:
		var length: float = _length_of(_state)
		return clampf(_time / length, 0.0, 1.0) if length > 0.0 else 0.0

## Seconds spent in the current state.
var time_in_state: float:
	get:
		return _time

var _state: State = State.IDLE
var _damage: int = 0
## Seconds spent in the current state.
var _time: float = 0.0


## Starts the fight, from idle: it begins to rear up.
func engage() -> void:
	if _state == State.IDLE:
		_enter(State.WINDUP)


## Stops fighting (the player has gone), keeping the damage it has taken.
func disengage() -> void:
	if _state != State.CLEARED and _state != State.IDLE:
		_enter(State.IDLE)


## Forgets the damage it has taken and stops fighting: the fog closes back
## over it. Does nothing once cleared.
func reset() -> void:
	if _state == State.CLEARED:
		return
	_damage = 0
	_enter(State.IDLE)


## Moves time on by [param delta] seconds, changing state as each runs out.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	_time += delta
	# A long tick can run through more than one state.
	var length: float = _length_of(_state)
	while length > 0.0 and _time >= length:
		var left_over: float = _time - length
		_enter(_after(_state))
		_time = left_over
		length = _length_of(_state)


## Whether a strike would count right now.
func is_open() -> bool:
	return _state == State.OPENING or _state == State.STAGGERED or _state == State.FLIPPED


## Whether it's at the end of its windup, committed to lunging where it aims:
## it doesn't turn to follow any more.
func is_committed() -> bool:
	return _state == State.WINDUP and _time >= windup_seconds - commit_seconds


## A knife strike doing [param damage]. Counts only while the crab is open,
## and returns whether it did. Once the damage reaches its [member fog], the
## fog clears.
func take_strike(damage: int = 1) -> bool:
	if not is_open():
		return false
	_damage += maxi(damage, 0)
	if _damage >= fog:
		_enter(State.CLEARED)
		cleared.emit()
	return true


## Its attack was parried: it's knocked back, staggered, or if
## [param perfect], flipped onto its back. Only while attacking.
func parry(perfect: bool = false) -> void:
	if _state == State.ATTACK:
		_enter(State.FLIPPED if perfect else State.STAGGERED)


## Flips it onto its back, if it's lunging: caught mid-attack. Returns
## whether it flipped.
func flip() -> bool:
	if _state != State.ATTACK:
		return false
	_enter(State.FLIPPED)
	return true


func _enter(next: State) -> void:
	_state = next
	_time = 0.0
	state_changed.emit(next)
	if next == State.ATTACK:
		attacked.emit()


# How long [param of] lasts, in seconds, or 0 if it doesn't end by itself.
func _length_of(of: State) -> float:
	match of:
		State.WINDUP:
			return windup_seconds
		State.ATTACK:
			return attack_seconds
		State.OPENING:
			return opening_seconds
		State.STAGGERED:
			return stagger_seconds
		State.FLIPPED:
			return flip_seconds
	return 0.0


# The state that follows [param of] when its time runs out.
func _after(of: State) -> State:
	match of:
		State.WINDUP:
			return State.ATTACK
		State.ATTACK:
			return State.OPENING
	# An opening, a stagger or a flip ends with it rearing up again.
	return State.WINDUP
