# Making a character with Meshy

How the heron captain was made (#139), so the rest of the crew can follow. Meshy makes 3D models from pictures; the Meshy CLI (`meshy`, npm package `meshy-cli` 0.8) and its Claude skill (`meshy-3d-generation`) drive it from the terminal. We have a paid plan: about 1,100 credits a month, reset monthly, so the costs below are small, but every step spends them, so say what a step costs and ask before running it.

## The steps

1. **A concept picture** (text-to-image, 9 credits; an edit with image-to-image, 12). Describe the character whole and unobstructed, in an A-pose (arms out and down), on a plain light grey background in soft studio light, in N64-era Ocarina of Time style. Show it before going on: a new picture costs less than a new model.
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
- **How it's drawn:** a `ThirdPartyModel` loads it by path, with `keep_as_made` on (the Kiln never fires it: it's shown at full quality), `grain` off and `detail` 1.
- **Its size:** Meshy's armature is scaled by 0.01 and its animations move bones in centimetres, so the model can't be fitted by `fit_size` (it reads 100 times too small, gets blown up, and its animations fly off). Leave `fit_size` at zero and scale the `ThirdPartyModel` node instead (the heron: 2.3 / 1.9 = 1.21).
- **Which way it faces:** Meshy models face +Z; our crew face -Z, so turn the node 180 degrees.
- **Its animations:** a `CrewAnimator` plays them from the conversation (idle, talking, listening), by the names in the file.

## What the heron cost

Three pictures (33), the model (15), the rig (5) and seven animations (21): 74 credits.
