"""Paints our placeholder textures (assets/placeholder/textures/): the same designs and colours as the old pixel art, but drawn with
smooth shapes and anti-aliased edges at several times the size, so nothing
reads as blocky squares (#135).

Run with Blender's command line (for its numpy and PNG writing); the script
tools/textures/paint_placeholders.sh does it for you:

    blender -b --factory-startup --python tools/textures/paint_placeholders.py -- \
        <textures folder> <originals folder>

Each recipe draws in the old texture's own pixel coordinates (so a stripe
"at x = 2" is where it always was) on a Canvas that renders SCALE times
bigger, 4 x 4 samples per final pixel, then averages them: every edge comes
out smooth. Colours are read from the old pixel art in <originals folder>,
so the palette stays the same. The noise is seeded, so painting again gives
the same files.
"""
import os
import sys

import bpy
import numpy

SAMPLES = 4
# How many times bigger than the original size each texture is painted,
# and the most pixels across its longer side.
DETAIL = 4
LARGEST = 1024


def load(path):
    """An image as rows top to bottom, RGBA 0-1, as stored (sRGB)."""
    image = bpy.data.images.load(os.path.abspath(path))
    w, h = image.size
    pixels = numpy.empty(w * h * 4, dtype=numpy.float32)
    image.pixels.foreach_get(pixels)
    bpy.data.images.remove(image)
    return pixels.reshape(h, w, 4)[::-1]


def save(rgba, path):
    h, w, _ = rgba.shape
    image = bpy.data.images.new("painted", w, h, alpha=True)
    image.colorspace_settings.name = "Non-Color"
    image.pixels.foreach_set(numpy.clip(rgba[::-1], 0.0, 1.0).astype(numpy.float32).ravel())
    image.filepath_raw = os.path.abspath(path)
    image.file_format = "PNG"
    image.save()
    bpy.data.images.remove(image)


class Canvas:
    """A texture [w] x [h] old pixels, painted [scale] times bigger."""

    def __init__(self, w, h, scale, seed=1):
        # The painted look (#168) wants crisp painted cloth, not small soft
        # textures: paint each DETAIL times bigger again, up to LARGEST
        # pixels on its longer side.
        scale = max(scale, min(scale * DETAIL, LARGEST // max(w, h)))
        self.w, self.h, self.scale = w, h, scale
        fine = scale * SAMPLES
        ys, xs = numpy.mgrid[0:h * fine, 0:w * fine].astype(numpy.float32)
        # Where each sample is, in old pixels.
        self.x = (xs + 0.5) / fine
        self.y = (ys + 0.5) / fine
        self.rgb = numpy.zeros(xs.shape + (3,), dtype=numpy.float32)
        self.alpha = numpy.ones(xs.shape, dtype=numpy.float32)
        self.rng = numpy.random.default_rng(seed)

    def fill(self, colour):
        self.rgb[...] = colour[:3]

    def paint(self, mask, colour, amount=1.0):
        weight = (mask.astype(numpy.float32) * amount)[..., None]
        self.rgb = self.rgb * (1.0 - weight) + numpy.asarray(colour[:3]) * weight

    # Shapes: each gives the samples inside it.
    def rect(self, x0, y0, x1, y1, round_by=0.0):
        cx, cy = (x0 + x1) / 2.0, (y0 + y1) / 2.0
        hx, hy = (x1 - x0) / 2.0 - round_by, (y1 - y0) / 2.0 - round_by
        dx = numpy.maximum(numpy.abs(self.x - cx) - hx, 0.0)
        dy = numpy.maximum(numpy.abs(self.y - cy) - hy, 0.0)
        return dx * dx + dy * dy <= round_by * round_by + 1e-9

    def band_x(self, x0, x1):
        """A full-height stripe (tiles across the top and bottom)."""
        return (self.x >= x0) & (self.x < x1)

    def band_y(self, y0, y1):
        return (self.y >= y0) & (self.y < y1)

    def ellipse(self, cx, cy, rx, ry):
        return ((self.x - cx) / rx) ** 2 + ((self.y - cy) / ry) ** 2 <= 1.0

    def stroke(self, points, width):
        """Round-ended line through [points], [width] wide."""
        best = numpy.full(self.x.shape, numpy.inf, dtype=numpy.float32)
        for (ax, ay), (bx, by) in zip(points[:-1], points[1:]):
            vx, vy = bx - ax, by - ay
            length = vx * vx + vy * vy
            t = numpy.clip(((self.x - ax) * vx + (self.y - ay) * vy) / max(length, 1e-9), 0, 1)
            d = (self.x - ax - t * vx) ** 2 + (self.y - ay - t * vy) ** 2
            best = numpy.minimum(best, d)
        return best <= (width / 2.0) ** 2

    def wave_x(self, period, depth):
        """Soft folds: lighter and darker down the x axis (curtains)."""
        return 1.0 + depth * numpy.sin(self.x / period * 2.0 * numpy.pi)

    def mottle(self, amount, size):
        """Soft blotches [size] old pixels across, lighter and darker, tiling."""
        gw, gh = max(1, round(self.w / size)), max(1, round(self.h / size))
        grid = self.rng.random((gh, gw)).astype(numpy.float32)
        gx = self.x / self.w * gw - 0.5
        gy = self.y / self.h * gh - 0.5
        x0 = numpy.floor(gx).astype(int)
        y0 = numpy.floor(gy).astype(int)
        fx = gx - x0
        fy = gy - y0
        fx = fx * fx * (3 - 2 * fx)
        fy = fy * fy * (3 - 2 * fy)

        def at(xi, yi):
            return grid[yi % gh, xi % gw]

        top = at(x0, y0) * (1 - fx) + at(x0 + 1, y0) * fx
        bottom = at(x0, y0 + 1) * (1 - fx) + at(x0 + 1, y0 + 1) * fx
        noise = top * (1 - fy) + bottom * fy
        self.rgb *= (1.0 + (noise - 0.5) * 2.0 * amount)[..., None]

    def weave(self, amount):
        """A faint woven cross-hatch, a few threads per old pixel."""
        threads = 3.0
        wx = 0.5 + 0.5 * numpy.sin(self.x * threads * 2 * numpy.pi)
        wy = 0.5 + 0.5 * numpy.sin(self.y * threads * 2 * numpy.pi)
        self.rgb *= (1.0 - amount * 0.5 + amount * 0.5 * (wx * 0.5 + wy * 0.5))[..., None]

    def result(self):
        fine = SAMPLES
        h, w = self.rgb.shape[0] // fine, self.rgb.shape[1] // fine
        rgb = self.rgb.reshape(h, fine, w, fine, 3).mean(axis=(1, 3))
        alpha = self.alpha.reshape(h, fine, w, fine).mean(axis=(1, 3))
        return numpy.concatenate([rgb, alpha[..., None]], axis=-1)


# --- Letters for the jar labels, on a 3 x 5 grid ------------------------------------
LETTERS = {
    "R": [[(0, 5), (0, 0), (2, 0), (3, 0.6), (3, 1.9), (2, 2.5), (0, 2.5)], [(1.5, 2.5), (3, 5)]],
    "O": [[(1, 0), (2, 0), (3, 1), (3, 4), (2, 5), (1, 5), (0, 4), (0, 1), (1, 0)]],
    "P": [[(0, 5), (0, 0), (2, 0), (3, 0.6), (3, 1.9), (2, 2.5), (0, 2.5)]],
    "E": [[(3, 0), (0, 0), (0, 5), (3, 5)], [(0, 2.5), (2.2, 2.5)]],
    "S": [[(3, 0.5), (2.4, 0), (0.6, 0), (0, 0.8), (0, 1.8), (0.6, 2.5), (2.4, 2.5),
           (3, 3.2), (3, 4.2), (2.4, 5), (0.6, 5), (0, 4.5)]],
    "A": [[(0, 5), (0, 1.2), (1, 0), (2, 0), (3, 1.2), (3, 5)], [(0, 3), (3, 3)]],
    "I": [[(0.5, 0), (2.5, 0)], [(1.5, 0), (1.5, 5)], [(0.5, 5), (2.5, 5)]],
    "L": [[(0, 0), (0, 5), (3, 5)]],
    "T": [[(0, 0), (3, 0)], [(1.5, 0), (1.5, 5)]],
}


def write(canvas, text, x, y, height, colour, width):
    size = height / 5.0
    advance = 4.0 * size
    for index, letter in enumerate(text):
        for stroke in LETTERS[letter]:
            points = [(x + index * advance + px * size, y + py * size) for px, py in stroke]
            canvas.paint(canvas.stroke(points, width), colour)


# --- The recipes ---------------------------------------------------------------------

def colour(old, x, y):
    return old[int(y), int(x), :3]


def pick(old, kind):
    """The old pixel art's most [kind] colour: reddest, bluest, yellowest,
    darkest or lightest (so recipes find the sail, the sea, the ink...)."""
    pixels = old[..., :3].reshape(-1, 3)
    r, g, b = pixels[:, 0], pixels[:, 1], pixels[:, 2]
    score = {
        "reddest": r - (g + b) / 2,
        "bluest": b - (r + g) / 2,
        "yellowest": (r + g) / 2 - b,
        "darkest": -(r + g + b),
        "lightest": r + g + b,
    }[kind]
    return pixels[int(numpy.argmax(score))]


def stripes_across(old, row, base):
    """The runs of columns along [row] that differ from [base]: (x0, x1, colour)."""
    found = []
    x = 0
    w = old.shape[1]
    while x < w:
        here = old[row, x, :3]
        end = x + 1
        while end < w and numpy.abs(old[row, end, :3] - here).sum() < 0.05:
            end += 1
        if numpy.abs(here - base).sum() > 0.15:
            found.append((x, end, here))
        x = end
    return found


def book_spread(old):
    """The open book you read in (#145): two cream pages in a leather cover,
    bowing down into a shadowed gutter, each framed by a double ink rule,
    with a few age spots."""
    c = Canvas(100, 58, 8, seed=10)
    leather, worn = colour(old, 50, 0), colour(old, 50, 1)
    paper, edge = colour(old, 20, 20), colour(old, 50, 55)
    ink, stain = colour(old, 20, 6), colour(old, 12, 44)
    c.fill(leather)
    c.mottle(0.12, 2)
    c.paint(c.rect(0.5, 0.5, 99.5, 57.5, 1.9) & ~c.rect(1.5, 1.5, 98.5, 56.5, 1.3), worn, 0.45)
    c.alpha = c.rect(0.0, 0.0, 100.0, 58.0, 2.2).astype(numpy.float32)
    # Both pages bow down into the gutter, top and bottom edges alike.
    dip = 1.4 * numpy.exp(-numpy.abs(c.x - 50.0) / 4.0)
    inside_x = (c.x >= 3.6) & (c.x <= 96.4)
    # The stack of pages under each page shows below it as a few thin edges.
    stack = inside_x & (c.y >= 2.6 + dip) & (c.y <= 56.0 + dip * 0.6)
    c.paint(stack, edge)
    for y in [54.9, 55.5]:
        c.paint(stack & (numpy.abs(c.y - (y + dip * 0.6)) < 0.12), paper, 0.6)
    page = (c.x >= 4.2) & (c.x <= 95.8) & (c.y >= 2.0 + dip) & (c.y <= 54.0 + dip * 0.6)
    page &= c.rect(4.2, 2.0, 95.8, 56.0, 0.8)
    c.paint(page, paper)
    gutter = 1.0 - 0.34 * numpy.exp(-numpy.abs(c.x - 50.0) / 2.4)
    gutter -= 0.07 * numpy.exp(-numpy.abs(c.x - 50.0) / 12.0)
    outer = 1.0 - 0.07 * numpy.exp(-numpy.minimum(c.x - 4.2, 95.8 - c.x) / 2.0)
    c.rgb *= numpy.where(page, gutter * outer, 1.0)[..., None]
    for x0, x1 in [(9.0, 46.0), (54.0, 91.0)]:
        for y, width in [(6.0, 0.22), (6.55, 0.12), (49.45, 0.12), (50.0, 0.22)]:
            c.paint(c.stroke([(x0, y), (x1, y)], width), ink, 0.85)
    rng = numpy.random.default_rng(7)
    for x, y in [(12.0, 44.0), (88.0, 10.0), (61.0, 47.0)]:
        r = 0.9 + rng.random() * 0.8
        c.paint(c.ellipse(x, y, r, r * 0.8) & page, stain, 0.3)
        c.paint(c.ellipse(x, y, r * 0.45, r * 0.35) & page, stain, 0.25)
    c.mottle(0.035, 5)
    return c


def bedlinen(old):
    c = Canvas(8, 8, 8, seed=11)
    c.fill(colour(old, 3, 3))
    c.weave(0.06)
    c.mottle(0.04, 3)
    return c


def blanket(old):
    c = Canvas(16, 8, 8, seed=12)
    base = colour(old, 12, 4)
    c.fill(base)
    for x0, x1, stripe in stripes_across(old, 4, base):
        c.paint(c.band_x(x0 + 0.05, x1 - 0.05), stripe)
    c.weave(0.1)
    c.mottle(0.06, 4)
    return c


def braided_rug(old):
    c = Canvas(32, 26, 4, seed=13)
    c.fill(colour(old, 16, 13))
    cx, cy = 16.0, 13.0
    # The rings, outside in, with the colours of the old pixel art read
    # along a line from the edge to the middle.
    rings = 9
    for ring in range(rings):
        t = ring / rings
        rx, ry = 15.6 * (1 - t), 12.6 * (1 - t)
        sample = colour(old, cx - rx + 0.8, cy)
        braid = c.ellipse(cx, cy, rx, ry)
        c.paint(braid, sample)
        # The braid: the ring's colour turns slightly lighter and darker
        # along it, a strand at a time.
        angle = numpy.arctan2((c.y - cy) / ry, (c.x - cx) / rx)
        strands = 0.5 + 0.5 * numpy.sin(angle * (26 - ring * 2))
        c.rgb *= numpy.where(braid, 0.92 + 0.12 * strands, 1.0)[..., None]
    c.alpha = c.ellipse(cx, cy, 15.8, 12.8).astype(numpy.float32)
    c.mottle(0.04, 3)
    return c


def canvas_cloth(old):
    c = Canvas(16, 16, 4, seed=14)
    c.fill(colour(old, 4, 4))
    c.paint(c.band_y(10.3, 10.9), colour(old, 8, 10))
    for x in numpy.arange(0.5, 16, 2.0):
        c.paint(c.rect(x, 10.2, x + 1.0, 11.0, 0.3), colour(old, 1, 10))
    c.paint(c.ellipse(9, 13.5, 2.6, 1.6), colour(old, 9, 13), 0.5)
    c.weave(0.08)
    c.mottle(0.06, 4)
    return c


def chart(old):
    c = Canvas(32, 24, 4, seed=15)
    paper, sea, land, ink = colour(old, 1, 1), pick(old, "bluest"), colour(old, 6, 17), pick(old, "darkest")
    c.fill(paper)
    c.paint(c.rect(1.5, 1.5, 30.5, 22.5, 0.8), sea)
    for (x, y, rx, ry) in [(7.5, 17.0, 4.0, 2.6), (25.0, 8.0, 2.8, 2.2), (27.0, 19.0, 2.0, 1.3)]:
        c.paint(c.ellipse(x, y, rx + 0.45, ry + 0.45), ink)
        c.paint(c.ellipse(x, y, rx, ry), land)
    route = pick(old, "reddest")
    for x in numpy.arange(9.5, 22.5, 2.0):
        y = 15.0 - (x - 9.5) * 0.55
        c.paint(c.stroke([(x, y), (x + 1.0, y - 0.55)], 0.55), route)
    c.paint(c.stroke([(7, 2.8), (7, 7.2)], 0.5), ink)
    c.paint(c.stroke([(4.8, 5), (9.2, 5)], 0.5), ink)
    c.paint(c.stroke([(7, 3.5), (7.8, 2.2)], 0.45), route)
    c.mottle(0.05, 5)
    return c


def curtain(old):
    c = Canvas(8, 16, 8, seed=16)
    c.fill(colour(old, 2, 6))
    c.rgb *= c.wave_x(4.0, 0.12)[..., None]
    c.paint(c.band_y(13.0, 13.8), colour(old, 2, 13))
    c.paint(c.band_y(14.6, 15.2), colour(old, 2, 14))
    c.rgb *= c.wave_x(4.0, 0.08)[..., None]
    c.weave(0.06)
    c.mottle(0.05, 3)
    return c


def drawing(old):
    c = Canvas(12, 10, 8, seed=17)
    c.fill(colour(old, 1, 1))
    hull, sail, sun, sea = pick(old, "darkest"), pick(old, "reddest"), pick(old, "yellowest"), pick(old, "bluest")
    c.paint(c.ellipse(9.5, 1.6, 1.1, 1.1), sun)
    c.paint(c.stroke([(3.6, 5.8), (3.6, 1.6)], 0.5), hull)
    c.paint(c.stroke([(4.0, 1.9), (6.2, 4.6), (4.0, 4.6), (4.0, 1.9)], 0.35), sail)
    sail_fill = (c.x > 4.0) & (c.y < 4.6) & ((c.y - 1.9) > (c.x - 4.0) * 1.23)
    c.paint(sail_fill, sail)
    c.paint(c.rect(2.0, 5.6, 7.6, 7.0, 0.5), hull)
    for x in [0.6, 3.6, 6.6, 9.6]:
        c.paint(c.stroke([(x, 8.9), (x + 0.8, 8.3), (x + 1.6, 8.9)], 0.45), sea)
    c.mottle(0.04, 4)
    return c


def label(old, text):
    c = Canvas(16, 10, 8, seed=18)
    c.fill(colour(old, 1, 4))
    c.paint(c.band_y(0, 1.0), colour(old, 1, 0))
    c.paint(c.band_y(9.0, 10), colour(old, 1, 9))
    for y in [2.4, 7.6]:
        c.paint(c.band_y(y, y + 0.3), colour(old, 1, 9), 0.4)
    ink = colour(old, 2, 4) if text != "TEA" else colour(old, 3, 4)
    darkest = min((old[y, x, :3] for y in range(10) for x in range(16)), key=lambda p: p.sum())
    write(c, text, 8.0 - len(text) * 2.0 + 0.5, 2.6, 5.0, darkest, 0.85)
    c.mottle(0.05, 4)
    return c


def net(old):
    c = Canvas(32, 32, 4, seed=19)
    c.fill(colour(old, 4, 4))
    twine = pick(old, "yellowest")
    for line in numpy.arange(0.5, 32, 8.0):
        c.paint(c.band_x(line - 0.45, line + 0.45), twine)
        c.paint(c.band_y(line - 0.45, line + 0.45), twine)
        for knot in numpy.arange(0.5, 32, 8.0):
            c.paint(c.ellipse(line, knot, 0.9, 0.9), twine)
    c.alpha = numpy.ones_like(c.alpha) * old[..., 3].mean()
    c.mottle(0.05, 6)
    return c


def oilskin(old):
    c = Canvas(8, 8, 8, seed=20)
    c.fill(colour(old, 1, 1))
    c.mottle(0.12, 3)
    return c


def painted_wood(old):
    c = Canvas(16, 16, 4, seed=21)
    c.fill(colour(old, 4, 4))
    c.paint(c.band_y(11.4, 12.0), colour(old, 4, 11))
    chips = pick(old, "darkest")
    rng = numpy.random.default_rng(5)
    for _ in range(11):
        x, y = rng.random() * 16, rng.random() * 16
        c.paint(c.ellipse(x, y, 0.45 + rng.random() * 0.3, 0.35 + rng.random() * 0.2), chips)
    c.paint(c.band_y(15.4, 16), colour(old, 4, 15))
    c.mottle(0.06, 4)
    return c


def quilt(old):
    c = Canvas(16, 16, 8, seed=22)
    seam = old[..., :3].reshape(-1, 3).mean(axis=0) * 0.7
    c.fill(seam)
    for j in range(4):
        for i in range(4):
            block = old[j * 4:j * 4 + 4, i * 4:i * 4 + 4, :3]
            a = block[0, 0]
            b = block[0, 1]
            x0, y0 = i * 4 + 0.15, j * 4 + 0.15
            patch = c.rect(x0, y0, x0 + 3.7, y0 + 3.7, 0.35)
            if numpy.abs(a - b).sum() > 0.15:
                # A gingham patch, woven: stripes of the darker colour run
                # both ways over the lighter, half see-through, so where they
                # cross is darkest and between them lightest, three soft tones.
                light, dark = (a, b) if a.sum() > b.sum() else (b, a)
                c.paint(patch, light)
                c.paint(patch & (numpy.floor(c.x * 1.2) % 2 == 0), dark, 0.5)
                c.paint(patch & (numpy.floor(c.y * 1.2) % 2 == 0), dark, 0.5)
            else:
                c.paint(patch, block[1, 1])
    c.weave(0.06)
    c.mottle(0.05, 4)
    return c


def rag_runner(old):
    c = Canvas(64, 8, 4, seed=23)
    c.fill(colour(old, 0, 4))
    x = 0
    while x < 64:
        here = colour(old, x, 4)
        end = x
        while end < 64 and numpy.abs(old[4, end, :3] - here).sum() < 0.05:
            end += 1
        c.paint(c.band_x(x, end), here)
        x = end
    c.weave(0.14)
    c.mottle(0.05, 3)
    return c


def recipe(old):
    c = Canvas(12, 16, 8, seed=24)
    c.fill(colour(old, 1, 1))
    ink = pick(old, "darkest")
    c.paint(c.stroke([(3.2, 3.2), (4.5, 2.2), (6.8, 2.2), (8.0, 3.2), (6.8, 4.2), (4.5, 4.2),
            (3.2, 3.2)], 0.45), ink)
    c.paint(c.stroke([(8.0, 3.2), (9.2, 2.3), (9.2, 4.1), (8.0, 3.2)], 0.45), ink)
    for y, x0, x1 in [(7, 1.5, 3.5), (7, 4.5, 5.5), (9, 1.5, 2.2), (9, 3.5, 9.0), (11, 1.5, 7.5),
            (13, 2.5, 8.5)]:
        c.paint(c.stroke([(x0, y), (x1, y)], 0.7), ink)
    c.mottle(0.04, 4)
    return c


def rug(old):
    c = Canvas(48, 32, 4, seed=25)
    field, gold, dark = colour(old, 10, 14), colour(old, 5, 5), colour(old, 1, 1)
    c.fill(dark)
    c.paint(c.rect(2, 2, 46, 30, 0.5), colour(old, 3, 3))
    c.paint(c.rect(4, 4, 44, 28, 0.5), field)
    for x0, y0, x1, y1 in [(2.4, 2.4, 45.6, 2.9), (2.4, 29.1, 45.6, 29.6), (2.4, 2.4, 2.9, 29.6),
            (45.1, 2.4, 45.6, 29.6)]:
        c.paint(c.rect(x0, y0, x1, y1), gold)
    c.paint(c.rect(6.5, 6.5, 41.5, 25.5, 0.4) & ~c.rect(7.1, 7.1, 40.9, 24.9, 0.4), gold)
    for cx in [15.5, 24.0, 32.5]:
        diamond = numpy.abs(c.x - cx) / 4.0 + numpy.abs(c.y - 16.0) / 4.0
        c.paint(diamond <= 1.0, gold)
        c.paint(diamond <= 0.72, field)
        c.paint(diamond <= 0.45, gold)
        c.paint(diamond <= 0.18, field)
    for x in numpy.arange(5.0, 44, 2.0):
        c.paint(c.ellipse(x, 5.1, 0.35, 0.35), gold)
        c.paint(c.ellipse(x, 26.9, 0.35, 0.35), gold)
    c.weave(0.1)
    c.mottle(0.05, 6)
    return c


def runner(old):
    c = Canvas(16, 32, 4, seed=26)
    base = colour(old, 8, 8)
    c.fill(base)
    for x0, x1, stripe in stripes_across(old, 8, base):
        c.paint(c.band_x(x0 + 0.1, x1 - 0.1), stripe)
    c.weave(0.1)
    c.mottle(0.05, 5)
    return c


def ticking(old):
    c = Canvas(8, 8, 8, seed=27)
    c.fill(colour(old, 2, 4))
    x = 0
    while x < 8:
        here = colour(old, x, 4)
        end = x
        while end < 8 and numpy.abs(old[4, end, :3] - here).sum() < 0.05:
            end += 1
        c.paint(c.band_x(x + 0.08, end - 0.08), here)
        x = end
    c.weave(0.06)
    c.mottle(0.04, 3)
    return c


def weathered_wood(old):
    c = Canvas(16, 10, 8, seed=28)
    c.fill(colour(old, 4, 4))
    for y in [2.6, 7.1]:
        c.paint(c.band_y(y, y + 0.35), colour(old, 4, 7), 0.6)
    c.paint(c.band_y(9.4, 10), colour(old, 4, 9))
    c.mottle(0.08, 4)
    return c


RECIPES = {
    "bedlinen": bedlinen,
    "book_spread": book_spread,
    "blanket_grey": blanket,
    "blanket_wool": blanket,
    "braided_rug": braided_rug,
    "canvas": canvas_cloth,
    "chart": chart,
    "curtain": curtain,
    "curtain_mustard": curtain,
    "curtain_rust": curtain,
    "drawing": drawing,
    "label_rope": lambda old: label(old, "ROPE"),
    "label_sail": lambda old: label(old, "SAIL"),
    "label_tea": lambda old: label(old, "TEA"),
    "net": net,
    "oilskin": oilskin,
    "painted_wood": painted_wood,
    "quilt_blue": quilt,
    "quilt_gold": quilt,
    "quilt_green": quilt,
    "quilt_red": quilt,
    "rag_runner": rag_runner,
    "recipe": recipe,
    "rug": rug,
    "runner": runner,
    "ticking": ticking,
    "weathered_wood": weathered_wood,
}


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    out_folder, old_folder = args[0], args[1]
    only = set(args[2:])
    for name, recipe_of in RECIPES.items():
        if only and name not in only:
            continue
        old = load(os.path.join(old_folder, name + ".png"))
        canvas = recipe_of(old)
        result = canvas.result()
        save(result, os.path.join(out_folder, name + ".png"))
        print("PAINTED %s %dx%d -> %dx%d" % (name, old.shape[1], old.shape[0],
                result.shape[1], result.shape[0]))


if __name__ == "__main__":
    main()
