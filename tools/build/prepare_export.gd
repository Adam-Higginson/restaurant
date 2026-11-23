extends SceneTree
## Gets the project ready to export a build. It:
## 1. stamps which build it is into project.godot (see [BuildInfo]): today's
##    date (UTC) and the commit given;
## 2. writes the files to put in it (see [ExportList]) into every export preset;
## 3. writes every name the build goes by to builds/build.env, for the shell
##    scripts to read, so the names are only ever made in [BuildInfo].
## Run by tools/build/export.sh, which puts project.godot and
## export_presets.cfg back afterwards:
##
##   godot --headless --path . -s res://tools/build/prepare_export.gd -- <commit>

const PRESETS: String = "res://export_presets.cfg"
const ENV: String = "res://builds/build.env"


# Called once the engine has started (unlike _init, which runs before it's
# ready, and crashed on the way out).
func _initialize() -> void:
	quit(_prepare())


func _prepare() -> int:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() != 1 or args[0].is_empty():
		printerr("Usage: -s res://tools/build/prepare_export.gd -- <commit>")
		return 1
	var commit: String = args[0]
	var version: String = BuildInfo.version_for(Time.get_date_dict_from_system(true))
	if BuildInfo.stamp(version, commit) != OK:
		printerr("Couldn't stamp project.godot.")
		return 1
	var files: PackedStringArray = ExportList.build()
	var presets: ConfigFile = ConfigFile.new()
	if presets.load(PRESETS) != OK:
		printerr("Couldn't read %s." % PRESETS)
		return 1
	for section: String in presets.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options"):
			presets.set_value(section, "export_filter", "resources")
			presets.set_value(section, "export_files", files)
	if presets.save(PRESETS) != OK:
		printerr("Couldn't write %s." % PRESETS)
		return 1
	DirAccess.make_dir_recursive_absolute(ENV.get_base_dir())
	var env: FileAccess = FileAccess.open(ENV, FileAccess.WRITE)
	if env == null:
		printerr("Couldn't write %s." % ENV)
		return 1
	env.store_string(BuildInfo.env_for(version, commit))
	env.close()
	print("Stamped %s and listed %d files to export." % [BuildInfo.label(), files.size()])
	return 0
