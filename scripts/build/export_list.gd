class_name ExportList
extends RefCounted
## Which files go into an exported build of the game.
##
## Exporting everything would carry about a gigabyte of pack files the game
## never uses (every outfit's textures, every format of every prop). Godot
## can export a list of files and whatever they need instead, so this lists:
## - every file of ours, outside the folders in [constant LEFT_OUT];
## - every pack file one of them names by path (the game loads models,
##   textures and sounds by path, so Godot can't see those by itself).
## Godot adds what those need, like a model's textures, as it exports.
##
## [code]tools/build/prepare_export.gd[/code] writes the list into the export
## presets just before a build.

## Folders that never go into a build, or (the packs) only the files named.
const LEFT_OUT: PackedStringArray = [
	"res://.godot",
	"res://addons/gdUnit4",
	"res://assets/third_party",
	"res://builds",
	"res://docs",
	"res://reports",
	"res://tests",
	"res://tools",
]
## Where the art packs are.
const THIRD_PARTY: String = "res://assets/third_party/"
## The kinds of text file that can name a pack file.
const NAMING: PackedStringArray = ["tscn", "tres", "gd", "dlg", "gdshader"]

## A pack path inside quotes, as scenes, resources and scripts write them.
static var _named: RegEx = RegEx.create_from_string("res://assets/third_party/[^\"\\n]+")


## Every file a build needs, sorted, before Godot adds what they depend on.
static func build() -> PackedStringArray:
	var found: Dictionary[String, bool] = {}
	for path: String in files_under("res://", true):
		if ResourceLoader.exists(path):
			found[path] = true
		if NAMING.has(path.get_extension()):
			for named: String in named_in(FileAccess.get_file_as_string(path)):
				if ResourceLoader.exists(named):
					found[named] = true
	var listed: PackedStringArray = PackedStringArray(found.keys())
	listed.sort()
	return listed


## Whether [param path] is in one of the [constant LEFT_OUT] folders.
static func is_left_out(path: String) -> bool:
	for folder: String in LEFT_OUT:
		if path == folder or path.begins_with(folder + "/"):
			return true
	return false


## Every pack path named in [param text], once each, in order.
static func named_in(text: String) -> PackedStringArray:
	var named: PackedStringArray = []
	for found: RegExMatch in _named.search_all(text):
		var path: String = found.get_string()
		if not named.has(path):
			named.append(path)
	return named


## Every file under [param folder], in every folder below it, except the
## import and uid files beside them. Skips folders Godot ignores (hidden ones,
## and those with a [code].gdignore[/code]). With [param leave_out], also
## skips the [constant LEFT_OUT] folders.
static func files_under(folder: String, leave_out: bool = false) -> PackedStringArray:
	var found: PackedStringArray = []
	if leave_out and is_left_out(folder):
		return found
	var dir: DirAccess = DirAccess.open(folder)
	if dir == null or dir.file_exists(".gdignore"):
		return found
	for file: String in dir.get_files():
		if file.ends_with(".import") or file.ends_with(".uid"):
			continue
		found.append(folder.path_join(file))
	for inner: String in dir.get_directories():
		found.append_array(files_under(folder.path_join(inner), leave_out))
	return found
