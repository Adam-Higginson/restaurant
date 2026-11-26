@tool
class_name ThirdPartyModel
extends Node3D
## Dresses the scene with a third-party model when its file is there, and
## otherwise leaves our greybox stand-in showing.
##
## Third-party art lives in the gitignored assets/third_party/, so a scene
## can't reference it directly: on a fresh clone (or in CI) the file is
## missing and the scene would fail to load. This node loads the model by
## path instead, as a child, and hides the [member stand_ins]. Gameplay
## (collision, interaction) always stays on our own scenes; models are only
## looks.
##
## It runs in the editor too ([code]@tool[/code]), so you see the real model
## while placing things. The loaded model is never saved into the scene.
##
## Models from the packs are built at their own scale, so the model is
## fitted into [member fit_size] (sitting on this node's origin, centred).
##
## With a [member style], the model is drawn stylised instead (#168): every
## surface gets the soft cel-shaded character material, with its own texture,
## and an outline. Clearing the style dresses it again exactly as it was made.

## Emitted each time [method dress] has run. [param shown] says whether the
## model is showing (true) or the greybox is (false), so a node that drives
## the model (its animations, say) can find it.
signal dressed(shown: bool)

## The model file, under res://assets/third_party/.
@export_file("*.gltf", "*.glb") var path: String = "":
	set(value):
		path = value
		if is_inside_tree():
			dress()
## The box the model is fitted into, in metres. Zero keeps its own size.
## A rigged model whose armature is scaled (Meshy's are, by 0.01, with their
## animations in centimetres) can't be measured this way: its mesh reads 100
## times too small, so fitting blows it up and its animations fly off. Leave
## this zero for those and scale this node instead.
@export var fit_size: Vector3 = Vector3.ZERO:
	set(value):
		fit_size = value
		if is_inside_tree():
			dress()
## Stretch to fill [member fit_size] exactly (for boxy furniture like
## counters). Off scales evenly to fit inside it, keeping the model's shape.
@export var stretch: bool = false:
	set(value):
		stretch = value
		if is_inside_tree():
			dress()
## Greybox meshes to hide while the model shows.
@export var stand_ins: Array[VisualInstance3D] = []
## Multiplies the model's colours: above 1 in a channel makes it stronger,
## e.g. to keep greens green under warm lamplight.
@export var tint: Color = Color.WHITE
## Treat texture alpha as opaque, for solid props whose source textures have alpha.
@export var opaque: bool = false
## Draws the model stylised (cel shading, warm shadows, rim light, outline),
## sharing this look's settings with every other model that uses it. Empty
## draws it as it was made. Changing the look's settings shows at once.
@export var style: CharacterStyle:
	set(value):
		if style != null and style.changed.is_connected(_restyle):
			style.changed.disconnect(_restyle)
		style = value
		if style != null:
			style.changed.connect(_restyle)
		if is_inside_tree():
			dress()
## What this character wears: pieces put on its skeleton when the model
## loads, each following its animations. Empty wears only the model's own paint.
@export var outfit: CharacterOutfit:
	set(value):
		if outfit != null and outfit.changed.is_connected(_redress):
			outfit.changed.disconnect(_redress)
		outfit = value
		if outfit != null:
			outfit.changed.connect(_redress)
		_redress()
## Repaints this character's near-white cloth (only with a [member style]):
## a stand-in for outfits. Empty leaves its paint as it is.
@export var recolour: ClothRecolour:
	set(value):
		if recolour != null and recolour.changed.is_connected(_restyle):
			recolour.changed.disconnect(_restyle)
		recolour = value
		if recolour != null:
			recolour.changed.connect(_restyle)
		_restyle()
## Whether the model casts shadows. Off for a backdrop that would otherwise
## put the whole scene in its shade (an island's cliffs, with a low sun
## behind them).
@export var casts_shadow: bool = true

## Every model loaded this run, kept so the next copy of a scene doesn't load
## it from disk again: the ship is made many times in the tests, and freeing it
## would otherwise free its models too (#196).
static var _loaded: Dictionary[String, PackedScene] = {}

## The loaded model, or null when its file isn't there.
var model: Node3D = null
## The stylised materials on the model now, kept to follow [member style]'s changes.
var _styled: Array[ShaderMaterial] = []


func _ready() -> void:
	dress()


## Loads and fits the source model, returning whether it is showing.
func dress() -> bool:
	if model != null:
		model.queue_free()
		model = null
	_styled.clear()
	var scene: PackedScene = null
	if not path.is_empty() and ResourceLoader.exists(path):
		scene = _load_model(path)
	if scene == null:
		_show_stand_ins(true)
		dressed.emit(false)
		return false
	model = scene.instantiate() as Node3D
	if model == null:
		_show_stand_ins(true)
		dressed.emit(false)
		return false
	add_child(model)
	_wear(model)
	_fit(model)
	if style != null or tint != Color.WHITE or opaque:
		_convert(model, {})
	if not casts_shadow:
		_cast_no_shadows(model)
	_show_stand_ins(false)
	dressed.emit(true)
	return true


func _fit(node: Node3D) -> void:
	var box: AABB = _bounds(node, Transform3D.IDENTITY)
	if box.size == Vector3.ZERO:
		return
	var factor: Vector3 = Vector3.ONE
	if fit_size != Vector3.ZERO:
		factor = fit_size / box.size
		if not stretch:
			var even: float = minf(factor.x, minf(factor.y, factor.z))
			factor = Vector3(even, even, even)
	node.scale = factor
	# Sit it on the origin, centred across.
	var bottom_centre: Vector3 = box.position + Vector3(box.size.x / 2.0, 0.0, box.size.z / 2.0)
	node.position = -bottom_centre * factor


# The bounding box of every mesh under [param node], in [param node]'s parent
# space before scaling.
func _bounds(node: Node, transform_so_far: Transform3D) -> AABB:
	var here: Transform3D = transform_so_far
	if node is Node3D and node != model:
		here = transform_so_far * (node as Node3D).transform
	var box: AABB = AABB()
	var found: bool = false
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		box = here * mesh_node.mesh.get_aabb()
		found = true
	for child: Node in node.get_children():
		var inner: AABB = _bounds(child, here)
		if inner.size == Vector3.ZERO:
			continue
		box = inner if not found else box.merge(inner)
		found = true
	return box


# Reuses the converted material across surfaces that share the same source.
func _convert(node: Node, made: Dictionary[BaseMaterial3D, Material]) -> void:
	var mesh_node: MeshInstance3D = node as MeshInstance3D
	var override: BaseMaterial3D = null
	if mesh_node != null:
		override = mesh_node.material_override as BaseMaterial3D
	if override != null:
		# One material over the whole mesh: convert that instead.
		var whole: Material = made.get(override, null)
		if whole == null:
			whole = _material_for(override)
			made[override] = whole
		mesh_node.material_override = whole
	elif mesh_node != null and mesh_node.mesh != null:
		for surface: int in mesh_node.mesh.get_surface_count():
			var source: BaseMaterial3D = mesh_node.mesh.surface_get_material(surface) as BaseMaterial3D
			if source == null:
				continue
			var converted: Material = made.get(source, null)
			if converted == null:
				converted = _material_for(source)
				made[source] = converted
			mesh_node.set_surface_override_material(surface, converted)
	for child: Node in node.get_children():
		_convert(child, made)


# The material a surface painted with [param source] is drawn with.
func _material_for(source: BaseMaterial3D) -> Material:
	var base: BaseMaterial3D = source
	if tint != Color.WHITE or opaque:
		base = source.duplicate() as BaseMaterial3D
		base.albedo_color *= tint
		if opaque:
			base.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	if style == null:
		return base
	var material: ShaderMaterial = style.make_material(base)
	if recolour != null:
		recolour.apply(material)
	_styled.append(material)
	return material


# Puts each piece of the [member outfit] on the model's skeleton: the piece's
# skinned meshes move onto it, so its bones (matched by name) move them.
func _wear(node: Node3D) -> void:
	if outfit == null:
		return
	var found: Array[Node] = node.find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		return
	var skeleton: Skeleton3D = found[0] as Skeleton3D
	var pieces: Dictionary[StringName, String] = outfit.pieces()
	for slot: StringName in pieces:
		var path: String = pieces[slot]
		if not ResourceLoader.exists(path):
			continue
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			continue
		var piece: Node = scene.instantiate()
		var part: int = 0
		for mesh: Node in piece.find_children("*", "MeshInstance3D", true, false):
			var skinned: MeshInstance3D = mesh as MeshInstance3D
			if skinned.skin == null:
				continue
			skinned.get_parent().remove_child(skinned)
			skinned.owner = null
			skinned.name = "Outfit_%s_%d" % [slot, part]
			part += 1
			skeleton.add_child(skinned)
			skinned.skeleton = NodePath("..")
			# No outline on clothes: the outline round a garment's lining
			# shows through the cloth as dark patches.
			skinned.set_instance_shader_parameter(&"outline_amount", 0.0)
		piece.free()
	_hide_under_outfit(skeleton)


# Tells each of the body's own meshes (not the pieces) which of its skin's
# bones are under clothing, as a bitmask the shaders read per mesh.
func _hide_under_outfit(skeleton: Skeleton3D) -> void:
	var hidden: PackedStringArray = outfit.hidden_bones()
	for child: Node in skeleton.get_children():
		var body: MeshInstance3D = child as MeshInstance3D
		if body == null or body.skin == null or String(body.name).begins_with("Outfit_"):
			continue
		var mask: int = 0
		for bind: int in mini(body.skin.get_bind_count(), 32):
			var bone: String = String(body.skin.get_bind_name(bind))
			if bone.is_empty():
				bone = skeleton.get_bone_name(body.skin.get_bind_bone(bind))
			if hidden.has(bone):
				mask |= 1 << bind
		body.set_instance_shader_parameter(&"hidden_bones", mask)


## [param file] loaded, from [member _loaded] if it was loaded before. In the
## editor it's always loaded afresh, so a model imported again shows at once.
static func _load_model(file: String) -> PackedScene:
	if not Engine.is_editor_hint() and _loaded.has(file):
		return _loaded[file]
	var scene: PackedScene = load(file) as PackedScene
	if scene != null and not Engine.is_editor_hint():
		_loaded[file] = scene
	return scene


# The outfit changed: dress the model again in it.
func _redress() -> void:
	if is_inside_tree():
		dress()


# The style's settings changed: show them on the model straight away.
func _restyle() -> void:
	if style == null:
		return
	for material: ShaderMaterial in _styled:
		style.apply(material)
		if recolour != null:
			recolour.apply(material)
		else:
			ClothRecolour.clear(material)


func _cast_no_shadows(node: Node) -> void:
	var shape: GeometryInstance3D = node as GeometryInstance3D
	if shape != null:
		shape.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child: Node in node.get_children():
		_cast_no_shadows(child)


# Shows or hides the greybox. In the editor this is done on the renderer
# only, so hiding never gets saved into the scene.
func _show_stand_ins(show_them: bool) -> void:
	for stand_in: VisualInstance3D in stand_ins:
		if stand_in == null:
			continue
		if Engine.is_editor_hint():
			RenderingServer.instance_set_visible(stand_in.get_instance(), show_them)
		else:
			stand_in.visible = show_them
