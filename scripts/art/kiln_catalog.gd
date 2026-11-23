class_name KilnCatalog
extends RefCounted
## Finds every model the game fires in the Kiln: each [ThirdPartyModel] with a
## look in the scenes, and each [CharacterParts] in the data. The batch
## (kiln.sh) fires the stale ones, and the Lookbook lays them all out.

## Where to look, by default.
const ROOTS: PackedStringArray = ["res://scenes", "res://data"]


## Every Kiln job under [param roots], each fired file once.
static func all_jobs(roots: PackedStringArray = ROOTS) -> Array[KilnJob]:
	var found: Array[KilnJob] = []
	var seen: Dictionary = {}
	for root: String in roots:
		for file: String in files_in(root):
			var jobs: Array[KilnJob] = jobs_in_scene(file) if file.ends_with(".tscn") \
					else jobs_in_resource(file)
			for job: KilnJob in jobs:
				if not seen.has(job.fired_path()):
					seen[job.fired_path()] = true
					found.append(job)
	return found


## The Kiln jobs of every [ThirdPartyModel] with a look in the scene at
## [param path]. The scene is built to read them, but never runs.
static func jobs_in_scene(path: String) -> Array[KilnJob]:
	var jobs: Array[KilnJob] = []
	for model: ThirdPartyModel in models_in_scene(path):
		jobs.append(model.kiln_job())
		model.free()
	return jobs


## A copy of every [ThirdPartyModel] with a look in the scene at
## [param path], with its settings but none of its scene (no stand-ins).
## They aren't in the tree: add them to show them, or free them.
static func models_in_scene(path: String) -> Array[ThirdPartyModel]:
	var found: Array[ThirdPartyModel] = []
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return found
	var root: Node = scene.instantiate()
	if root == null:
		return found
	var nodes: Array[Node] = root.find_children("*", "", true, false)
	nodes.append(root)
	for node: Node in nodes:
		var model: ThirdPartyModel = node as ThirdPartyModel
		if model == null or model.kiln_job() == null:
			continue
		var copy: ThirdPartyModel = model.duplicate(Node.DUPLICATE_SCRIPTS) as ThirdPartyModel
		for child: Node in copy.get_children():
			child.free()
		copy.stand_ins = []
		copy.name = model.name
		found.append(copy)
	root.free()
	return found


## The Kiln jobs of the resource at [param path], if it's [CharacterParts].
static func jobs_in_resource(path: String) -> Array[KilnJob]:
	var parts: CharacterParts = load(path) as CharacterParts
	return parts.jobs() if parts != null else ([] as Array[KilnJob])


## Every scene and resource file under [param root], in every folder.
static func files_in(root: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var folder: DirAccess = DirAccess.open(root)
	if folder == null:
		return found
	for file: String in folder.get_files():
		if file.ends_with(".tscn") or file.ends_with(".tres"):
			found.append(root.path_join(file))
	for inner: String in folder.get_directories():
		found.append_array(files_in(root.path_join(inner)))
	return found
