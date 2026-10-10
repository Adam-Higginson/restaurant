class_name DayLight
extends CanvasModulate
## Tints the world with the time of day, from a warm dawn through daylight to
## a dark blue night, and turns the lamps up as it gets dark.
##
## Both follow the clock: [member gradient] gives the room's colour and
## [member lamp_curve] the lamps' level, each from 6:00 am (0) to 2:00 am (1).
## Each clock step drifts to the new values; a new day snaps straight to the
## morning. The HUD and panels are on their own canvas layers, so they're
## never tinted.

## How long the light takes to drift to each new clock step.
const TWEEN_SECONDS: float = 1.0

## The room's colour through the day. White leaves the world untinted.
@export var gradient: Gradient = null
## How far on the lamps are through the day, from 0 to 1.
@export var lamp_curve: Curve = null

## The state whose clock this follows. Tests set their own before adding it;
## otherwise it's the [code]Game[/code] autoload.
var game_state: GameState = null
## How long each drift takes. Tests make it shorter.
var tween_seconds: float = TWEEN_SECONDS

var _tween: Tween = null


func _ready() -> void:
	if game_state == null:
		game_state = Game
	game_state.clock.time_changed.connect(_on_time_changed)
	game_state.day_changed.connect(_on_day_changed)
	_snap_to(game_state.clock.minutes)


## How far through the day [param minutes] is: 0 at 6:00 am, 1 at 2:00 am,
## clamped outside that.
static func day_fraction(minutes: int) -> float:
	# TODO 1: inverse_lerp(from, to, value) is the opposite of lerp: it tells
	#         you how far value is between from and to (0 at from, 1 at to).
	#         Use it with GameClock.START_MINUTES and GameClock.END_MINUTES,
	#         then clampf the result between 0.0 and 1.0.
	return 0.0


## The room's colour at [param minutes], or white without a gradient.
static func colour_at(day_gradient: Gradient, minutes: int) -> Color:
	# TODO 2: if day_gradient is null, return Color.WHITE. Otherwise return
	#         day_gradient.sample(...) at this time's day_fraction.
	return Color.WHITE


## How far on the lamps are at [param minutes], from 0 to 1, or 0 without a
## curve.
static func lamp_level_at(curve: Curve, minutes: int) -> float:
	# TODO 3: like colour_at, with curve.sample(...), returning 0.0 without a
	#         curve. Clamp the result between 0 and 1 in case the curve is
	#         drawn outside that.
	return 0.0


func _on_time_changed(minutes: int) -> void:
	_fade_to(minutes)


func _on_day_changed(_day: int) -> void:
	_snap_to(game_state.clock.minutes)


# Drifts the room's colour and every lamp to [param minutes] together.
func _fade_to(minutes: int) -> void:
	# TODO 4: _stop_tween(), then _tween = create_tween() and set_parallel(),
	#         so all the steps below run at the same time.
	# TODO 5: tween self's "color" to colour_at(gradient, minutes) over
	#         tween_seconds.
	# TODO 6: work out the lamp level once with lamp_level_at, then for each
	#         lamp in get_tree().get_nodes_in_group(Lamp.GROUP), tween its
	#         "level" to it. Tweening a property with a setter calls the setter
	#         every frame, so the lamp's light follows along.
	#         Loop variables need a type too: for lamp: Node in ...
	pass


# Jumps straight to [param minutes], for a new day behind the black screen.
func _snap_to(minutes: int) -> void:
	# TODO 7: _stop_tween(), so no drift left over pulls it back to the night.
	# TODO 8: set color, and each lamp's level, directly. A Node from the group
	#         needs a cast to set level: (lamp as Lamp).level = ...
	pass


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
