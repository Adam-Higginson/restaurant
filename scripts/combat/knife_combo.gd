class_name KnifeCombo
extends RefCounted
## Which cut the knife makes, from how Use tool is pressed: taps chain the
## [member chain] (chop, slice, thrust), and a press held on charges a
## spinning fillet.
##
## - A press starts the next cut of the chain at once. A press during a cut
##   waits for it to end (it's buffered), so tapping in rhythm never drops one.
## - After a cut there's a short window to carry on the chain. If it runs
##   out, or after the last cut, the chain starts again from the first.
## - Held on after its cut, the press charges: from [member charge_delay_seconds]
##   after the press, full at [member charge_full_seconds]. Let go when full
##   for the [member fillet]; any earlier while charging for the feeble
##   [member weak_spin].
##
## Plain data with no node: [method tick] moves time on, so tests can step it
## exactly. The [Duellist] owns one and lands its cuts.

## Emitted when a cut starts.
signal cut_started(cut: KnifeCut)
## Emitted when a held press starts to charge.
signal charge_started
## Emitted when the charge is full: letting go now fillets.
signal charge_filled
## Emitted when a charge ends without a spin (a blow, the pan, a dodge).
signal charge_cancelled

## The cuts that taps chain, in order.
var chain: Array[KnifeCut] = []
## The spin a full charge lets go.
var fillet: KnifeCut = null
## The spin a charge let go too early gives.
var weak_spin: KnifeCut = null
## How long after a cut a press still carries on the chain, in seconds.
var chain_window_seconds: float = 0.4
## How long a press must be held before it starts to charge, in seconds.
var charge_delay_seconds: float = 0.3
## How long a press must be held for a full charge, in seconds.
var charge_full_seconds: float = 1.0

## The cut being made, or null.
var current: KnifeCut:
	get:
		return _current if _cut_left > 0.0 else null

## The last cut made, even once it's over, or null.
var last: KnifeCut:
	get:
		return _current

## Which cut of the [member chain] a press would start next.
var next_index: int:
	get:
		return _next

var _current: KnifeCut = null
var _cut_left: float = 0.0
## Seconds left to carry on the chain, after a cut.
var _window_left: float = 0.0
var _next: int = 0
## Whether a press is waiting for the cut to end.
var _buffered: bool = false
## Whether the button is down (from a press that counted).
var _held: bool = false
## Seconds the button has been down.
var _held_for: float = 0.0
var _charging: bool = false
var _filled: bool = false


## The button going down. Starts the next cut of the chain, or if one is
## being made, waits for it. Returns whether a cut started now.
func press() -> bool:
	if _charging:
		return false
	_held = true
	_held_for = 0.0
	if _cut_left > 0.0:
		_buffered = true
		return false
	_start_next()
	return true


## The button coming up. While charging, lets go the spin: the [member fillet]
## if the charge was full, the [member weak_spin] otherwise. Returns the spin
## that started, or null.
func release() -> KnifeCut:
	_held = false
	if not _charging:
		return null
	var spin: KnifeCut = fillet if _filled else weak_spin
	_charging = false
	_filled = false
	_next = 0
	if spin != null:
		_start(spin)
	return spin


## Moves time on by [param delta] seconds.
func tick(delta: float) -> void:
	if delta <= 0.0:
		return
	if _held:
		_held_for += delta
	var left_over: float = delta
	if _cut_left > 0.0:
		left_over = maxf(delta - _cut_left, 0.0)
		_cut_left = maxf(_cut_left - delta, 0.0)
		if _cut_left == 0.0:
			_cut_ended()
	# A long tick can end a cut and run on into the window after it.
	if _cut_left == 0.0 and _window_left > 0.0 and left_over > 0.0:
		_window_left = maxf(_window_left - left_over, 0.0)
		if _window_left == 0.0:
			_next = 0
	_charge()


## Whether a cut is being made.
func is_cutting() -> bool:
	return _cut_left > 0.0


## How far through the cut being made it is, from 0 to 1 (0 with none).
func cut_progress() -> float:
	if _cut_left <= 0.0 or _current == null:
		return 0.0
	return clampf(1.0 - _cut_left / maxf(_current.seconds, 0.001), 0.0, 1.0)


## Whether a held press is charging.
func is_charging() -> bool:
	return _charging


## Whether the charge is full, so letting go fillets.
func is_charged() -> bool:
	return _charging and _filled


## How full the charge is, from 0 to 1 (0 when not charging).
func charge() -> float:
	if not _charging:
		return 0.0
	var span: float = charge_full_seconds - charge_delay_seconds
	if span <= 0.0:
		return 1.0
	return clampf((_held_for - charge_delay_seconds) / span, 0.0, 1.0)


## Ends a charge without a spin: the player was hit, raised the pan or
## dodged. The button must be pressed again to charge again.
func cancel_charge() -> void:
	_held = false
	_buffered = false
	if _charging:
		_charging = false
		_filled = false
		charge_cancelled.emit()


## Forgets everything: no cut, no charge, the chain back at its start.
func reset() -> void:
	cancel_charge()
	_current = null
	_cut_left = 0.0
	_window_left = 0.0
	_next = 0


func _start_next() -> void:
	if chain.is_empty():
		return
	var cut: KnifeCut = chain[_next]
	_next = (_next + 1) % chain.size()
	_start(cut)


func _start(cut: KnifeCut) -> void:
	_current = cut
	_cut_left = maxf(cut.seconds, 0.001)
	_window_left = 0.0
	cut_started.emit(cut)


func _cut_ended() -> void:
	if _buffered:
		_buffered = false
		_start_next()
		return
	# After the last cut of the chain, or a spin, the chain starts again.
	_window_left = chain_window_seconds if _next != 0 else 0.0


func _charge() -> void:
	if not _held or _cut_left > 0.0 or _buffered:
		return
	if not _charging and _held_for >= charge_delay_seconds:
		_charging = true
		_next = 0
		charge_started.emit()
	if _charging and not _filled and _held_for >= charge_full_seconds:
		_filled = true
		charge_filled.emit()
