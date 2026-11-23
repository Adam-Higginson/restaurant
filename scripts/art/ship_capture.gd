extends Node3D
## PROTOTYPE (#168): photographs the ship in the sea scene with the painted
## look ([PaintedLook]) off and on, to compare. Run
## scenes/tools/ship_capture.tscn with [code]-- --out=<folder>[/code]; add
## [code]--only=galley[/code] to take only the shots whose names start so.

const SEA: PackedScene = preload("res://scenes/prototype/sea.tscn")
const SETTLE: int = 50


## One photograph: where the camera is and looks, in the ship's space, and
## the time of day (0 night, 1 dawn).
class Shot:
	var name: String
	var from: Vector3
	var to: Vector3
	var dawn: float

	func _init(called: String, eye: Vector3, target: Vector3, morning: float) -> void:
		name = called
		from = eye
		to = target
		dawn = morning


func _ready() -> void:
	var out: String = "user://ship"
	var only: String = ""
	for option: String in OS.get_cmdline_user_args():
		if option.begins_with("--out="):
			out = option.trim_prefix("--out=")
		if option.begins_with("--only="):
			only = option.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(out)
	var sea: Node3D = SEA.instantiate() as Node3D
	var opening: Opening = sea.get_node(^"Opening") as Opening
	opening.skip = true
	opening.load_save = false
	add_child(sea)
	var look: PaintedLook = sea.get_node(^"PaintedLook") as PaintedLook
	look.enabled = false
	var ship: Node3D = sea.get_node(^"Ship") as Node3D
	var time: TimeOfDay = sea.get_node(^"TimeOfDay") as TimeOfDay
	var camera: Camera3D = Camera3D.new()
	camera.fov = 55.0
	ship.add_child(camera)
	camera.make_current()
	var shots: Array[Shot] = [
		# Shots named "player" are measured from where the player stands.
		Shot.new("player_dawn", Vector3(1.0, 1.3, -2.8), Vector3(0.0, 0.95, 0.0), 1.0),
		Shot.new("player_side_dawn", Vector3(2.6, 1.2, -0.4), Vector3(0.0, 0.95, 0.0), 1.0),
		Shot.new("galley_night", Vector3(-1.2, 2.5, 7.6), Vector3(2.6, 1.7, 2.6), 0.0),
		Shot.new("table_night", Vector3(0.2, 2.2, 6.4), Vector3(1.6, 1.8, 4.9), 0.0),
		Shot.new("counters_night", Vector3(2.6, 2.5, 5.6), Vector3(-0.6, 1.6, 1.6), 0.0),
		Shot.new("bunks_night", Vector3(2.6, 2.6, 12.6), Vector3(-1.3, 2.3, 10.15), 0.0),
		Shot.new("bunks_port", Vector3(2.4, 2.7, 10.2), Vector3(-5.5, 2.0, 12.2), 0.0),
		Shot.new("bunks_starboard", Vector3(-2.6, 2.7, 10.6), Vector3(5.5, 2.0, 12.4), 0.0),
		Shot.new("nook_night", Vector3(2.2, 2.5, 14.0), Vector3(-0.6, 1.5, 11.4), 0.0),
		Shot.new("curtains_night", Vector3(3.0, 2.5, 12.2), Vector3(5.7, 2.3, 10.4), 0.0),
		Shot.new("deck_night", Vector3(3.0, 7.4, 8.0), Vector3(-0.5, 6.0, -4.0), 0.0),
		Shot.new("deck_dawn", Vector3(3.0, 7.4, 8.0), Vector3(-0.5, 6.0, -4.0), 1.0),
		Shot.new("galley_dawn", Vector3(-1.2, 2.5, 7.6), Vector3(2.6, 1.7, 2.6), 1.0),
	]
	for frame: int in 90:
		await get_tree().process_frame
	var both: Array[bool] = [false, true]
	for shot: Shot in shots:
		if not only.is_empty() and not shot.name.begins_with(only):
			continue
		time.dawn = shot.dawn
		var from: Vector3 = shot.from
		var to: Vector3 = shot.to
		if shot.name.begins_with("player"):
			var player: Node3D = sea.get_node(^"Player") as Node3D
			from = ship.to_local(player.global_position + shot.from)
			to = ship.to_local(player.global_position + shot.to)
		camera.position = from
		for on: bool in both:
			look.enabled = on
			for frame: int in SETTLE:
				await get_tree().process_frame
				camera.look_at(ship.to_global(to))
			var picture: Image = get_viewport().get_texture().get_image()
			picture.save_png("%s/%s_%s.png" % [out, shot.name, "painted" if on else "before"])
	get_tree().quit()
