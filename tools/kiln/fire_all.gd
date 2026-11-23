extends Node
## Fires every model the game uses that's stale (kiln.sh runs this scene).
##
## Options, after --:
## - [code]--all[/code]: fire every model, stale or not.
## - [code]--list[/code]: only say where each model stands.
## - any other word: only models whose file name contains it.


func _ready() -> void:
	var options: PackedStringArray = OS.get_cmdline_user_args()
	var every: bool = options.has("--all")
	var only_list: bool = options.has("--list")
	var words: PackedStringArray = []
	for option: String in options:
		if not option.begins_with("--"):
			words.append(option.to_lower())
	if not Kiln.has_blender() and not only_list:
		printerr("KILN: no Blender at %s (set BLENDER to its path)" % Kiln.blender())
		get_tree().quit(1)
		return
	var failed: int = 0
	var fired: int = 0
	for job: KilnJob in KilnCatalog.all_jobs():
		var named: String = job.fired_path().get_file()
		if not words.is_empty() and not _matches(named, words):
			continue
		if only_list or not job.can_fire() or (not every and not job.is_stale()):
			print("KILN %s: %s" % [named, job.status()])
			continue
		print("KILN firing %s ..." % named)
		var lines: Array[String] = []
		if Kiln.run(job, lines):
			fired += 1
			print("KILN %s: %s" % [named, job.status()])
		else:
			failed += 1
			printerr("KILN couldn't fire %s:" % named)
			for line: String in lines:
				printerr(line.right(2000))
	print("KILN fired %d, %d failed" % [fired, failed])
	get_tree().quit(1 if failed > 0 else 0)


func _matches(named: String, words: PackedStringArray) -> bool:
	for word: String in words:
		if named.to_lower().contains(word):
			return true
	return false
