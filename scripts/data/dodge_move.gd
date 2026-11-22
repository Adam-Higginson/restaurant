class_name DodgeMove
extends Resource
## One way of jumping out of the way, as in Ocarina of Time: the sidehop,
## the backflip and the roll. One .tres file per move under
## res://data/combat/, so each can be tuned in the Inspector.
##
## [Dodge] picks which from the stick and lock-on; [Player3D] carries it
## out; the [CharacterModel] plays its animation. A dodge has no moment of
## being untouchable: it just gets you out of a blow's way. See Combat in
## docs/GDD.md.

## Stable internal name, e.g. &"sidehop".
@export var id: StringName = &""
## What the action prompt calls it.
@export var display_name: String = ""
## How long it lasts, in seconds. The stick does nothing until it's done.
@export var seconds: float = 0.35
## How fast it carries the player along the ground, in metres per second.
@export var speed: float = 6.0
## How fast it lifts the player off the ground as it starts, in metres per
## second (0 stays on the ground).
@export var hop: float = 0.0
## Whether the body turns head over heels backwards (the backflip).
@export var flips: bool = false
## The animation it plays, from the character's animation library.
@export var animation: StringName = &""
## Where in the animation it starts, in seconds.
@export var animation_from: float = 0.0
## How much of the animation it plays, in seconds, fitted to [member seconds].
## 0 plays to its end.
@export var animation_length: float = 0.0
