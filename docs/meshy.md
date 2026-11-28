# Making a character with Meshy

How the heron captain was made (#139), so the rest of the crew can follow. Meshy makes 3D models from pictures; the Meshy CLI (`meshy`, npm package `meshy-cli` 0.8) and its Claude skill (`meshy-3d-generation`) drive it from the terminal. We have a paid plan: about 1,100 credits a month, reset monthly, so the costs below are small, but every step spends them, so say what a step costs and ask before running it.

## The steps

1. **A concept picture** (text-to-image, 9 credits; an edit with image-to-image, 12). Describe the character whole and unobstructed, in an A-pose (arms out and down), on a plain light grey background in soft studio light, in the painted style described in `docs/look.md`. Show it before going on: a new picture costs less than a new model.
   - **A three-quarter view** (body and head turned the same way, about 30 degrees) is best for a single picture: from the front a long beak or snout looks short, and a head turned away from the body gets baked into the model and fights the rig.
2. **The model** (image-to-3D, 15 credits): clean game geometry ("smart topology", `meshy-t2.5`) with a triangle target, the `meshy-n1` texture model at 2K and the A-pose. The heron is 2,812 triangles.
   ```bash
   meshy image-to-3d create --input-task-id IMAGE_TASK --model-type smart-topology --ai-model meshy-t2.5 --target-polycount 3000 --texture-model meshy-n1 --texture-resolution 2k --pose-mode a-pose --target-formats glb --async --format json --no-update-check
   ```
3. **The rig** (5 credits), at the height you want in metres. It comes with a walk and a run.
   ```bash
   meshy rigging create --input-task-id MODEL_TASK --height-meters 1.9 --async --format json --no-update-check
   ```
4. **Animations** (3 credits each, up to 10 in one file) from Meshy's library. Look them up for free with `meshy animation-catalog list --search talk`; each has a preview GIF to watch first. Film the candidates on the character in Godot before choosing: a move that looks fine on Meshy's mannequin can look wrong on a bird in a coat.
   ```bash
   meshy animate create --rig-task-id RIG_TASK --action-ids 309,313,47,336 --async --format json --no-update-check
   ```
   A move the library hasn't got can be made from words (text-to-motion, about 10 credits).

Wait on each task with `meshy <kind> wait ID`, then fetch it with `meshy <kind> get ID -o <folder>` (`meshy download --resource rigging|animate ...` for a rig's or an animation's own files).

## Into the game

- **Where it goes:** `assets/third_party/meshy/<character>/`, gitignored like the packs: never commit it. A fresh clone or CI shows the greybox instead.
- **How it's drawn:** a `ThirdPartyModel` loads it by path and optionally applies a stylised character material.
- **Its size:** Meshy's armature is scaled by 0.01 and its animations move bones in centimetres, so the model can't be fitted by `fit_size` (it reads 100 times too small, gets blown up, and its animations fly off). Leave `fit_size` at zero and scale the `ThirdPartyModel` node instead (the heron: 2.3 / 1.9 = 1.21).
- **Which way it faces:** Meshy models face +Z; our crew face -Z, so turn the node 180 degrees.
- **Its animations:** a `CrewAnimator` plays them from the conversation (idle, talking, listening), by the names in the file.

## What the heron cost

Three pictures (33), the model (15), the rig (5) and seven animations (21): 74 credits.

## Props and food (#152)

Not every Meshy model is a character. The galley's treasure chests and the fish and crab meat were made the same way, with steps 1 and 2 only (no rig):

- **The concept picture**, three-quarter view, whole and unobstructed, on plain light grey; for something meant to open, ask for "a clear seam where it opens". Pictures come out in crisp pixels, but the model's own texture is painted soft.
- **The model** with fewer triangles than a character: 2,000 for a chest, 1,000 for a fish.
- **A lid that opens:** Meshy makes a chest as one closed mesh. `tools/meshy/split_lid.py` (Blender 4.4) cuts it at the seam's height into a `Body` and a `Lid` whose origin is its back edge on the cut, so turning the lid about X opens it on a hinge. Find the seam by eye: run it with a preview path and it renders the chest open, from the front and from the side (where a lid floating off its hinge would show). The hinge is measured on the cut line only: the dome can bulge further back higher up.
- **See-through by accident:** Meshy's textures carry an alpha channel, so the imported materials are see-through and don't hide what's behind them. The chest (`TreasureChest`) and the food (`ItemModel`) set them solid when the model loads.
- **One model, several items:** an item can reuse another's model with a `model_tint`: the mackerel is the herring tinted greener, and the cooked dishes are the fillet and the claw tinted golden brown.

The chests' seams: the big gold one at -0.005 (just under its band, so the band lifts with the lid like a hasp), the small sea-worn one at 0.025. Each split model is saved beside its download as `chest_big.glb` / `chest_small.glb`:

```bash
"C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b -P tools/meshy/split_lid.py -- \
    assets/third_party/meshy/chest_big/model/model.glb assets/third_party/meshy/chest_big/chest_big.glb -0.005
```

What they cost: the chests (two pictures, 18; two models, 30) and the food (three pictures, 27; three models, 45): 120 credits.

## The ship's hull and the ship's props (#196)

**The hull** is a Meshy model too, made to wrap our own decks and rooms rather than replace them:

- **Draw the concept over our greybox.** A render of our ship (side and quarter views, on plain grey) went in with the style reference, so the picture kept our layout: raised forecastle and quarterdeck, the stern, the heron. Then edits took away what we build ourselves: no masts, sails or rigging; no rails, stairs or deck (an **open, hollow hull**, like an empty boat); no portholes or stern windows (we place windows where the rooms want them). Ask for "longer and sleeker" and "a pointed raked bow": the first open hull came out a tubby rowing boat.
- **A black background with a glow** came back once: `tools/meshy/plain_background.gd` greyed it first.
- **The model:** image-to-3D from one picture (the stern quarter), smart topology at 30,000 triangles, `meshy-7` texture at 4K (15 credits). A second, bow-side picture disagreed with the first about the shape, so it wasn't used.
- **It came with holes.** Its port side's upper planking is mostly missing, and both skins have smaller holes. `HullShell` builds the hull from the starboard half and a mirror of it, cut exactly on the centreline (so the heron is symmetrical too).
- **Fitting it** (`HullShell`; see the GDD's Architecture notes): the model is a metre long, its length along X, bow at -X. It's stretched along the ship by a few pairs (the middle more than the ends), deeper below its top edge than above so the rooms sit where it's wide, and let out where a room would poke through. Check every change from outside and on deck: a render can look right from one side and show a room's wall through the hull from the other.
- **Its inside is ours.** Meshy painted the hull to be seen from outside; up close its inner faces are smeared. Each triangle is marked as outer skin or inside when it's fitted (by which way its corners wind, which agrees with Godot; Meshy's normals don't everywhere), and the shader draws the inside with our planks, coloured from a blurred read of Meshy's paint.
- After changing the fit, run `tools/ship/measure_hull.gd` to save its shape again (`data/ship/hull_outline.tres`): the decks, rails, walls and porthole depths follow that file.

**Props** went in the same way as before (`ThirdPartyModel`, `keep_as_made`, the greybox as stand-ins), stretched to their greybox's box: the galley hearth (made a little taller, so the hobs on its top sit on it), pantry, plate rack, crock shelf, the table's benches, the coat stand (with its coat and cap), the peg rails (with the oilskin and sou'wester) and the galley's bell (hung still: its bracket is in the model, so it can't swing).

- **One book, many books.** The bookshelf is an empty Meshy shelf, filled with `BookRow`s of the one Meshy book (`ShelfBook`): its tan leather recoloured per book, its gilt (the most saturated paint) and page edges (by which way they face) left alone. Ask for the book's cover in a plain undyed leather so it takes any colour.
- **The porthole** model wasn't used: its glass is painted solid blue, and our portholes are see-through now.

What it cost: 444 credits in all, including the pictures and models that weren't used (the first hull concepts, the bow view, the porthole, the life ring's picture).

## Tucking one layer into another (#206)

Layers fitted by `tools/meshy/fit_layer.py` each sit 12 mm off the body, so where two overlap neither is inside the other: the shirt's back hung over the trousers, and the slimmed boots let the trouser legs poke through. `tools/meshy/tuck_layer.py` pulls the inner layer in wherever the outer one covers it, until it's just inside (6 mm), and leaves the outer one alone. It measures the outer layer in slices (by height, and by angle round the body's middle, or round each leg's for boots), so it follows the waistband and the boot tops. Run it after fitting, inner first, then outer:

    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b -P tools/meshy/tuck_layer.py -- \
        start_top.glb start_legs.glb start_top.glb waist
    "C:/Program Files/Blender Foundation/Blender 4.4/blender.exe" -b -P tools/meshy/tuck_layer.py -- \
        start_legs.glb sea_feet.glb start_legs.glb legs

The hero's own (`meshy/boy_stern/layers/`) were tucked this way: shirt into trousers, trousers into the sea boots. A layer refitted with `fit_layer.py` comes out untucked again, so tuck it again after.

## Models wanted (home waters, #227)

The opening's first beat (`scenes/prototype/intro/home_waters.tscn`) is greybox. Every prop is its own scene under `scenes/props/home/`, so a Meshy model replaces a prop in one place and every instance picks it up. Sizes are rough, in metres. Concept images are in `docs/concept/opening/`.

| Scene | Size (W x H x D) | What it is | Concept image |
|---|---|---|---|
| `cottage.tscn` | 6.8 x 9 x 5.6 (chimney included) | A stone-walled island cottage with a red roof, chimney, two glowing windows, a window light and a smoke plume. Five of them climb the hill. | `home-from-the-water.webp` |
| `jetty_cottage.tscn` | 6.8 x 9 x 5.6 | Your home by the jetty: like the cottage but with one big lit window, a green door and a warmer light. Holds `SiblingVoice`, where your sibling's call comes from. | `jetty-start.webp`, `home-from-the-water.webp` |
| `jetty.tscn` | 3 x 5 x 11 | A wooden jetty on piles, running out into the water; the boat is tied up at its end. | `jetty-start.webp` |
| `lamp_post.tscn` | 0.6 x 3.1 x 1.0 | A wooden post with an arm and a hanging lit lantern (flickering light). Six along the path up from the jetty. | `jetty-start.webp` |
| `mooring.tscn` | 12 x 9 x 12 | The stone mooring on the island's summit, with an iron post and a great ring where the chain was fixed. | `home-from-the-water.webp` |
| `buoy.tscn` | 5 x 7 x 5 | The rusted marker buoy: a round float with eyes, a four-legged cage rising to a railed platform and a lantern with a cap. Floats on the swell. Its `Model` node holds the shapes; `FloatOnSea` and `Wall` stay. | `buoy-and-chain.webp`, `rowing-out.webp` |

Not wanted as models: the island's land (hill, shelf, knoll and rocks) is terrain, left as plain shapes; the great chain is built by `HangingChain` from one link; the rowboat has its own scene (`scenes/prototype/intro/rowboat.tscn`).

**Swapping one in:** open the prop's scene, replace its shapes with the model (via `ThirdPartyModel`, as for the props above), and keep the root's name and any logic nodes (`SiblingVoice`, `Wall`, `FloatOnSea`, the lights and smoke). `home_waters.gd` finds the buoy, the buoy's wall and `SiblingVoice` by their paths.
