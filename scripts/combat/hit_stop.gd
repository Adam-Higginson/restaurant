class_name HitStop
extends Node
## Freezes the game for a few ticks when a blow lands (hitstop), so it lands
## with weight: the moment of contact hangs on screen for a beat before
## everything moves on.
##
## It works by turning [member Engine.time_scale], Godot's dial for how fast
## game time passes, almost down to nothing. Every [code]delta[/code] shrinks
## with it, so everything that moves by delta stops: the player, the crab,
## particles, the camera's shake fading. Physics ticks still come 60 times a
## second in real time (with a tiny delta), and that's what this counts, so
## a freeze lasts the same on every machine. Sound isn't game time, so it
## carries on.
##
## It runs even while the game is paused, so a freeze always ends, and it
## puts the speed back if it leaves the tree mid-freeze.

## How many ticks a strike that counts freezes the game for.
const STRIKE_TICKS: int = 4
## How many ticks the strike that clears a crab's fog freezes the game for.
const CLEARING_TICKS: int = 10
## How many ticks a parry freezes the game for.
const PARRY_TICKS: int = 6
## How many ticks a blow landing on the player freezes the game for.
const HURT_TICKS: int = 8
## The game's speed while frozen. Not quite 0: a step of no time at all can
## divide by zero in the physics of moving platforms (the ship).
const FROZEN_SCALE: float = 0.02

## Physics ticks left of the freeze, or 0 when the game isn't frozen.
var ticks_left: int:
	get:
		return maxi(_until - Engine.get_physics_frames(), 0) if _frozen else 0

var _frozen: bool = false
## The physics tick the freeze ends on.
var _until: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	if _frozen and Engine.get_physics_frames() >= _until:
		_release()


func _exit_tree() -> void:
	if _frozen:
		_release()


## Freezes the game for [param ticks] physics ticks from now. A freeze already
## running isn't added to: whichever ends later wins.
func freeze(ticks: int) -> void:
	if ticks <= 0:
		return
	var until: int = Engine.get_physics_frames() + ticks
	_until = maxi(_until, until) if _frozen else until
	_frozen = true
	Engine.time_scale = FROZEN_SCALE


## Whether the game is frozen right now.
func is_frozen() -> bool:
	return _frozen


func _release() -> void:
	_frozen = false
	Engine.time_scale = 1.0
