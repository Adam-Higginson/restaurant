# Overnight firebreak (branch `firebreak/overnight`)

A night of building towards a game, on one branch, while you slept. Nothing here is merged; nothing on the board changed. Each feature is its own commit with tests, so you can keep, change or drop them one by one. Pick what you like and we'll turn it into proper issues and PRs.

Ground rules I kept: no merges, no new issues, nothing on `main`, tests for every feature, the headless check and the full suite passing at every commit.

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
