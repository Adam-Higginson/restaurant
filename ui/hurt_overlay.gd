class_name HurtOverlay
extends ColorRect
## Lays the hurt over the whole screen: a white flash and grey fog closing
## in at the edges when a blow lands, and the colour draining away while the
## player is down to their last heart. The look is the shader
## (shaders/hurt_overlay.gdshader); this only says how strong each part is.
## It follows the [Duellist]; the rules live there and in [Hearts].
##
## Everything fades by game time, so the flash holds while a hit freezes the
## game, and fades once it moves again.

## How long the flash takes to fade, in seconds.
@export var flash_seconds: float = 0.2
## How long the fog takes to clear from the edges, in seconds.
@export var fog_seconds: float = 1.2
## How long the colour takes to drain or come back, in seconds.
@export var drain_seconds: float = 0.8

## How strong the white flash is now, from 0 to 1.
var flash: float:
	get:
		return _flash
## How far the fog has closed in now, from 0 to 1.
var fog: float:
	get:
		return _fog
## How much colour has drained away now, from 0 to 1.
var drain: float:
	get:
		return _drain

var _flash: float = 0.0
var _fog: float = 0.0
var _drain: float = 0.0
var _hearts: Hearts = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta / flash_seconds, 0.0)
	_fog = maxf(_fog - delta / fog_seconds, 0.0)
	var drained: float = 1.0 if _hearts != null and _hearts.is_last_heart() else 0.0
	_drain = move_toward(_drain, drained, delta / drain_seconds)
	_show()


## Follows [param player]'s hearts, or stays hidden if they have none.
func setup(player: Player3D) -> void:
	var duellist: Duellist = player.get_node_or_null("Duellist") as Duellist
	if duellist == null or duellist.hearts == null:
		set_process(false)
		return
	_hearts = duellist.hearts
	duellist.hurt.connect(_on_hurt)


func _on_hurt(_halves: int) -> void:
	_flash = 1.0
	_fog = 1.0
	_show()


# Hands the strengths to the shader, and only draws while there's something
# to show, so it costs nothing the rest of the time.
func _show() -> void:
	visible = _flash > 0.0 or _fog > 0.0 or _drain > 0.0
	if not visible:
		return
	var shader: ShaderMaterial = material as ShaderMaterial
	if shader == null:
		return
	shader.set_shader_parameter(&"flash", _flash)
	shader.set_shader_parameter(&"fog", _fog)
	shader.set_shader_parameter(&"drain", _drain)
