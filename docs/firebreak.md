# Overnight firebreak (branch `firebreak/overnight`)

A night of building towards a game, on one branch, while you slept. Nothing here is merged; nothing on the board changed. Each feature is its own commit with tests, so you can keep, change or drop them one by one. Pick what you like and we'll turn it into proper issues and PRs.

Ground rules I kept: no merges, no new issues, nothing on `main`, tests for every feature, the full suite passing at checkpoints.

## Start here: a ten-minute tour

The night's theme: **the ship became a place you live, and the lantern became someone you live with.** There's now a little loop to play: wake, explore, stop the ship, fish, cook, eat with the lantern, remember, sleep, wake to dawn.

1. `git checkout firebreak/overnight`, open `scenes/prototype/sea.tscn`, press **F6** (F5 still runs the old 2D restaurant, see the notes at the end).
2. **Black, "Somewhere at sea".** You wake in the bunk room at night; the lantern at your shoulder says his first words. He follows you everywhere, lights the way, blinks, and drifts over to anything you stop at.
3. At the head of your bunk, **read your note** ("Don't forget..."). At its foot you can **sleep**.
4. Go up the hatch ramp into the storm. Walk to the **bow** at night: the lantern spots the far light in the fog and has a guess about it.
5. Climb to the forecastle and **ring the bell** (Interact at the rope): the ship eases to a stop. The lantern approves.
6. At the starboard rail, by the chimney, **cast a line**. When the bobber dips and the lantern hops, **strike**. A herring! And your first memory of home ("A cold jetty"), hummed by the lantern.
7. Below in the galley, read the **recipe book** on the cook's stool. Fillet the herring on the board (3 cuts), fry it in the **pan on the hearth** (6 s).
8. Or carry the **saucepan** up to the **water butt** on deck (port waist), fill it with rain, boil it, add diced tomato and chopped onion: **Tomato Soup**. Ladle it into a **bowl** from the stack on the table.
9. Take a dish down to the little **round table by the bunk room's stove** and **share it with the lantern**. He drifts down, eats, glows warm again ("I'm glowing. Am I glowing?"). Left alone for half an hour he dims and asks for soup.
10. **Sleep** at the foot of your bunk: "Day 2. Morning". Go up on deck: a misty grey-rose dawn, the rain a drizzle, and out in the mist, the **lighthouse island** the light came from. Stand at the bow.

To see every memory you've got back, read your note again. Ring the bell once more to set sail.

## What's new in the code (the shape of it)
- **The lantern** (`scripts/companion/`): `LanternSpirit` (follow, hover, blink, excite, warmth, visit), `LanternVoice` (his floating lines), `LanternLines` (everything he says: rewrite it in your own voice), `Hum` (the synthesised melody), `Lookout` (the bow).
- **Story** (`scripts/story/`): `MemoryBook` on `Game.memories`, `Opening`. Data in `data/memories/` and `data/recipes/` (new `Memory` and `Recipe` resources, listed in the catalog).
- **Cooking**: fire (a timed element) and two `Hob`s on the hearth; saucepan, frying pan, bowls, rainwater, onions, herring. All the GDD's designed steps and shortcuts for Tomato Soup, plus Pan-fried Herring.
- **The ship and the world**: `Ship.heave_to()` / `get_under_way()` and `way`; `ShipsBell`; `FishingLine` + `FishingSpot`; `WaterButt`; `TimeOfDay` (night to dawn, one number) and `Bedside`; `DistantIsland` + a silhouette shader.
- **Tests**: every feature has a suite; about 75 new tests. The full suite passes: 933 tests, 0 failures, 0 orphans (run after feature 14).

## What I built, in order

### 1. The lantern spirit follows you (#65's ground, done as a sketch)
A little iron-and-glass lantern with two dark eyes floats by your right shoulder, bobbing, lighting the way with a warm flickering light (and a halo in the fog). He lags a moment when you walk off and drifts back; the ship carries him along as it sails. Stop at something (face it for 0.6 s) and he drifts over to hover above it, a bit brighter, curious; walk away and he comes back. He blinks every few seconds.
- `scenes/prototype/lantern_spirit.tscn`, `scripts/companion/lantern_spirit.gd` (in the player's scene, wired to its interaction detector).
- He's `top_level`, so he lives in the world rather than moving rigidly with the player; he adds the floor's platform velocity each tick so he rides the ship.
- Tests: `tests/scripts/companion/lantern_spirit_test.gd` (shoulder spot, keeps up walking, keeps up sailing, hovers and returns, ignores things you only walk past, blinks).
- **Try it:** F5, walk about the deck; stand facing the bell rope or a counter in the galley for a second.

### 2. Ring the bell to heave to and set sail
Walk up the forecastle stairs; at the top, face the bell rope and press Interact ("Ring the bell: heave to"). The bell swings hard and the ship eases to a stop over five seconds: the wake fades, the spray stops, the sea keeps moving. Ring again ("set sail") and she eases back up to speed. Your lantern hovers by the rope if you linger.
- `scripts/ship/ships_bell.gd` on the belfry (finds its ship up the tree), an `Interactable3D` "Rope", and a `RingSound` spot (plays `assets/third_party/audio/ship/bell_ring.ogg` if you add one).
- `Ship` gained `heave_to()`, `get_under_way()`, `way` (0 to 1 of full speed) and `ease_seconds`; the sea's wake and the bow spray follow `way`. `Swinging` gained `kick()` for a big swing that dies away.
- Tests: `tests/scripts/ship/ships_bell_test.gd` (eases to a stop, stays put, eases back up, the bell toggles and its prompt says which, pulling the rope with Interact rings it, the bell swings hard).
- This is the start of #67's "ring the bell to set sail"; mooring at an island still needs the gangplank.

### 3. Fishing from the rail, into the galley
A rod in a holder at the starboard rail (by the chimney), with a bait bucket. Interact to cast; the bobber floats out on the real swell (it reads the sea's wave height). Fish only bite while the ship is hove to, which gives the bell a reason: under way the prompt says "Reel in (they bite when hove to)". After a wait the bobber dips and bobs; your lantern hops about excitedly; you have a moment to Interact ("Strike!"). Land it and a **herring** goes in your toolbar. Below, on the chopping board, 3 cuts make a **herring fillet** (a new reaction), ready for when the stove cooks.
- `scripts/fishing/fishing_line.gd` (the pure logic: cast, wait in still water, bite, strike or it gets away), `scripts/fishing/fishing_spot.gd` + `scenes/prototype/props/fishing_spot.tscn`.
- Data: `data/items/herring.tres`, `herring_fillet.tres`, `data/reactions/fillet_herring.tres`, added to the catalog (and to the GDD's dishes).
- `Sea` joins a `sea` group so things aboard can ask the water's height; `LanternSpirit.excite()`.
- Tests: `tests/scripts/fishing/` (6 for the line, 5 for the spot: cast with Interact, strike lands a herring in the toolbar, nothing bites under way, the lantern gets excited, the fillet reaction).

### 4. The hearth cooks: fire, a frying pan, Pan-fried Herring
The first heat in the game. On the galley hearth's iron top, right of the stew pot, sits a **hob** (a trivet over glowing iron) with a **frying pan** on it. Whatever vessel is on the hob has **fire**, a timed element, so fire recipes cook second by second (the progress bar fills); lift the pan off and cooking pauses, keeping its progress. The full loop now works: ring the bell, fish, fillet on the board, fry in the pan: **Pan-fried Herring** (★★★ done properly; a whole herring thrown in is the ★ shortcut, as the cooking design asks).
- `scripts/props/hob.gd` (a `Counter3D` that heats its vessel), `scenes/prototype/props/hob.tscn`, in `ship.tscn` under `Galley/Hob`.
- Data: `data/elements/fire.tres`, `data/items/frying_pan.tres`, `pan_fried_herring.tres`, `data/reactions/fry_herring.tres` and `fry_whole_herring.tres`; in the catalog and the GDD's dishes table.
- Tests: `tests/scripts/props/hob_test.gd` (the pan's over the fire, a fillet fries with the right quality, the shortcut, lifting it off pauses, it's on the hearth aboard), and the catalog checks the three herring reactions.
- The frying pan draws as a dark slab for now, like the board.

### 5. Tastes of home: memories that come back as you cook and fish
The story says you remember home only as tastes and sounds, so now cooking *is* remembering. The first time you make or catch certain things, a memory comes back: a soft panel at the top of the screen, its title in amber, then each line fading in, lingering, and fading away; your lantern lights up. Five so far: catching your first herring ("A cold jetty"), filleting it ("Silver on a tin plate"), frying it ("A fogged window"), slicing a tomato ("Warm from the vine") and a Garden Salad ("A squeaky gate"). Each comes back once and is kept in a `MemoryBook` on the game state.
- `scripts/data/memory.gd` (a `Memory` resource: trigger item, title, lines), `data/memories/*.tres`, listed in the catalog's new `memories`.
- `scripts/story/memory_book.gd` (on `Game.memories`; `notice(item)` returns a new memory once), `ui/memory_card.gd` (on the 3D HUD; queues memories that come together).
- Hooks: `CounterSlot` gained a `food_made` signal (from its vessel's finished reactions), which every `Counter3D` (and so the hob) passes to the book; the rod tells it what you caught.
- Tests: `tests/scripts/story/memory_book_test.gd` (once only, nothing for things without one, every memory well-formed, slicing on the board and frying on the hob bring theirs back, the card shows a line at a time, the lantern lights up).
- **Bug found on `main` (from #90):** the player's start spot in `sea.tscn` (ship-space z 11) is now inside the cabin under the quarterdeck. Fixed here (z 7, open deck); `main` needs the same one-line fix.

### 6. Sleep through the storm into dawn
Go down to the bunk room and Interact at your bunk ("Sleep until morning"). The screen fades to black, "Morning", and you wake to a misty grey-rose dawn: the rain is a drizzle (so no lightning), the fog has thinned and warmed, the moon is a low warm sun, the sea's night glow has gone and it mirrors the pale sky; the lanterns and windows still glow. Sleep again ("Rest until nightfall") and the storm comes back. It's the first sense of time passing: the night now has an ending.
- `scripts/weather/time_of_day.gd` (`TimeOfDay`, in `sea.tscn`: one `dawn` value from 0 to 1 blends the sky shader's colours and clouds, the environment's ambient light, fog and exposure, the moon's colour and energy, the rain, and the water's glow and reflection).
- `scripts/props/bedside.gd` + `scenes/prototype/props/bedside.tscn` (at your bunk in `ship.tscn`; reuses the existing `ScreenFade`; you can't walk while asleep).
- Tests: `tests/scripts/weather/time_of_day_test.gd` (night vs dawn, the warm sun, halfway is halfway, sleeping brings the morning and back, you can't walk off while asleep).

### 7. The note by your pillow replays your memories
The GDD already put "a folded note in your own hand" by your pillow; now it's your memory book. At the head of your bunk, Interact ("Read your note") and every memory you've got back comes back again, one after another, on the memory card. Before you've remembered anything it says only: "Don't forget. Cook something. Catch something. It comes back." Sleeping moved to the foot of the bunk so the two don't fight over Interact.
- `scripts/props/memory_note.gd` + `scenes/prototype/props/memory_note.tscn` (in `ship.tscn`'s bunk room); the memory card joined a `memory_card` group so the note can find it.
- Tests: `tests/scripts/props/memory_note_test.gd` (the blank note, replaying memories, reading at the head of the bunk, sleeping at its foot).

### 8. The lantern talks, and the far light means something
He has a voice now: a few warm words float beside him, always facing you, one line at a time. He speaks at the moments that matter, cheerfully (and, per the story, wrongly) sure about home:
- a memory comes back: "Was that home? It sounded like home." / "Oh! Say it again. Slower."
- you land a fish: "A fish! Is home a fish? ...No. Probably not."
- you stop the ship at the bell: "Stopping? Good. I like it when the sea holds still."
- you wake at dawn: "Morning! Did you sleep? I don't. I just glow quieter."
- you walk out onto the bow at night, towards the far light in the fog: "A light! That's it. That's home. Probably. Almost certainly. Maybe." (not at dawn, when the fog's thinned, and not every time: he has a think between guesses).
- `scripts/companion/lantern_voice.gd` (a billboard `Label3D` with a queue and fades), `scripts/companion/lantern_lines.gd` (all his lines, picked at random, never the same twice running; **easy to rewrite in your own voice**), `scripts/companion/lookout.gd` + `scenes/prototype/props/lookout.tscn` (an area at the bow).
- Tests: `tests/scripts/companion/lantern_voice_test.gd` (8: queueing and quiet, no repeats, each moment he speaks at, not at dawn, the think between guesses).

### 9. Rainwater Tomato Soup, the way the GDD designed it
The storm feeds the galley. The water butt on deck (port waist) is open to the rain; carry the **saucepan** up from the hearth and Interact ("Fill Saucepan with rainwater"). Back on its hob, the water boils (4s); add diced tomato and **chopped onion** (onions chop in 3 cuts now) and it boils into **Tomato Soup** (8s, ★★★ done properly). Everything dumped into cold water is the rough ★ shortcut (12s), exactly as the cooking design says. Holding a **bowl** from the new stack on the crew table, Interact at the saucepan to ladle it in. Your first soup brings back a memory ("Rain on the roof").
- The hearth now has two hobs: the **saucepan** where the decorative stew pot was (so the stove's steam rises from your soup) and the frying pan; the kettle moved to the back corner.
- `scripts/props/water_butt.gd` + `scenes/prototype/props/water_butt.tscn`, `scenes/prototype/props/bowl_stack.tscn` (a `Dispenser3D`).
- Data: `saucepan`, `bowl`, `rainwater`, `boiling_water`, `chopped_onion`; reactions `chop_onion`, `boil_water`, `tomato_soup`, `tomato_soup_shortcut`; memory `rain_on_the_roof`.
- Tests: `tests/scripts/cooking/tomato_soup_test.gd` (filling at the butt with Interact, nothing for empty hands, ★★★ soup, the ★ shortcut, ladling into a bowl, the memory), and the catalog checks the four reactions.

### 10. Supper by the stove rekindles the lantern
The GDD says "a warm meal by the stove rekindles him", so now it does, and cooking has a reason beyond memories. The lantern has a **warmth** that fades slowly (about 30 minutes from full to his dimmest; never out): his light gets dimmer and reaches less far, and when he's low he says so ("I'm a bit... dim. Is there soup?"). Carry a bowl or plate with a dish down to the little round table by the bunk room's stove and Interact ("Share Tomato Soup with the lantern"): the dish sits on the table, he drifts down to it, it's gone, and he glows warm again ("Oh, that's warm all the way through."). A ★★★ dish warms him far more than a ★ one. You keep the bowl.
- `LanternSpirit` gained `warmth`, `rekindle()`, `visit()`; his light's energy and range follow his warmth. New lines `SUPPER` and `DIM`.
- `scripts/props/supper_spot.gd` + `scenes/prototype/props/supper_spot.tscn` on the nook's round table in `ship.tscn`.
- Tests: `tests/scripts/props/supper_spot_test.gd` (fades but never out, says when he's low, sharing soup at the table warms him and empties the bowl, nothing to share in an empty bowl, a better dish warms more).
- Tuning to try: `warmth_per_minute` (how fast he fades) and `base_warmth` / `per_star` (how much a dish gives).

### 11. The lighthouse island behind the far light
The far light now has a source. Out in the fog (the centre of the ship's circling route, about 150 m off) is an island with a lighthouse on its headland; the beacon sweeps from its lamp room. At night you see only the light and the faintest shape. At dawn the island comes out of the grey-rose mist as a ghostly silhouette: cliffs, a hill, sea stacks and the lighthouse. Walk out on the bow at dawn and the lantern has something to say about it ("There! An island. With a lighthouse. Lighthouses are for people who are lost. So, us."). It's a destination you can see but can't reach yet: a natural lead-in to #67 (mooring) and the first island.
- `scenes/prototype/islands/lighthouse_island.tscn` (chunky low-poly cylinders), `shaders/distant_silhouette.gdshader` (ignores the fog and fades itself, paler towards the top), `scripts/weather/distant_island.gd` (the `TimeOfDay` sets how much shows through a `distant` group).
- The lookout at the bow picks the light or the island depending on the time; new `ISLAND` lines.
- Tests: the island's reveal follows the dawn (`time_of_day_test`), and the lantern spots the island from the bow at dawn (`lantern_voice_test`).

### 12. The game has a beginning
Run `sea.tscn` and it opens on black: "Somewhere at sea". The fade lifts on the bunk room at night, the camera looking aft over your shoulder at your bunk, the stove and the stern windows with rain on them, and the lantern says his first words: "There you are." / "You were in the water. I pulled. You held on. Good holding." / "I'll get you home. I know exactly where it is. Roughly." Then you're free to explore, read your note, go up into the storm.
- `scripts/story/opening.gd` (the `Opening` node in `sea.tscn`, with its own `ScreenFade`; tick **Skip** in the Inspector to start on deck as before).
- **Bug fixed along the way:** sleeping (feature 6) switched the player's physics off, so on a sailing ship the deck sailed away from under you while you slept. The player now has `controls_enabled` (stand still, but the deck still carries you), used by sleeping and the opening.
- Tests: `tests/scripts/story/opening_test.gd` (you wake by your bunk and can't move until the fade's done, the lantern speaks, you stay aboard while the ship sails on, skipping starts you where you stand).
- **Note:** F5 still runs the old 2D restaurant (`main.tscn` is the project's main scene). To play the 3D game, open `scenes/prototype/sea.tscn` and press F6. Making `sea.tscn` the main scene is a project-setting change I've left for you to decide.

### 13. A recipe book in the galley, and days at sea
Learning the dishes is now part of the game: the galley's **recipe book** lies open on the cook's stool at the head of the table. Read it (Interact) and its pages come up one after another on the card: Garden Salad, Tomato Soup, Pan-fried Herring, each in a few short steps (with a wry line about the shortcut). And the days now count: each time you sleep through to morning the title says which ("Day 2. Morning").
- `scripts/data/recipe.gd` (a `Recipe`: dish, title, steps), `data/recipes/*.tres` in the catalog's new `recipes`; `scripts/props/recipe_book.gd` + `scenes/prototype/props/recipe_book.tscn`; `MemoryCard.show_card()` shows any page.
- `TimeOfDay.day` and `day_began`; the bedside's morning title uses it.
- Tests: `tests/scripts/props/recipe_book_test.gd` (a page per recipe, every recipe's dish is something a reaction makes, each morning is a new day).

### 14. The lantern hums the memory melody
The GDD's "fragment of a song from home, a few notes at first" now exists: the lantern hums three notes (A, C, B, the last one lingering) when a memory comes back and after you share supper with him. There's no recording: the hum is made on the fly (a soft sine with a little overtone, each note swelling in and out, a slight waver), so it works without any third-party audio. It's the seed for learning more of the song on the voyage: add notes to `MELODY`.
- `scripts/companion/hum.gd` (an `AudioStreamPlayer3D` with an `AudioStreamGenerator`, filled with samples each frame), in the lantern's scene; `LanternSpirit.hum()`.
- Tests: `tests/scripts/companion/hum_test.gd` (notes in tune, in order, swelling in and silent after, he hums when a memory comes back).
- **Listen to it** before keeping it: I could test the maths, not the sound. `loudness` and the notes are easy to change.

### 15. Pans, pots and bowls look like themselves
The frying pan, saucepan and bowls drew as slabs and plates; now a vessel's `vessel_shape` (flat, bowl, pan, pot) picks its model: a shallow pan with a long handle, a deep copper pot with two side handles (the stove's steam rises from it), a flared bowl. Food sits at each shape's own height.
- `Item.vessel_shape` (new enum `VesselShape`), drawn by `ItemModel`; set on `frying_pan`, `saucepan` and `bowl`.
- Test: `item_model_test` (pans, pots and bowls look like themselves).

## Notes, loose ends and decisions for you

**Bugs on `main` I found (fixed here, but `main` needs them too):**
- The player's start spot in `sea.tscn` is inside the new cabin under the quarterdeck (from #90). Fixed here by the opening, and by moving the start to open deck.
- My #91 PR said "Press F5" to test; F5 runs the old 2D restaurant. The 3D game is `sea.tscn` with F6.

**Decisions for you:**
- **Make `sea.tscn` the main scene?** Then F5 plays the 3D game with its opening. It's a project setting, so I didn't change it.
- **The lantern's voice:** all his lines are in `scripts/companion/lantern_lines.gd` and the opening's in `scripts/story/opening.gd`. They're a first draft of a character; rewrite freely.
- **Ship sounds:** the deck's sound spots (creaks, rope groans, sail cracks, rain on canvas, the bell) and the bell's ring are silent until recordings are in `assets/third_party/audio/ship/`: `creak_1-3.ogg`, `rope_1-2.ogg`, `sail_flap_1-2.ogg`, `rain_canvas.ogg`, `bell_knock.ogg`, `bell_ring.ogg`.
- **How these become real work:** I'd suggest issues roughly by feature (the lantern companion could close #65; the bell is half of #67), each a PR from this branch's commits.

**Known gaps (deliberately small):**
- The hum is synthesised and tested as maths; it needs a listen.
- The lighthouse island can't be reached; the ship circles it. Mooring there is the natural next step (#67).
- Fish only bite while hove to, and there's one kind of fish.
- Days count, but nothing changes from day to day yet.
- The lantern's warmth isn't saved, and nothing is: there's no save game yet.
