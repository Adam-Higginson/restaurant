class_name HitFeel
extends Node
## Makes the player's blows, and the ones they take, land with weight. It
## only listens: the [Duellist] says what happened, and this answers with
## a freeze ([HitStop]), a camera shake, sparks off the pan, the player
## flickering while they can't be hit again, and the sound muffling for a
## moment when they're hurt.
##
## The screen's flash, fog and colour drain are the HUD's [HurtOverlay];
## the sounds are [DuelSounds].

## The name of the low-pass effect on the Master bus that muffles the sound.
const MUFFLE_EFFECT: StringName = &"Muffle"
## The muffle's cutoff at its deepest, in Hz: only the low end gets through.
const MUFFLED_HZ: float = 500.0
## The cutoff the muffle opens back up to, in Hz: everything gets through.
const CLEAR_HZ: float = 20000.0

## How far a strike that counts shakes the camera, in metres.
@export var strike_shake: float = 0.06
## How far the strike that clears a crab shakes the camera, in metres.
@export var clearing_shake: float = 0.14
## How far a parry shakes the camera, in metres.
@export var parry_shake: float = 0.08
## How far a blow landing on the player shakes the camera, in metres.
@export var hurt_shake: float = 0.22
## How long the sound stays muffled after a blow lands, in seconds.
@export var muffle_seconds: float = 0.8
## How many times a second the player flickers while they can't be hit.
@export var flicker_rate: float = 15.0

## How muffled the sound is, from 0 (clear) to 1 (deepest).
var muffle: float:
	get:
		return _muffle

var _muffle: float = 0.0
## Seconds spent flickering.
var _flicker_time: float = 0.0
## The Master bus's muffle effect and its index there, or null and -1 if
## the bus layout doesn't have one.
var _muffle_effect: AudioEffectLowPassFilter = null
var _muffle_index: int = -1

@onready var _duellist: Duellist = $"../Duellist"
@onready var _hit_stop: HitStop = $"../HitStop"
@onready var _camera_rig: CameraRig = $"../CameraRig"
@onready var _model: Node3D = $"../Model"
@onready var _sparks: CPUParticles3D = $"../Model/Sparks"


func _ready() -> void:
	_duellist.strike_landed.connect(_on_strike_landed)
	_duellist.parried.connect(_on_parried)
	_duellist.hurt.connect(_on_hurt)
	_find_muffle()


func _process(delta: float) -> void:
	_flicker(delta)
	if _muffle > 0.0:
		_muffle = maxf(_muffle - delta / muffle_seconds, 0.0)
		_apply_muffle()


func _exit_tree() -> void:
	# Never leave the whole game muffled.
	if _muffle > 0.0:
		_muffle = 0.0
		_apply_muffle()


## The cutoff, in Hz, for the sound muffled by [param amount], from 0 (clear)
## to 1 (deepest). Ears hear pitch on a log scale, so it falls evenly through
## the octaves rather than in Hz.
static func muffle_hz(amount: float) -> float:
	return CLEAR_HZ * pow(MUFFLED_HZ / CLEAR_HZ, clampf(amount, 0.0, 1.0))


func _on_strike_landed(_crab: FogCrab, cleared: bool) -> void:
	_hit_stop.freeze(HitStop.CLEARING_TICKS if cleared else HitStop.STRIKE_TICKS)
	_camera_rig.shake(clearing_shake if cleared else strike_shake)


func _on_parried() -> void:
	_hit_stop.freeze(HitStop.PARRY_TICKS)
	_camera_rig.shake(parry_shake)
	_sparks.restart()


func _on_hurt(_halves: int) -> void:
	_hit_stop.freeze(HitStop.HURT_TICKS)
	_camera_rig.shake(hurt_shake)
	_muffle = 1.0
	_apply_muffle()


# Blinks the model while the player can't be hit, and shows it steadily after.
func _flicker(delta: float) -> void:
	if not _duellist.is_invulnerable():
		_flicker_time = 0.0
		_model.visible = true
		return
	_flicker_time += delta
	_model.visible = int(_flicker_time * flicker_rate * 2.0) % 2 == 0


func _find_muffle() -> void:
	var master: int = AudioServer.get_bus_index(&"Master")
	for index: int in AudioServer.get_bus_effect_count(master):
		var effect: AudioEffectLowPassFilter = AudioServer.get_bus_effect(master, index) \
				as AudioEffectLowPassFilter
		if effect != null and effect.resource_name == MUFFLE_EFFECT:
			_muffle_effect = effect
			_muffle_index = index
			return


# Sets the muffle's cutoff, and switches the effect off altogether when the
# sound is clear, so it costs nothing and colours nothing.
func _apply_muffle() -> void:
	if _muffle_effect == null:
		return
	_muffle_effect.cutoff_hz = muffle_hz(_muffle)
	AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(&"Master"), _muffle_index,
			_muffle > 0.0)
