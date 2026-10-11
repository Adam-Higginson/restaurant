# Game Design Document

Working title: **Restaurant** (TBD)

## Pitch
A cosy top-down restaurant game in the spirit of Stardew Valley. You run a small restaurant on your own in a town full of people: buy ingredients, cook, serve the townsfolk and earn money. Your restaurant becomes the town's living room, where you get to know everyone through the food you cook for them. Over time the restaurant grows into a full farm-to-table operation, where you grow and raise the ingredients you cook with.

## Pillars
1. **Cosy, not stressful.** Busy moments, but nothing burns and nobody shouts. Failing costs you a sale, never progress or friendship.
2. **People are the heart.** Every customer is someone from town with tastes, habits and a story. The rush is the seasoning, not the meal.
3. **Hands-on.** You walk your character between stations and tables. The restaurant is a place, not a menu.
4. **Farm to table (long-term).** Every dish should feel traceable to where its ingredients came from.
5. **Growth you can see.** More money leads to more dishes, a nicer restaurant, staff, a growing town and a better star rating.

## Core loop (MVP)
Time always moves, like Stardew Valley. There are no fixed phases: you choose when to open, when to close and when to go to bed.

- **The calendar:** four seasons (Spring, Summer, Autumn, Winter) of 28 days each, and 7-day weeks. Day 1 is Spring 1, a Monday, in year 1, and after Winter 28 comes Spring 1 of the next year. Dates read like "Spring 2, Tuesday".
- **The clock** runs from 6:00 to 2:00 in 10-minute steps, about 20 real minutes per day (one step every ~10 real seconds). It shows 12-hour time ("6:40 pm") by default, with a 24-hour option. It stops while any panel is open (shop, container, summary, the bed's question).
- **Light:** the room's light follows the clock: a warm dawn at 6:00, plain daylight from about 9:00, golden in the early evening, a lavender dusk around 20:30, then a dark blue night from 22:00. Lamps over the tables, in the kitchen, by the door and in the back room fade up as it gets dark (from about 18:00, fully on by 21:00) and cast warm pools of light, and walls cast shadows. The HUD and panels are never tinted.
- **Getting late:** at midnight a small "Getting late…" note appears at the top of the screen and fades away after a few seconds. It's a nudge, not a warning.
- **Morning:** you wake in bed in the back room at 6:00. Yesterday's orders are waiting in the delivery crate by the door. Carry them to the fridge and cupboard, set up the kitchen, and order tomorrow's ingredients at the shop board.
- **Open and close whenever you like** by flipping the sign on the door (E). While it says Open, townsfolk arrive, sit and order one dish. Fetch the ingredients, prepare and cook them, carry the dish to the customer and get paid. Customers left waiting too long leave without paying.
- **Mealtimes:** for now one customer comes at lunch and one at dinner (see Customers → MVP), so choosing when to be open decides who you serve. Later they trickle in at most times, with peaks around lunch (12:00–14:00) and dinner (18:00–21:00) (#54).
- **Closing:** flipping the sign to Closed stops new customers. Anyone already seated stays until they're served or run out of patience.
- **Bed:** go to bed (E on the bed) at any time to end the day. The bed asks "Go to bed?" first, adding "The restaurant will close." while it's open. If the restaurant is still open, it closes and anyone still seated leaves without paying, counting as lost. If you're still up at 2:00, you fall asleep where you stand and wake in bed. No penalty in the MVP.
- **The night:** when the day ends, the game pauses and the screen fades to black. Behind it the next day starts and you're moved to the bed. The new date fades in as a title card ("Spring 2, Tuesday"), holds for a moment, then the screen fades back in on the morning at 6:00. About 4 seconds in all.
- **Summary:** when the day ends, a summary shows earnings, ingredients spent, customers served and customers lost, between the fade to black and the morning. Continue to the next morning. (Not built yet: today the night goes straight to the morning.)

Everything stays where you left it between days: ingredients in storage or the crate, and food on counters. Nothing decays in the MVP.

## Player
- One character, top-down 4-direction movement.
- Acts on the object in front of them (containers, counters, the stove, pans, tables, the shop board, the door sign, the bed).
- **Arms:** carries up to **3 items** stacked above their head: ingredients, prepared food, and utensils (chopping board, frying pan, saucepan, plates, bowls). A plate or bowl carries whatever is on it. Each item takes one slot. The stack bobs as they walk. Utensils are carried from place to place like food; they never go on the belt.
- **Tool belt:** a small row of slots (4) for hand tools, always with you. The MVP has one tool, the knife. One slot is selected at a time. Tools can only be used with empty arms: put everything down first.

### Controls
Three separate buttons, so each one always means the same thing: **pick up / put down** moves things, **interact** works things, **use tool** uses the selected belt tool.

| Action | Keyboard | Controller (Xbox naming) | Does |
|---|---|---|---|
| Move | WASD / arrows | Left stick / D-pad | Walk in 4 directions |
| Pick up / put down | Space | A | Take the top item from a counter, board or pan (or an empty utensil itself), or a whole plate or bowl. Put your top item on a counter, into a utensil, or into a container. Bring a bowl or plate to a pan to tip the pan into it. |
| Interact | E | X | Turn a burner on or off, fill a pan at the sink, take a clean plate or bowl from the rack, open a container, flip the door sign, go to bed |
| Use tool | F | B | Use the selected belt tool on what you're facing (the knife chops). Empty arms only. |
| Rotate stack | Q | Right bumper | Rotate the stack, so a different item is on top |
| Select belt slot | 1–4 / scroll | Left bumper (cycle) | Choose the active tool. Cycling goes through every slot, empty ones too. |

Only the top item of the stack is active: put down uses that one, and anything you pick up goes on top.

Each action is a named action in Godot's Input Map with both the keyboard and the controller bound, so gameplay code never checks a specific key or button. Core play must never need the mouse, and panels (shop, containers, summary) must be usable with the D-pad.

## Starting kit (day one)
| Thing | Kind | Starts |
|---|---|---|
| Cheap chef's knife | Belt tool | On the belt |
| Basic chopping board | Utensil (carried in arms) | On a counter |
| Basic frying pan | Utensil (carried in arms) | On a stove burner |
| Basic saucepan | Utensil (carried in arms) | On the other stove burner |
| Basic fridge (12 slots) | Storage furniture | Placed in the kitchen |
| Basic cupboard (12 slots) | Storage furniture | Placed in the kitchen |
| Plate rack, bowl rack | Fixed kitchen fittings | Always give a clean plate or bowl (Interact) |
| Counters, stove (2 burners), sink | Fixed kitchen fittings | Placed in the kitchen |

## Storage
- The **fridge** holds chilled food, and the **cupboard** holds dry food. Every food item says which kind of storage it needs.
- Containers have a fixed number of slots, and each item uses one. Bigger containers are a later upgrade.
- Interact on a container opens a small panel showing its contents. Picking an item puts it in your arms if you have space. Put down on a container while your top item is food it accepts puts it away.
- Containers hold any **solid** food, raw or prepared, so you can prep ahead: chop tomatoes and onions in the morning, or make sandwiches ready to fry. Each slot holds one piece of food, keeping its quality. Liquids can't be stored in the MVP (jars are on the roadmap).
- Bought ingredients arrive in the **delivery crate** by the door at 6:00 the next morning. The crate has no limit and works like a container you can only take from.
- Furniture is fixed in place in the MVP. Later it can be moved (see the roadmap).

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
- **Timed** elements stay while their source does and count seconds. A lit burner provides **fire** to the pan on it, so any heat source (a stove now, an oven or campfire later) works for any fire recipe. Turning the burner off pauses reactions without losing progress.

A vessel keeps checking its contents. **Every reaction whose items are all present runs**, each with its own progress, moving forward while its elements are present, so a potato and a carrot can boil side by side in the same water. Consumed food is claimed by its reaction; required items can be shared. If two reactions want the same food, the one that uses more items wins, even taking over from a smaller reaction that already started. Taking food out of a vessel cancels its reactions, losing their progress. When a reaction finishes, its consumed food is swapped for the result, which may let the next reaction start.

**Building up beats dumping in.** Because each step makes a new intermediate item, the order you add things matters without the game tracking it. A sauce built up step by step (oil, then garlic, then tomato) goes through the proper reactions. Dumping everything in at once triggers a separate, designed **shortcut reaction** that gives the same dish at a lower quality. Cooking never fails outright and never burns.

### Quality
- Each piece of food has a quality from ★ to ★★★. Shop ingredients and water from the sink are ★, the normal quality.
- Each reaction has a quality: proper steps are ★★★, shortcuts are ★.
- A reaction's result is the average of its ingredients' average quality and the reaction's own quality, **rounded up**. One rushed step pulls a dish down a little, and careful steps afterwards pull it back up.
- Quality only ever adds: a ★ dish pays the menu price, ★★ adds a 25% tip and ★★★ a 50% tip.

### Vessels and fittings
- **Counter:** holds one item, food or a utensil.
- **Chopping board:** holds one food item (a bigger board can be an upgrade later). With empty arms and the knife selected, each Use tool on the board's counter is one cut. A progress bar shows how far the current cut level is. Pick up takes the food off (losing progress towards the next cut level), and only an empty board is picked up itself. Its food would travel with it, like a plate's.
- **Plate and bowl:** hold up to 3 food items, and assemble what's on them instantly when it matches a reaction (chopped lettuce + sliced tomato on a plate → Garden Salad). Food goes on while the plate sits on a counter. Pick up always takes the plate whole, with its food, and customers are served it that way. Food that matches nothing just sits there; there's no way to take it back off yet (a bin is a possible follow-up). Racks give clean ones without limit (Interact); washing up is on the roadmap.
- **Vessels don't nest:** only food goes into a board, plate, bowl or pan, never another utensil.
- **Saucepan and frying pan:** hold up to 3 food items, and cook on the two-burner stove. Interact turns a burner on or off. A progress bar shows each running reaction. Finished food waits in the pan.
- **Sink:** Interact with a saucepan at the sink fills it with water.
- **Getting food out of a pan:** pick up takes the top solid item. Bring a plate or bowl and the pan's whole contents, liquids and solids, are tipped into it. Each food item is either a liquid (water, boiling water, soup) or a solid.
- The intended fun is juggling: both burners cook on their own while you chop, plate and serve.

## MVP menu
| Dish | Proper (★★★) | Shortcut (★ or ★★) | Price |
|---|---|---|---|
| Garden Salad | Chop lettuce, slice tomato, put both on a plate | Whole lettuce and tomato on a plate | 12 |
| Tomato Soup | Fill the saucepan at the sink, boil it (4s) → boiling water. Add diced tomato and chopped onion, boil (8s). Tip it into a bowl. | Diced tomato and chopped onion into cold water, then turn the burner on (12s) | 18 |
| Grilled Cheese | Bread + cheese on a plate → sandwich. Melt butter in the hot frying pan (2s), add the sandwich, fry (6s). | Sandwich straight into the frying pan without butter (6s) | 15 |

| Ingredient | Storage | Shop price |
|---|---|---|
| Lettuce | Fridge | 3 |
| Tomato | Fridge | 3 |
| Cheese | Fridge | 4 |
| Butter | Fridge | 2 |
| Onion | Cupboard | 2 |
| Bread | Cupboard | 3 |

Worked example: a tomato (★) sliced properly gives (1 + 3) / 2 = ★★ sliced tomato. Chopped lettuce and sliced tomato (both ★★) on a plate give (2 + 3) / 2 = 2.5, rounded up to a ★★★ Garden Salad. Whole lettuce and tomato on a plate give (1 + 1) / 2 = a ★ salad.

Water is free from the sink. Tomato is shared by two dishes, which makes stocking up a small decision. The numbers are starting points for balancing.

## Customers
Customers are **townsfolk**: a fixed cast of hand-written people, like Stardew Valley's villagers. Every face in the dining room is someone with a name, tastes, habits and a story. Getting to know them is the heart of the game, and the cooking rush is the seasoning.

### Vision (long-term)
- **The cast:** about 25–30 townsfolk in the full game. For now you only meet them in the restaurant: their lives happen offstage and you hear about them over meals. A walkable town comes later.
- **Why they visit:** each person has a routine (the blacksmith comes for lunch on weekdays, the night-owl writer drops in late), so your opening hours decide who you meet. Weather, town events and how much they like you vary it. Your menu and reputation draw new people in: putting soup on the menu might be what finally brings the soup lover through the door.
- **Ordering:** each person has hidden **loves, likes and dislikes**. They order from your menu by taste, and you discover their preferences by watching and chatting. Sometimes they ask for a **craving** ("something warm", "something with cheese") or an off-menu dish instead, which becomes a small goal.
- **Waiting:** each person has their own patience. The retired teacher will wait all evening; the busy builder won't. When patience runs out they leave politely ("I'll pop back another time"): you lose the sale, never friendship. Next visit they might tease you about it, with no mechanical cost.
- **Getting to know them:** friendship grows by serving dishes they like (loved dishes and high quality count most), chatting to them at their table, and giving gifts. Each person has a written **storyline** that advances as friendship grows, with moments you help through cooking: a birthday cake, a comfort meal after bad news.
- **What friendship gives you:** family recipes and techniques, ingredients and new suppliers (the farmer drops off eggs), friends you can hire as staff, and friends who wait longer, tip more and bring others along.
- **A social room:** friends, families and couples arrive together and share a table. You overhear chatter as you walk past: gossip, story hints, reactions to your food. The town's own stories happen in your restaurant: first dates, reconciliations, birthday parties.
- **Pacing:** busy but player-paced. The room fills to match your capacity (tables and menu), new arrivals wait for seats to free up, and patience is generous. Lively, rarely frantic.
- **Reputation:** a visible **star rating** that rises with good service and quality and unlocks things such as newcomers moving to town. **Critics** visit to award Michelin-style stars. Their visits are announced ahead (a letter, town gossip) so you can prepare. A bad review just means trying again next season. You never lose stars.
- **New arrivals:** the town starts with a smaller cast and new people move in as your reputation grows, so each newcomer is an event.

### MVP
- **The cast:** 6 townsfolk, each a `Person` resource with a name, a placeholder colour, loved, liked and disliked dishes, and their patience in real seconds:

  | Name | Who | Patience | Loves | Likes | Dislikes |
  |---|---|---|---|---|---|
  | Bram | blacksmith | 90 s | Grilled Cheese | Tomato Soup | Garden Salad |
  | Wren | retired teacher | 180 s | Tomato Soup | Garden Salad | – |
  | Milo | builder | 90 s | Grilled Cheese | Garden Salad | – |
  | Pip | schoolkid | 120 s | Garden Salad | Grilled Cheese | Tomato Soup |
  | Isla | night-owl writer | 120 s | Garden Salad | Tomato Soup | – |
  | Hazel | farmer | 150 s | Tomato Soup | Garden Salad | Grilled Cheese |

- **Arriving:** on a fixed schedule for now: one customer at lunch (due 12:30) and one at dinner (due 19:00), each at most once a day. If the restaurant isn't open when they're due, they come as soon as it opens, until 14:00 for lunch and 21:00 for dinner; after that, nobody comes for that meal. Random arrivals with mealtime peaks may replace this (#54), and personal routines come later.
- **Who comes:** a random townsperson who isn't already inside and has something on the menu they'd order. Someone who dislikes every dish on the menu never comes. They walk in from the door and find their way around the tables to a random free table's seat. If every table is full or nobody can come, the arrival is skipped.
- **Walking:** customers walk through the player and each other rather than bumping (#53 decides whether to keep this).
- **Ordering:** they pick a dish from the menu weighted by taste: a loved dish counts 3, a liked one 2, anything else 1, and a disliked dish is never ordered. The order shows in a speech bubble above their head, with their name below them. The menu is Garden Salad (12) for now; Tomato Soup and Grilled Cheese join it when they can be cooked (#37, #38).
- **Patience:** a bar above their head drains in real time while they wait at the table, and pauses whenever the clock does (any panel open). If it empties they say "I'll pop back another time" and walk out of the door, and the sale is lost.
- **Closing and the night:** flipping the sign to Closed doesn't send seated customers away. Anyone still inside when the day ends is gone by the morning (counting them as lost comes with #10).
- **Serving:** put down the plate or bowl holding the dish they ordered while facing them. They pay the menu price plus the quality tip (★★ +25%, ★★★ +50%). A **loved dish** also shows a heart and adds a bonus tip of 25% of the price (a starting number for balancing). A wrong dish isn't accepted. They eat briefly, then leave with the plate or bowl and free the table.
- **Tables:** 4 tables, one diner each. Groups come later.
- Not in the MVP: routines, friendship, chatting, gifts, storylines, cravings, groups, the star rating and critics.

## Economy
- Start with 50 coins and empty storage. On day one a starter delivery is waiting in the crate (2 of each ingredient), so there's something to cook before your first order arrives.
- Money is spent in the shop and earned from customers (menu price plus quality tips). No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, clock, and whether the restaurant is open. Until the HUD is built (#13), a temporary label in the top left shows the date, time and open state ("Spring 3, Wednesday · 6:40 pm · Open").
- **Question panel:** a small yes/no question ("Go to bed?") with an optional detail line. It pauses the game while open, Yes has focus so a controller can answer, and Esc or cancel means No.
- **Night fade:** a full-screen fade to black with the new date as a title card, drawn above everything else.
- **Notices:** short notes at the top centre ("Getting late…") that fade in, stay for 3 seconds and fade away by themselves. A new note replaces the old one.
- **Belt bar** showing the belt slots and the selected tool, dimmed while the arms aren't empty.
- **Held item label** above the belt bar naming the top carried item and its quality ("Sliced Tomato ★★", "Plate: Garden Salad ★★★").
- **Quality pips:** food in the world shows 1–3 small dots for its stars, as a placeholder until there's real art.
- **Shop panel** at the shop board by the door. Orders arrive the next morning.
- **Container panel** for taking food out of the fridge, cupboard and crate.
- **End-of-day summary** screen, including tips.

## Architecture notes
- Definitions are `Resource` files under `res://data/`, listed in `res://data/catalog.tres` (`Catalog`):
  - `Item` (`data/items/`): anything physical. Every food state (tomato, sliced tomato, Garden Salad) and every utensil (chopping board, plate). A vessel has a `capacity` (how much food fits; 0 for everything else) and `carried_whole` (plates and bowls yes, boards and pans no). Fields like liquid/solid (#37) and storage kind (#32) are added when a feature needs them.
  - `Element` (`data/elements/`): cut, fire, later cold. Instant or timed.
  - `HandTool` (`data/tools/`): a belt tool, and the `Element` it applies (the knife applies cut). Kept apart from `Item` because tools never go in the arms.
  - `Reaction` (`data/reactions/`): consumed items, required items (including the vessel), elements, amount, result and quality.
  - Prices aren't on items: the shop (#12) and the menu (#9) hold what's sold and for how much, so anything can be bought or put on the menu.
- Definitions are shared and never change. A physical thing in the world is an `ItemInstance` (`scripts/cooking/`) pointing at its `Item` and holding its own quality (and later freshness). Arms, vessels and counters hold these. A vessel's instance also owns its `VesselContents`, so its food goes wherever it goes.
- A `Counter` passes pick up, put down and Use tool through to a vessel on it. A stove burner can be a counter that also adds fire. `ItemDraw` (`scripts/visuals/`) draws any instance, its food and its progress the same way on counters, in the arms and later on the stove.
- A `Dispenser` prop gives a fresh item on Interact without limit: the plate rack, and (temporarily, until storage #32) a lettuce bin and a tomato bin.
- `VesselContents` is the cooking logic of one vessel, with no nodes, so it's unit tested on its own. Its changes (`add_item`, `remove_item`, `add_element`, `remove_element`, `tick`) run the reaction engine inside them; its `get_` methods only read. Board and pan nodes feed it input and time, and redraw from its signals (`contents_changed`, `reaction_started`, `reaction_progressed`, `reaction_cancelled`, `reaction_finished`).
- Arms, the tool belt and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- Interact, pick up and use tool are routed the same way: the player's `InteractionDetector` sends each press to the focused `Interactable`, which emits `interacted`, `pick_up_pressed` or `tool_used(player, tool)` for its prop to handle. The empty-arms rule for tools is checked there.
- A container's contents are a list of food objects with a capacity, with no notion of where the food came from. Today the shop fills it; later farms will too. It replaces the existing `Pantry` counts store.
- Each townsperson is a `Person` resource (`data/people/`): name, placeholder colour, loved, liked and disliked dishes, and patience. Later it grows routines, friendship and a storyline. A customer in the dining room is a `Customer` node (`scenes/customer.tscn`) pointing at its `Person` and its order, and each townsperson is inside at most once.
- Money and the day number live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. The global `Game.pantry` goes away when storage containers are built.
- The clock and the restaurant's open/closed state are gameplay state too, replacing the old prep/service/summary phases. `Game` holds a `GameClock` (`scripts/time/`, no nodes) and the open state, with `set_open()`, `end_day()` and `start_next_day()`. Other code listens to its signals: `time_changed`, `open_changed`, `day_ended` and `day_changed`. The clock emits `reached_end` at 2:00 and `Game` ends the day; it never ends the day itself. Each open panel pauses it as its own source, so closing one can't restart it while another is open. `Calendar` (`scripts/time/`) is static functions turning a day number into a season, weekday and year.
- `DayCycle` (`scripts/time/day_cycle.gd`, a node in the main scene) runs the day: it ticks the clock with real time, shows the midnight note, and plays the night when `day_ended` fires. The night is one function that awaits each step in turn (fade out, start the next day, move the player to the `WakeSpot` marker, show the date, fade in) and emits `morning_started` at the end. The game is paused throughout, and the fade keeps running because its process mode is Always.
- `ScreenFade` and `Notice` (`ui/`) are display only: the day cycle decides when they show and what they say. Each animates with its own Tween, and `ScreenFade`'s methods can be awaited.
- `DayLight` (`scripts/visuals/day_light.gd`) is a `CanvasModulate` in the main scene. A `Gradient` sets the room's colour and a `Curve` the lamps' level, both keyed from 6:00 (0) to 2:00 (1) and editable in the Inspector. Each clock step drifts to the new values with a one-second tween; a new day snaps straight to the morning. Each `Lamp` prop (`scenes/props/lamp.tscn`) is a `PointLight2D` with a radial texture and a per-lamp `max_energy`, and joins the `lamps` group so the day light finds every lamp without knowing where they are. Solid tiles in the placeholder tileset have occluders on its occlusion layer, so walls cast shadows.
- The menu is a `Menu` resource (`data/menu.tres`): a `Dictionary[Item, int]` of dishes and prices.
- `CustomerSpawner` (`scripts/customers/`, a node in the main scene) brings customers in. An `ArrivalPlanner` (no nodes) decides when, from `Arrival` resources (`data/arrivals/`, a due time and an until time each), checked on every clock step and when the sign opens. The spawner picks who and which table with a `RandomNumberGenerator` that tests seed, tracks which tables are taken, and clears everyone on `day_changed`, behind the night's black screen. A `Customer` walks with a `NavigationAgent2D`, waits with a `PatienceMeter` (no nodes), and emits `seated` and `left`.
- `FloorNavigation` (`scripts/navigation/`, a `NavigationRegion2D` in the restaurant) bakes the walkable floor when the scene starts, cutting out the collision shapes of everything in the `navigation_source` group (the tiles and the props), so it always matches the layout. Debug → Visible Navigation shows it while the game runs.
- `DebugKeys` (`scripts/debug/`) gives testing shortcuts in debug builds only: F9 skips an hour, F10 toggles ×20 fast forward, F11 brings a customer in now.
- Orders placed at the shop are held as pending until the next morning, then moved into the crate.

## Out of scope for the MVP
Saving and loading, menus and settings, friendship and the other long-term customer features (see Customers), real art and audio, decor and upgrades, multiple customers per table, ingredient decay, moving furniture, energy, washing up, the sieve, the ladle, and storing liquids.

## Future roadmap
Rough order, all post-MVP:
1. Save and load.
2. More dishes that show off building up (marinara: oil, then garlic, then tomato; boiled potatoes), staples like oil and salt, tools (whisk, peeler) and stations (oven, grill).
3. **Cold** as a timed element provided by the fridge (or a freezer), for chilled recipes like jelly, ice cream or a set cheesecake.
4. Reactions with several results: splitting (a loaf into slices) and byproducts (an egg and its shell). Needs a rule for results that don't fit in the vessel.
5. **Sieve:** bring a sieve and a bowl to a pan, and the solids go into the bowl while the liquid stays in the pan, ready for the next batch.
6. **Ladle and servings:** one pot of soup serves several bowls, ladled out one at a time.
7. **Jars and bottles:** bring a jar to a pan and the liquid pours in, solids stay behind. Jars go in the fridge or cupboard and pour back into a pan later, so you can make garlic oil in the morning for the evening's sauces.
8. Washing up: served plates and bowls come back dirty and need washing at the sink.
9. Movable furniture: lift a fridge or cupboard above your head with empty arms (it must be empty inside) and place it elsewhere.
10. Ingredient decay: food loses freshness over time, slower in the fridge. Fresher food earns more.
11. Energy: how much you slept sets the next day's energy. Low energy makes you walk and chop a bit slower, but never stops you playing.
12. Restaurant upgrades: more tables, decor, better utensils (a faster knife, a bigger pan).
13. Atmosphere: windows that show the sky changing with the time of day (#50), and a light switch so the player can turn the lamps on and off (#51).
14. **Farming:** plant, water and harvest crops that fill your storage. Later, animals for eggs, milk and cheese.
15. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
16. **Townsfolk and friendship:** routines, friendship from serving, chatting and gifts, storylines, cravings, and the cast growing towards 25–30 (design epic #46).
17. **Reputation and critics:** a star rating, announced critic visits and Michelin-style stars (design epic #47).
18. **Groups and social dining:** groups and couples sharing tables, overheard chatter, town events in the restaurant (design epic #48).
19. Hiring staff (waiter, cook) from among your friends, to automate parts of the loop.
20. A walkable town where townsfolk live out their routines.
21. Seasons that affect crops and the menu.
22. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
