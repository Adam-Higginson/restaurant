extends Node3D
## PROTOTYPE (#168): photographs the cove island with the painted look
## ([PaintedLook]) off and on, to compare. Run
## scenes/tools/island_capture.tscn with [code]-- --out=<folder>[/code]; add
## [code]--only=beach[/code] to take only the shots whose names start so.

const COVE: PackedScene = preload("res://scenes/prototype/islands/cove.tscn")
const SETTLE: int = 60


## One photograph: where the camera is and what it looks at.
class Shot:
	var name: String
	var from: Vector3
	var to: Vector3

	func _init(called: String, eye: Vector3, target: Vector3) -> void:
		name = called
		from = eye
		to = target


func _ready() -> void:
	var out: String = "user://island"
	var only: String = ""
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--out="):
			out = option.trim_prefix("--out=")
		if option.begins_with("--only="):
			only = option.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(out)
	var cove: Node3D = COVE.instantiate() as Node3D
	add_child(cove)
	var look: PaintedLook = cove.get_node(^"PaintedLook") as PaintedLook
	look.enabled = false
	var camera: Camera3D = Camera3D.new()
	camera.fov = 55.0
	cove.add_child(camera)
	camera.make_current()
	var shots: Array[Shot] = [
		Shot.new("beach", Vector3(9.0, 3.4, 13.0), Vector3(2.0, 2.2, 0.0)),
		Shot.new("crab", Vector3(3.4, 3.1, 5.0), Vector3(2.0, 0.9, 1.9)),
		Shot.new("shore_wide", Vector3(-12.0, 5.5, 24.0), Vector3(6.0, 3.0, -6.0)),
		Shot.new("jungle", Vector3(14.0, 3.0, 6.0), Vector3(20.0, 4.0, -14.0)),
	]
	for frame: int in 120:
		await get_tree().process_frame
	var both: Array[bool] = [false, true]
	for shot: Shot in shots:
		if not only.is_empty() and not shot.name.begins_with(only):
			continue
		camera.global_position = shot.from
		camera.look_at(shot.to)
		for on: bool in both:
			look.enabled = on
			for frame: int in SETTLE:
				await get_tree().process_frame
			var picture: Image = get_viewport().get_texture().get_image()
			picture.save_png("%s/%s_%s.png" % [out, shot.name, "painted" if on else "before"])
	get_tree().quit()
