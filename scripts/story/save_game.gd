class_name SaveGame
extends RefCounted
## The voyage so far, kept between plays: the memories of home you've got
## back, which day it is and whether it's morning, how warm the lantern is,
## what conversations remember (their flags), and who the player is (their
## [PlayerLook]). Saved when you wake from sleep in your bunk, loaded by the [Opening].
##
## A small JSON file in the user folder (Project > Open User Data Folder).
## Delete it to start a new voyage.

## Where the voyage is kept. Tests point it somewhere else.
static var path: String = "user://voyage.save"

## Bumped if the format changes, so an old save can be recognised.
const VERSION: int = 1


## What's worth keeping, now, as plain data.
static func capture(memories: MemoryBook, time: TimeOfDay, warmth: float,
		dialogue: DialogueState = null,
		look: PlayerLook.Body = PlayerLook.Body.BOY) -> Dictionary:
	var ids: Array[String] = []
	for id: StringName in memories.remembered_ids():
		ids.append(String(id))
	return {
		"version": VERSION,
		"memories": ids,
		"day": time.day if time != null else 1,
		"morning": time != null and time.is_morning(),
		"warmth": warmth,
		"flags": dialogue.to_dict() if dialogue != null else {},
		"look": PlayerLook.to_text(look),
	}


## Writes [param data] to [member path]. Returns whether it worked.
static func write(data: Dictionary) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


## The saved voyage, or an empty dictionary if there isn't one (or it can't
## be read).
static func read() -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	var version: int = data.get("version", 0)
	if version != VERSION:
		return {}
	return data


## Whether there's a voyage to continue.
static func exists() -> bool:
	return not read().is_empty()


## Forgets the saved voyage.
static func erase() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Puts a saved voyage back: the memories (quietly, without their cards), the
## day and time, the lantern's warmth, and what conversations remember. A
## save from before conversations has no flags, and that's fine.
static func restore(data: Dictionary, memories: MemoryBook, time: TimeOfDay,
		spirit: LanternSpirit, dialogue: DialogueState = null) -> void:
	var ids: Array[StringName] = []
	for id: Variant in data.get("memories", []):
		ids.append(StringName(str(id)))
	memories.restore(ids)
	var morning: bool = data.get("morning", false)
	var day: int = data.get("day", 1)
	var warmth: float = data.get("warmth", 1.0)
	if time != null:
		time.dawn = 1.0 if morning else 0.0
		time.day = day
	if spirit != null:
		spirit.warmth = warmth
	if dialogue != null:
		var flags: Dictionary = data.get("flags", {})
		dialogue.restore(flags)


## Who the player was in the saved voyage [param data]. A save from before
## looks were chosen is a boy, the first choice.
static func look_of(data: Dictionary) -> PlayerLook.Body:
	return PlayerLook.from_text(str(data.get("look", "")))
