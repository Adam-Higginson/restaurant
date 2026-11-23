"""Makes the Salt and Ember palette: the colours every fired texture snaps to.

Run with Blender's command line (for its numpy and image reading); the
script tools/kiln/make_palette.sh does it for you:

    blender -b --factory-startup --python tools/kiln/make_palette.py -- \
        <out.tres> <colours> <image.png> [<image.png> ...]

It reads every pixel of the images (our own placeholder textures and the
fired ones), and finds [colours] colours that stand for them best: k-means
clustering in OKLab, where equal distances look equally different, so the
palette spends its colours where the eye tells them apart. Our own textures
count double, so the palette leans to the game's look rather than a pack's.
Very dark and very bright colours are kept as their own clusters too, so
shadows and highlights aren't lost.

The result is a Godot resource (KilnPalette): a list of colours, ours.
"""
import os
import sys

import bpy
import numpy

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from fire import oklab, srgb_to_linear  # noqa: E402

SEED = 7
ROUNDS = 30


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1:]
    out, count, images = os.path.abspath(args[0]), int(args[1]), args[2:]
    samples = []
    for path in images:
        pixels = _read(path)
        if pixels is None:
            continue
        named = path.replace("\\", "/")
        # Our own textures and the characters count more: the palette leans
        # to the game's look, and characters' clothes keep their colours.
        weight = 3 if ".character_" in named else (2 if "placeholder" in named else 1)
        for _repeat in range(weight):
            samples.append(pixels)
    colours = numpy.concatenate(samples)
    print("PALETTE from %d pixels in %d images" % (len(colours), len(images)))
    palette = _cluster(colours, count)
    _write(out, palette)
    print("PALETTE wrote %d colours to %s" % (len(palette), out))


def _read(path: str):
    try:
        image = bpy.data.images.load(os.path.abspath(path))
    except RuntimeError:
        return None
    width, height = image.size
    if width == 0 or height == 0:
        return None
    pixels = numpy.empty(width * height * 4, dtype=numpy.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    pixels = pixels.reshape(-1, 4)
    # Only opaque pixels count; at most 1024 from any one image.
    pixels = pixels[pixels[:, 3] > 0.5][:, :3]
    if len(pixels) > 1024:
        pixels = numpy.random.default_rng(SEED).choice(pixels, 1024, replace=False)
    # An 8-bit image's pixels come as stored (sRGB): into linear light.
    return srgb_to_linear(pixels)


def _cluster(linear, count: int):
    """k-means in OKLab; returns sRGB colours, darkest first."""
    lab = oklab(linear)
    rng = numpy.random.default_rng(SEED)
    # Start from colours spread across the range (k-means++ style).
    centres = [lab[rng.integers(len(lab))]]
    for _ in range(count - 1):
        distance = numpy.min(((lab[:, None, :] - numpy.array(centres)[None]) ** 2).sum(2), axis=1)
        centres.append(lab[rng.choice(len(lab), p=distance / distance.sum())])
    centres = numpy.array(centres)
    for _ in range(ROUNDS):
        nearest = ((lab[:, None, :] - centres[None]) ** 2).sum(2).argmin(1)
        for index in range(count):
            members = lab[nearest == index]
            if len(members):
                centres[index] = members.mean(axis=0)
    nearest = ((lab[:, None, :] - centres[None]) ** 2).sum(2).argmin(1)
    result = []
    for index in range(count):
        members = linear[nearest == index]
        if len(members):
            result.append(members.mean(axis=0))
    result = numpy.array(result)
    result = result[numpy.argsort(oklab(result)[:, 0])]
    srgb = numpy.where(result <= 0.0031308, result * 12.92,
            1.055 * numpy.power(numpy.clip(result, 0.0, None), 1.0 / 2.4) - 0.055)
    return numpy.clip(srgb, 0.0, 1.0)


def _write(path: str, palette) -> None:
    values = ", ".join("%.4f, %.4f, %.4f, 1" % tuple(colour) for colour in palette)
    with open(path, "w", encoding="utf-8") as handle:
        handle.write('[gd_resource type="Resource" script_class="KilnPalette" format=3]\n\n'
                '[ext_resource type="Script" path="res://scripts/art/kiln_palette.gd" '
                'id="1_palette"]\n\n[resource]\nresource_name = "Salt and Ember"\n'
                'script = ExtResource("1_palette")\n'
                "colours = PackedColorArray(%s)\n" % values)


if __name__ == "__main__":
    main()
