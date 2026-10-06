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
Each in-game day has three phases:

1. **Prep (morning).** The restaurant is closed and there's no time pressure. Buy ingredients at the shop board by the door. They arrive in a delivery crate, and you carry them to the fridge and cupboard. Press "Open" to start service.
2. **Service (timed, ~3 real minutes).** Customers arrive, sit, and order one dish. Fetch the ingredients, prepare and cook them, carry the dish to the customer and get paid. Customers left waiting too long leave without paying. Service ends when the clock hits closing time and the last seated customers have been served or have left.
3. **Summary (evening).** Shows earnings, ingredients spent, customers served and customers lost. Continue to the next day.

Everything stays where you left it between days: ingredients in storage or the crate, and food on counters. Nothing decays in the MVP.

## Player
- One character, top-down 4-direction movement.
- Interacts with the object in front of them (containers, counters, the stove, tables, the shop board).
- **Arms:** carries up to **3 items** stacked above their head: ingredients, prepared food, finished dishes and utensils (chopping board, pan). Each item takes one slot. The stack bobs as they walk.
- **Tool belt:** a small row of slots (4) for hand tools. One slot is selected at a time. Selecting an empty slot means bare hands.

### Controls
| Key | Action |
|---|---|
| E | **Interact with the arms:** take an item, put down the top item, open a container |
| Space | **Use** the selected belt tool on what you're facing: the knife chops, bare hands combine |
| Q | Rotate the stack, so a different item is on top |
| 1–4 / scroll | Select a belt slot |

Only the top item of the stack is active: E puts that one down, and anything you pick up goes on top.

## Starting kit (day one)
| Thing | Kind | Starts |
|---|---|---|
| Cheap chef's knife | Belt tool | On the belt |
| Basic chopping board | Utensil (carried in arms) | On a counter |
| Basic frying pan | Utensil (carried in arms) | On the stove |
| Basic fridge (12 slots) | Storage furniture | Placed in the kitchen |
| Basic cupboard (12 slots) | Storage furniture | Placed in the kitchen |
| Counters, stove | Fixed kitchen fittings | Placed in the kitchen |

## Storage
- The **fridge** holds chilled ingredients, and the **cupboard** holds dry ones. Each ingredient says which kind of storage it needs.
- Containers have a fixed number of slots, and each item uses one. Bigger containers are a later upgrade.
- E on a container opens a small panel showing its contents. Picking an ingredient puts it in your arms if you have space. E on a container while holding an ingredient it accepts puts that ingredient away.
- Containers hold raw ingredients only, not prepared food or dishes.
- Bought ingredients arrive in the **delivery crate** by the door. The crate has no limit and works like a container you can only take from.
- Furniture is fixed in place in the MVP. Later it can be moved (see the roadmap).

## Cooking
Cooking is hands-on: you move ingredients between places and apply tools to them. Recipes are fixed: only combinations that match a known recipe work, and anything else is refused with a small "that doesn't go together" bubble.

- **Surfaces:** a counter holds one item, either food or a utensil. The chopping board and pan each hold up to 3 food items.
- **Chopping:** with the knife selected, press Use at a chopping board to chop the raw item on it (for example tomato → chopped tomato). Chopping takes a few presses.
- **Combining:** with bare hands, press Use at a board or counter holding items that match a combine recipe to turn them into one item (for example chopped lettuce + chopped tomato → Garden Salad).
- **Stove cooking:** a pan on the stove holding items that match a cook recipe starts cooking. A progress bar shows the time left. When it's done, the result waits in the pan until you take it. It never burns.
- The intended fun is juggling: the stove cooks on its own while you chop or serve.
- **Future ideas:** optional extra steps that improve a dish (toast the bread for a nicer grilled cheese that pays more), and the fresh-dish tip bonus. See the roadmap.

## MVP menu
| Dish | Steps | Cook time | Price |
|---|---|---|---|
| Garden Salad | Chop lettuce, chop tomato → combine by hand | — | 12 |
| Tomato Soup | Chop tomato, chop onion → cook in the pan | 8s | 18 |
| Grilled Cheese | Combine bread + cheese by hand → cook in the pan | 6s | 15 |

| Ingredient | Storage | Shop price |
|---|---|---|
| Lettuce | Fridge | 3 |
| Tomato | Fridge | 3 |
| Cheese | Fridge | 4 |
| Onion | Cupboard | 2 |
| Bread | Cupboard | 3 |

Tomato is shared by two dishes, which makes stocking up a small decision. The numbers are starting points for balancing.

## Customers
- Spawn at the door at intervals during service, walk to a free table and sit.
- Order a random dish from the menu, shown in a speech bubble.
- Have a patience meter that drains while they wait for their food. If it empties they leave and you lose the sale.
- Serving the correct dish pays the dish price. The customer eats briefly, then leaves and frees the table.
- MVP: 4 tables, one customer per table.

## Economy
- Start with 50 coins and empty storage.
- Money is spent in the shop and earned from customers. No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, phase, service clock.
- **Belt bar** showing the belt slots and the selected tool.
- **Shop panel** during prep.
- **Container panel** for taking ingredients out of the fridge, cupboard and crate.
- **End-of-day summary** screen.

## Architecture notes
- Ingredients and dishes are `Resource` definitions under `res://data/`. Prepared food (chopped tomato, a raw sandwich) is defined the same way, so everything food-related is an item definition.
- Recipes are `Resource` definitions too: a method (chop, combine or cook), the input items, the output item and a time. Customers order from the dishes on the menu.
- Arms, the tool belt and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- A container's contents are a store of ingredient counts with a capacity, with no notion of where ingredients came from. Today the shop fills it; later farms will too. The existing `Pantry` class (counts per ingredient) can become this store.
- Money, day and phase live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. Phase changes go through `start_service()`, `end_service()` and `start_next_day()`, which refuse transitions from the wrong phase. The global `Game.pantry` goes away when storage containers are built.

## Out of scope for the MVP
Saving and loading, menus and settings, real art and audio, decor and upgrades, multiple customers per table, ingredient decay, moving furniture, optional recipe steps.

## Future roadmap
Rough order, all post-MVP:
1. Save and load.
2. Fresh-dish tip bonus, plus more dishes, tools (ladle, whisk, peeler) and stations (oven, grill).
3. Optional recipe steps that improve a dish and its price (e.g. toasted bread in a grilled cheese).
4. Movable furniture: lift a fridge or cupboard above your head with empty arms (it must be empty inside) and place it elsewhere.
5. Ingredient decay: food loses freshness over time, slower in the fridge. Fresher food earns more.
6. Restaurant upgrades: more tables, decor, better utensils (a faster knife, a bigger pan).
7. **Farming:** plant, water and harvest crops that fill your storage. Later, animals for eggs, milk and cheese.
8. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
9. Regulars with names, favourite dishes and relationship levels.
10. Hiring staff (waiter, cook) to automate parts of the loop.
11. Seasons that affect crops and the menu.
12. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
