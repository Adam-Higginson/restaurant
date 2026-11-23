class_name KilnReport
extends RefCounted
## The budget report: every fired model against its look's budgets, with
## anything out of line flagged, as a table (kiln.sh --report, and beside the
## Lookbook's pictures).

## How far over its triangle budget a model may be before it's flagged.
const TRIANGLE_SLACK: float = 1.1
## How far from its look's pixels per metre a model may be (as a fraction of
## it, either way) before it's flagged.
const DENSITY_SLACK: float = 0.25


## What's out of line with [param job]'s fired model, in a few words each.
## Empty when it's all within budget.
static func problems(job: KilnJob) -> PackedStringArray:
	var found: PackedStringArray = []
	var made: Dictionary = job.report()
	if made.is_empty():
		found.append("not fired")
		return found
	if job.is_stale():
		found.append("stale")
	var triangles: float = made.get("triangles", 0.0)
	if triangles > job.look.triangles * TRIANGLE_SLACK:
		found.append("over budget")
	var density: float = made.get("pixels_per_metre", 0.0)
	var wanted: float = job.look.pixels_per_metre
	var texture: float = made.get("texture", 0.0)
	if density < wanted * (1.0 - DENSITY_SLACK):
		found.append("pixels too big" if texture < job.look.max_texture
				else "pixels too big (texture at its cap)")
	elif density > wanted * (1.0 + DENSITY_SLACK):
		found.append("pixels too small")
	var lost: Array = made.get("bones_lost", [])
	for bone: Variant in lost:
		# Fingertips fusing into mitten hands is intended.
		if not _is_finger(str(bone)):
			found.append("bone %s has nothing to move" % bone)
	return found


## A markdown table of [param jobs]: one row per fired model.
static func table(jobs: Array[KilnJob]) -> String:
	var rows: PackedStringArray = [
		"| Model | Look | Triangles (budget) | Texture | Pixels per metre (wanted) | Notes |",
		"|---|---|---|---|---|---|",
	]
	for job: KilnJob in jobs:
		var made: Dictionary = job.report()
		var triangles: float = made.get("triangles", 0.0)
		var texture: float = made.get("texture", 0.0)
		var density: float = made.get("pixels_per_metre", 0.0)
		var notes: PackedStringArray = problems(job)
		rows.append("| %s | %s | %d (%d) | %d px | %d (%d) | %s |" % [
				job.sources[0].get_file().get_basename(), job.look.tag(), roundi(triangles),
				job.look.triangles, roundi(texture), roundi(density),
				roundi(job.look.pixels_per_metre),
				", ".join(notes) if not notes.is_empty() else "ok"])
	return "\n".join(rows) + "\n"


## How many of [param jobs] have something out of line.
static func count_problems(jobs: Array[KilnJob]) -> int:
	var count: int = 0
	for job: KilnJob in jobs:
		if not problems(job).is_empty():
			count += 1
	return count


static func _is_finger(bone: String) -> bool:
	for finger: String in ["thumb", "index", "middle", "ring", "pinky"]:
		if bone.begins_with(finger):
			return true
	return false
