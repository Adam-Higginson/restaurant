class_name FishingSpot
extends Node3D
## A rod in a holder at the rail. Interact to cast; the bobber floats out on
## the real swell. Fish only bite while the ship is hove to (ring the bell).
## When the bobber dips, Interact to strike: catch it and it goes in your
## toolbar, ready to fillet on the chopping board below. Your lantern gets
## excited when something bites.
##
## The rod's local +x points out over the side.

## Emitted when you land a fish.
signal caught(item: ItemInstance)

## What you catch at night.
@export var catch: Item
## What you catch at dawn, when different fish come up. Unset: the same.
@export var dawn_catch: Item
## How far out from the rod tip the bobber lands, in metres (along local +x).
@export var cast_reach: float = 2.2

## The line's state and timing.
var line: FishingLine = FishingLine.new()

var _ship: Ship = null
var _sea: Sea = null
var _angler: Player3D = null
var _time: float = 0.0

@onready var _reach: Interactable3D = $Reach
@onready var _rod_base: Marker3D = $RodBase
@onready var _rod_tip: Marker3D = $RodTip
@onready var _rod: MeshInstance3D = $Rod
@onready var _line_mesh: MeshInstance3D = $Line
@onready var _bobber: Node3D = $Bobber


func _ready() -> void:
	_ship = _find_ship()
	_reach.interacted.connect(_on_interacted)
	_reach.describe_interact = func(_player: Player3D) -> String: return prompt()
	line.bitten.connect(_on_bitten)
	_stretch(_rod, _rod_base.position, _rod_tip.position, 0.045)
	_show_line(false)


func _physics_process(delta: float) -> void:
	_time += delta
	line.step(delta, still_water())
	if line.state != FishingLine.State.REELED_IN:
		_place_bobber()


## What would bite now: herring at night, mackerel at dawn.
func catch_now() -> Item:
	var time: TimeOfDay = get_tree().get_first_node_in_group(&"time_of_day") as TimeOfDay
	if dawn_catch != null and time != null and time.is_morning():
		return dawn_catch
	return catch


## Whether fish will bite: the ship is stopped (or there's no ship).
func still_water() -> bool:
	return not is_instance_valid(_ship) or not _ship.is_sailing


## What Interact would do now, for the HUD.
func prompt() -> String:
	match line.state:
		FishingLine.State.BITING:
			return "Strike!"
		FishingLine.State.WAITING:
			return "Reel in" if still_water() else "Reel in (they bite when hove to)"
	return "Cast a line"


func _on_interacted(player: Player3D) -> void:
	_angler = player
	match line.state:
		FishingLine.State.REELED_IN:
			line.cast()
			_show_line(true)
			_place_bobber()
		_:
			var landed: bool = line.reel()
			_show_line(false)
			var fish_now: Item = catch_now()
			if landed and fish_now != null:
				var fish: ItemInstance = ItemInstance.new(fish_now)
				if player.toolbar.add(fish):
					caught.emit(fish)
					_tell(player, &"caught", &"news_fish")
					Game.memories.notice(fish_now)


# The lantern reacts to [param moment] if he's near enough to have seen;
# otherwise it's [param news] he'll bring up when you next talk to him.
func _tell(player: Player3D, moment: StringName, news: StringName) -> void:
	var spirit: LanternSpirit = player.get_node_or_null("LanternSpirit") as LanternSpirit
	if spirit != null:
		spirit.tell(moment, news)


func _on_bitten() -> void:
	if is_instance_valid(_angler):
		var spirit: LanternSpirit = _angler.get_node_or_null("LanternSpirit") as LanternSpirit
		if spirit != null:
			spirit.excite()


# The bobber rides the swell where it lands, and bobs under when a fish bites.
func _place_bobber() -> void:
	var out: Vector3 = _rod_tip.position + Vector3(cast_reach, 0.0, 0.0)
	var world: Vector3 = to_global(Vector3(out.x, 0.0, out.z))
	var water: float = _water_height(world)
	var dip: float = 0.0
	if line.state == FishingLine.State.BITING:
		dip = -0.12 - 0.1 * absf(sin(_time * 19.0))
	var bob: float = sin(_time * 2.1) * 0.03
	var at: Vector3 = to_local(Vector3(world.x, water, world.z)) + Vector3(0, 0.05 + dip + bob, 0)
	_bobber.position = at
	_stretch(_line_mesh, _rod_tip.position, at, 0.012)


# How high the water is at a world spot, in world space. With no sea, the
# still-water level (the ship's waterline).
func _water_height(world: Vector3) -> float:
	if not is_instance_valid(_sea):
		_sea = get_tree().get_first_node_in_group(&"sea") as Sea
	var waterline: float = _ship.global_position.y if is_instance_valid(_ship) else 0.0
	if not is_instance_valid(_sea) or not is_instance_valid(_ship):
		return waterline
	var here: float = _sea.height_at(Vector2(world.x, world.z))
	var under_ship: float = _sea.height_at(Vector2(_ship.global_position.x, _ship.global_position.z))
	return waterline + here - under_ship


func _show_line(out: bool) -> void:
	_line_mesh.visible = out
	_bobber.visible = out


# Stretches a unit-tall rod mesh from a to b (local), [param thick] across.
static func _stretch(rod: MeshInstance3D, a: Vector3, b: Vector3, thick: float) -> void:
	var along: Vector3 = b - a
	if along.length() < 0.001:
		return
	var side: Vector3 = Vector3.RIGHT if absf(along.normalized().x) < 0.9 else Vector3.FORWARD
	var x: Vector3 = along.cross(side).normalized() * thick
	var z: Vector3 = x.cross(along).normalized() * thick
	rod.transform = Transform3D(Basis(x, along, z), (a + b) * 0.5)


func _find_ship() -> Ship:
	var node: Node = get_parent()
	while node != null:
		if node is Ship:
			return node as Ship
		node = node.get_parent()
	return null
