extends SceneTree
## Replaces a picture's smooth background (plain, or a soft glow) with plain
## light grey, keeping a textured subject: everything smooth that can be
## reached from the picture's edge without crossing anything rough (#173).
## Meshy sometimes draws a clothing piece on black with a glow, which makes a
## poor model; this cleans the picture for free. Run from the project folder:
##   godot_console.exe --headless --script tools/meshy/plain_background.gd -- IN.png OUT.png [ROUGHNESS, default 0.009]

const REACH: int = 3


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var image: Image = Image.load_from_file(args[0])
	image.convert(Image.FORMAT_RGBA8)
	var limit: float = float(args[2]) if args.size() > 2 else 0.009
	var width: int = image.get_width()
	var height: int = image.get_height()
	var data: PackedByteArray = image.get_data()
	var light: PackedFloat32Array = PackedFloat32Array()
	light.resize(width * height)
	for at: int in width * height:
		light[at] = (0.2126 * data[at * 4] + 0.7152 * data[at * 4 + 1]
				+ 0.0722 * data[at * 4 + 2]) / 255.0
	# How much each pixel differs from its neighbours, summed so any square's
	# total can be read in four look-ups.
	var sums: PackedFloat64Array = PackedFloat64Array()
	sums.resize((width + 1) * (height + 1))
	for y: int in height:
		var row: float = 0.0
		for x: int in width:
			var at: int = y * width + x
			var right: float = light[at + 1] if x < width - 1 else light[at]
			var below: float = light[at + width] if y < height - 1 else light[at]
			row += absf(light[at] - right) + absf(light[at] - below)
			sums[(y + 1) * (width + 1) + x + 1] = sums[y * (width + 1) + x + 1] + row
	var smooth: PackedByteArray = PackedByteArray()
	smooth.resize(width * height)
	for y: int in height:
		var y0: int = maxi(y - REACH, 0)
		var y1: int = mini(y + REACH + 1, height)
		for x: int in width:
			var x0: int = maxi(x - REACH, 0)
			var x1: int = mini(x + REACH + 1, width)
			var total: float = sums[y1 * (width + 1) + x1] - sums[y0 * (width + 1) + x1] \
					- sums[y1 * (width + 1) + x0] + sums[y0 * (width + 1) + x0]
			if total / float((x1 - x0) * (y1 - y0)) < limit:
				smooth[y * width + x] = 1
	var outside: PackedByteArray = PackedByteArray()
	outside.resize(width * height)
	var queue: PackedInt32Array = PackedInt32Array()
	for x: int in width:
		queue.append(x)
		queue.append((height - 1) * width + x)
	for y: int in height:
		queue.append(y * width)
		queue.append(y * width + width - 1)
	var head: int = 0
	while head < queue.size():
		var at: int = queue[head]
		head += 1
		if outside[at] == 1 or smooth[at] == 0:
			continue
		outside[at] = 1
		var x: int = at % width
		var y: int = at / width
		if x > 0:
			queue.append(at - 1)
		if x < width - 1:
			queue.append(at + 1)
		if y > 0:
			queue.append(at - width)
		if y < height - 1:
			queue.append(at + width)
	var grey: int = 200
	var changed: int = 0
	for at: int in width * height:
		if outside[at] == 1:
			data[at * 4] = grey
			data[at * 4 + 1] = grey
			data[at * 4 + 2] = grey
			data[at * 4 + 3] = 255
			changed += 1
	Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, data).save_png(args[1])
	print("REGREY changed %d%% of the picture" % (100 * changed / (width * height)))
	quit()
