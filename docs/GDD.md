# Game Design Document

Working title: **Restaurant** (TBD)

## Pitch
A cosy top-down restaurant game in the spirit of Stardew Valley. You run a small restaurant on your own: buy ingredients, cook, serve customers and earn money. Over time the restaurant grows into a full farm-to-table operation, where you grow and raise the ingredients you cook with.

## Pillars
1. **Cosy, not stressful.** Busy moments, but nothing burns and nobody shouts. Failing costs you a sale, never progress.
2. **Hands-on.** You walk your character between stations and tables. The restaurant is a place, not a menu.
3. **Farm to table (long-term).** Every dish should feel traceable to where its ingredients came from.
4. **Growth you can see.** More money leads to more dishes, a nicer restaurant, staff and regulars.

## Core loop (MVP)
Time always moves, like Stardew Valley. There are no fixed phases: you choose when to open, when to close and when to go to bed.

- **The clock** runs from 6:00 to 2:00 in 10-minute steps, about 20 real minutes per day (one step every ~10 real seconds). It stops while any panel is open (shop, container, summary).
- **Morning:** you wake in bed in the back room at 6:00. Yesterday's orders are waiting in the delivery crate by the door. Carry them to the fridge and cupboard, set up the kitchen, and order tomorrow's ingredients at the shop board.
- **Open and close whenever you like** by flipping the sign on the door (E). While it says Open, customers arrive, sit and order one dish. Fetch the ingredients, prepare and cook them, carry the dish to the customer and get paid. Customers left waiting too long leave without paying.
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
| Select belt slot | 1–4 / scroll | Left bumper (cycle) | Choose the active tool |

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
| Plate rack, bowl rack | Fixed kitchen fittings | Always give a clean plate or bowl |
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
- **Chopping board:** holds one food item. With empty arms and the knife selected, each Use tool is one cut.
- **Plate and bowl:** hold food, and assemble what's on them instantly when it matches a reaction (chopped lettuce + sliced tomato on a plate → Garden Salad). Customers are served the plate or bowl, which you carry whole. Racks give clean ones without limit; washing up is on the roadmap.
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
- Spawn at the door while the restaurant is open, more often at mealtimes. They walk to a free table and sit.
- Order a random dish from the menu, shown in a speech bubble.
- Have a patience meter that drains while they wait for their food. If it empties they leave and you lose the sale.
- Serving the correct dish (on its plate or in its bowl) pays the dish price, plus a tip for ★★ or ★★★ quality. The customer eats briefly, then leaves and frees the table. The plate or bowl goes with them.
- MVP: 4 tables, one customer per table.

## Economy
- Start with 50 coins and empty storage. On day one a starter delivery is waiting in the crate (2 of each ingredient), so there's something to cook before your first order arrives.
- Money is spent in the shop and earned from customers (menu price plus quality tips). No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, clock, and whether the restaurant is open.
- **Belt bar** showing the belt slots and the selected tool.
- **Shop panel** at the shop board by the door. Orders arrive the next morning.
- **Container panel** for taking food out of the fridge, cupboard and crate.
- **End-of-day summary** screen, including tips.

## Architecture notes
- Definitions are `Resource` files under `res://data/`, listed in `res://data/catalog.tres` (`Catalog`):
  - `Item` (`data/items/`): anything physical. Every food state (tomato, sliced tomato, Garden Salad) and every utensil (chopping board, plate). Fields like liquid/solid (#37) and storage kind (#32) are added when a feature needs them.
  - `Element` (`data/elements/`): cut, fire, later cold. Instant or timed.
  - `Reaction` (`data/reactions/`): consumed items, required items (including the vessel), elements, amount, result and quality.
  - Prices aren't on items: the shop (#12) and the menu (#9) hold what's sold and for how much, so anything can be bought or put on the menu.
- Definitions are shared and never change. A physical thing in the world is an `ItemInstance` (`scripts/cooking/`) pointing at its `Item` and holding its own quality (and later freshness). Arms, vessels and counters hold these.
- `VesselContents` is the cooking logic of one vessel, with no nodes, so it's unit tested on its own. Its changes (`add_item`, `remove_item`, `add_element`, `remove_element`, `tick`) run the reaction engine inside them; its `get_` methods only read. Board and pan nodes feed it input and time, and redraw from its signals (`contents_changed`, `reaction_started`, `reaction_progressed`, `reaction_cancelled`, `reaction_finished`).
- Arms, the tool belt and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- A container's contents are a list of food objects with a capacity, with no notion of where the food came from. Today the shop fills it; later farms will too. It replaces the existing `Pantry` counts store.
- Money and the day number live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. The global `Game.pantry` goes away when storage containers are built.
- The clock and the restaurant's open/closed state are gameplay state too, replacing the old prep/service/summary phases (`start_service()`, `end_service()`, `start_next_day()`). Other code listens to signals such as the time changing, the restaurant opening or closing, and the day ending.
- Orders placed at the shop are held as pending until the next morning, then moved into the crate.

## Out of scope for the MVP
Saving and loading, menus and settings, real art and audio, decor and upgrades, multiple customers per table, ingredient decay, moving furniture, energy, washing up, the sieve, the ladle, and storing liquids.

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
15. Regulars with names, favourite dishes and relationship levels.
16. Hiring staff (waiter, cook) to automate parts of the loop.
17. Seasons that affect crops and the menu.
18. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
