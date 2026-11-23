class_name CurtainCloth
extends MeshInstance3D
## A hanging curtain that moves like cloth as the ship rolls (#168). Put it on
## the curtain's flat greybox board: when the game starts it swaps the board
## for a finely divided sheet drawn by shaders/curtain_cloth.gdshader, which
## hangs in pleats from the board's top edge, and keeps the board's own
## texture and colour.
##
## It isn't a physics cloth: a soft body tears and lags aboard a ship that is
## itself sailing through the world. The hem is a weight on a spring that
## chases the ship's roll (the same shared sea clock as every [Rocking] thing
## aboard), so it lags the roll, overshoots and settles; the shader swings
## the sheet by that much from its rail, and sends ripples down it that grow
## with how fast the hem is moving.

const SHADER: Shader = preload("res://shaders/curtain_cloth.gdshader")
## Rows and columns the sheet is divided into.
const DIVISIONS: Vector2i = Vector2i(14, 22)

## Seconds for one full roll of the ship, there and back.
@export var period: float = 5.5
## How far behind the roll this curtain is, 0 to 1.
@export_range(0.0, 1.0) var phase: float = 0.0
## How many folds it hangs in for each metre along the rail.
@export var pleats_per_metre: float = 11.0
## How far the hem swings at a full roll, in metres.
@export var sway_metres: float = 0.14
## How strongly the hem is pulled after the roll: higher follows it tightly.
@export var stiffness: float = 26.0
## How quickly its swinging dies down: lower swings on for longer.
@export var damping: float = 2.2

## How far the hem has swung, about -1 to 1, and how fast it's moving.
var swing: float = 0.0
var swing_speed: float = 0.0

# Which way across the ship is, in this sheet's own space.
var _across: Vector3 = Vector3.BACK

# One material for every curtain of the same cloth.
static var _materials: Dictionary[Material, ShaderMaterial] = {}


func _ready() -> void:
	# A moment later, so whatever owns the curtain (a [BunkBay]) has set how
	# wide it hangs and what cloth it's cut from.
	_become_cloth.call_deferred()


func _process(delta: float) -> void:
	step(Rocking.sea_time(), minf(delta, 0.05))


## Moves the hem on by [param delta] seconds towards where the ship's roll is
## at [param time], and tells the shader.
func step(time: float, delta: float) -> void:
	var roll: float = sin(TAU * (time / period - phase)) if period > 0.0 else 0.0
	swing_speed += ((roll - swing) * stiffness - swing_speed * damping) * delta
	swing += swing_speed * delta
	set_instance_shader_parameter(&"sway", _across * swing)
	set_instance_shader_parameter(&"gust", clampf(absf(swing_speed) * 0.6, 0.0, 1.2))


# Swaps the flat board for the sheet: as wide and as long as the board was,
# hung from its top edge.
func _become_cloth() -> void:
	var board: BoxMesh = mesh as BoxMesh
	var width: float = 0.3
	var drop: float = 1.0
	if board != null:
		width = board.size.x * scale.x
		drop = board.size.y * scale.y
	var source: Material = material_override
	var sheet: QuadMesh = QuadMesh.new()
	sheet.size = Vector2(width, drop)
	sheet.subdivide_width = DIVISIONS.x
	sheet.subdivide_depth = DIVISIONS.y
	mesh = sheet
	# The shader hangs the sheet down from this node, so it sits on the rail.
	position.y += drop * 0.5
	scale = Vector3.ONE
	material_override = _material_for(source)
	# The shader moves it well outside the flat sheet it was told about.
	extra_cull_margin = drop
	_across = _ship_across()
	set_instance_shader_parameter(&"size", Vector2(width, drop))
	set_instance_shader_parameter(&"pleats", maxf(roundf(width * pleats_per_metre), 2.0) + 0.5)
	set_instance_shader_parameter(&"seed", float(get_instance_id() % 97) * 0.37)


func _material_for(source: Material) -> ShaderMaterial:
	if _materials.has(source):
		return _materials[source]
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter(&"sway_metres", sway_metres)
	var painted: BaseMaterial3D = source as BaseMaterial3D
	if painted != null:
		material.set_shader_parameter(&"albedo", painted.albedo_color)
		if painted.albedo_texture != null:
			material.set_shader_parameter(&"albedo_texture", painted.albedo_texture)
	if source != null:
		_materials[source] = material
	return material


# Across the ship (the way a roll tips things), seen from this sheet. With no
# ship above it, straight out from the cloth.
func _ship_across() -> Vector3:
	var node: Node = get_parent()
	while node != null:
		if node is Ship:
			var ship: Node3D = node as Node3D
			return (global_basis.inverse() * ship.global_basis.x).normalized()
		node = node.get_parent()
	return Vector3.BACK
