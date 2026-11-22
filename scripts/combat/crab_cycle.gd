class_name CrabCycle
extends RefCounted
## A fog-crab's fight, as a state machine: it is always in exactly one
## [enum State], and moves to the next when that state's time runs out.
##
## Engaged, it loops: windup (the tell you read), attack (the hit lands as
## this starts), opening (it's tired: strike now), and round again. A parried
## hit staggers it instead, which is a longer opening. Enough strikes while
## it's open clear its fog, and it's done fighting for good.
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
}

## How long it rears up before attacking, in seconds.
var windup_seconds: float = 0.8
## How long the lunge lasts before it tires, in seconds.
var attack_seconds: float = 0.25
## How long it stays open after an attack, in seconds.
var opening_seconds: float = 1.2
## How long a parry staggers it, in seconds.
var stagger_seconds: float = 1.5
## How many strikes, while it's open, clear its fog.
var strikes_to_clear: int = 3

## The state it's in now.
var state: State:
	get:
		return _state

## How many strikes have counted so far.
var strikes: int:
	get:
		return _strikes

## How far through the current state it is, from 0 to 1 (0 in states that
## don't end by themselves).
var progress: float:
	get:
		var length: float = _length_of(_state)
		return clampf(_time / length, 0.0, 1.0) if length > 0.0 else 0.0

var _state: State = State.IDLE
var _strikes: int = 0
## Seconds spent in the current state.
var _time: float = 0.0


## Starts the fight, from idle: it begins to rear up.
func engage() -> void:
	if _state == State.IDLE:
		_enter(State.WINDUP)


## Stops fighting (the player has gone), keeping the strikes it has taken.
func disengage() -> void:
	if _state != State.CLEARED and _state != State.IDLE:
		_enter(State.IDLE)


## Forgets the strikes it has taken and stops fighting: the fog closes back
## over it. Does nothing once cleared.
func reset() -> void:
	if _state == State.CLEARED:
		return
	_strikes = 0
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
	return _state == State.OPENING or _state == State.STAGGERED


## A knife strike. Counts only while the crab is open, and returns whether it
## did. The last one clears the fog.
func take_strike() -> bool:
	if not is_open():
		return false
	_strikes += 1
	if _strikes >= strikes_to_clear:
		_enter(State.CLEARED)
		cleared.emit()
	return true


## Its attack was parried: it's knocked back, staggered. Only while attacking.
func parry() -> void:
	if _state == State.ATTACK:
		_enter(State.STAGGERED)


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
	return 0.0


# The state that follows [param of] when its time runs out.
func _after(of: State) -> State:
	match of:
		State.WINDUP:
			return State.ATTACK
		State.ATTACK:
			return State.OPENING
	# An opening or a stagger ends with it rearing up again.
	return State.WINDUP
