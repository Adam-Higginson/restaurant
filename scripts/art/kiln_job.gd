@tool
class_name KilnJob
extends RefCounted
## One model to fire in the Kiln: which pack files, with which [ArtLook], and
## where the fired model goes. Pure logic, no nodes, so it's tested alone.
##
## The fired files sit beside each other under [member out_root], mirroring
## the pack's own folders, and are gitignored with the packs they're made
## from:
## - [method fired_path]: the model (.glb), crunched, without materials;
## - [method texture_path]: its texture (.png), drawn by our N64 shader;
## - [method report_path]: what was made (.kiln.json), including the
##   [method fingerprint] it was fired with, which says if it's stale.

## Bump to make every fired model stale, when fire.py changes what it makes.
const VERSION: int = 4
## Where the packs live.
const THIRD_PARTY: String = "res://assets/third_party/"
## Where fired models go.
const OUT_ROOT: String = "res://assets/third_party/_kiln/"

## Where fired models are looked for. Tests point it at their own stand-ins.
static var out_root: String = OUT_ROOT
## The fired model's file type. Tests use scenes of their own (tscn) as
## stand-in fired models, since real ones are made from pack files.
static var fired_extension: String = "glb"

## The files to read. The first is the model; any others only lend their
## look (eyebrows painted onto a head).
var sources: PackedStringArray = []
## A colour each source's colours are multiplied by, in the same order
## (white if missing): grey hair textures are made for tinting.
var tints: Array[Color] = []
## How to fire it.
var look: ArtLook = null
## If not empty, only the parts these bones mostly move are kept (a head and
## neck off a whole body).
var keep_bones: PackedStringArray = []
## Meshes in the sources, by name, to leave out (a base body's own eyebrows).
var drop_meshes: PackedStringArray = []
## The box the model is fitted into in the game, in metres (see
## [member ThirdPartyModel.fit_size]); zero for none. With [member scale],
## this says how big it's drawn, so its pixels come out the right size.
var fit_size: Vector3 = Vector3.ZERO
## Whether it's stretched to fill [member fit_size].
var stretch: bool = false
## How much it's scaled in the game, on top of the fit.
var scale: float = 1.0


func _init(model: String = "", with_look: ArtLook = null) -> void:
	if not model.is_empty():
		sources = [model]
	look = with_look


## Whether there's something to fire: a look and every source file.
func can_fire() -> bool:
	if look == null or sources.is_empty():
		return false
	for source: String in sources:
		if source.is_empty() or not FileAccess.file_exists(source):
			return false
	return true


## The fired model's path.
func fired_path() -> String:
	return _stem() + "." + fired_extension


## The fired model's texture.
func texture_path() -> String:
	return _stem() + ".png"


## What was made, written by fire.py.
func report_path() -> String:
	return fired_path() + ".kiln.json"


## The job file fire.py reads.
func job_path() -> String:
	return fired_path() + ".job.json"


## Whether the model has been fired: its model and texture are there and
## Godot has imported them.
func is_fired() -> bool:
	return ResourceLoader.exists(fired_path()) and ResourceLoader.exists(texture_path())


## Whether it was fired with other settings or from older files than now.
## Not fired at all counts as stale.
func is_stale() -> bool:
	return report().get("fingerprint", "") != fingerprint()


## What fire.py reported making: triangles, texture, pixels_per_metre and
## more. Empty if it hasn't been fired.
func report() -> Dictionary:
	if not FileAccess.file_exists(report_path()):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path()))
	if not parsed is Dictionary:
		return {}
	var made: Dictionary = parsed
	return made


## A short text naming everything the fired model depends on: the settings,
## when each source file last changed, and [constant VERSION].
func fingerprint() -> String:
	var parts: Dictionary = settings()
	var changed: Array[int] = []
	for source: String in sources:
		changed.append(FileAccess.get_modified_time(source) if FileAccess.file_exists(source) else 0)
	parts["changed"] = changed
	parts["version"] = VERSION
	return JSON.stringify(parts, "", true).md5_text()


## Everything that decides how the model fires, by fire.py's names (without
## file paths on this machine).
func settings() -> Dictionary:
	var all: Dictionary = look.firing() if look != null else {}
	all["sources"] = Array(sources)
	var tint_list: Array[Array] = []
	for index: int in sources.size():
		var tint: Color = tints[index] if index < tints.size() else Color.WHITE
		tint_list.append([snappedf(tint.r, 0.001), snappedf(tint.g, 0.001),
				snappedf(tint.b, 0.001)])
	all["tints"] = tint_list
	all["keep_bones"] = Array(keep_bones)
	all["drop_meshes"] = Array(drop_meshes)
	all["fit_size"] = [fit_size.x, fit_size.y, fit_size.z]
	all["stretch"] = stretch
	all["scale"] = scale
	return all


## The job fire.py reads: [method settings], with the files as full paths on
## this machine (Blender doesn't know res://).
func to_dictionary() -> Dictionary:
	var job: Dictionary = settings()
	var full: Array[String] = []
	for source: String in sources:
		full.append(ProjectSettings.globalize_path(source))
	job["sources"] = full
	job["out"] = ProjectSettings.globalize_path(fired_path())
	job["out_png"] = ProjectSettings.globalize_path(texture_path())
	job["fingerprint"] = fingerprint()
	return job


## Writes the job file (and the folder for the fired files). Returns its
## full path, or an empty text if it couldn't be written.
func write() -> String:
	var folder: String = ProjectSettings.globalize_path(fired_path().get_base_dir())
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return ""
	var file: FileAccess = FileAccess.open(job_path(), FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(to_dictionary(), " ", true))
	file.close()
	return ProjectSettings.globalize_path(job_path())


## A line about where the model stands, for the Inspector.
func status() -> String:
	if look == null:
		return "No look: drawn as it comes, with grain"
	if not can_fire():
		return "Pack file missing: the greybox shows"
	var made: Dictionary = report()
	if made.is_empty():
		return "Not fired yet: press Fire in Kiln"
	var triangles: float = made.get("triangles", 0.0)
	var from: float = made.get("source_triangles", 0.0)
	var texture: float = made.get("texture", 0.0)
	var density: float = made.get("pixels_per_metre", 0.0)
	var line: String = "%d triangles (from %d), %d px texture, %d px per metre" % [
			roundi(triangles), roundi(from), roundi(texture), roundi(density)]
	if is_stale():
		return "Stale (settings or files changed): " + line
	return "Fired: " + line


# The fired files' path without an extension: the source's path under the
# packs, mirrored under out_root, with the look's tag.
func _stem() -> String:
	var source: String = sources[0] if not sources.is_empty() else ""
	var inside: String = source.trim_prefix(THIRD_PARTY) if source.begins_with(THIRD_PARTY) \
			else source.get_file()
	var tag: String = look.tag() if look != null else "none"
	return out_root + inside.get_basename() + "." + tag
