class_name KnifeCut
extends Resource
## One cut of the knife: the chop, slice and thrust of the combo, and the
## spins a held press lets go. One .tres file per cut under
## res://data/combat/, so each can be tuned in the Inspector.
##
## [KnifeCombo] decides which cut comes next; the [Duellist] lands it on
## whatever is in reach; the [CharacterModel] plays its animation; [HitFeel]
## and [DuelSounds] give it its freeze and sound. See Combat in docs/GDD.md.

## Stable internal name, e.g. &"chop".
@export var id: StringName = &""
## How long the cut takes, in seconds. Another can't start until it's done
## (a press meanwhile waits for it).
@export var seconds: float = 0.25
## When, in seconds into the cut, the blade meets whatever is in reach: the
## moment it lands (and the game freezes, if it counts).
@export var hit_at: float = 0.1
## How far it reaches, in metres from the player's centre.
@export var reach: float = 2.0
## How wide it sweeps, in degrees, centred on the way the player faces.
## 360 hits all round.
@export_range(0.0, 360.0) var arc_degrees: float = 120.0
## How much of a crab's fog it takes, when it counts.
@export var damage: int = 1
## How many physics ticks the game freezes for when it counts (hitstop).
@export var hitstop_ticks: int = 4
## How hard it knocks a crab back, in metres per second.
@export var push: float = 6.0
## How fast the player steps forward as it starts, in metres per second,
## dying away like a knock back (0 for none).
@export var step: float = 0.0
## Whether it catches a crab mid-lunge, flipping it onto its back.
@export var flips_lunging: bool = false
## The animation it plays, from the character's animation library.
@export var animation: StringName = &""
## Where in the animation the cut starts, in seconds.
@export var animation_from: float = 0.0
## How much of the animation the cut plays, in seconds, sped up or slowed
## down to fit [member seconds]. 0 plays to its end.
@export var animation_length: float = 0.0
## The animation played after the cut when no other follows it.
@export var recovery_animation: StringName = &""
## The name of its swing sound in [DuelSounds].
@export var sound: StringName = &"Swing"
