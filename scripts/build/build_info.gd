class_name BuildInfo
extends RefCounted
## Which build of the game this is, so a player can say which one they
## played: "2026.11.23 (a1b2c3d)", the day it was built and the commit it was
## built from. Run from the editor it's [constant DEV].
##
## A published build is stamped by [code]tools/build/prepare_export.gd[/code]
## just before exporting: it writes the version and commit into the project's
## settings, which go into the build with everything else. The same names
## make the release's tag and its zips, so they always match.

## Shown when the game wasn't built by the publish workflow.
const DEV: String = "dev"
## The day the build was made, as [code]YYYY.MM.DD[/code]. Godot also uses it
## as the Windows file version and the Mac app's version.
const VERSION_SETTING: String = "application/config/version"
## The short commit the build was made from. Our own setting.
const COMMIT_SETTING: String = "application/config/build_commit"
## The file name every zip starts with.
const GAME: String = "SaltAndEmber"


## This build's name, from the project's settings.
static func label() -> String:
	return label_for(
			str(ProjectSettings.get_setting(VERSION_SETTING, "")),
			str(ProjectSettings.get_setting(COMMIT_SETTING, "")))


## A build's name: "2026.11.23 (a1b2c3d)". [constant DEV] with no version.
static func label_for(version: String, commit: String) -> String:
	if version.is_empty():
		return DEV
	if commit.is_empty():
		return version
	return "%s (%s)" % [version, commit]


## The version for a build made on [param date] (a date from
## [method Time.get_date_dict_from_system]): "2026.11.23".
static func version_for(date: Dictionary) -> String:
	var year: int = date.get("year", 0)
	var month: int = date.get("month", 0)
	var day: int = date.get("day", 0)
	return "%04d.%02d.%02d" % [year, month, day]


## The release's tag on GitHub: "build-2026.11.23-a1b2c3d".
static func tag_for(version: String, commit: String) -> String:
	return "build-%s-%s" % [version, commit]


## The name of one platform's zip: "SaltAndEmber-2026.11.23-a1b2c3d-windows.zip".
static func zip_name(version: String, commit: String, platform: String) -> String:
	return "%s-%s-%s-%s.zip" % [GAME, version, commit, platform]


## Every name a build goes by, as lines a shell script can read with
## [code]source[/code]: the version, commit, label, tag and each zip's name.
static func env_for(version: String, commit: String) -> String:
	var names: Dictionary[String, String] = {
		"VERSION": version,
		"COMMIT": commit,
		"LABEL": label_for(version, commit),
		"TAG": tag_for(version, commit),
		"WINDOWS_ZIP": zip_name(version, commit, "windows"),
		"MACOS_ZIP": zip_name(version, commit, "macos"),
	}
	var lines: String = ""
	for key: String in names:
		lines += "%s='%s'\n" % [key, names[key]]
	return lines


## Writes [param version] and [param commit] into the project's settings
## file, for the export that follows to carry. Only the publish tools call
## this: it changes [code]project.godot[/code].
static func stamp(version: String, commit: String) -> Error:
	ProjectSettings.set_setting(VERSION_SETTING, version)
	ProjectSettings.set_setting(COMMIT_SETTING, commit)
	return ProjectSettings.save()
