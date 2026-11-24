extends SceneTree
## Measures the ship's fitted Meshy hull and saves its top edge as
## data/ship/hull_outline.tres (#196), which the deck's edge and the rails are
## built from. Run it again after changing how the hull is fitted
## ([HullShell]'s settings in ship.tscn). Needs the art. From the project
## folder:
##   godot_console.exe --headless --path . --script tools/ship/measure_hull.gd

const SHIP: String = "res://scenes/prototype/ship.tscn"
const OUT: String = "res://data/ship/hull_outline.tres"


func _initialize() -> void:
	_run()


func _run() -> void:
	var ship: Node3D = (load(SHIP) as PackedScene).instantiate() as Node3D
	root.add_child(ship)
	await process_frame
	var shell: HullShell = ship.get_node(^"Visuals/HullShell") as HullShell
	if shell.model == null:
		push_error("The hull model isn't there: clone the art first (see CLAUDE.md).")
		quit(1)
		return
	var outline: HullOutline = shell.measure_outline()
	DirAccess.make_dir_recursive_absolute(OUT.get_base_dir())
	var saved: Error = ResourceSaver.save(outline, OUT)
	print("MEASURE_HULL saved %d samples from z %.2f to %.2f (%s)" % [
		outline.samples(), outline.start_z, outline.end_z(), error_string(saved)])
	ship.free()
	quit(0 if saved == OK else 1)
