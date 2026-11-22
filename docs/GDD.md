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
- **The promise:** the lantern promises to get them home. He's sure they came from the nearest island. He's wrong, and he keeps being cheerfully wrong, island after island ("perhaps your home *moved*?"). Over time his guesses get more tender: he quietly hopes he's wrong, because if they find home, they'll leave the ship. **He talks (first sketch):** a few words float beside him at the moments that matter: a memory coming back ("Was that home? It sounded like home."), a fish landed ("A fish! Is home a fish? ...No. Probably not."), the ship stopping, waking at dawn, and standing at the bow at night looking at the far light ("A light! That's it. That's home. Probably. Almost certainly. Maybe."). His lines are in `scripts/companion/lantern_lines.gd`. **He has a home (first sketch, #93):** he lives at the little round table by the bunk room's stove, and you go to him to talk (Interact at the table). He no longer follows you about the ship. What he isn't there to see (a fish landed, the bell rung, the light off the bow, a memory coming back) he asks about when you next visit: "You smell of fish. Was it a good fish?" Near enough to see (about 8 m), he still says his line on the spot. His following (at your shoulder, hovering over what you stop at) is kept in the code for #65 to decide. **His warmth (first sketch):** he fades slowly over time (dimmer, his light reaching less far, never out), and says so when he's low ("I'm a bit... dim. Is there soup?"). Share a dish with him at the little round table by the bunk room's stove and he drifts down to it, it's gone, and he glows warm again, more for a better dish: the GDD's "a warm meal by the stove rekindles him", and a reason to cook well.
- **Memory:** the player remembers home only as **tastes and sounds**: a bread with something bitter and green in it, and three notes of a song. They search by cooking that taste and humming that tune to the people they meet, who recognise flavours and melodies and point the way ("That's sea-fennel. That only grows in the north."). The melody gains notes and the dish gets closer as the voyage goes on.
  - **Tastes of home (first sketch):** the first time you make or catch certain things, a memory comes back: a few quiet lines that fade in at the top of the screen while the lantern lights up ("A fogged window": butter spitting in a black pan, a boat drawn in a steamed-up window, somebody calling down the stairs). Each comes back once and is kept in your memory book. So far: your first herring, filleting it, frying it, slicing a tomato and a Garden Salad. They're data (`data/memories/`), so writing more is just writing.
- **The crew:** each crew member comes from an island that turned out not to be home. The first is the gruff **heron captain**. The second (in the Prologue) is a **mossy rock cook**.
- **The ending question:** when you finally find home, do you stay?
- The wider story is still to be written.

## How it begins (first sketch)
The intro is one cutscene in nine beats. The second half (6 to 9) is built; the first half, in the water, comes next.

1. **The dark.** Black water, the storm's surface churning far above with lightning flickering through it. Your figure drifts down. Nothing else: no hints of home, no wreckage.
2. **The light.** A small warm light comes down through the dark, the first warm thing in the game. A hand of flame is offered.
3. **The reach.** The scene waits, with you still sinking, until you press Interact and take it. It's the only thing you do, and it makes "Good holding." true.
4. **The surface.** He hauls you up into the storm: rain, waves, the ship towering over you with its heron figurehead and bow lantern.
5. **The boathook.** A tall thin silhouette at the rail against the lightning, unmistakably a heron, reaches down a long boathook. It catches your collar. Black. No face and no words.
6. **Title.** "Somewhere at sea".
7. **Waking.** You wake standing by your bunk at night, the storm outside, the bunk room warm and lamplit, the camera looking aft over your shoulder at your bunk, the stove and the stern windows. The lantern, from his round table: "There you are." / "You were in the water. I pulled. You held on. Good holding." / "I'll get you home. I know exactly where it is. Roughly." (Having seen whose boathook it was, "I pulled" is him taking the credit.)
8. **The doorway.** The camera cuts to the galley door: the captain stands in it, lit from behind, the rain coming down the hatch beside them and the boathook leaning on the wall. "Nobody drowns on my ship. Nobody goes hungry either." / "You've managed the first."
9. **The stove.** The camera lingers on the galley stove, where a pot has been left warm, while the captain goes back to the fire. Then the camera is behind you again and the ship is yours. Nothing tells you to go and eat. Talking to the captain by the stove afterwards is your first proper conversation ("So. You're the one the lamp fished out.").

Hold Tab (Start on a controller) for a second to skip it. (In `sea.tscn`, the `Opening` node; tick its Skip to start on deck, or set its Start Section to open on a later beat. The script is `data/dialogue/intro.dlg`: see Cutscenes under Conversations.)

**Keeping the voyage (first sketch):** sleeping in your bunk is where the game saves: the memories you've got back, the day and whether it's morning, and the lantern's warmth. Start again and the opening carries on ("Day 3. Morning", "You're back. I kept the light on.") instead of beginning anew. To start a new voyage, delete `voyage.save` from the user data folder.

## A day is a song
A day has four parts, like a song:
- **Morning ashore, the verse:** different every day. Explore an island, gather ingredients, solve its puzzles, duel what lives there, meet its people.
- **Afternoon sailing, the bridge:** the crew sails on through the fog. Wonders at scale drift past (towering kelp, a heron the size of a lighthouse, a sea arch carved like a face).
- **Evening in the galley, the chorus:** cook dinner, and the crew gathers at the galley table to eat, talk and play music. It comes back every day, growing richer as the crew grows.
- **Night on deck, the outro:** hum the memory melody into the fog, and hope something answers.

The ship's bell marks the day, as on real ships: eight bells calls everyone down to dinner.

## The ship
- A big wooden ship with a small crew. A **crew member steers** by default. Taking the wheel yourself comes later.
- **Deck:** open to the sky, a working ship in a storm, built in three levels so it never reads as a flat platform (#90). Ship space: the bow is -z, the main deck's top is 5.3 m up.
  - **The shape:** a pointed, raked bow with a stem post carrying a long bowsprit, and a gilded heron figurehead under it, lit by a lantern hung from the bowsprit. The waist's bulwarks sweep up towards the bow and stern (the sheer), with chunky stanchions and a capped rail; the deck itself stays level. Planked outside, with wales, brass-rimmed portholes glowing along both sides, and a **stern gallery**: the captain's cabin's five warm windows and two quarter galleries hung out over the wake.
  - **The forecastle** (0.9 m up) at the bow: stairs up its middle under the **belfry**, an arch with the ship's bell (ring it to set sail, #67). On it, the mooring gear: the windlass with its cable, bitts, coiled hawsers, a hawse pipe, and the anchor catted outside the starboard bow.
  - **The waist** (the main deck): the main mast in its fife rail hung with coils, pin rails under the shrouds, the cargo hatch's grating, lashed crates and barrels forward; someone's net being mended over a barrel by the starboard rail under a lantern post; a water butt to port; the hatch below with a rail round it and a framed entrance with a lantern, and a bucket and mop by it; the galley's skylight glowing up through its grating; supplies stacked by the cabin.
  - **The quarterdeck** (2 m up) at the stern, up stairs on both sides: its front is the captain's cabin's wall (a shut door, two glowing portholes, a noticeboard with a map and notes, a lifebuoy, an oilskin and hat on a newel), with the ship's cat asleep on the doorstep under the lantern. On top: the wheel, the binnacle's lit compass, a chart table (chart, dividers, spyglass, pipe, lamp), a flag locker, and the mizzen mast with its boom out over the stern.
  - **Masts and rigging:** a rope-wrapped main mast with a fighting top, topmast and pennant; shrouds with rope-ladder ratlines and deadeyes; stays to the bowsprit; slack running rigging that sags and bows forward in the wind; loose ends and a block that swing. The course is **reefed** (half set, billowing and breathing in the gusts); the topsail and the spanker are furled. Gulls hunch on the yard.
  - **Water everywhere:** rain runs off the yard-arms, the sail's corners, the boom and the gallery, and pours out of scuppers along both sides.
  - Walkways stay open round the mast, along both waists, past the hatch, to the foot of each stair, round the windlass and round the wheel; tests check them.
  - The cabin behind the quarterdeck's door is a facade for now. The **heron captain** is at the wheel in the morning (see Conversations); the rest of the crew aren't on deck yet.
- **Below deck:**
  - **The galley:** the kitchen and the mess in one room, so the crew eats at a table beside the stove. Its stations stand in a row along the bulkhead: the pantry, a counter, the chopping board on its counter, and the plate rack.
  - **The hearth:** the galley is a snug, low room (about 9 x 6.5 m, a plank ceiling 2.6 m up), closed off from the ramp's corridor and from the bunks aft, with posts down the walls under heavy beams. It's crammed with things like the reference image, but every corner is for something:
    - **The table** stands in the middle of the room under the middle beam, long side across the ship, with a bench along each side, a red runner, a deep red woven rug and a half-eaten supper (bread, cheese, stew, tankards, one knocked over). Two lanterns hang over it. A stool at its head is for whoever's in charge.
    - **The hearth** is a stone fireplace by the cooking row, its fire burning in an arched mouth, a big pot steaming on its iron top, a flue up to the ceiling and an iron chimney through the deck. Firewood with a hatchet stands beside it.
    - **By the door** to the bunks (hung open): coats on hooks, an oilskin, a sou'wester and a scarf, a lantern on a bracket, and the ship's bell.
    - **The navigator's corner**, by the riveted brass porthole: a pinned sea chart with dividers, a spyglass, a rolled chart and a compass.
    - **Stores:** barrels, sacks and crates, a fishing net with cork floats, a lifebuoy, a rope coil.
    - **Little lives:** a recipe pinned above the counters, a wool jacket dropped over a bench, a ship in a bottle on the bookshelf, drying herbs, golden motes in the air.
  - The free camera works everywhere in the galley; the walkways (doorway to counters, round the table, between the table and the hearth) stay open, and tests walk them. Its walls run right up to the deck, so there's no gap above its ceiling.
  - **The bunk room:** aft of the galley, through its open door (and at the foot of the hatch ramp). The warmest, safest place on the ship: where you wake up, and where the crew sleep through the storm. Low, tight and crammed rather than roomy.
    - **A low plank ceiling** 3 m up, with heavy beams across the ship resting on headers over the bunk fronts, so the bunks look built into the hull. Over the ramp's foot it stays open up through the hatch. The ceiling stops the camera, so it never rises above it.
    - **Bunks down both sides**, two tiers to a bay, with ladders, drawers and woollen curtains (madder red, mustard or rust): bunched open, or drawn where someone's asleep. Each bed has a ticking mattress you can see the thickness of, a sheet and chunky pillows, and is either neatly made (quilt turned back, a striped wool blanket folded at the foot) or slept in (the quilt thrown back in a heap). A drawn curtain with a light on behind it glows. Every crew bay has a lamp or a candle lit, and each bunk is somebody's:
      - **Forward starboard:** the fiddler (slept in, the fiddle by the pillow, a child's drawing pinned up) under the navigator's mate (a compass, a rolled chart and dividers, a hand-drawn map pinned up).
      - **Middle starboard:** the artist, by the porthole (a sketchbook, drawings pinned round the window) under the angler (the rod along the bunk, lures swaying on a line).
      - **Aft starboard:** yours (see below), under a spare bunk piled with travel bags.
      - **Middle port:** the reader (slept in, a stack of books, one left open face down, spectacles, a shirt over the ladder) under the knitter, reading by candlelight behind drawn curtains.
      - **Aft port:** the old bosun, asleep behind drawn curtains, his navy coat on the bunk post, under the collector (shells, a bottle, a carved whale and framed pictures set out on the quilt).
      - Boots stand by the ladders, one pair kicked over.
    - **The stove nook** in the middle is where the crew relax together: a little pot-bellied iron stove on a stone slab, its door ajar on the fire, a kettle on top and a copper pot beside it, socks drying on its brass rail and its pipe up through the ceiling. Round it on an oval braided rug: a small round table with mugs, a card game and a candle, two stools (an accordion set down on one), a sea chest with cushions to sit on, a basket of knitting, boots drying, and a line of socks between the beams above.
    - **Two canvas hammocks** hang along the stern beam either side of the windows, well above your head and out of the walkways, and roll with the sea. One is slept in and empty; in the other someone's curled up asleep, a woolly hat on the pillow and one socked foot poking out.
    - **The stern wall** has two round windows onto the night, a shelf between them with candles, and sea chests below (blankets folded on one).
    - **The port stern corner** is the crew's shared storage: a chest of drawers in faded teal paint (its top drawer left open, a scarf trailing out) with keepsakes and a candle on top and a hand-drawn map pinned above, a coat rack with a wool coat and cap, a net bag of floats and twine hung from a beam, and bags stowed on top of the locker. The space in front of the port bunks stays clear.
    - **By the galley wall:** stencilled boxes (SAIL, ROPE, TEA), crates and a rope coil, oilskins on pegs and a shelf. A rag-rug runner runs along the front, and a sheepskin lies by your bunk.
    - Light gathers in pools: the stove's fire (which casts shadows) and one softened lantern over the door side (the other shadow), a softer lantern over your side, the bunks' lamps and candles, candles on the table, the stern shelf and the chest of drawers, and cold blue moonlight from the windows. The room's own ambient light is dim but not black, so the corners stay dark brown.
  - **The pantry:** a tall cupboard at the end of the galley's row (see Storage).
  - **Your bunk:** the aft starboard lower bunk in the bunk room, under a gold patchwork quilt, its lantern lit. By the pillow: a shell from a beach you can't name, a folded note in your own hand, and a cushion where the lantern likes to sit.
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
- **The galley is roomy enough for the free camera** (a plank ceiling 2.65 m up and the full width of the hull), so cooking uses the same camera and controls as everywhere else. Below deck, the ceilings and their beams stop the camera's spring arm, so it's pulled in under them rather than rising into the space below the deck. We tried a fixed shot there first (#63), but it looked at the player's back while they cooked at the counters.
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
| Interact | E or Space / right click | X or A | Put down, pick up, put away, open, ring, talk, gather. In a conversation: next line, or pick the reply |
| Move (in a conversation) | W and S / arrows | Left stick or D-pad | Move between replies |
| Skip a cutscene | Hold Tab | Hold Start | Held for a second, runs the cutscene to its end |
| Use tool | F / left click | B | Use the selected tool, or the tool that fits what you're facing (the knife chops) |
| Select toolbar slot | 1–9, 0, -, = / scroll | Bumpers (cycle) | Choose what you hold |
| Lock-on, attack, parry | To be set in #66 | To be set in #66 | Duels |

Each action is a named action in Godot's Input Map with keyboard and controller bound, so gameplay code never checks a specific key. Panels must be usable with the D-pad. While a panel is open the mouse cursor is freed so it can be clicked, and it's captured again when the panel closes.

## Conversations
Talking is how you get to know the crew, so it comes in two kinds (the second is #94).

**A proper conversation (#93).** Stand in front of someone and Interact ("Talk to Captain"). A dark sea-teal box in a riveted brass frame opens at the bottom of the screen, the speaker's name on a little plank at its corner, and their words type out with a soft blip (lower for the gruff heron, higher for the lantern). Interact shows the rest of a line at once, then moves on. When there's a reply to pick, the choices are listed in the box with a small flame beside the one you're on: move with up and down, pick with Interact. Up to four show at once; a longer list scrolls.
- **You stand still and turn to face each other**, but the world keeps running: the ship sails on and pots keep cooking.
- **The camera stays yours** in an ordinary chat. A script can ask for a framed shot for a moment that matters (the heron's first greeting by the stove), and the camera glides there and back.
- **People remember.** Scripts set and check flags (you've met, you've asked about the heading) and can ask about the world (night or morning, raining, sailing, which day). Flags are saved with the voyage.
- **Who's aboard, and where:** the heron captain warms himself by the bunk room stove at night and stands at the wheel in the morning; he changes places while you sleep. The lantern is at his round table. (Crew who walk the ship through a full day are #95.)
- **Writing them:** each conversation is a plain text file in `data/dialogue/` (`heron.dlg`, `lantern.dlg`), one statement to a line: `speaker: words`, `- a reply -> section`, `? condition` guarding the next line, `set flag`, `@shot name`, `-> section`. A test reads every file, so a typo fails the tests rather than a talk.

**Overheard (#94).** Small pill-shaped speech bubbles float beside the crew's heads as they remark on things and chat to each other, so you overhear them as you pass. Nobody stops you or touches the camera.
- **The bubbles** have a place in the world beside the speaker's head and always face you, shrinking gently with distance and fading out far away. They draw over a low beam rather than being cut in half, but a wall between you and the speaker hides them. Styles: speech, thought (a trail of dots), shout (amber words) and sound (paler, quieter words, for a hum or a grunt). One bubble at a time in an exchange.
- **When:** every 25 to 60 seconds, one remark or short exchange, only from people within earshot (9 m) you can see, and everyone in an exchange must be near each other. Never during a proper conversation (one starting cuts the chatter off), never while you're asleep or the title's up.
- **The lantern** says his reactions (a fish landed, the bell rung, a memory back) in the same bubbles, and they cut any chatter off so he's heard. If he didn't see it, it's news he asks about later, as before.
- **Writing them:** chatter is in `data/dialogue/ambient.dlg`, the lantern's reactions in `moments.dlg`, in the same format as conversations. Each section is one remark; a `?` line just before it says when it can be said (`? night and raining`), and tags after its name say how often: `[weight 2]` (twice as likely), `[cooldown 300]` (seconds before it's said again, 120 if not given), `[priority 1]` (said before others that fit), `[on caught]` (a reaction to that moment). A line can end in `[thought]`, `[shout]` or `[sound]`. Nothing is said twice running.

**Cutscenes (#100).** A cutscene is a conversation that nobody in particular starts, written in the same kind of file, whose `@` cues stage the scene. Lines wait for Interact as usual. A cue that takes time holds the script until it's done, so the file reads top to bottom as the scene plays.
- **The cues so far:** `@shot doorway` (glide the camera to a shot; add `cut` to cut, and `@shot free` gives it back), `@fade out` / `@fade in 2.0`, `@title Somewhere at sea`, `@wait 1.5`, `@wait_for interact` (the scene waits for the player), `@place heron doorway` (stand someone on a mark), `@face heron player`, `@hide heron` / `@show heron`, and `@home heron` (back to their usual spot). Nobody walks yet, so people are moved while the camera looks elsewhere.
- **Places have names, not numbers.** A shot or a mark is a marker in the ship scene (under `Shots` and `Marks`), named for the cue: drag it in the editor to reframe, without touching the script.
- **Skipping** (hold Tab or Start for a second) blacks the screen and runs the script to its end at once, so its flags are set and everyone ends up where they should be. It stops at a choice, which is never made for you.
- **Tuning one:** set Start Section on the `Opening` node to open the game on a later beat. While the game runs from the editor, F8 reads the file again and replays the section you're in, so the loop is edit, save, F8. A mistyped cue is reported with its line number, and the tests check every file.
- **Still to come:** `@play` for movements shaped on Godot's animation timeline (the lantern's descent), and lines marked to play on their own timing in a speech bubble instead of waiting for the button.

The text is set in Varela Round, a soft rounded face like OoT's.

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
| Tomato Soup | Fill the saucepan with rainwater at the water butt on deck, boil it on the hearth (4s) → boiling water. Add diced tomato and chopped onion (3 cuts), boil (8s). Ladle it into a bowl from the stack on the table. | Diced tomato and chopped onion into cold water, then heat (12s) |
| Grilled Cheese | Bread + cheese on a plate → sandwich. Melt butter in the hot frying pan (2s), add the sandwich, fry (6s). | Sandwich straight into the frying pan without butter (6s) |
| Pan-fried Herring | Catch a herring, fillet it on the board (3 cuts), fry the fillet in the pan on the hob (6s). | A whole herring straight into the pan (9s) |

Garden Salad, Tomato Soup and Pan-fried Herring work today, and the galley's **recipe book** (open on the cook's stool at the head of the table) shows how to make each, a page at a time (`data/recipes/`). The hearth has two hobs (a saucepan where the stew pot was, and a frying pan); bowls are stacked on the crew table. Grilled Cheese still needs butter and the sandwich step.

**Caught, not bought:** a **herring** (at night; at dawn, a **mackerel**, which fillets and fries the same way) from the rod at the starboard rail (fish only bite while the ship is hove to: ring the bell). Fillet it on the chopping board (3 cuts) for a **herring fillet**, fried in the pan on the galley **hob** (the hearth's hot iron top, which gives fire to whatever vessel sits on it; lift the pan off and cooking pauses). The fish keep in the fridge.

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
- **The memory melody:** a fragment of a song from home, a few notes at first. (First sketch: the lantern hums three notes, A, C, B, when a memory comes back and after supper, synthesised in `scripts/companion/hum.gd`; more notes can join `MELODY` as the voyage goes on.) The player can hum it (the lantern accompanies them), and they learn more of it on the voyage. The full theme is only heard when it's complete.
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
- **Small motion everywhere:** flickering firelight, swinging lanterns, a swaying net and bell, mugs rocking with the sea, candle flames wavering, hammocks rolling, curtains and blanket ends swaying, socks stirring in a stove's warm air. Slow and small, so nothing on screen lurches.
- **The N64 recipe:** every surface has a small texture (32 x 32) stretched so its pixels show, about 64 per metre. Big things are simple textured blocks (tables, benches, barrels, the stove). Planks run on floors, ceilings and walls.
- **Third-party models** (KayKit, Tiny Treats) are only for small detailed props (pots, jars, bread, cheese). They keep their colours under a chunky grain so they don't read as smooth modern toys. They dress our greybox when downloaded; gameplay always lives on our own shapes, so the game works without them.
- **Sea and sky:** fog, good-looking water, weather.

### The rainy night (the opening's atmosphere)
The game opens at night in steady rain, and Studio Ghibli's rain is the reference: patient, heavy rain that settles in, where the sound is half the picture.
- **The fog wall:** visibility ends about 30–45 m out. There's no horizon, so the ship feels like a lit room floating in grey. The fog starts about 10 m from the camera, so rooms stay clear.
- **The only warmth** is the ship's: lanterns on posts and hooks round the deck, the cabin's and the gallery's windows, the galley skylight, and the hearth below. Everything else is cold blue: the light gathers in warm **pools** with dark deck between them, each lantern glowing in its own halo of mist and rain (volumetric fog), and the colour grade keeps shadows teal and highlights amber. Only three deck lanterns cast shadows (the mast, the hatch and the stern). Lanterns flicker a little.
- **The wet deck reflects:** soaked planks are a little glossy and water stands in their seams and low spots, so the lanterns streak and mirror across them (screen-space reflections). The boards vary in width, with nail heads over each beam.
- **Wet, not shiny:** soaked wood goes darker and richer rather than glossy. Water pools in low spots and plank seams, and those puddles are what mirror the lanterns and the moon. Rain rings ripple across them, water runs down the rails and mast, and drips fall from the hatch rim and the sail. Undersides stay dry.
- **Rain lands everywhere:** every drop that hits the ship splashes where it lands, on the deck, the rails or your head, and the deck above keeps the galley dry.
- **The moon** shows faintly through drifting cloud, lighting the cloud edges silver, so the moonlight has a source.
- **Distant lightning:** while it rains hard, every so often the sky flashes, a quick double flicker. On deck the whole ship is lit cold-white for a moment, every rope thrown in sharp shadow. Below deck you see it as the porthole lighting up and a moment of cold light across the galley. (Thunder to follow, with audio.)
- **A light far off:** somewhere out in the fog, always far away, a light swells and fades as if a lighthouse beam were sweeping past. At night that's all you see; at dawn the island it comes from shows through the mist as a ghostly silhouette, cliffs, hills and a lighthouse on its headland. The ship circles it on its route but never reaches it (yet). The lantern has guesses about both from the bow.
- **The galley chimney** smokes up on deck, the plume leaning astern in the wind.
- **The sea:** a long, heavy swell with a steep wind sea and a fine chop on top, modern water (Gerstner waves, Fresnel sky reflection, light through the crests, whitecaps on crests, foam along the hull and in the wake, rain rings). Under way, the bow throws up a wave of foam and every few seconds a burst of spray. Where the water is stirred (along the hull, in the wake) tiny specks of plankton glint blue-green. The ship stays level and still; the sea rises and falls around the hull instead.
- **Sound:** rain loud on deck, muffled and quieter below deck, with waves underneath, gliding as you go through the hatch. The ship makes its own sounds from where they happen: timbers creaking at the mast and the hull, the rigging groaning, the sail cracking in a gust, rain drumming on the canvas, the bell knocking in the swell. (Each needs a recording in `assets/third_party/audio/ship/`; without one it stays silent.)
- **Dawn (first sketch):** sleep in your bunk (Interact at it) and the screen fades to black: "Morning". You wake to a misty, grey-rose dawn: the rain eases to a drizzle (so the lightning stops), the fog thins and warms, the moon becomes a low warm sun, the sea stops glowing and mirrors the paler sky. Sleep again ("Rest until nightfall") for the night and the storm. Each morning is a new day ("Day 2. Morning"). One number blends it all (`TimeOfDay.dawn`), so dusk and a full day can come later by moving it slowly.
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
- **Conversations** (`scripts/dialogue/`): `DialogueScript` reads a `.dlg` text file into a `DialogueTree` (steps in order, sections by name). `DialogueRunner` walks it with no nodes, so it's unit tested alone; it reads and changes a `DialogueState` (`Game.dialogue`: saved flags, plus facts the game answers on the spot, registered by `DialogueFacts`). `Conversation` is the one node that joins it to the world: it stops the player, shows lines in the `DialogueBox` (display only), reads the buttons and emits `cue` for the scene. `ShotCues` turns a `@shot` cue into `CameraRig.hold_shot`. **Cutscenes** (`scripts/cutscene/`): `Conversation.play` starts a script as a cutscene. `CueList` names every cue and how it's written, which `DialogueScript` checks as it reads. Each family of cues has a small `CueHandler` node in the scene (`ShotCues`, `FadeCues`, `WaitCues`, `ActorCues`); one that takes time calls `hold()` and later `release()`, and the runner reads no further while any hold is open. Adding a cue is one handler and one line in `CueList`. `Opening` plays `intro.dlg`; `CutsceneKeys` is the F8 replay. A `Crewmate` is anyone you can talk to: a `Person` and the name of a script, nothing about any one character.
- Godot concepts are explained in `docs/godot-notes.md`.
