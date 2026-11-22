# Game Design Document

Working title: **TBD** (the repo is still called `restaurant`)

## Pitch
A cosy 3D adventure in the spirit of Ocarina of Time. You're pulled from the sea by a lantern spirit who promises to take you home, and you join the crew of a ship sailing between fog-wrapped islands. You remember home only as tastes and sounds, so you search for it by cooking and humming. Ashore, you explore, gather, solve puzzles and duel fog-touched creatures. Aboard, the ship's galley is the warm heart of it all, where the crew you gather eat together every evening.

## Pillars
1. **Wonder.** Like Kokiri Forest at the start of OoT, a real place where everything is new. Every island has new sights, sounds, tastes and textures, and there's always something round the next corner.
2. **Safe hearth, dangerous shore.** The ship is home: nothing ever attacks it. Danger, duels and puzzles live ashore, so coming back aboard always feels like relief.
3. **Food and music are the map.** Cooking and humming are how you search for home, how you prepare for adventure, and how you get to know the crew.
4. **People are the heart.** The crew are the people from the islands that weren't home. Together they become home.
5. **Hands-on.** You walk your character between stations, across the deck and over the islands. The ship is a place, not a menu.

## Story
- **The rescue:** a young adult sinks in dark water. A small, warm light drifts down and a hand of flame takes theirs. It's a **lantern spirit** (he/him), and he pulls them aboard a ship.
- **The promise:** the lantern promises to get them home. He's sure they came from the nearest island. He's wrong, and he keeps being cheerfully wrong, island after island ("perhaps your home *moved*?"). Over time his guesses get more tender: he quietly hopes he's wrong, because if they find home, they'll leave the ship.
- **Memory:** the player remembers home only as **tastes and sounds**: a bread with something bitter and green in it, and three notes of a song. They search by cooking that taste and humming that tune to the people they meet, who recognise flavours and melodies and point the way ("That's sea-fennel. That only grows in the north."). The melody gains notes and the dish gets closer as the voyage goes on.
- **The crew:** each crew member comes from an island that turned out not to be home. The first is the gruff **heron captain**. The second (in the Prologue) is a **mossy rock cook**.
- **The ending question:** when you finally find home, do you stay?
- The wider story is still to be written.

## A day is a song
A day has four parts, like a song:
- **Morning ashore, the verse:** different every day. Explore an island, gather ingredients, solve its puzzles, duel what lives there, meet its people.
- **Afternoon sailing, the bridge:** the crew sails on through the fog. Wonders at scale drift past (towering kelp, a heron the size of a lighthouse, a sea arch carved like a face).
- **Evening in the galley, the chorus:** cook dinner, and the crew gathers at the galley table to eat, talk and play music. It comes back every day, growing richer as the crew grows.
- **Night on deck, the outro:** hum the memory melody into the fog, and hope something answers.

The ship's bell marks the day, as on real ships: eight bells calls everyone down to dinner.

## The ship
- A big wooden ship with a small crew. A **crew member steers** by default. Taking the wheel yourself comes later.
- **Deck:** open to the sky, with the mast, the wheel, the ship's bell and the hatch down below.
- **Below deck:**
  - **The galley:** the kitchen and the mess in one room, so the crew eats at a table beside the stove. Its stations stand in a row along the bulkhead: the pantry, a counter, the chopping board on its counter, and the plate rack.
  - **The hearth:** the galley is a snug, low room (about 9 x 6.5 m, a plank ceiling 2.6 m up), closed off from the ramp's corridor and from the bunks aft, with posts down the walls under heavy beams. It's crammed with things like the reference image, but every corner is for something:
    - **The table** stands in the middle of the room under the middle beam, long side across the ship, with a bench along each side, a red runner, a deep red woven rug and a half-eaten supper (bread, cheese, stew, tankards, one knocked over). Two lanterns hang over it. A stool at its head is for whoever's in charge.
    - **The hearth** is a stone fireplace by the cooking row, its fire burning in an arched mouth, a big pot steaming on its iron top, a flue up to the ceiling and an iron chimney through the deck. Firewood with a hatchet stands beside it.
    - **By the door** to the bunks (hung open): coats on hooks, an oilskin, a sou'wester and a scarf, a lantern on a bracket, and the ship's bell.
    - **The navigator's corner**, by the riveted brass porthole: a pinned sea chart with dividers, a spyglass, a rolled chart and a compass.
    - **Stores:** barrels, sacks and crates, a fishing net with cork floats, a lifebuoy, a rope coil.
    - **Little lives:** a recipe pinned above the counters, a wool jacket dropped over a bench, a ship in a bottle on the bookshelf, drying herbs, golden motes in the air.
  - The free camera works everywhere in the galley; the walkways (doorway to counters, round the table, between the table and the hearth) stay open, and tests walk them.
  - **The pantry:** a tall cupboard at the end of the galley's row (see Storage).
  - **Your bunk.**
- The ship **really moves** between islands, but it never tilts or rocks: the deck stays level and still, so nothing slides off the counters and nobody feels seasick. The sea's motion shows in the water moving around the hull and in hanging things that swing, like the lanterns.
- **Mooring:** at an island, a **gangplank** connects the ship to the shore. **Ring the ship's bell** while aboard to set sail.

## Islands
Each island is a verse with its own sound, palette, ingredients and people. You often hear an island through the fog before you see it.
- **Gathering:** ingredients behave like part of the island. Some need a trick, a tool or the right time: a fruit that only opens at noon, mushrooms that grow when you hum.
- **Puzzles:** OoT-style environmental puzzles, often musical. On the Bell Rocks, you ring bells in the order of your memory melody.
- **Fog-touched creatures:** the fog sometimes gets into creatures and makes them wild. Defeating one **clears the fog** from it: it shakes itself off and wanders away peacefully. Combat is rescue, never killing.
- **People:** islanders to talk to, taste and listen to, and sometimes to invite aboard.

## Combat
OoT-style duels: lock on, read the enemy, strike at the opening.
- **Lock-on:** the lantern flies to the target and hovers over it, and the player strafes around it. His glow shows the fight's state: he flickers before the enemy strikes and brightens at an opening.
- **The cook's kit is the adventure kit:**
  - The **knife** strikes quickly and precisely.
  - The **frying pan** parries. Time it right for a big *clang* that staggers the enemy.
  - Later, the **ladle** sweeps, the **pepper grinder** makes creatures sneeze, and the lantern lights dark places and burns webs.

  The toolbar is the item bar, and new utensils open new parts of old islands.
- **Hearts:** the player's health.
- **Enemies have rhythms:** a readable windup, an attack, then an opening. Learning a fight is like learning a recipe.

### Preparation
- **Dinner is the briefing:** crew gossip at the table tells you what's on tomorrow's island ("the crabs hate pepper", "the tide goes out at four bells").
- **Tonight's meal is tomorrow's blessing:** what the crew eats at dinner shapes the next day ashore (a hearty stew for an extra heart, ginger soup against the cold).
- **Packing:** going ashore is a real choice: healing buns, a jar of honey to lure something, pepper. What you take is what fits on your toolbar next to your tools, so space is the limit.
- **Taste weaknesses:** creatures react to food (pepper makes them sneeze, honey distracts, smoke makes them sleepy), so cooking knowledge is combat knowledge.

### Defeat
When you lose a fight, **the lantern pulls you out**, echoing how you met. You reappear at the island's landing with half of what you were carrying. (Later: each rescue dims him a little, and a warm meal by the stove rekindles him.)

## Player
- A young adult, rescued at sea. Their name and look are to be decided.
- 3D movement relative to the camera, turning to face the way they walk.
- Acts on the thing in front of them: counters, the pantry, the stove, pans, the bell, the gangplank, plants, people.
- **Toolbar (like Stardew Valley):** 12 slots that hold hand tools and items together: ingredients, prepared food and utensils (chopping board, frying pan, saucepan, plate, bowl). A plate or bowl carries whatever is on it. One slot is selected at a time, and **the selected slot is what you hold**: an item there shows above your head, and Interact uses it. Picking anything up puts it in the first free slot and selects it. The knife starts in slot 1. (Before this, the 2D prototype had a stack of 3 with a rotate button, then the 3D prototype briefly had one item in hand; both were confusing in playtests, #76.)
- **Tools** work whatever you're holding. Use tool uses the selected tool, or if an item or an empty slot is selected, the tool that does something to what you're facing (the knife on a board).

### Camera
- **Free third-person camera** everywhere you walk: on deck, below deck in the galley, and on islands, orbited with the right stick or mouse. A spring arm pulls it in when a wall or the mast is in the way. It keeps its direction in the world when the ship turns, rather than turning with the deck. With a mouse, the cursor is captured while playing: Esc frees it and a click captures it again.
- **The galley is roomy enough for the free camera** (a 4 m ceiling and the full width of the hull), so cooking uses the same camera and controls as everywhere else. We tried a fixed shot there first (#63), but it looked at the player's back while they cooked at the counters.
- **Fixed, framed shots** are kept for spaces too tight for the free camera, like your bunk or an island shop, as in OoT's houses. A *camera zone* blends to its shot as you walk in, and back to the free camera's angle from before as you leave. The camera can't be turned in a fixed shot. Movement always follows the active camera, except that if the camera switches while you hold a direction, you keep walking the same way until you let go or swing the stick, so a switch never turns you round.
- **Lock-on** frames the player and the target together.

### Controls
One button, **interact**, does everything with the thing in front of you.

**The interact rule:** if what you're holding goes here, it goes in or on; otherwise you use the object. Every object follows it, so new ones need no new buttons.

**The action prompt:** the top-right corner of the HUD always says what Interact and Use tool would do right now, like OoT's A-button text: `[RMB] Put down Tomato` above `[LMB] Chop`. A line hides when its button would do nothing. On keyboard and mouse it names the mouse buttons, as in Stardew (E and F still work); after a controller press it names Xbox buttons (`[X]`, `[B]`) until the keyboard or mouse is used again. Along the bottom of the HUD are the toolbar and the name and quality of the selected item.

| Action | Keyboard / mouse | Controller (Xbox naming) | Does |
|---|---|---|---|
| Move | WASD / arrows | Left stick | Walk, relative to the camera |
| Camera | Mouse (Esc frees the cursor) | Right stick | Orbit the free camera |
| Interact | E or Space / right click | X or A | Put down, pick up, put away, open, ring, talk, gather |
| Use tool | F / left click | B | Use the selected tool, or the tool that fits what you're facing (the knife chops) |
| Select toolbar slot | 1–9, 0, -, = / scroll | Bumpers (cycle) | Choose what you hold |
| Lock-on, attack, parry | To be set in #66 | To be set in #66 | Duels |

Each action is a named action in Godot's Input Map with keyboard and controller bound, so gameplay code never checks a specific key. Panels must be usable with the D-pad. While a panel is open the mouse cursor is freed so it can be clicked, and it's captured again when the panel closes.

## Crew and meals
- For now you cook **for the crew only**. There are no paying customers and no money.
- **Mealtimes:** dinner in the galley every evening. The crew sit at the galley table, and you serve each of them a dish.
- Each crew member has tastes (loves, likes, dislikes) and a dish that means home to them. Getting it right, without being told how, is how you become family.
- **Dinner gives:**
  - gossip (tomorrow's briefing),
  - tomorrow's blessing,
  - the crew's mood,
  - the next pieces of each crew member's story.
- **Music at the table:** crew members play instruments (the accordion-playing lantern, for one). Each recruit can add a part to the galley's song.
- Still to design: whether meals other than dinner exist, how crew mood works, and what quality does now that there are no tips (probably a stronger blessing).

## Cooking
Cooking is hands-on and works like a small chemistry system, in the spirit of Breath of the Wild: food reacts to where you put it. Every state food can be in is a named, designed item (tomato, sliced tomato, diced tomato, boiling water, tomato soup), so only combinations someone designed exist. Anything else simply doesn't react.

### Reactions
A **reaction** is a rule: when everything it needs is present together, for long enough, it becomes something else. Its inputs are:

- **Consumed items:** the food that gets used up.
- **Required items:** things that must be present but aren't used up. This includes the **vessel** it happens in (chopping board, frying pan, saucepan, plate or bowl), and kept food like the boiling water a potato boils in.
- **Elements:** things the surroundings provide rather than physical items (see below).
- **Amount:** how much of the driving element it takes. With no elements, the reaction is **immediate**.
- **Result:** the item that comes out, and the reaction's **quality** (see below).

**Elements** come in two kinds:
- **Instant** elements arrive in one-off steps and don't stay. Each press of Use tool with the knife adds one **cut**. Cuts chain through cut levels: lettuce → chopped lettuce (3 cuts); tomato → sliced tomato (2 cuts) → diced tomato (3 more). You choose where to stop.
- **Timed** elements stay while their source does and count seconds. A lit stove provides **fire** to the pan on it, so any heat source (the galley stove now, a campfire ashore later) works for any fire recipe. Turning the heat off pauses reactions without losing progress.

A vessel keeps checking its contents. **Every reaction whose items are all present runs**, each with its own progress, moving forward while its elements are present, so a potato and a carrot can boil side by side in the same water. Consumed food is claimed by its reaction; required items can be shared. If two reactions want the same food, the one that uses more items wins, even taking over from a smaller reaction that already started. Taking food out of a vessel cancels its reactions, losing their progress. When a reaction finishes, its consumed food is swapped for the result, which may let the next reaction start.

**Building up beats dumping in.** Because each step makes a new intermediate item, the order you add things matters without the game tracking it. A sauce built up step by step (oil, then garlic, then tomato) goes through the proper reactions. Dumping everything in at once triggers a separate, designed **shortcut reaction** that gives the same dish at a lower quality. Cooking never fails outright and never burns.

### Quality
- Each piece of food has a quality from ★ to ★★★. Gathered ingredients and water are ★, the normal quality.
- Each reaction has a quality: proper steps are ★★★, shortcuts are ★.
- A reaction's result is the average of its ingredients' average quality and the reaction's own quality, **rounded up**. One rushed step pulls a dish down a little, and careful steps afterwards pull it back up.
- Quality only ever adds. What it adds now there are no tips is still open: most likely a stronger blessing and a happier crew.

Worked example: a tomato (★) sliced properly gives (1 + 3) / 2 = ★★ sliced tomato. Chopped lettuce and sliced tomato (both ★★) on a plate give (2 + 3) / 2 = 2.5, rounded up to a ★★★ Garden Salad. Whole lettuce and tomato on a plate give (1 + 1) / 2 = a ★ salad.

### Vessels and fittings
- **Counter:** holds one item, food or a utensil.
- **Chopping board:** holds one food item. Each Use tool on the board's counter is one cut (the knife, which works whatever you're holding). A progress bar shows how far the current cut level is. Interact takes the food off (losing progress towards the next cut level), and only an empty board is picked up itself. Holding a plate or bowl, Interact slides the board's food onto it instead, if it fits.
- **Plate and bowl:** hold up to 3 food items, and assemble what's on them instantly when it matches a reaction (chopped lettuce + sliced tomato on a plate → Garden Salad). Food goes on while the plate sits on a counter. Interact always takes the plate whole, with its food, and the crew are served it that way. A rack gives clean ones without limit.
- **Vessels don't nest:** only food goes into a board, plate, bowl or pan, never another utensil.
- **Saucepan and frying pan:** hold up to 3 food items, and cook on the galley stove. Interact puts what you're holding into the pan if it fits; otherwise it turns the heat on or off. Finished food waits in the pan.
- **Water barrel** (was the sink): Interact while holding an empty saucepan fills it with water.
- **Getting food out of a pan:** with nothing that goes in it, Interact takes the top solid item. Bring a plate or bowl and the pan's whole contents, liquids and solids, are tipped into it.
- The intended fun is juggling: the stove cooks on its own while you chop, plate and serve.

### Dishes so far
| Dish | Proper (★★★) | Shortcut |
|---|---|---|
| Garden Salad | Chop lettuce, slice tomato, put both on a plate | Whole lettuce and tomato on a plate |
| Tomato Soup | Fill the saucepan at the water barrel, boil it (4s) → boiling water. Add diced tomato and chopped onion, boil (8s). Tip it into a bowl. | Diced tomato and chopped onion into cold water, then heat (12s) |
| Grilled Cheese | Bread + cheese on a plate → sandwich. Melt butter in the hot frying pan (2s), add the sandwich, fry (6s). | Sandwich straight into the frying pan without butter (6s) |

Garden Salad works today. Tomato Soup and Grilled Cheese need the stove, pans and water barrel.

## Storage
- The galley **pantry** (and later the hold) stores ingredients. Containers have a fixed number of slots, and each item uses one.
- Interact on a container while holding food it accepts (and there's room) puts it away. Otherwise it opens a small panel showing its contents, and picking an item puts it on your toolbar if there's a free slot. While you hold food the container accepts, Interact puts it away instead, so select an empty slot or a tool to open it.
- Browsing a container's panel pauses the game (the ship stops and cooking waits), like OoT's item screen. Esc or Close shuts it.
- The galley pantry holds 12 pieces and starts stocked with 3 lettuce and 3 tomatoes for now.
- Containers hold any **solid** food, raw or prepared, so you can prep ahead. Liquids can't be stored yet.
- Whether chilled and dry storage stay separate aboard a ship (an ice box?) is still open.

## Music
- The user composes the score.
- **A mix:** a score underneath (themes for the galley, the deck, the open sea and each island, shifting with time and weather), with music from inside the world woven in. The crew play at dinner, islanders sing, and the player hums.
- **The memory melody:** a fragment of a song from home, a few notes at first. The player can hum it (the lantern accompanies them), and they learn more of it on the voyage. The full theme is only heard when it's complete.
- Islands can be heard before they're seen, and their melody merges into the score as you arrive.

## Look and feel
N64 / OoT style with modern rendering. The reference is a ship's galley at night: a heron in a raincoat, a mossy rock cook in an apron and an accordion-playing lantern at a table, lit by hanging lanterns, with rain at the porthole.
- **Models:** low-poly with flat faces. The characters are chunky folk-tale creatures.
- **Textures:** small, blocky and low-resolution, with nearest-neighbour filtering.
- **Lighting:** modern, where the cosiness comes from. Warm lantern point lights with soft shadows, glowing emissive flames, a stove fire that lights the room.
  - **Pools, not a wash:** indoors, light comes only from what's in the room (lanterns, the hearth, the porthole), so it gathers in warm pools with dark corners between. A room's own dim, warm ambient light (an interior ReflectionProbe) stands in for the night sky's, and subtle SSAO darkens creases and the space under furniture.
  - **Warm inside, cold outside:** the only cold colour in the galley is the blue moonlight through the porthole.
  - **A shadow budget:** point-light shadows are costly, so in a room only the lights that matter most cast them (in the galley, the hearth and the two lanterns over the table).
- **Particles:** steam from pots, drifting embers, chimney smoke, fireflies.
- **Small motion everywhere:** flickering firelight, swinging lanterns, a swaying net and bell, mugs rocking with the sea. Slow and small, so nothing on screen lurches.
- **The N64 recipe:** every surface has a small texture (32 x 32) stretched so its pixels show, about 64 per metre. Big things are simple textured blocks (tables, benches, barrels, the stove). Planks run on floors, ceilings and walls.
- **Third-party models** (KayKit, Tiny Treats) are only for small detailed props (pots, jars, bread, cheese). They keep their colours under a chunky grain so they don't read as smooth modern toys. They dress our greybox when downloaded; gameplay always lives on our own shapes, so the game works without them.
- **Sea and sky:** fog, good-looking water, weather.

### The rainy night (the opening's atmosphere)
The game opens at night in steady rain, and Studio Ghibli's rain is the reference: patient, heavy rain that settles in, where the sound is half the picture.
- **The fog wall:** visibility ends about 30–45 m out. There's no horizon, so the ship feels like a lit room floating in grey. The fog starts about 10 m from the camera, so rooms stay clear.
- **The only warmth** is the ship's: swinging lanterns on the mast, the stern and the hatch, and the galley's hearth below. Their light streaks across the wet deck.
- **Wet, not shiny:** soaked wood goes darker and richer rather than glossy. Water pools in low spots and plank seams, and those puddles are what mirror the lanterns and the moon. Rain rings ripple across them, water runs down the rails and mast, and drips fall from the hatch rim and the sail. Undersides stay dry.
- **Rain lands everywhere:** every drop that hits the ship splashes where it lands, on the deck, the rails or your head, and the deck above keeps the galley dry.
- **The moon** shows faintly through drifting cloud, lighting the cloud edges silver, so the moonlight has a source.
- **Distant lightning:** while it rains hard, every so often the sky flashes, a quick double flicker. Below deck you see it as the porthole lighting up and a moment of cold light across the galley. (Thunder to follow, with audio.)
- **The galley chimney** smokes up on deck, the plume leaning astern in the wind.
- **The sea:** a long, heavy swell with a fine chop on top, modern water (Gerstner waves, Fresnel sky reflection, light through the crests, foam on crests, along the hull and in the wake, rain rings). The ship stays level and still; the sea rises and falls around the hull instead.
- **Sound:** rain loud on deck, muffled and quieter below deck, with waves underneath, gliding as you go through the hatch.
- **The moment to aim for:** sitting by the stove while the crew drift in from the rain, with stories and music. In the score, the music *is* the crew playing.
- Rain and weather are one intensity, so a heavier or lighter night changes the rain, the rings on the sea, how wet everything looks and the sound together.
- High resolution: no pixelated low-resolution viewport. This needs the Forward+ renderer.
- Placeholder art is simple coloured shapes (greybox) until real models are made.

## MVP: the Prologue
A tiny complete story arc that proves the "day is a song" loop and ends on the game's hook.
1. **The rescue:** black water, a warm light, a hand of flame. You wake in your bunk. The heron captain is gruff, and the lantern is certain: "The nearest island, that'll be your home!"
2. **Evening one, the galley:** cook your first meal (Garden Salad) for the captain. Dinner gossip hints at the island ("mind the fog-crabs"). The meal gives tomorrow's blessing (+1 heart).
3. **Night on deck:** hum the three notes you remember. Nothing answers yet.
4. **Morning ashore, the first island:**
   - **Gather** 2–3 ingredients, one of which needs a trick.
   - **Solve the bell puzzle:** ring the bells in the order of your memory melody.
   - **Duel fog-crabs** with the knife and a frying-pan parry, with the lantern as lock-on. Defeat means the lantern pulls you out.
   - **Recruit** the mossy rock cook, who was trapped behind the puzzle. He tastes your food: "That bread you described... that's not from here."
5. **Afternoon, sailing on:** the island slips into the fog, and one wonder drifts by.
6. **Evening two:** dinner for three. The lantern, sheepish: "...Next island. *Definitely* the next one." End card.

**In:**
- The deck, the galley and the bunk.
- The ship sailing a fixed route, with the crew at the wheel.
- The lantern companion.
- One island, one enemy type, one puzzle.
- Two crew members and two or three dishes.
- A three-note hum.
- Three music tracks: galley, deck, island.

### Prototype first
Before the Prologue, a greybox **Prototype** milestone proves the hardest new pieces without story or art: the sailing ship, the 3D player and free camera, camera zones, 3D cooking, the lantern, the duel, ship to island, and a galley mood pass (#60–#68).

## Out of scope for the MVP
Taking the wheel, the sea chart, storms, bosses, more islands, crew field abilities, money and trading, weather, the lantern dimming, saving and loading, menus and settings, real art.

## Open questions
- The title, and the player character's name and look.
- The story beyond the Prologue: where home is, the lantern's secret, why the player was in the sea.
- How crew mood works, and what quality gives without tips.
- Meals other than dinner, and food for the lantern.
- Money and trading: is there any economy at all?
- Storage aboard: one pantry or chilled and dry, and the hold.
- How much of a day is player-paced vs clock-driven (the 2D game's clock ran 6:00–2:00).

## Future roadmap
Rough, all post-MVP:
1. More islands, each a verse with its own sound, ingredients, puzzles and creatures.
2. Recruiting crew, crew stories and friendship, and crew field abilities (bring one ashore: the heron reaches high ledges, the rock cook holds switches down).
3. Taking the wheel, the sea chart, wind and steering.
4. Storms as "dungeons" at sea, weathered from the galley.
5. Bosses that guard a note of a melody, fighting in time with their theme.
6. More kitchen tools as adventure items: the ladle, the pepper grinder, the whisk.
7. Night-sea wonders: bioluminescence, whale song, stars, phantom islands that only appear in the right conditions.
8. The ship as a museum of the voyage: each island leaves something aboard.
9. More cooking: a campfire ashore, the sieve, servings, jars, cold as an element, washing up.
10. Save and load.

## Architecture notes
These cover the pure-logic code that carries over to 3D. The 2D world layer (player, interaction, props, customers, navigation, lighting, the tilemap level) is legacy: it is rebuilt in 3D in the Prototype tickets and then deleted.

- Definitions are `Resource` files under `res://data/`, listed in `res://data/catalog.tres` (`Catalog`):
  - `Item` (`data/items/`): anything physical. Every food state and every utensil. A vessel has a `capacity` (how much food fits; 0 for everything else) and `carried_whole` (plates and bowls yes, boards and pans no). A `storage` kind says where food is put away.
  - `Element` (`data/elements/`): cut, fire, later cold. Instant or timed.
  - `HandTool` (`data/tools/`): a toolbar tool, and the `Element` it applies (the knife applies cut). Kept apart from `Item` because tools are never put down or into anything.
  - `Reaction` (`data/reactions/`): consumed items, required items (including the vessel), elements, amount, result and quality.
  - `Person` (`data/people/`): a character with tastes. Will describe crew members.
- Definitions are shared and never change. A physical thing in the world is an `ItemInstance` (`scripts/cooking/`) pointing at its `Item` and holding its own quality. Arms, vessels and counters hold these. A vessel's instance also owns its `VesselContents`, so its food goes wherever it goes.
- `VesselContents` is the cooking logic of one vessel, with no nodes, so it's unit tested on its own. Its changes (`add_item`, `remove_item`, `add_element`, `remove_element`, `tick`) run the reaction engine inside them; its `get_` methods only read. It emits `contents_changed`, `reaction_started`, `reaction_progressed`, `reaction_cancelled` and `reaction_finished` for the world to redraw from.
- The 3D toolbar (`scripts/player/toolbar.gd`, an `Arms` whose selected item is its "top", so every arms rule works with it), the legacy 2D arms and tool belt (`arms.gd`, `tool_belt.gd`), and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- A container's contents are a `StorageContents` (`scripts/state/`, no nodes): a list of `ItemInstance`s with a capacity, the storage kind it accepts and a take-only flag. `put_away()` follows the player's rules; `add()` ignores them (deliveries); `take_into(arms, item, quality)` moves the oldest matching piece onto the arms. It emits `changed`.
- Interact and use tool are routed the same way: the player's interaction detector sends each press to the focused interactable, which hands it to its prop. Each prop applies the interact rule itself. The 3D versions (`Area3D`) keep this design (#64).
- Shared state lives in the `Game` autoload (`scripts/state/game_state.gd`). `GameClock` and `Calendar` (`scripts/time/`) are pure logic. Whether the clock-driven day stays is an open question.
- `DayLight` (`scripts/visuals/day_light.gd`) maps the time of day to colours and lamp levels. In 3D it will drive the sun, sky and lanterns.
- `DebugKeys` (`scripts/debug/`) gives testing shortcuts in debug builds only.
- The 3D prototype lives in `scenes/prototype/` until it replaces `scenes/main.tscn`.
- Godot concepts are explained in `docs/godot-notes.md`.
