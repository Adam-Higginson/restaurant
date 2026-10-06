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
- The **fridge** holds chilled ingredients, and the **cupboard** holds dry ones. Each ingredient says which kind of storage it needs.
- Containers have a fixed number of slots, and each item uses one. Bigger containers are a later upgrade.
- Interact on a container opens a small panel showing its contents. Picking an ingredient puts it in your arms if you have space. Put down on a container while your top item is an ingredient it accepts puts that ingredient away.
- Containers hold raw ingredients only, not prepared food or dishes. Shop ingredients all arrive at the same quality (★), so a container only needs to count them.
- Bought ingredients arrive in the **delivery crate** by the door at 6:00 the next morning. The crate has no limit and works like a container you can only take from.
- Furniture is fixed in place in the MVP. Later it can be moved (see the roadmap).

## Cooking
Cooking is hands-on and works like a small chemistry system, in the spirit of Breath of the Wild: food reacts to where you put it. Every state food can be in is a named, designed item (tomato, chopped tomato, boiling water, tomato soup), so only combinations someone designed exist. Anything else simply doesn't react.

### Reactions
A **reaction** is a rule: in a given **vessel**, under given **conditions**, a set of food turns into a result after some time.

- **Vessel:** where it happens: chopping board, frying pan, saucepan, plate or bowl.
- **Conditions:** what the vessel needs: the burner under it switched on (heat), or a tool being used on it (the knife).
- **Consumed:** the food that gets used up.
- **Kept:** food that must be present but isn't used up, like the boiling water a potato boils in.
- **Time:** seconds of heat, chops with the knife, or instant.
- **Result:** the food that comes out, and the reaction's **quality** (see below).

A vessel keeps checking its contents. **Every reaction whose food is all present and whose conditions hold runs**, each with its own timer, so a potato and a carrot can boil side by side in the same water. Food taking part in a reaction is claimed by it. If two reactions want the same food, the one that uses more food wins. When a reaction finishes, its consumed food is swapped for the result, which may let the next reaction start.

**Building up beats dumping in.** Because each step makes a new intermediate item, the order you add things matters without the game tracking it. A sauce built up step by step (oil, then garlic, then tomato) goes through the proper reactions. Dumping everything in at once triggers a separate, designed **shortcut reaction** that gives the same dish at a lower quality. Cooking never fails outright and never burns.

### Quality
- Each piece of food has a quality from ★ to ★★★. Shop ingredients and water from the sink are ★, the normal quality.
- Each reaction has a quality: proper steps are ★★★, shortcuts are ★.
- A reaction's result is the average of its ingredients' average quality and the reaction's own quality, **rounded up**. One rushed step pulls a dish down a little, and careful steps afterwards pull it back up.
- Quality only ever adds: a ★ dish pays the menu price, ★★ adds a 25% tip and ★★★ a 50% tip.

### Vessels and fittings
- **Counter:** holds one item, food or a utensil.
- **Chopping board:** holds up to 3 food items. With empty arms and the knife selected, Use tool chops (a few presses).
- **Plate and bowl:** hold food, and assemble what's on them instantly when it matches a reaction (chopped lettuce + chopped tomato on a plate → Garden Salad). Customers are served the plate or bowl, which you carry whole. Racks give clean ones without limit; washing up is on the roadmap.
- **Saucepan and frying pan:** hold up to 3 food items, and cook on the two-burner stove. Interact turns a burner on or off. A progress bar shows each running reaction. Finished food waits in the pan.
- **Sink:** Interact with a saucepan at the sink fills it with water.
- **Getting food out of a pan:** pick up takes the top solid item. Bring a plate or bowl and the pan's whole contents, liquids and solids, are tipped into it. Each food item is either a liquid (water, boiling water, soup) or a solid.
- The intended fun is juggling: both burners cook on their own while you chop, plate and serve.

## MVP menu
| Dish | Proper (★★★) | Shortcut (★ or ★★) | Price |
|---|---|---|---|
| Garden Salad | Chop lettuce, chop tomato, put both on a plate | Whole lettuce and tomato on a plate | 12 |
| Tomato Soup | Fill the saucepan at the sink, boil it (4s) → boiling water. Add chopped tomato and chopped onion, boil (8s). Tip it into a bowl. | Chopped tomato and onion into cold water, then turn the burner on (12s) | 18 |
| Grilled Cheese | Bread + cheese on a plate → sandwich. Melt butter in the hot frying pan (2s), add the sandwich, fry (6s). | Sandwich straight into the frying pan without butter (6s) | 15 |

| Ingredient | Storage | Shop price |
|---|---|---|
| Lettuce | Fridge | 3 |
| Tomato | Fridge | 3 |
| Cheese | Fridge | 4 |
| Butter | Fridge | 2 |
| Onion | Cupboard | 2 |
| Bread | Cupboard | 3 |

Worked example: a tomato (★) chopped properly gives (1 + 3) / 2 = ★★ chopped tomato. Chopped lettuce and chopped tomato (both ★★) on a plate give (2 + 3) / 2 = 2.5, rounded up to a ★★★ Garden Salad. Whole lettuce and tomato on a plate give (1 + 1) / 2 = a ★ salad.

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
- **Container panel** for taking ingredients out of the fridge, cupboard and crate.
- **End-of-day summary** screen, including tips.

## Architecture notes
- Every food state is a `Resource` definition under `res://data/`: ingredients, prepared food (chopped tomato, boiling water, a sandwich) and dishes. Each says whether it's a liquid or a solid. Anything that can be carried in your arms shares a holdable-item base; food is one kind, and utensils will be another. Customers order from the dishes on the menu.
- Reactions are `Resource` definitions too: vessel, conditions, consumed food, kept food, time, result and quality. The matching rules (per-reaction matching, claiming, more-food-wins, quality averaging) are plain gameplay logic with no scenes, so they can be unit tested on their own.
- Definitions are shared and never change. A piece of food in the world is a small runtime object pointing at its definition and holding its own quality (and later freshness). Arms, vessels and counters hold these objects. Vessels also hold the running reactions and their timers.
- Arms, the tool belt and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- A container's contents are a store of ingredient counts with a capacity, with no notion of where ingredients came from. Today the shop fills it; later farms will too. The existing `Pantry` class (counts per ingredient) can become this store.
- Money and the day number live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. The global `Game.pantry` goes away when storage containers are built.
- The clock and the restaurant's open/closed state are gameplay state too, replacing the old prep/service/summary phases (`start_service()`, `end_service()`, `start_next_day()`). Other code listens to signals such as the time changing, the restaurant opening or closing, and the day ending.
- Orders placed at the shop are held as pending until the next morning, then moved into the crate.

## Out of scope for the MVP
Saving and loading, menus and settings, real art and audio, decor and upgrades, multiple customers per table, ingredient decay, moving furniture, energy, washing up, the sieve and the ladle.

## Future roadmap
Rough order, all post-MVP:
1. Save and load.
2. More dishes that show off building up (marinara: oil, then garlic, then tomato; boiled potatoes), staples like oil and salt, tools (whisk, peeler) and stations (oven, grill).
3. **Sieve:** bring a sieve and a bowl to a pan, and the solids go into the bowl while the liquid stays in the pan, ready for the next batch.
4. **Ladle and servings:** one pot of soup serves several bowls, ladled out one at a time.
5. Washing up: served plates and bowls come back dirty and need washing at the sink.
6. Movable furniture: lift a fridge or cupboard above your head with empty arms (it must be empty inside) and place it elsewhere.
7. Ingredient decay: food loses freshness over time, slower in the fridge. Fresher food earns more.
8. Energy: how much you slept sets the next day's energy. Low energy makes you walk and chop a bit slower, but never stops you playing.
9. Restaurant upgrades: more tables, decor, better utensils (a faster knife, a bigger pan).
10. **Farming:** plant, water and harvest crops that fill your storage. Later, animals for eggs, milk and cheese.
11. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
12. Regulars with names, favourite dishes and relationship levels.
13. Hiring staff (waiter, cook) to automate parts of the loop.
14. Seasons that affect crops and the menu.
15. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
