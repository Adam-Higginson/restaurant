# Restaurant game

## Stack
- Godot 4.7, GDScript only (no C#).
- Use Godot 4 APIs only: CharacterBody2D, `await`, TileMapLayer. Never Godot 3 APIs (KinematicBody2D, `yield`, TileMap).
- Typed GDScript everywhere: type every variable, parameter and return value (enforced as errors; see Code style).
- Compatibility renderer. 2D top-down pixel art, 16px tiles (change if the art pack differs), nearest-neighbour filtering.
- Godot binary: `C:\Godot\godot_console.exe`

## The game
A cosy top-down restaurant game in the spirit of Stardew Valley. The player controls a single character who runs a small restaurant: buys ingredients, cooks, serves customers and earns money. Later: hiring staff, and regulars the player builds relationships with. Not combat-focused.

Use placeholder coloured shapes until real art is added.

The full design lives in `docs/GDD.md`. Read it before starting a gameplay task, and keep it up to date when the design changes.

## Architecture
- Dish and ingredient definitions are Resource files under `res://data/`.
- Keep gameplay logic out of UI scripts.

## Public repo
- This repo is public. Third-party art and audio go in `assets/third_party/`, which is gitignored: never commit anything from it, and never commit keys or tokens.

## Task tracking
- The backlog is GitHub Project #1 owned by `Adam-Higginson` (kanban columns: Todo, In Progress, In Review, Done). Each task is an issue in `Adam-Higginson/restaurant` added to the board.
- The user chooses which task to work on. If none was given, list the Todo items and ask.
- Each task goes through a branch and a PR that the user reviews:
  1. Start from an up-to-date `main` and create a branch named `<issue-number>-<short-slug>`, e.g. `2-player-movement`. Move the card to In Progress.
  2. Commit on the branch as you go. Reference the issue number in commit messages, e.g. `Add customer spawning (#12)`.
  3. When the task is working and the headless check passes, push the branch and open a PR into `main`. The PR body summarises the change, says how to test it in-game, and includes `Closes #<n>`.
  4. Move the card to In Review, then stop and tell the user the PR is ready for review. Address review comments as new commits on the same branch.
  5. **Only merge when the user explicitly tells you to.** Then:
     - Check CI is green, then merge with a merge commit: `gh pr merge <n> --merge`. Don't pass `--delete-branch` while another open PR is based on that branch, because deleting a PR's base branch closes the PR.
     - Confirm the issue closed and the card is in Done. The board normally does this; if it hasn't, close the issue or move the card yourself.
     - Delete the merged branch (remote and local), switch to `main` and pull, and check CI passes on `main`.
     - Report back with what was merged and the board state.
- Never commit directly to `main`: it is protected and only accepts PRs. This includes changes to CLAUDE.md and docs, which go on a `docs/<slug>` branch.
- Godot rewrites `project.godot` in its own format when the editor saves it. If it shows as modified with no real setting changes, commit it separately as a normalise commit.
- Don't add new issues to the board yourself. Suggest follow-ups and bugs to the user instead.
- Useful commands:
  - List items: `gh project item-list 1 --owner Adam-Higginson`
  - New issues in the repo are added to the board as Todo automatically (the board's auto-add workflow). MVP issues use the `MVP` milestone.
  - Set status: `gh project item-edit --project-id PVT_kwHOABMmCs4Blqh2 --id <item-id> --field-id PVTSSF_lAHOABMmCs4Blqh2zhkWd0E --single-select-option-id <option>`
    - Options: Todo `f75ad846`, In Progress `47fc9ee4`, In Review `cb535e89`, Done `98236657`

## Workflow
- After each change, run the project headless to catch script errors:
  `C:\Godot\godot_console.exe --headless --path . --quit-after 300`
- Commit after each working step with a clear message.
- Ask before adding plugins or changing project settings.
- Add or update gdUnit4 tests for gameplay logic in every task (see Testing).
- After every change, tell the user:
  - **What changed:** the files and behaviour, in plain terms.
  - **How to test it manually:** numbered steps in the game or editor (e.g. "Press F5, walk into a wall, you should stop"), what they should see, and anything not testable yet.
  Put the same testing steps in the PR body.

## Testing
- Unit tests use the gdUnit4 plugin (`addons/gdUnit4`, v6.2.1). Don't edit files in `addons/`.
- Tests live in `tests/`, mirroring the script path: `scripts/player.gd` → `tests/scripts/player_test.gd`. Each suite `extends GdUnitTestSuite` and has typed `func test_<behaviour>() -> void` cases.
- Test gameplay logic directly (pantry, money, recipes, day phases). Use `scene_runner(...)` with `simulate_action_press` and `simulate_frames` for behaviour that needs a running scene. Don't test visuals.
- Run all tests from the command line (Git Bash):
  `GODOT_BIN=/c/Godot/godot_console.exe bash addons/gdUnit4/runtest.sh -a res://tests --headless --ignoreHeadlessMode`
  Input simulation works headless in this project. Reports go to `reports/`, which is gitignored.
- CI (`.github/workflows/tests.yml`) runs the tests on every PR and on pushes to `main`. A PR is only ready for review when the tests pass both locally and in CI.

## Code style
Follow the official GDScript style guide. Godot enforces some of it: in project settings, missing types and unsafe calls/casts are **errors**, and unused or shadowed variables are warnings. `tests/code_standards_test.gd` loads every script under `scripts/`, `ui/` and `tests/`, so CI fails if any script breaks these rules.
- **Naming:** `snake_case` files, variables and functions. `PascalCase` for `class_name` and node names. `CONSTANT_CASE` for constants and enum values. Prefix private members with `_`.
- **Signals** are named in the past tense: `order_placed`, `dish_served`, `money_changed`.
- **Script order:** `class_name`, `extends`, a `##` doc comment, signals, enums, constants, `@export` vars, public vars, private vars, `@onready` vars, built-in callbacks (`_ready`, `_physics_process`, ...), public functions, private functions.
- **Formatting:** tabs for indentation. Two blank lines between functions. Lines under about 100 characters.
- **Types:** type everything explicitly (`var speed: float = 80.0`), including loop variables (`for item: Ingredient in items`) and typed arrays (`Array[Dish]`). Avoid `Variant` unless something truly can be any type. Cast with `as` from a concrete type, not from a `Variant`.
- **Comments:** `##` doc comments on classes and on public members that aren't obvious. Otherwise comment why, not what.
- **Nodes:** reference child nodes with `@onready var _x: Type = $X`, not `get_node` scattered through the code. Connect signals in code, not the editor, so wiring is visible in scripts.
