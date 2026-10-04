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

1. **Prep (morning).** The restaurant is closed and there's no time pressure. Buy ingredients from the shop, which go into the pantry. Press "Open" to start service.
2. **Service (timed, ~3 real minutes).** Customers arrive, sit, and order one dish. Cook it at a station, carry it to them, get paid. Customers left waiting too long leave without paying. Service ends when the clock hits closing time and the last seated customers have been served or have left.
3. **Summary (evening).** Shows earnings, ingredients spent, customers served and customers lost. Continue to the next day.

Unused ingredients carry over between days. Ingredients don't spoil in the MVP.

## Player
- One character, top-down 4-direction movement.
- Interacts with the nearest object in front of them (stations, tables, pantry, door).
- Carries **one dish at a time**.

## Cooking
- **Stations:** Chopping Board and Stove.
- Interacting with an idle station opens a small picker listing that station's dishes. Dishes you lack ingredients for are greyed out.
- Picking a dish takes its ingredients from the pantry and starts a timer with a progress bar over the station.
- When the timer finishes, the dish waits on the station until you collect it. It never burns.
- Stations run in parallel. The intended fun is juggling several stations and tables at once.
- **First fix to try if cooking feels flat (post-MVP):** a dish collected soon after it's ready counts as "fresh" and earns a tip bonus.

## MVP menu
| Dish | Ingredients | Station | Cook time | Price |
|---|---|---|---|---|
| Garden Salad | Lettuce, Tomato | Chopping Board | 4s | 12 |
| Tomato Soup | Tomato, Onion | Stove | 8s | 18 |
| Grilled Cheese | Bread, Cheese | Stove | 6s | 15 |

| Ingredient | Shop price |
|---|---|
| Lettuce | 3 |
| Tomato | 3 |
| Onion | 2 |
| Bread | 3 |
| Cheese | 4 |

Tomato is shared by two dishes, which makes stocking up a small decision. The numbers are starting points for balancing.

## Customers
- Spawn at the door at intervals during service, walk to a free table and sit.
- Order a random dish from the menu, shown in a speech bubble.
- Have a patience meter that drains while they wait for their food. If it empties they leave and you lose the sale.
- Serving the correct dish pays the dish price. The customer eats briefly, then leaves and frees the table.
- MVP: 4 tables, one customer per table.

## Economy
- Start with 50 coins and an empty pantry.
- Money is spent in the shop and earned from customers. No other sinks in the MVP.
- No lose condition. A bad day is just a bad day.

## UI
- **HUD:** money, day number, phase, service clock.
- **Shop panel** during prep.
- **Station dish picker.**
- **End-of-day summary** screen.

## Architecture notes
- Ingredients and dishes are `Resource` definitions under `res://data/`.
- The pantry is a plain store of ingredient counts with no notion of where ingredients came from. Today the shop fills it; later farms will too.
- The game state (money, pantry, day, phase) lives in gameplay code, not in UI scripts. UI reads it and listens to signals.

## Out of scope for the MVP
Saving and loading, menus and settings, real art and audio, decor and upgrades, multiple customers per table, spoilage.

## Future roadmap
Rough order, all post-MVP:
1. Save and load.
2. Fresh-dish tip bonus, plus more dishes and stations (oven, grill).
3. Restaurant upgrades: more tables, decor, faster stations.
4. **Farming:** plant, water and harvest crops that feed the pantry. Later, animals for eggs, milk and cheese.
5. Farm-to-table bonus: dishes made with home-grown ingredients sell for more.
6. Regulars with names, favourite dishes and relationship levels.
7. Hiring staff (waiter, cook) to automate parts of the loop.
8. Seasons that affect crops and the menu.
