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

- **The clock** runs from 6:00 to 2:00 in 10-minute steps, about 20 real minutes per day (one step every ~10 real seconds). It stops while any panel is open (shop, container, summary).
- **Morning:** you wake in bed in the back room at 6:00. Yesterday's orders are waiting in the delivery crate by the door. Carry them to the fridge and cupboard, set up the kitchen, and order tomorrow's ingredients at the shop board.
- **Open and close whenever you like** by flipping the sign on the door (E). While it says Open, townsfolk arrive, sit and order one dish. Fetch the ingredients, prepare and cook them, carry the dish to the customer and get paid. Customers left waiting too long leave without paying.
- **Mealtime rushes:** customers trickle in at most times, with peaks around lunch (12:00–14:00) and dinner (18:00–21:00). Choosing when to be open is part of the game.
- **Closing:** flipping the sign to Closed stops new customers. Anyone already seated stays until they're served or run out of patience.
- **Bed:** go to bed (E on the bed) at any time to end the day. If the restaurant is still open, it closes and anyone still seated leaves without paying, counting as lost. If you're still up at 2:00, you fall asleep where you stand and wake in bed. No penalty in the MVP.
- **Summary:** when the day ends, a summary shows earnings, ingredients spent, customers served and customers lost. Continue to the next morning.

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
- **The cast:** 6 townsfolk, each a `Person` resource with a name, a placeholder colour, loved and liked dishes, and their patience.
- **Arriving:** while the restaurant is open, a random townsperson who isn't already inside walks in from the door, more often at mealtimes, and sits at a free table. If every table is full, nobody new arrives. Personal routines come later.
- **Ordering:** they pick a dish from the menu weighted by taste (loved dishes most, then liked, then anything else on the menu), never one they dislike. The order shows in a speech bubble.
- **Patience:** a meter drains at that person's rate while they wait. If it empties they leave politely and the sale is lost.
- **Serving:** put down the plate or bowl holding the dish they ordered while facing them. They pay the menu price plus the quality tip (★★ +25%, ★★★ +50%). A **loved dish** also shows a heart and adds a bonus tip of 25% of the price (a starting number for balancing). A wrong dish isn't accepted. They eat briefly, then leave with the plate or bowl and free the table.
- **Tables:** 4 tables, one diner each. Groups come later.
- Not in the MVP: routines, friendship, chatting, gifts, storylines, cravings, groups, the star rating and critics.

## Economy
- Start with 50 coins and empty storage. On day one a starter delivery is waiting in the crate (2 of each ingredient), so there's something to cook before your first order arrives.
- Money is spent in the shop and earned from customers (menu price plus quality tips). No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, clock, and whether the restaurant is open.
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
- Each townsperson is a `Person` resource (`data/people/`): name, placeholder colour, loved, liked and disliked dishes, and patience. Later it grows routines, friendship and a storyline. A customer in the dining room is a node pointing at its `Person`, and at most one is inside at a time.
- Money and the day number live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. The global `Game.pantry` goes away when storage containers are built.
- The clock and the restaurant's open/closed state are gameplay state too, replacing the old prep/service/summary phases (`start_service()`, `end_service()`, `start_next_day()`). Other code listens to signals such as the time changing, the restaurant opening or closing, and the day ending.
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
13. **Farming:** plant, water and harvest crops that fill your storage. Later, animals for eggs, milk and cheese.
14. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
15. **Townsfolk and friendship:** routines, friendship from serving, chatting and gifts, storylines, cravings, and the cast growing towards 25–30 (design epic #46).
16. **Reputation and critics:** a star rating, announced critic visits and Michelin-style stars (design epic #47).
17. **Groups and social dining:** groups and couples sharing tables, overheard chatter, town events in the restaurant (design epic #48).
18. Hiring staff (waiter, cook) from among your friends, to automate parts of the loop.
19. A walkable town where townsfolk live out their routines.
20. Seasons that affect crops and the menu.
21. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
