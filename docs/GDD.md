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
- Interacts with the object in front of them (containers, counters, the stove, tables, the shop board, the door sign, the bed).
- **Arms:** carries up to **3 items** stacked above their head: ingredients, prepared food, finished dishes and utensils (chopping board, pan). Each item takes one slot. The stack bobs as they walk.
- **Tool belt:** a small row of slots (4) for hand tools. One slot is selected at a time. Selecting an empty slot means bare hands.

### Controls
| Key | Action |
|---|---|
| E | **Interact:** take an item, put down the top item, open a container, flip the door sign, go to bed |
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
- Bought ingredients arrive in the **delivery crate** by the door at 6:00 the next morning. The crate has no limit and works like a container you can only take from.
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
- Spawn at the door while the restaurant is open, more often at mealtimes. They walk to a free table and sit.
- Order a random dish from the menu, shown in a speech bubble.
- Have a patience meter that drains while they wait for their food. If it empties they leave and you lose the sale.
- Serving the correct dish pays the dish price. The customer eats briefly, then leaves and frees the table.
- MVP: 4 tables, one customer per table.

## Economy
- Start with 50 coins and empty storage. On day one a starter delivery is waiting in the crate (2 of each ingredient), so there's something to cook before your first order arrives.
- Money is spent in the shop and earned from customers. No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, clock, and whether the restaurant is open.
- **Belt bar** showing the belt slots and the selected tool.
- **Shop panel** at the shop board by the door. Orders arrive the next morning.
- **Container panel** for taking ingredients out of the fridge, cupboard and crate.
- **End-of-day summary** screen.

## Architecture notes
- Ingredients and dishes are `Resource` definitions under `res://data/`. Prepared food (chopped tomato, a raw sandwich) is defined the same way, so everything food-related is an item definition.
- Recipes are `Resource` definitions too: a method (chop, combine or cook), the input items, the output item and a time. Customers order from the dishes on the menu.
- Arms, the tool belt and each container's contents are gameplay state in scripts, not in UI scripts. UI reads them and listens to signals.
- A container's contents are a store of ingredient counts with a capacity, with no notion of where ingredients came from. Today the shop fills it; later farms will too. The existing `Pantry` class (counts per ingredient) can become this store.
- Money and the day number live in the `Game` autoload (`scripts/state/game_state.gd`), so any script can use `Game.money` and so on. The global `Game.pantry` goes away when storage containers are built.
- The clock and the restaurant's open/closed state are gameplay state too, replacing the old prep/service/summary phases (`start_service()`, `end_service()`, `start_next_day()`). Other code listens to signals such as the time changing, the restaurant opening or closing, and the day ending.
- Orders placed at the shop are held as pending until the next morning, then moved into the crate.

## Out of scope for the MVP
Saving and loading, menus and settings, real art and audio, decor and upgrades, multiple customers per table, ingredient decay, moving furniture, optional recipe steps, energy.

## Future roadmap
Rough order, all post-MVP:
1. Save and load.
2. Fresh-dish tip bonus, plus more dishes, tools (ladle, whisk, peeler) and stations (oven, grill).
3. Optional recipe steps that improve a dish and its price (e.g. toasted bread in a grilled cheese).
4. Movable furniture: lift a fridge or cupboard above your head with empty arms (it must be empty inside) and place it elsewhere.
5. Ingredient decay: food loses freshness over time, slower in the fridge. Fresher food earns more.
6. Energy: how much you slept sets the next day's energy. Low energy makes you walk and chop a bit slower, but never stops you playing.
7. Restaurant upgrades: more tables, decor, better utensils (a faster knife, a bigger pan).
8. **Farming:** plant, water and harvest crops that fill your storage. Later, animals for eggs, milk and cheese.
9. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
10. Regulars with names, favourite dishes and relationship levels.
11. Hiring staff (waiter, cook) to automate parts of the loop.
12. Seasons that affect crops and the menu.
13. More storage: bigger fridges and cupboards, a walk-in pantry, more arm and belt space (design epic #28).
