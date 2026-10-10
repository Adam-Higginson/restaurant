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
	return clampf(
			inverse_lerp(GameClock.START_MINUTES, GameClock.END_MINUTES, minutes), 0.0, 1.0)


## The room's colour at [param minutes], or white without a gradient.
static func colour_at(day_gradient: Gradient, minutes: int) -> Color:
	if day_gradient == null:
		return Color.WHITE
	return day_gradient.sample(day_fraction(minutes))


## How far on the lamps are at [param minutes], from 0 to 1, or 0 without a
## curve.
static func lamp_level_at(curve: Curve, minutes: int) -> float:
	if curve == null:
		return 0.0
	return clampf(curve.sample(day_fraction(minutes)), 0.0, 1.0)


func _on_time_changed(minutes: int) -> void:
	_fade_to(minutes)


func _on_day_changed(_day: int) -> void:
	_snap_to(game_state.clock.minutes)


# Drifts the room's colour and every lamp to [param minutes] together.
func _fade_to(minutes: int) -> void:
	_stop_tween()
	_tween = create_tween()
	_tween.set_parallel()
	_tween.tween_property(self, "color", colour_at(gradient, minutes), tween_seconds)
	var lamp_level: float = lamp_level_at(lamp_curve, minutes)
	for lamp: Node in get_tree().get_nodes_in_group(Lamp.GROUP):
		_tween.tween_property(lamp, "level", lamp_level, tween_seconds)


# Jumps straight to [param minutes], for a new day behind the black screen.
func _snap_to(minutes: int) -> void:
	_stop_tween()
	color = colour_at(gradient, minutes)
	var lamp_level: float = lamp_level_at(lamp_curve, minutes)
	for lamp: Node in get_tree().get_nodes_in_group(Lamp.GROUP):
		(lamp as Lamp).level = lamp_level


func _stop_tween() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
