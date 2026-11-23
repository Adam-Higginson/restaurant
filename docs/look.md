# The stylised look: how to tune it

The game is moving from the soft N64 look to a warm, painted, anime-styled one: low golden light through windows, glowing lanterns, warm shadows, and characters with soft cel shading, a rim of light and a thin dark outline. This page says where each part of that look lives and which number to turn for each effect. It started with the look-dev cabin (#168).

## Where to try it

Open `scenes/tools/look_dev_cabin.tscn` and press **F6** (run this scene). The buttons at the top left switch, while it runs:

- **Stylised characters**: the heron and the boy drawn with the stylised shader, or as made.
- **Outlines**: the dark outline on or off.
- **Golden cabin light**: the golden-hour cabin, or plain grey studio light that shows the models as they come.

The buttons change a copy of the style, so they never change the saved files. To tune for real, edit the files below in the Inspector: the cabin shows the changes in the editor viewport straight away, without running.

To photograph every shot in every treatment (for comparing before and after):

```bash
C:/Godot/godot_console.exe --path . --resolution 1600x900 res://scenes/tools/look_dev_cabin.tscn -- --capture=C:/somewhere/captures
```

## What lives where

| Part | File | What it is |
|---|---|---|
| Character shading and outline | `data/art/styles/character.tres` (a `CharacterStyle`) | One shared look for every stylised character. |
| The shader behind it | `shaders/stylised_character.gdshader`, `shaders/outline.gdshader` | Set from the style; you don't edit these to tune. |
| Which characters use it | the `style` slot on each `ThirdPartyModel` | Empty draws the model as made. |
| The cabin's light, fog and post-processing | `data/art/environments/golden_cabin.tres` (an `Environment`) | Ambient light, tone mapping, SSAO, glow, volumetric fog. |
| The sun | the `Sun` node in the cabin | Its colour, energy and shadow. |
| The lanterns | `Lanterns/*/Lamp` (light) and `Lanterns/*/Glow` (`PaintedGlow`) | The light they cast, and how their painted glass glows. |

## Turning the dials

### Shadow bands and thresholds

In `character.tres`, group **Shading**:

- **Shadow Threshold** (-1 to 1, default 0.05): where light turns to shadow. 0 puts the edge exactly side-on to the light; raise it to push more of the body into shadow (moodier, stronger shapes), lower it for more light.
- **Bands** (1 to 4, default 1): 1 is two-tone, soft anime. 3 or 4 gives stepped Wind Waker-style shading.
- **Lit Falloff** (0 to 1, default 0.35): how much the lit side still dims as it turns away from the light. 0 is flat cel colour; higher keeps some roundness inside the light.

### Shadow softness

- **Shadow Softness** (in **Shading**, 0 to 0.5, default 0.04): how soft the light/shadow edge is on the character. 0 is a hard cut; about 0.1 is a soft painted edge. It also softens cast shadows falling on characters.
- For shadows in the room, select the `Sun` and change **Shadow > Blur** (default 0.6): higher is softer. Its **Angular Distance** gives physically soft shadows that grow softer with distance, but costs more.

### Shadow colour

- **Shadow Color** (in **Colour**): what colour the shadow side is lit with, as a share of the light. Warm and a little purple keeps shadows rich; grey gives the flat "just darker" look we're avoiding.

### Base colours

- **Base Tint** (in **Colour**): multiplies every stylised character's own colours. Use it to warm or cool the whole cast together.
- **Ambient Strength** (in **Colour**, 0 to 1): how much of the room's ambient light reaches the characters. Lower leans on the sun and lamps for stronger shapes.
- A single character's colours come from its own texture; to shift one character, use the `tint` on its `ThirdPartyModel`.

### Outline thickness

In `character.tres`, group **Outline**:

- **Outline** (on/off).
- **Outline Thickness** (pixels at 1080p, default 1.6): the line stays this wide on screen near and far.
- **Outline Max Width** (metres, default 0.008): the widest it can be however close the camera, so small details (fingers, beak, buttons) don't get heavy lines in close-ups.
- **Outline Color**: dark brown by default, not black, so it reads as a painted line.

### Rim lighting

In `character.tres`, group **Rim**:

- **Rim Strength** (0 turns it off; default 0.2).
- **Rim Width** (0 to 1): how far in from the silhouette it reaches.
- **Rim Color**: warm cream by default. It only appears on the side the light reaches.

### Light intensity

- **The sun:** select `Sun`, then **Light > Energy** (golden default 3.0) and **Color**. While the scene runs, the cabin sets these from its own **Golden Sun Energy / Color** (on the `LookDevCabin` root, group **Sun**), so change those too.
- **The light shafts:** the sun's **Volumetric Fog > Energy** (default 10) makes the beams brighter; the fog itself is in `golden_cabin.tres` under **Volumetric Fog** (Density 0.006: more makes the room hazier, less leaves only the beams).
- **The lanterns:** each `Lamp`'s **Energy** (1.4 to 1.6) and **Range**; the glass's glow is the `Glow` node's **Energy** and **Threshold**.
- **Overall brightness:** `golden_cabin.tres` → **Tonemap > Exposure** (1.25), and **Ambient Light > Energy** (0.7).

### Bloom intensity

In `golden_cabin.tres`, group **Glow**:

- **Intensity** (default 0.3): how strong the bloom is.
- **HDR Threshold** (default 1.6): how bright something must be before it blooms. Raise it so only lanterns and the window glow; lower it and sunlit coats start to glow too.
- **Bloom** (default 0.02): a haze over everything; keep it near 0 for a crisp picture.

## What's not stylised

Only characters get the cel shader and outline. Rooms and props keep their own materials (and so their texture detail), and are drawn into the same palette by the light: the warm sun, the ambient colour, and the tone mapping.
