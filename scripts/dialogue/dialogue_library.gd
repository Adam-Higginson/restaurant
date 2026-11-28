class_name DialogueLibrary
extends RefCounted
## Finds conversations by name. Each is a [code].dlg[/code] text file in
## [constant FOLDER] (see [DialogueScript] for how they're written), read
## once and kept.
##
## These are plain text, not Godot resources, so when the game is first
## exported [code]*.dlg[/code] must be added to the export's "non-resource
## files" filter.

const FOLDER: String = "res://data/dialogue"
const ENDING: String = ".dlg"
## The files that hold remarks (things said in passing, see [Remark]) rather
## than conversations.
const REMARK_FILES: Array[StringName] = [&"ambient", &"moments", &"home_waters"]

static var _trees: Dictionary[StringName, DialogueTree] = {}
static var _remarks: Dictionary[StringName, Array] = {}


## The conversation called [param id] ([code]heron[/code] is
## [code]data/dialogue/heron.dlg[/code]), or null if there's no such file.
## Its mistakes, if any, are reported once as errors.
static func find(id: StringName) -> DialogueTree:
	if _trees.has(id):
		return _trees[id]
	var path: String = "%s/%s%s" % [FOLDER, id, ENDING]
	if not FileAccess.file_exists(path):
		push_error("DialogueLibrary: no conversation at %s" % path)
		return null
	var tree: DialogueTree = DialogueScript.parse(FileAccess.get_file_as_string(path), id,
			is_remarks(id))
	for error: String in tree.errors:
		push_error("%s, %s" % [path, error])
	_trees[id] = tree
	return tree


## Every remark in the file called [param id] (see [constant REMARK_FILES]),
## read once and kept.
static func remarks(id: StringName) -> Array[Remark]:
	var found: Array[Remark] = []
	if _remarks.has(id):
		found.assign(_remarks[id])
		return found
	found = Remark.all_in(find(id))
	_remarks[id] = found
	return found


## Reads the conversation called [param id] from its file again, for tuning
## it while the game runs. If the file's fine, the fresh version is kept and
## returned. If it has mistakes they're reported and the version already
## read (if any) is returned instead, so a typo never leaves you with
## nothing to play. Null if there's no such file.
static func reread(id: StringName) -> DialogueTree:
	var path: String = "%s/%s%s" % [FOLDER, id, ENDING]
	if not FileAccess.file_exists(path):
		return null
	var tree: DialogueTree = DialogueScript.parse(FileAccess.get_file_as_string(path), id,
			is_remarks(id))
	if tree.errors.is_empty():
		_trees[id] = tree
		_remarks.erase(id)
		return tree
	for error: String in tree.errors:
		push_error("%s, %s" % [path, error])
	if _trees.has(id):
		return _trees[id]
	return null


## Whether the file called [param id] holds remarks rather than a conversation.
static func is_remarks(id: StringName) -> bool:
	return REMARK_FILES.has(id)


## The name of every file in [constant FOLDER]: the conversations and the
## files of remarks.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for file: String in DirAccess.get_files_at(FOLDER):
		if file.ends_with(ENDING):
			ids.append(StringName(file.trim_suffix(ENDING)))
	return ids


## Forgets what's been read, so files are read afresh. For tests and tools.
static func forget() -> void:
	_trees.clear()
	_remarks.clear()
