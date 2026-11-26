extends GameTestSuite
## Tests that our placeholder textures are painted soft (#135), not pixel art:
## each is big enough to hold smooth shapes, with the in-between colours that
## anti-aliased edges leave, and every one has its pixel-art original kept
## for the painting script (tools/textures/paint_placeholders.sh).

const TEXTURES: String = "res://assets/placeholder/textures"
const ORIGINALS: String = "res://tools/textures/originals"


func test_every_texture_is_big_enough_for_smooth_shapes() -> void:
	for file: String in _textures():
		var image: Image = _image(file)
		assert_int(mini(image.get_width(), image.get_height())) \
				.override_failure_message("%s is %dx%d" % [file, image.get_width(),
				image.get_height()]).is_greater_equal(32)


func test_every_texture_has_soft_edges_not_a_few_flat_colours() -> void:
	# Pixel art uses a handful of colours; smooth painting leaves many
	# in-between ones along every edge and in the mottling.
	for file: String in _textures():
		var image: Image = _image(file)
		var seen: Dictionary = {}
		for y: int in range(0, image.get_height(), 2):
			for x: int in range(0, image.get_width(), 2):
				seen[image.get_pixel(x, y).to_rgba32()] = true
		assert_int(seen.size()).override_failure_message(
				"%s has only %d colours" % [file, seen.size()]).is_greater(40)


func test_every_texture_keeps_its_pixel_art_original() -> void:
	for file: String in _textures():
		assert_bool(FileAccess.file_exists(ORIGINALS.path_join(file))) \
				.override_failure_message(file).is_true()
	# Godot leaves the originals alone: they're only for the painting script.
	assert_bool(FileAccess.file_exists(ORIGINALS.path_join(".gdignore"))).is_true()


func test_the_bunks_pillows_are_pack_pillows_over_our_boxes() -> void:
	var bay: Node = (load("res://scenes/prototype/props/bunk_bay.tscn") as PackedScene).instantiate()
	for pillow: String in ["LowerPillow", "LowerPillowSmall", "UpperPillow", "UpperPillowSmall"]:
		var pack: ThirdPartyModel = bay.get_node("%s/Pack" % pillow) as ThirdPartyModel
		assert_object(pack).override_failure_message(pillow).is_not_null()
		assert_str(pack.path.get_file()).is_equal("pillow_A.gltf")
		assert_object(bay.get_node("%s/Box" % pillow)).is_not_null()
	bay.free()


func _textures() -> PackedStringArray:
	var found: PackedStringArray = []
	for file: String in DirAccess.get_files_at(TEXTURES):
		if file.ends_with(".png"):
			found.append(file)
	return found


func _image(file: String) -> Image:
	var texture: Texture2D = load(TEXTURES.path_join(file)) as Texture2D
	return texture.get_image()
