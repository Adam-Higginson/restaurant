@tool
class_name Kiln
extends RefCounted
## Starts Blender to fire [KilnJob]s, and tells the editor about the files it
## makes.
##
## Blender comes from its usual install folder, or from the BLENDER
## environment variable if that's set. Without Blender nothing fires, and
## everything carries on drawing the models as they come.

## Where Blender usually is.
const DEFAULT_BLENDER: String = "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe"
## The firing script Blender runs.
const SCRIPT: String = "res://tools/kiln/fire.py"


## The Blender program to run.
static func blender() -> String:
	var chosen: String = OS.get_environment("BLENDER")
	return chosen if not chosen.is_empty() else DEFAULT_BLENDER


## Whether Blender is there to fire with.
static func has_blender() -> bool:
	return FileAccess.file_exists(blender())


## What Blender is started with for the job file [param job_file]: in the
## background, with its factory settings, running the firing script on it.
static func arguments(job_file: String) -> PackedStringArray:
	return ["-b", "--factory-startup", "--python", ProjectSettings.globalize_path(SCRIPT),
			"--", job_file]


## Starts firing [param job] without waiting. Returns Blender's process id,
## or -1 if it couldn't start (no Blender, no pack file).
static func start(job: KilnJob) -> int:
	if not job.can_fire() or not has_blender():
		return -1
	var job_file: String = job.write()
	if job_file.is_empty():
		return -1
	return OS.create_process(blender(), arguments(job_file))


## Fires every one of [param jobs] at once, in the background, waiting
## (without stopping the editor or game) until all are done, then imports
## them in the editor. Call it with [code]await[/code]. Returns how many came
## out fresh.
static func fire_in_background(jobs: Array[KilnJob]) -> int:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	var running: Array[int] = []
	for job: KilnJob in jobs:
		var process: int = start(job)
		if process >= 0:
			running.append(process)
	while running.any(func(process: int) -> bool: return OS.is_process_running(process)):
		await tree.create_timer(0.25).timeout
	var fresh: int = 0
	for job: KilnJob in jobs:
		import_in_editor(job)
		if not job.is_stale():
			fresh += 1
		elif not running.is_empty():
			push_warning("The Kiln couldn't fire %s: try kiln.sh to see why." % job.sources[0])
	FiredModel.forget()
	return fresh


## Fires [param job] and waits until it's done. Returns whether it made a
## fresh model; [param lines] gets Blender's output.
static func run(job: KilnJob, lines: Array[String] = []) -> bool:
	if not job.can_fire() or not has_blender():
		return false
	var job_file: String = job.write()
	if job_file.is_empty():
		return false
	var output: Array = []
	var code: int = OS.execute(blender(), arguments(job_file), output, true)
	for line: Variant in output:
		lines.append(str(line))
	return code == 0 and not job.is_stale()


## In the editor, imports [param job]'s fresh files straight away, so they
## can be loaded. Returns whether it could (not outside the editor).
static func import_in_editor(job: KilnJob) -> bool:
	if not Engine.is_editor_hint() or not Engine.has_singleton(&"EditorInterface"):
		return false
	# The editor's own classes can't be named in game code (they're not in a
	# built game), so it's reached by name.
	var editor: Object = Engine.get_singleton(&"EditorInterface")
	var files: Object = editor.call(&"get_resource_filesystem")
	var paths: PackedStringArray = [job.texture_path(), job.fired_path()]
	for path: String in paths:
		files.call(&"update_file", path)
	files.call(&"reimport_files", paths)
	return true
