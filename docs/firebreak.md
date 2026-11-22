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
