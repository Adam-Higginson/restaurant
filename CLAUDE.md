# Restaurant game

## Stack
- Godot 4.7, GDScript only (no C#).
- Use Godot 4 APIs only: CharacterBody2D, `await`, TileMapLayer. Never Godot 3 APIs (KinematicBody2D, `yield`, TileMap).
- Typed GDScript everywhere: type every variable, parameter and return value.
- Compatibility renderer. 2D top-down pixel art, 16px tiles (change if the art pack differs), nearest-neighbour filtering.
- Godot binary: `C:\Godot\Godot_v4.7.2-stable_win64_console.exe`

## The game
A cosy top-down restaurant game in the spirit of Stardew Valley. The player controls a single character who runs a small restaurant: buys ingredients, cooks, serves customers and earns money. Later: hiring staff, and regulars the player builds relationships with. Not combat-focused.

Use placeholder coloured shapes until real art is added.

## Architecture
- Dish and ingredient definitions are Resource files under `res://data/`.
- Keep gameplay logic out of UI scripts.

## Public repo
- This repo is public. Third-party art and audio go in `assets/third_party/`, which is gitignored: never commit anything from it, and never commit keys or tokens.

## Task tracking
- The backlog is GitHub Project #1 owned by `Adam-Higginson` (kanban columns: Todo, In Progress, Done). Each task is an issue in `Adam-Higginson/restaurant` added to the board.
- The user chooses which task to work on. If none was given, list the Todo items and ask.
- When starting a task, move it to In Progress. When it's committed and working, move it to Done and close the issue.
- Reference the issue number in commit messages, e.g. `Add customer spawning (#12)`.
- Don't add new issues to the board yourself. Suggest follow-ups and bugs to the user instead.
- Useful commands:
  - List items: `gh project item-list 1 --owner Adam-Higginson`
  - Add an issue: `gh project item-add 1 --owner Adam-Higginson --url <issue-url>`
  - Set status: `gh project item-edit --project-id PVT_kwHOABMmCs4Blqh2 --id <item-id> --field-id PVTSSF_lAHOABMmCs4Blqh2zhkWd0E --single-select-option-id <option>`
    - Options: Todo `f75ad846`, In Progress `47fc9ee4`, Done `98236657`

## Workflow
- After each change, run the project headless to catch script errors:
  `C:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 300`
- Commit after each working step with a clear message.
- Ask before adding plugins or changing project settings.