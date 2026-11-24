class_name TreasureChest
extends Node3D
## A treasure chest, as in Ocarina of Time: Interact opens it, and what's
## inside is held up for all to see (#152). Every chest in the game is this
## scene; what it holds is a setting.
##
## Opening plays the cutscene [constant CUTSCENE] ([code]data/dialogue/chest.dlg[/code])
## from the section named for what's inside ([code]~ chefs_knife[/code]), so
## each treasure has its own words. The cutscene's [code]@open[/code] and
## [code]@hold_up[/code] cues ([ChestCues]) find the chest being opened through
## [method opening_in], swing the lid with [method swing_open], and hold the
## treasure up where [method item_spot] is. The script gives the treasure
## itself, with [code]set has_chefs_knife[/code] (see [member HandTool.owned_flag]).
##
## Once opened, it stays open: [member flag] is set, and flags are saved.
##
## The model is a Meshy chest whose lid was split off by
## [code]tools/meshy/split_lid.py[/code], so its [code]Lid[/code] node turns on
## its hinge. Without the model, the greybox's own [code]LidHinge[/code] does.

## Emitted when the lid starts to open.
signal opened

## The group every chest is in.
const GROUP: StringName = &"treasure_chests"
## The cutscene a chest plays as it's opened.
const CUTSCENE: StringName = &"chest"

## What's inside: a tool to keep.
@export var contents: HandTool
## Or an item to keep, if it holds no tool: the frying pan washed up on the
## cove's beach (#187).
@export var item: Item
## The conversation flag set once it's opened, so it stays open in a saved
## voyage. Each chest needs its own ([code]opened_galley_chest[/code]).
@export var flag: StringName = &""
## How far the lid swings open, in degrees, and how long it takes.
@export var open_degrees: float = 105.0
@export var open_seconds: float = 0.8
## How bright the light inside is once it's open.
@export var glow_energy: float = 0.9
## How much of the light stays once the treasure's been taken (0 to 1), and
## how long it takes to settle there.
@export var afterglow: float = 0.0
@export var settle_seconds: float = 1.5

var _opening: bool = false
var _open: bool = false

@onready var _reach: Interactable3D = $Reach
@onready var _model: ThirdPartyModel = $Model
@onready var _lid_hinge: Node3D = $LidHinge
@onready var _glow: OmniLight3D = $Glow
@onready var _sparkles: CPUParticles3D = $Sparkles
@onready var _beam: MeshInstance3D = $Beam
@onready var _inner_floor: MeshInstance3D = $InnerFloor
@onready var _item_spot: Marker3D = $ItemSpot
@onready var _stand: Marker3D = $Stand
@onready var _open_shot: Marker3D = $OpenShot
@onready var _hold_shot: Marker3D = $HoldShot


func _ready() -> void:
	add_to_group(GROUP)
	_reach.interacted.connect(open_for)
	_reach.describe_interact = func(player: Player3D) -> String: return prompt(player)
	_model.dressed.connect(_on_dressed)
	_on_dressed(_model.model != null)
	_glow.light_energy = 0.0
	_sparkles.emitting = false
	if is_opened():
		_set_open(1.0)
		_set_light(afterglow)
		_reach.enabled = false


## The chest being opened in [param tree] right now, or null.
static func opening_in(tree: SceneTree) -> TreasureChest:
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(GROUP):
		var chest: TreasureChest = node as TreasureChest
		if chest != null and chest.is_opening():
			return chest
	return null


## Whether it's been opened, in this voyage.
func is_opened() -> bool:
	return _open or (flag != &"" and Game.dialogue.is_set(flag))


## Whether its cutscene is playing.
func is_opening() -> bool:
	return _opening


## What Interact would do for [param player]: open it, if there's room on
## the toolbar for what's inside.
func prompt(player: Player3D) -> String:
	if is_opened() or _opening:
		return ""
	if contents != null and not player.toolbar.has_tool(contents.id) \
			and player.toolbar.is_full():
		return "Your toolbar is full"
	if contents == null and item != null and not player.toolbar.has_item(item.id) \
			and player.toolbar.is_full():
		return "Your toolbar is full"
	return "Open"


## The id of what's inside, the tool's or else the item's: it names the
## section of the chest's cutscene that's played. Empty if it's empty.
func treasure_id() -> StringName:
	if contents != null:
		return contents.id
	return item.id if item != null else &""


## Opens it for [param player]: plays the chest's cutscene. Returns whether
## it started.
func open_for(player: Player3D) -> bool:
	if prompt(player) != "Open" or treasure_id() == &"":
		return false
	var conversation: Conversation = Conversation.find(self)
	if conversation == null:
		return false
	_opening = true
	if not conversation.play(CUTSCENE, player, treasure_id()):
		_opening = false
		return false
	conversation.ended.connect(_on_cutscene_ended, CONNECT_ONE_SHOT)
	_reach.enabled = false
	if flag != &"":
		Game.dialogue.set_flag(flag)
	return true


## Swings the lid open over [member open_seconds] and lights the inside.
## [param at_once] skips to the end (a skipped cutscene). Returns the tween,
## or null if it was done at once.
func swing_open(at_once: bool = false) -> Tween:
	_open = true
	opened.emit()
	_sparkles.emitting = true
	if at_once:
		_set_open(1.0)
		return null
	var tween: Tween = create_tween()
	tween.tween_method(_set_open, 0.0, 1.0, open_seconds) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tween


## Lets the light settle down to its [member afterglow] once the treasure's
## out, over [member settle_seconds]: the beam fades and the sparkles stop.
func settle(at_once: bool = false) -> void:
	_sparkles.emitting = false
	if at_once:
		_set_light(afterglow)
		return
	create_tween().tween_method(_set_light, 1.0, afterglow, settle_seconds)


## Where the treasure rises from: inside, in the middle.
func item_spot() -> Marker3D:
	return _item_spot


## Where whoever opens it stands, facing it.
func stand_mark() -> Marker3D:
	return _stand


## The camera's shot while the lid opens: over the opener's shoulder.
func open_shot() -> Marker3D:
	return _open_shot


## The camera's shot while the treasure is held up: the opener, from the
## front, with the glowing chest behind them.
func hold_shot() -> Marker3D:
	return _hold_shot


## The lid that turns: the model's, or the greybox's.
func lid() -> Node3D:
	if _model.model == null:
		return _lid_hinge
	var model_lid: Node3D = _model.model.find_child("Lid", true, false) as Node3D
	return model_lid if model_lid != null else _lid_hinge


# Sets how open the lid is, 0 shut to 1 open, and the light inside with it.
func _set_open(amount: float) -> void:
	var hinge: Node3D = lid()
	# The greybox's lid faces -Z, the way the chest does, so it lifts by
	# turning about X the positive way. The Meshy lid faces +Z in its own
	# model (which is turned round to face -Z), so it turns the other way.
	var lift: float = 1.0 if hinge == _lid_hinge else -1.0
	hinge.rotation.x = deg_to_rad(open_degrees) * amount * lift
	_set_light(clampf(amount, 0.0, 1.0))


# Sets how strong the light pouring out is, 0 (none) to 1 (full): the lamp
# inside, the beam and the glowing floor together.
func _set_light(strength: float) -> void:
	_glow.light_energy = glow_energy * strength
	_beam.visible = strength > 0.0
	(_beam.material_override as ShaderMaterial).set_shader_parameter(&"brightness", strength)
	(_inner_floor.material_override as ShaderMaterial).set_shader_parameter(&"brightness",
			strength)


func _on_dressed(shown: bool) -> void:
	_lid_hinge.visible = not shown
	if shown:
		_make_solid(_model)
	if shown and is_opened():
		_set_open(1.0)
		_set_light(afterglow)


# Meshy's textures carry an alpha channel, so the import draws the chest as
# see-through: its walls then don't hide the light inside, which shows
# through them. A chest is solid wood and metal.
func _make_solid(node: Node) -> void:
	var mesh_instance: MeshInstance3D = node as MeshInstance3D
	if mesh_instance != null and mesh_instance.mesh != null:
		for surface: int in mesh_instance.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh_instance.get_active_material(surface) \
					as BaseMaterial3D
			if material != null and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				var solid: BaseMaterial3D = material.duplicate() as BaseMaterial3D
				solid.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
				mesh_instance.set_surface_override_material(surface, solid)
	for child: Node in node.get_children():
		_make_solid(child)


func _on_cutscene_ended(_tree_id: StringName) -> void:
	_opening = false
