# Prologue: The Grave of the Lanterns

**Location:** the Salt and Ember, and the Grave of the Lanterns
**Estimated playtime:** 30–45 minutes
**Purpose:** introduce the world, establish the relationship between the player and the lantern, teach exploration and cooking through the first puzzle, and bring the player to the first island.

This is the script the opening is being rebuilt to (#181), now led by the Unmooring (#233, below): your home, the chain breaking and the ship finding you. The GDD's *The opening as intended* and *MVP: the Prologue* summarise it; the scene-by-scene words are here. Each scene says which issue builds it, and whether it's built or planned.

**How it was fitted to the game (decided 2026-11-24; some of it superseded by the Unmooring, #233, as marked):**
- **The ship is the Salt and Ember**, not the Wayward. *(Superseded: the title screen no longer stays her carved nameboard on a new voyage, which opens on home waters; her name is the title drop when she finds you, #231, #232. A saved voyage still opens on the nameboard. The rail scene no longer begins on your press: it is replaced by the Grave scene, #230.)*
- **The player never speaks.** Where the script says the player nods, shakes their head or asks something, that's a reply you choose in the conversation box.
- **You wake in your own bunk** in the bunk room, not a cabin, with the captain standing over you at its foot (not calling from the doorway), and the lantern lies on his round table by the stove. *(Superseded: you climb a rope ladder onto a dark, abandoned ship, #231. What happens to the bunk and the captain's place is open.)*
- **The navigation room** is a new room in the empty bow half below deck, through a door at the forward end of the hatch ramp's corridor. The captain's cabin stays shut for now.
- **The captain gives you the cooking pot** (open: whether the captain is aboard to give it, #233) at the helm, where he stays while the lantern is low, going for a drink at the water butt now and then. The frying pan, your shield in a fight, is the first thing you find ashore.
- **The deck talk plays by itself** the first time you come up on deck after the soup, and **the frying pan is in a washed-up chest** on the cove's beach (#187).
- **The water comes from the water butt** on deck, not a stream off the rigging, and the soup is made in two steps (a Tomato Soup, then the chilli and herbs stirred in), as the recipe book has it (#186).
- **They look out together (#203).** *(Superseded by the Unmooring: no rail talk.)* After the captain's first line from the wheel, the lantern bobs up to the captain at the wheel, then leads him to the starboard rail, so the rest of the talk is side by side at the rail, and he goes over the side from there.
- **The rescue ends in white.** The haul up through the dead lanterns, the storm surface and the heron at the rail are gone; how you came aboard isn't shown. *(In the Unmooring the white is followed by you surfacing beside your upturned rowboat and the ship finding you, #231.)*
- **The arrival is the cove** (#163): the ship anchors off the beach and you row ashore. The harbour, the settlement and the old structures belong to Chapter 1.

---

## The Unmooring (#233)

*Planned, except the rowing (#226) and home waters (#227), which are built as greyboxes. This is the new opening, and it comes before everything below. It replaces Scene 0's title and rail talk and Scene 2's waking, and changes Scene 1's lines. The words here are first drafts, and only the quoted lines are decided; where the beats say "lines to be written", they're open. Greybox shapes first.*

**The premise.** The islands were once anchored by great chains, and the chains are breaking. You are your island's chain-tender, and the lantern is your friend, the buoy's light. You aren't a castaway and you don't lose your memory: you know home. It has drifted away. People find their way by an island's cooking and its songs, and the taste of home is your older sibling's fish stew. Lanterns are one kind of sea spirit among many.

**The player never walks ashore here.** Everything is the rowboat, the water and the buoy.

### Scene U1: Home waters at dusk (#227)

**Location:** the water off your home island, at dusk.

The first shot of the game: your island seen from the water, its lights, bells and chimney smoke, before it's lost. The rowboat is at the jetty and the lantern rides a pole at its bow.

Your older sibling calls from a lit window. You never see them.

**SIBLING (off):** "Back by supper. I'm doing the fish stew."

Out in the dusk is the marker buoy, and the great chain rises from the sea to the island. You row out to it while the lantern chatters: you've done this a hundred times. His lines (first drafts, in `data/dialogue/home_waters.dlg`), each said once as it comes:

- *Leaving the jetty:* **LANTERN:** "Off we go. Out to the buoy, light it, home for stew." / "Mind the third post. You always nearly hit the third post."
- *A fifth of the way:* **LANTERN:** "Smell that? The onions are on already."
- *Halfway:* **LANTERN:** "Halfway. I counted. I always count." / "Ninety-one strokes, if you don't dawdle. You're dawdling."
- *Passing the chain:* **LANTERN:** "Evening, chain." / "It hums, you know. You'll feel it when we tie up. Like a cat, only iron."
- *The buoy in sight:* **LANTERN:** "There she is. Lamp's out again, look." / "Don't worry. I've got plenty."
- *Nearly there:* **LANTERN:** "Easy on the last bit, or you'll bump her and she sulks."
- *Alongside:* **LANTERN:** "Bump. ...Gently, I said."
- *Rowed off into the fog (in turn):* **LANTERN:** "Wrong way, chain-tender. The buoy's back there." / "There's nothing out here but fog. Turn us round?"

*Built as a greybox (#227):* `scenes/prototype/intro/home_waters.tscn`: the island, the jetty, the buoy, the chain, the lantern on the pole, the sibling's call and the island's bells (see the GDD's "The Unmooring"). The rowboat is a greybox until the Meshy model (#234).

### Scene U2: Tending the buoy (#228)

**Location:** the buoy, over your island's chain.

Your nightly job: row out to the buoy, check it and keep its light lit. You tie up and climb onto it. You put a hand on the chain and feel its slow hum.

The buoy's lamp is out. The lantern gives it a little of his flame.

**LANTERN:** "Just a little. Doesn't hurt."

This sets up that his light can be given away, which the ship's stove pays off later. *(The rest to be written.)*

### Scene U3: The chain breaks and you're swept away (#229)

**Location:** the buoy, then open water. About a minute, as one beat.

The chain's hum stops. A ringing comes up it. It falls slack and slides into the sea. Alarm bells at home, and the island's lights turn away into the fog.

**(Speaker to settle, probably the lantern)** "Row! Row!"

You row after it, and at first the boat answers. But the current is already taking you: the steering fades over about 20 seconds, the island slides off to one side and the bells fade. (This is the rowing greybox's `takeover`, built in #226: at full takeover your strokes do nothing, the bow swings round with the water, and the current runs at 4 m/s.)

**(Speaker to settle)** "It's not us. It's the sea."

The fog closes, and home is gone.

**It must never feel like you failed to catch it.** The sea was taking you the whole time.

**Weather (#239).** Wind, rain, spray and swell should rise with the current's `takeover`, the swell first, so being swept away feels like the sea taking over. Keep the landmarks readable, or you can't tell the boat is being carried. **Open question:** does the storm break the chain, so the weather builds *before* the current takes the boat, or does the weather rise with the current? To settle before #239 is built.

### Scene U4: Into the Grave, the capsize and the rescue (#230)

**Location:** the Grave of the Lanterns, which nobody has heard of.

Swept through the fog, you come out over lights below. The lantern leans out, thrilled. He thinks it's home.

**LANTERN:** "There you are..."

They're dead lanterns, his own kind. Nobody ever told him where lanterns go.

**LANTERN:** "...Oh."

The ringing, the pull, the capsize: the Grave pulls him off the pole, you reach for him and go in after him.

Then the rescue as built (Scene 1 below, `underwater.tscn`), with his lines rewritten for a friend rather than a stranger. This replaces Scene 0's rail talk. *(Lines to be written.)*

### Scene U5: The ship finds you (#231)

**Location:** the fog, at sea.

After the white you surface, clinging to your upturned rowboat with half its name still on the bow (the first clue to home), the lantern in your arms, barely lit.

A bell in the fog. A ship comes alongside, dark, and nobody calls out.

Lightning shows her name on her stern: SALT AND EMBER. This is the title drop (the nameboard is reused).

A rope ladder is already trailing in the water. You climb up together, carrying him, and the abandoned ship begins.

**Open question:** who, if anyone, is aboard. The captain's scenes below (2 to 8) were written with the heron beside you when you arrive; that has to be decided before they're reworked. *(See the GDD's Open questions.)*

### The title (#232)

A new voyage opens on home waters at dusk (Scene U1) instead of her nameboard; the ship's name is the title drop when she finds you. A saved voyage still opens on the nameboard, since you live aboard by then. Continue and Start a new voyage keep working (#151). Where "who are you" is asked is open.

---

*Everything from here is the Prologue as first drafted (#181), before the Unmooring. What's marked below as superseded is kept for its lines and pictures.*


## Scene 0: The title screen (#182, built; replaced by the Unmooring, #227 to #232)

*Superseded. This is the nameboard title and the rail talk as built. A new voyage now opens on home waters (Scene U1) and the lantern finds the Grave from your rowboat (Scene U4), not from the rail beside a captain. Kept for its lines and the shots the new scenes reuse (the lights under the water, "There you are...", the nameboard for the title drop).*

BLACK SCREEN.

The sound of waves. A distant gull. The gentle creaking of old timber.

A small golden light appears.

A lantern swings slowly on a hook at the ship's stern. As it swings, its warm light slides across the carved letters of her name on the nameboard, a few at a time. Beyond the ship, the ocean is almost completely black.

The lantern swings.

TITLE: SALT AND EMBER

PRESS ANY BUTTON TO BEGIN.

The player presses Start.

The swinging stops. The camera pulls back from the board, revealing the stern of a sailing ship moving slowly through a vast, dark ocean.

Faint lights shimmer beneath the surface.

The lantern notices them.

**LANTERN:** "There you are…"

He leans out over the rail.

**LANTERN:** "I knew I hadn't imagined it."

He looks towards the wheel, where the heron captain stands.

**LANTERN:** "Captain? I think I've found something."

**HERON:** "Something, or another one of your little lights?"

The lantern lifts off his hook and settles beside the captain.

**LANTERN:** "Captain. Come take a look."

He leads the captain to the rail and turns towards the ocean.

**LANTERN:** "Look."

The camera moves past him and out over the water.

Thousands of lanterns lie beneath the surface. Some are broken. Others are tangled in enormous chains. A few still glow faintly, like dying stars.

The ship is passing through the Grave of the Lanterns.

**LANTERN:** "There must be hundreds of them."

**HERON:** "Thousands, most likely."

**LANTERN:** "I wonder how long they've been down there."

**HERON:** "Longer than either of us."

The lantern notices a faint light further ahead.

**LANTERN:** "Wait. That one…"

He moves closer to the rail.

**LANTERN:** "Captain, I think there's something down there."

**HERON:** "What do you hear?"

The lantern leans further.

A faint metallic ringing echoes from beneath the water.

The lantern goes quiet.

**LANTERN:** "That's strange."

Something moves beneath the ship.

**HERON:** "Back away from the rail."

**LANTERN:** "I think I saw—"

A shape passes beneath the surface.

The lantern notices something drifting amongst the dead lights. At first it looks like another broken lantern.

Then we see a hand.

**LANTERN:** "…"

He moves closer.

**LANTERN:** "Captain?"

**HERON:** "What is it?"

**LANTERN:** "There's somebody in the water."

**HERON:** "What?"

**LANTERN:** "Somebody overboard!"

The heron turns sharply.

**HERON:** "Don't you dare—"

The lantern is already gone, off his hook and over the side.

---

## Scene 1: The rescue (#183, built; lines to be rewritten, #230)

*The pictures stay (the descent, the dead lanterns, his hand, the light going into you, the white). The words change: in the Unmooring he is your friend, not a stranger, so "I don't know who you are..." goes, and the rest is rewritten for a friend (#230).*

**Location:** the Grave of the Lanterns, underwater.

The camera plunges beneath the surface. The sound of the ship disappears.

The player is sinking slowly through dark water. All around them are the remains of countless lanterns. Some are completely extinguished. Others give a faint, dying glow.

The lantern approaches.

**LANTERN:** "Hello?"

No response.

**LANTERN:** "Can you hear me?"

He dips to look beneath the player's bowed head, pauses for a response and drifts back.

**LANTERN:** "Oh, you're in a bad way…"

He tries to lift the player, but struggles.

**LANTERN:** "Come on. Come on!"

The player keeps sinking.

The lantern looks towards the surface, then back at the player.

**LANTERN:** "Hold on. I've got you."

He moves closer and reaches out his little hand.

**LANTERN:** "Here. Take my hand."

**GAMEPLAY: REACH OUT.** The player slowly raises their hand. For a moment the two hands almost touch. The lantern reaches a little further. The player takes his hand. Their eyelids flutter open and they look towards him.

A strange sound resonates through the water.

The lantern freezes. His flame suddenly grows brighter.

**LANTERN:** "Oh…"

A golden light begins to travel from the lantern into the player's hand. The player's body begins to glow. At the same time a thinner thread of his glow sinks away from him, down towards the dead lanterns far below, fading as it goes: they're drawing on him too.

**LANTERN:** "The lanterns down there…"

**LANTERN:** "they're calling my light."

The light keeps flowing. The lantern tries to pull away, but the connection holds. His flame begins to shrink.

**LANTERN:** "I can't…"

**LANTERN:** "I can't hold on to it."

The lanterns all around begin to flicker. A deep rumble rolls through the ocean.

The lantern looks down. Something enormous shifts in the darkness below them: only a vast silhouette, passing beneath the chains.

The lantern looks back at the player. His flame is almost out.

**LANTERN:** "I don't know who you are…"

A pause.

**LANTERN:** "But I can't let you go."

He releases the last of his light.

A huge burst of golden light fills the screen.

WHITEOUT.

Silence.

---

## Chapter 1: The Salt and Ember

*Scenes 2 to 8 were written with the heron captain aboard. After the Unmooring the ship is dark and abandoned, so who is aboard when you arrive, and how the captain and crew fit, is open (#233; see the GDD's Open questions). Until that is decided these stay as drafted and as built.

### Scene 2: Waking up (#184, built; to be replaced by the ship finding you, #231)

*Superseded, and open. In the Unmooring you climb aboard an abandoned ship instead of waking in a bunk, and you aren't an amnesiac: you know where you came from. So the captain's questions below ("Do you remember anything?") don't survive, and who is aboard is open (see the GDD's Open questions). Kept for its lines, the recipe book by your pillow and the first beats of the lantern's weakness.*

**Location:** the Salt and Ember, the bunk room.

The sound of waves. A gull cries in the distance.

The player slowly opens their eyes. They're lying in their bunk in the ship's bunk room: low beams, the crew's bunks down both sides, a small stove, a round porthole.

Rainwater drips from somewhere above.

The heron captain stands at the foot of the bunk, beside them, as if he's been keeping watch.

**HERON:** "Ah. You're awake."

A pause.

**HERON:** "Good. I was beginning to wonder whether we'd rescued you or merely inconvenienced a corpse."

The lantern sits on his little round table by the stove. His flame is barely visible.

**LANTERN:** "I told you they'd wake up!"

**HERON:** "You also told me you were perfectly capable of swimming."

**LANTERN:** "I am!"

His flame flickers.

**HERON:** "Clearly."

The lantern turns towards the player.

**LANTERN:** "Oh! Hello!"

He tries to float towards the player, but his light flickers and he sinks a little.

**LANTERN:** "Oh. That's not ideal."

**HERON:** "You've used nearly all your light."

**LANTERN:** "I know."

**HERON:** "You could have left them."

The lantern goes quiet.

**LANTERN:** "I know."

The heron looks towards the player.

**HERON:** "Do you remember anything?"

*(Reply: shake your head.)*

**HERON:** "Your name?"

*(Reply: nothing.)*

**HERON:** "Where you came from?"

*(Reply: nothing.)*

**HERON:** "How you ended up in the water?"

*(Reply: look down.)*

**HERON:** "I see."

He looks towards the lantern.

**HERON:** "Well, whatever happened out there, you're fortunate he's as stubborn as he is."

**LANTERN:** "You're welcome."

**HERON:** "I wasn't thanking you."

The heron turns towards the door.

**HERON:** "Come along. You should have a look around."

He pauses.

**HERON:** "And try not to fall overboard again."

The heron leaves.

**LANTERN:** "Don't mind him."

A pause.

**LANTERN:** "He's always like that."

The player looks around. By their pillow is a small, battered book. They pick it up.

It's a recipe book. The cover is worn and the corners are frayed. Several recipes are written inside, some with little illustrations and handwritten notes. The player turns the pages. They seem to know what they're looking at.

**LANTERN:** "What's that?"

The player shows him the book.

**LANTERN:** "A recipe book!"

A pause.

**LANTERN:** "Are you a cook?"

*(Reply: hesitate, then nod.)*

**LANTERN:** "Oh!"

He floats a little higher.

**LANTERN:** "Well, that's something!"

**HERON (off):** "Come up on deck when you're ready."

**ITEM ACQUIRED: RECIPE BOOK**

GAMEPLAY BEGINS.

### Scene 3: Exploring the Salt and Ember (#185)

The player is free to explore the ship. It should feel like a small, self-contained world: old, lived-in and full of things to investigate. There are three main places: the galley, the upper deck and the navigation room.

**The galley.** A cosy, well-used space, with a stove, shelves, hanging pans and storage crates. There's no cooking pot on the stove.

- **The empty stove:** "An old stove. It looks like it's been used quite a bit."
- **The shelves:** "Rows of jars, spices and ingredients. Some are empty."
- **The storage crate:** "Food supplies. There are a few ripe tomatoes." **ITEM ACQUIRED: TOMATOES**
- **A small wooden chest** in the corner holds an old cooking knife. **ITEM ACQUIRED: COOKING KNIFE.** "An old kitchen knife. Well used, but still sharp."

**The upper deck.** It's raining lightly. Water drips from the rigging and runs along the deck. There are barrels, ropes and other equipment.

- **Rainwater:** "Fresh rainwater is collecting along the edge of the deck." The player has no pot yet, so there's nothing to do with it.

**The navigation room.** Through a door at the forward end of the corridor from the hatch ramp, beside the galley: a small room full of maps and books. Old charts cover the walls, some with strange markings.

- **The navigation chart:** one chart has a hand-drawn route through a stretch of ocean marked with a faded warning, THE GRAVE OF THE LANTERNS. A destination is marked beyond it, but the island's name is lost to age and water damage. "An old chart. Someone has marked a route through the Grave of the Lanterns. The destination appears to be an island somewhere beyond the fog."
- **The old book:** on a shelf, an old leather-bound volume with a faded lantern on its cover. "An old book about the creatures and spirits of the sea." Its yellowed pages have drawings of little lantern creatures, and a passage:

  > The little lights of the deep are creatures of warmth. Their flames are sustained by the heat of living things, and they are particularly fond of strong spices.
  >
  > When a lantern's flame grows faint, a hot broth of ripe tomatoes, red chilli and wild herbs may restore its warmth.

  The player pauses. This seems relevant. **CLUE DISCOVERED: LANTERN WARMTH**

### Scene 4: The captain (#186)

The heron stands at the helm.

**HERON:** "Settling in?"

*(Reply: nod.)*

**HERON:** "Good."

He gestures about the ship.

**HERON:** "This is the Salt and Ember. She's seen better days, but she'll get us where we need to go."

The player looks out at the ocean.

**HERON:** "We've been following an old trail. It hasn't been easy to find."

He glances at the chart.

**HERON:** "We were hoping to find something at the end of it."

*(Reply: ask what.)*

The heron pauses.

**HERON:** "Something we've been looking for a long time."

He turns back to the water.

**HERON:** "Perhaps we'll have better luck once we reach land."

*(Reply: ask about the lantern.)*

**HERON:** "He's still recovering."

**HERON:** "I've never seen him use so much of his light."

A pause.

**HERON:** "I wouldn't worry too much. He's tougher than he looks."

*(Reply: gesture towards the galley.)*

**HERON:** "Looking to cook something?"

*(Reply: nod.)*

The heron opens a storage locker nearby and takes out an old cooking pot.

**HERON:** "Here. This might help."

**ITEM ACQUIRED: COOKING POT**

**HERON:** "It's not much, but it'll do."

The player looks at the pot.

**HERON:** "Try not to burn the ship down."

### Quest 1: A little warmth (#186, #224)

The journal found beside your bunk opens to Voyage and has a Recipes section. The captain points you to the cookbook in the galley after handing over the pot. The chart room stays closed. Fresh water can be found by looking and listening on deck, or by asking the captain. Soup goes in a bowl. Both crewmates come when you ring for supper. Lantern needs spicy tomato soup to recover, and a plain batch can be finished with chilli. Spare pantry ingredients and the slops bucket make it possible to retry.

> The lantern gave nearly all of his light to save you. He's barely able to float, let alone light the way. Perhaps there's something you can do to help.

**Objective:** find a way to restore the lantern's warmth.

The quest doesn't tell the player what to do. They work it out from the books and things aboard the ship.

**Puzzle 1: Discover the clue.** The player has a recipe book with a handful of starter recipes, an old book saying that lanterns like spicy food, a cooking pot, a knife and some tomatoes.

If the player talks to the lantern:

**LANTERN:** "Oh, hello again!"

**LANTERN:** "I'm feeling a little better. I think."

His flame flickers.

**LANTERN:** "Well, perhaps not."

If the player has read the old book:

**LANTERN:** "Spicy food?"

A pause.

**LANTERN:** "I do like spicy food."

**LANTERN:** "I don't think I've ever had any, though."

If they haven't read it, he doesn't give the clue away.

**Puzzle 2: Find the ingredients.**

| Ingredient | Where |
|---|---|
| Tomatoes | The storage crate in the galley |
| Dried chilli | The pantry cupboard |
| Fresh herbs | A little pot of herbs growing by the rail on the upper deck |

**ITEM ACQUIRED: DRIED CHILLI.** **ITEM ACQUIRED: FRESH HERBS.**

**Puzzle 3: Collect the rainwater.** *As built (#186): the water butt on deck, as before, rather than a stream off the rigging (decided 2026-11-24). The captain, at the helm, goes for a drink at the butt every so often, which shows where the water is.* The player has the cooking pot and has to work out that it can be filled with rainwater. Water is collecting in several places on the upper deck, but in one spot a steady stream falls from the rigging. The player sets the pot underneath it, and it fills gradually. **ITEM ACQUIRED: POT OF RAINWATER**

**Puzzle 4: Make the soup.** Back in the galley, the stove is ready. *As built (#186): two steps, as the recipe book has it. A Tomato Soup first (rainwater boiled in the pot, then diced tomato and chopped onion), then a chopped chilli stirred in with the herbs and boiled again. The pot holds three things, and the soup you learn first is the one you build on. The chilli is the pantry's (fresh, not dried); the herbs grow in a planter against the starboard rail.*

1. Put the pot on the stove.
2. Add the rainwater.
3. Chop the tomatoes with the knife.
4. Add the tomatoes.
5. Add the dried chilli.
6. Add the fresh herbs.
7. Bring the soup to the boil.

The player can read the recipe book if they need help. The soup begins bubbling, a little steam rises, and the smell fills the galley.

### Scene 5: The first meal (#186)

The player takes the soup to the lantern at his round table.

**LANTERN:** "Oh! What's that?"

The player shows him the soup.

**LANTERN:** "Is that… for me?"

*(Reply: nod.)*

**LANTERN:** "You made that?"

*(Reply: nod again.)*

**LANTERN:** "Well, I…"

A pause.

**LANTERN:** "I've never had soup before."

The player offers him the bowl. The lantern leans towards it.

The soup begins to glow. A warm golden light spreads through the lantern's glass. His flame grows brighter.

**LANTERN:** "Oh!"

His light grows stronger. He floats upwards, spinning a little.

**LANTERN:** "Oh, that's much better!"

He circles the player.

**LANTERN:** "I feel wonderful!"

The heron appears in the doorway.

**HERON:** "Well, I'll be."

**LANTERN:** "Look! Look at me!"

**HERON:** "I can see."

**LANTERN:** "They made me soup!"

**HERON:** "Yes. I gathered that."

The lantern floats over to the player.

**LANTERN:** "Thank you."

A pause.

**LANTERN:** "I remember you reaching for me."

He looks at the player.

**LANTERN:** "I'm glad you did."

The music softens.

**QUEST COMPLETE: A LITTLE WARMTH**

### Scene 6: The journey continues (#187)

**Location:** the Salt and Ember, on deck.

The player steps out onto the deck. The weather has begun to clear: the rain is easing, and a little sunlight breaks through the clouds.

The heron stands at the helm, looking towards the horizon. The lantern floats beside him.

**LANTERN:** "Much better, isn't it?"

**HERON:** "Yes. Much."

**LANTERN:** "I was beginning to think I'd never feel warm again."

**HERON:** "Let's hope you don't make a habit of nearly putting yourself out."

**LANTERN:** "I'll try."

The player comes up.

**HERON:** "We've lost a little time, but we haven't lost our way."

He looks towards the chart.

**HERON:** "We're still heading for the island."

**LANTERN:** "Oh! I do like that island."

**HERON:** "You've never been there."

**LANTERN:** "I like the look of it."

The player looks between them.

**HERON:** "It's the last mark on the old chart. Whatever we're looking for, there's a good chance we'll find a clue there."

The lantern looks towards the horizon.

**LANTERN:** "I wonder what it'll be like."

**HERON:** "Probably wet."

**LANTERN:** "Everything's wet!"

The heron sends the player to bed. *(Lines drafted for #187; change them freely.)*

**HERON:** "Get some sleep. We'll make land by morning."

**LANTERN:** "Sleep well! I'll keep a lookout."

Talking to either of them afterwards says it again ("Bed. We'll make land by morning." / "Off to your bunk! We'll be there by morning.").

The player can now explore the ship freely. Sleeping in their bunk takes them to the next morning.

### Scene 7: Passage of time (#187)

*As built (#187, the full montage #197): about a minute, as written below. The flying fish became fish simply leaping from the water: wings made in code looked cheap. The rainwater dripping from the rigging is the last of the night's rain running off it, before the clouds part.*

**Location:** the Salt and Ember, at sea.

A short atmospheric montage as the ship sails on:

- The clouds slowly clear.
- Rainwater drips from the rigging.
- The ocean changes from dark blue to a brighter turquoise.
- Flying fish leap out of the water.
- The lantern floats about the deck, noticeably brighter than before.
- The heron studies the old chart.
- The Grave of the Lanterns slowly disappears behind the ship.

There's no dialogue through most of it. The music and the changing world say that time has passed and the ship is leaving the strange waters behind.

At last the lantern notices something in the distance.

**LANTERN:** "Captain?"

**HERON:** "Hm?"

**LANTERN:** "Look!"

### Scene 8: The first shore (#187)

*As built (#187): in the cove, the ship sails in from the fog and anchors during the scene; then "The end of the Prologue", and you're on deck. Ashore, the frying pan is in a washed-up chest a few steps from where the boat lands you.*

**Location:** approaching the island.

The camera moves out over the ocean. The mist has lifted. The sea is a brilliant turquoise, sunlight glistening across the waves. Birds fly overhead.

In the distance, a lush island emerges: palm trees above a pale beach, jungle behind it, and green hills climbing beyond.

The Salt and Ember sails towards it.

**LANTERN:** "Oh!"

He floats closer to the rail.

**LANTERN:** "Isn't it lovely?"

**HERON:** "Land at last."

**LANTERN:** "Do you think they have any tomatoes?"

**HERON:** "You had soup yesterday."

**LANTERN:** "I liked the soup."

The heron studies the island. He takes out the old chart.

**HERON:** "This is it."

**LANTERN:** "The island?"

**HERON:** "The last mark on the chart."

A pause.

**HERON:** "We've finally found it."

The lantern looks towards the island.

**LANTERN:** "So… what are we looking for?"

The heron folds the chart.

**HERON:** "That's what we're here to find out."

The player looks towards the island. The camera moves ahead of the ship, showing the whole cove. The Salt and Ember comes into the cove and drops anchor off the beach.

**HERON:** "Come along. We've got a lot to do."

**LANTERN:** "Adventure!"

**HERON:** "Supplies."

**LANTERN:** "Adventure and supplies!"

The camera pulls back from the ship at anchor.

FADE TO BLACK.

END OF PROLOGUE.

---

## Chapter 1: The first shore

You wake on deck at anchor in the cove, with the jolly boat by the rail. Row ashore. The first thing you find on the beach is a **frying pan** (an item-get), your shield for the crabs along the sand.

Still to come in Chapter 1: the harbour, the small coastal settlement, the jungle mountain and the strange old structures along the coast.
