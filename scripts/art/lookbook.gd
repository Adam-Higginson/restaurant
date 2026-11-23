extends Node3D
## The Lookbook: every model the Kiln fires, laid out before (the pack's own,
## as the game drew it until now) and after (fired), each labelled with its
## triangles and texture. Open scenes/tools/lookbook.tscn and press F6.
##
## Run with [code]-- --capture=<folder>[/code] and it photographs every
## model close up, before and after side by side, from a few angles and (for
## animated ones) at a few moments of a walk, saves the pictures there and
## quits. That's how fired models are checked by eye.


## One model shown before and after.
class Exhibit:
	var name: String
	var before: Node3D
	var after: Node3D
	## Where it stands along the floor (x), in metres.
	var centre: float

	func _init(called: String, pack: Node3D, fired: Node3D, at: float) -> void:
		name = called
		before = pack
		after = fired
		centre = at


## The player's scene, whose character settings (animations) are borrowed.
const PLAYER_SCENE: String = "res://scenes/prototype/player.tscn"
## The gap around each exhibit, in metres.
const GAP: float = 0.5
## The moments of a walk photographed, as parts of the way through it.
const WALK_MOMENTS: Array[float] = [0.0, 0.25, 0.5]
## The one moment photographed of a model that doesn't walk.
const STILL: Array[float] = [0.0]
## The camera's angles round each exhibit (degrees from the front) and above.
const ANGLES: Array[Vector2] = [Vector2(25.0, 20.0), Vector2(110.0, 15.0), Vector2(-150.0, 35.0)]

## Every exhibit, in order along the floor.
var exhibits: Array[Exhibit] = []

var _capture_folder: String = ""
## Only exhibits whose name has this in it, if set ([code]--only=crab[/code]).
var _only: String = ""

@onready var _camera: Camera3D = $Camera


func _ready() -> void:
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--capture="):
			_capture_folder = option.trim_prefix("--capture=")
		elif option.begins_with("--only="):
			_only = option.trim_prefix("--only=").to_lower()
	# Characters and models are built over the first frames.
	await get_tree().process_frame
	_lay_out()
	await get_tree().process_frame
	_label_all()
	_frame_all()
	if not _capture_folder.is_empty():
		await _capture_all()
		get_tree().quit()


## How many triangles every mesh under [param node] has, at full detail.
static func triangles(node: Node) -> int:
	var total: int = 0
	var meshes: Array[Node] = node.find_children("*", "MeshInstance3D", true, false)
	for found: Node in meshes:
		var shape: MeshInstance3D = found as MeshInstance3D
		if not shape.is_visible_in_tree():
			continue
		var mesh: ArrayMesh = shape.mesh as ArrayMesh
		if mesh == null:
			continue
		for surface: int in mesh.get_surface_count():
			var corners: int = mesh.surface_get_array_index_len(surface)
			if corners <= 0:
				corners = mesh.surface_get_array_len(surface)
			@warning_ignore("integer_division")
			total += corners / 3
	return total


## The box round every visible mesh under [param node], in world space.
static func bounds(node: Node) -> AABB:
	var box: AABB = AABB()
	var found: bool = false
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var shape: MeshInstance3D = child as MeshInstance3D
		if not shape.is_visible_in_tree() or shape.mesh == null:
			continue
		var inner: AABB = shape.global_transform * shape.get_aabb()
		box = inner if not found else box.merge(inner)
		found = true
	return box


func _lay_out() -> void:
	var x: float = 0.0
	for file: String in KilnCatalog.files_in("res://scenes"):
		if not file.ends_with(".tscn"):
			continue
		for model: ThirdPartyModel in KilnCatalog.models_in_scene(file):
			x = _add_prop(model, x)
	var animations: PackedStringArray = _player_animations()
	for file: String in KilnCatalog.files_in("res://data"):
		if not file.ends_with(".tres"):
			continue
		var parts: CharacterParts = load(file) as CharacterParts
		if parts != null:
			x = _add_character(file.get_file().get_basename(), parts, animations, x)


# A prop's before and after, side by side from [param x]. Returns where the
# next exhibit starts.
func _add_prop(model: ThirdPartyModel, x: float) -> float:
	var named: String = model.kiln_job().fired_path().get_file().get_basename()
	for exhibit: Exhibit in exhibits:
		if exhibit.name == named:
			model.free()
			return x
	var before: ThirdPartyModel = model.duplicate(Node.DUPLICATE_SCRIPTS) as ThirdPartyModel
	before.look = null
	model.transform = Transform3D.IDENTITY
	before.transform = Transform3D.IDENTITY
	var width: float = maxf(maxf(model.fit_size.x, model.fit_size.z), 0.3)
	return _place(named, before, model, width, x)


func _add_character(named: String, parts: CharacterParts, animations: PackedStringArray,
		x: float) -> float:
	var pair: Array[CharacterModel] = []
	for fired: bool in [false, true]:
		var body: CharacterModel = CharacterModel.new()
		body.parts_override = parts
		body.use_kiln = fired
		body.animation_files = animations
		pair.append(body)
	return _place(named, pair[0], pair[1], 0.8, x)


# Puts [param before] and [param after] side by side from [param x].
func _place(named: String, before: Node3D, after: Node3D, width: float, x: float) -> float:
	if not _only.is_empty() and not named.to_lower().contains(_only):
		before.free()
		after.free()
		return x
	var centre: float = x + width + GAP
	before.position = Vector3(centre - width / 2.0 - GAP / 4.0, 0.0, 0.0)
	after.position = Vector3(centre + width / 2.0 + GAP / 4.0, 0.0, 0.0)
	add_child(before)
	add_child(after)
	exhibits.append(Exhibit.new(named, before, after, centre))
	return centre + width + GAP


# A label over each side of each exhibit: what it is and its numbers.
func _label_all() -> void:
	for exhibit: Exhibit in exhibits:
		var before: Node3D = exhibit.before
		var after: Node3D = exhibit.after
		var high: float = maxf(bounds(before).end.y, bounds(after).end.y)
		_label(before, "%s\npack: %d triangles" % [exhibit.name, triangles(before)], high)
		_label(after, _fired_line(after), high)


func _fired_line(after: Node3D) -> String:
	var model: ThirdPartyModel = after as ThirdPartyModel
	if model != null:
		if not model.fired:
			return "Not fired"
		return model.kiln_status().replace(": ", ":\n").replace("), ", ")\n")
	var body: CharacterModel = after as CharacterModel
	var lines: PackedStringArray = []
	for job: KilnJob in body.parts_override.jobs():
		var made: Dictionary = job.report()
		var tris: float = made.get("triangles", 0.0)
		var texture: float = made.get("texture", 0.0)
		lines.append("%s %d tris %d px" % [job.look.tag().trim_prefix("character_"),
				roundi(tris), roundi(texture)])
	return "Fired: %d triangles\n%s" % [triangles(after), "\n".join(lines)]


func _label(over: Node3D, text: String, high: float) -> void:
	var label: Label3D = Label3D.new()
	label.text = text
	label.pixel_size = 0.0012
	label.font_size = 28
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	add_child(label)
	label.global_position = Vector3(over.global_position.x, high + 0.12, 0.0)


# Points the camera at the whole Lookbook.
func _frame_all() -> void:
	if exhibits.is_empty():
		return
	var last: float = exhibits[-1].centre
	_camera.position = Vector3(last / 2.0, 1.4, last * 0.6 + 2.0)
	_camera.look_at(Vector3(last / 2.0, 0.4, 0.0))


func _capture_all() -> void:
	DirAccess.make_dir_recursive_absolute(_capture_folder)
	await _settle(10)
	await _shoot("00_overview")
	for index: int in exhibits.size():
		var exhibit: Exhibit = exhibits[index]
		var stem: String = "%02d_%s" % [index + 1, exhibit.name]
		var animated: bool = _start_walk(exhibit)
		var moments: Array[float] = WALK_MOMENTS if animated else STILL
		for moment: float in moments:
			if animated:
				_pose_walk(exhibit, moment)
				await _settle(3)
			for angle: int in ANGLES.size():
				if animated and moment > 0.0 and angle > 0:
					continue
				_aim(exhibit, ANGLES[angle])
				await _settle(2)
				var shot: String = "%s_angle%d" % [stem, angle]
				if animated:
					shot += "_walk%d" % roundi(moment * 100.0)
				await _shoot(shot)


func _aim(exhibit: Exhibit, angle: Vector2) -> void:
	# Skinned meshes' boxes are where they were modelled, not where they're
	# posed, so exhibits are framed by where they stand and how big they are.
	var size: Vector3 = Vector3(0.8, 1.5, 0.8)
	var model: ThirdPartyModel = exhibit.before as ThirdPartyModel
	if model != null and model.fit_size != Vector3.ZERO:
		size = model.fit_size
	var left: Vector3 = exhibit.before.global_position
	var right: Vector3 = exhibit.after.global_position
	var box: AABB = AABB(Vector3(minf(left.x, right.x) - size.x / 2.0, 0.0, -size.z / 2.0),
			Vector3(absf(right.x - left.x) + size.x, size.y, size.z))
	var centre: Vector3 = box.get_center()
	var reach: float = box.size.length() * 0.95 + 0.2
	var turn: float = deg_to_rad(angle.x)
	var up: float = deg_to_rad(angle.y)
	# Characters face -Z; props are seen from +Z.
	var facing: float = PI if exhibit.before is CharacterModel else 0.0
	var direction: Vector3 = Vector3(sin(turn + facing) * cos(up), sin(up),
			cos(turn + facing) * cos(up))
	_camera.global_position = centre + direction * reach
	_camera.look_at(centre)


# Whether [param exhibit] walks: a character, or a model with a walk.
func _start_walk(exhibit: Exhibit) -> bool:
	return exhibit.before is CharacterModel or not _walkers(exhibit).is_empty()


# Holds both sides of [param exhibit] still at [param moment] of the way
# through their walk.
func _pose_walk(exhibit: Exhibit, moment: float) -> void:
	for animator: AnimationPlayer in _walkers(exhibit):
		var walk: StringName = _walk_of(animator)
		animator.play(walk)
		animator.seek(animator.get_animation(walk).length * moment, true)
		animator.pause()
	for side: String in ["before", "after"]:
		var body: CharacterModel = (exhibit.before if side == "before" else exhibit.after) as CharacterModel
		if body != null:
			# Played so slowly it stands still at that moment.
			var length: float = body.clip_length(body.walk_animation)
			body.act(body.walk_animation, length * moment, 0.001, 1000.0, CharacterModel.Pose.WALK)


# The animation players with a walk on both sides of a model exhibit (not
# characters: they walk by CharacterModel.act).
func _walkers(exhibit: Exhibit) -> Array[AnimationPlayer]:
	var found: Array[AnimationPlayer] = []
	for side: String in ["before", "after"]:
		var node: Node3D = exhibit.before if side == "before" else exhibit.after
		if node is CharacterModel:
			continue
		for child: Node in node.find_children("*", "AnimationPlayer", true, false):
			var animator: AnimationPlayer = child as AnimationPlayer
			if not _walk_of(animator).is_empty():
				found.append(animator)
	return found


func _walk_of(animator: AnimationPlayer) -> StringName:
	for named: StringName in animator.get_animation_list():
		if String(named).to_lower().contains("walk"):
			return named
	return &""


func _settle(frames: int) -> void:
	for frame: int in frames:
		await get_tree().process_frame


func _shoot(named: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(_capture_folder.path_join(named + ".png"))


func _player_animations() -> PackedStringArray:
	var scene: PackedScene = load(PLAYER_SCENE) as PackedScene
	if scene == null:
		return []
	var state: SceneState = scene.get_state()
	for node: int in state.get_node_count():
		for property: int in state.get_node_property_count(node):
			if state.get_node_property_name(node, property) == &"animation_files":
				var files: PackedStringArray = state.get_node_property_value(node, property)
				return files
	return []
