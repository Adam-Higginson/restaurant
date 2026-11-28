# Ship adventure game (repo name: restaurant)

## Stack
- Godot 4.7, GDScript only (no C#).
- Use Godot 4 APIs only: CharacterBody3D, `await`, AnimatableBody3D. Never Godot 3 APIs (KinematicBody, `yield`).
- Typed GDScript everywhere: type every variable, parameter and return value (enforced as errors; see Code style).
- 3D, Forward+ renderer (switched from Compatibility in #61). See `docs/look.md` for the painted environments and stylised character materials.
- The 2D world layer (2D player, props, customers, tilemap) is legacy, being replaced by the 3D prototype in `scenes/prototype/`. Don't extend it.
- Godot binary: `C:\Godot\godot_console.exe`

## The game
A cosy 3D adventure in the spirit of Ocarina of Time. You are your island's chain-tender, with a lantern spirit for a friend. When the great chain that holds your island breaks, the sea sweeps you away into the Grave of the Lanterns and a ship finds you. Home hasn't gone anywhere you can't follow: like all the islands it has drifted off through the fog (you lose no memory), so you join a crew sailing between fog-wrapped islands to find it, guided by each island's cooking and songs and by the taste of your older sibling's fish stew. Ashore: exploring, gathering, puzzles and OoT-style duels against fog-touched creatures. Aboard: the ship is a safe hearth, and the galley, where you cook for the crew, is its heart. The hands-on cooking system carries over from the earlier restaurant design.

Use greybox placeholder shapes until real art is added.

The full design lives in `docs/GDD.md`. Read it before starting a gameplay task, and keep it up to date when the design changes.

## Architecture
- Dish and ingredient definitions are Resource files under `res://data/`.
- Keep gameplay logic out of UI scripts.

## Public repo
- This repo is public. Third-party art and audio go in `assets/third_party/`, which is gitignored: never commit anything from it, and never commit keys or tokens.
- **The art is backed up in a private repo (#142).** `assets/third_party/` is its own git repo, a clone of the private `Adam-Higginson/restaurant-assets` (the packs, Meshy models and ambient sounds, `.import` files included). Its `.gitattributes` turns off line-ending conversion so it's a byte-for-byte copy.
  - **Back up** after adding a pack or making a Meshy model: in `assets/third_party/`, `git add -A`, commit with the issue in the message (`Adam-Higginson/restaurant#<n>`), and push. Say when a task changed the art, so the user knows to back it up.
  - **New PC or worktree, if the task needs the real art:** `git clone https://github.com/Adam-Higginson/restaurant-assets.git assets/third_party`, then import (`godot_console.exe --headless --path . --import`). Clone, don't copy, so the copy is a working backup too.
  - It stays private: it holds the raw packs, which we ship inside builds but don't re-host.
- Our own placeholder art (generated, not third-party) lives in `assets/placeholder/` and is committed. Its cloth, paper and painted textures are painted soft by `tools/textures/paint_placeholders.sh` from the pixel-art originals in `tools/textures/originals/` (#135): change an original or a recipe and run it again; don't hand-edit the painted PNGs.
- Two exceptions are committed because the game needs them to look and sound the same for everyone, each with its licence file beside it: fonts under the SIL Open Font Licence in `assets/fonts/`, and CC0 sounds in `assets/audio/`. Anything else third-party still needs asking first.

## Meshy (3D models)
- We have a paid Meshy subscription (about 1,100 credits a month, reset monthly) for generating crew and creature models. The Meshy CLI (`meshy`, npm `meshy-cli` 0.8) is installed and signed in, and the `meshy-3d-generation` skill drives it.
- Credits are real money: before any paid step, say what it is and what it costs (a picture 9, an edit 12, a model 15, a rig 5, an animation 3), and wait for the user's go-ahead. Show the concept picture and get it approved before making the model.
- Generated files go in `assets/third_party/meshy/<name>/`, gitignored: never commit them. The greybox stays as the fallback.
- `ThirdPartyModel` loads models directly from their imported files. Rigged characters can use a stylised material.
- The recipe, the prompts that worked and the gotchas (scale the node, never `fit_size`; turn it 180 degrees) are in `docs/meshy.md`.

## Task tracking
- The backlog is GitHub Project #1 owned by `Adam-Higginson` (kanban columns: Todo, In Progress, In Review, Done). Each task is an issue in `Adam-Higginson/restaurant` added to the board.
- Claude works on GitHub as `adam-higginson-claude`, a machine account with Write on this repo, `restaurant-assets` and the board. Its login and commit name come from the gitignored `.claude/settings.local.json` (an `env` block: `GH_CONFIG_DIR` for `gh`, `GIT_CONFIG_*` so git pushes use `gh auth git-credential`, and `GIT_AUTHOR_*`/`GIT_COMMITTER_*`), which `.worktreeinclude` copies into new worktrees. Before the first push in a session, check `gh api user --jq .login` says `adam-higginson-claude`; if not, stop and say so. Never print or handle its token.
- Each task runs in its own git worktree on its own branch, usually as a separate Claude session the user can open and steer. The main chat coordinates from a clean `main` and doesn't do task coding in its own folder.
- The user chooses which task to work on. If none was given, list the Todo items and ask.
- **Plan and discuss before writing code.** For every task or other non-trivial change, first present a plan in chat and wait for the user's explicit approval before executing. The plan covers: the goal, the approach (with alternatives and a recommendation), the pieces/files involved, edge cases, the tests, what's out of scope, and any decisions the user needs to make (including project settings or plugins). Explain unfamiliar Godot concepts along the way. If the approach needs to change significantly during the task, stop and discuss before continuing. Small implementation details that don't change the approach can be decided as you go, but call them out in the summary.
- Each task goes through a branch and a PR that the user reviews:
  1. Start from an up-to-date `main` and create a branch named `<issue-number>-<short-slug>`, e.g. `2-player-movement`. Move the card to In Progress.
  2. Commit on the branch as you go. Reference the issue number in commit messages, e.g. `Add customer spawning (#12)`.
  3. When the task is working and the headless check passes, push the branch and open a PR into `main`. The PR body summarises the change, says how to test it in-game, and includes `Closes #<n>`. Request the user's review when opening it (`gh pr create --reviewer Adam-Higginson`, or `gh pr edit <n> --add-reviewer Adam-Higginson` if it's already open), so it shows in their GitHub review requests. Then ask Codex to review it by commenting from the user's own `gh` login, since Codex only takes requests from its linked account: `GH_CONFIG_DIR="$APPDATA/GitHub CLI" gh pr comment <n> --body "@codex review"`. Use that login for this one comment only, never to approve, merge or push.
  4. Move the card to In Review, then stop and tell the user the PR is ready for review. The user reviews and **approves the PR in GitHub** from their own account. Address review comments as new commits on the same branch.
  5. **Only merge after the user's approval in GitHub (or an explicit instruction).** `main` requires one approving review. Then:
     - Check CI is green, then merge with a merge commit: `gh pr merge <n> --merge`. Don't pass `--delete-branch` while another open PR is based on that branch, because deleting a PR's base branch closes the PR.
     - Confirm the issue closed and the card is in Done. The board normally does this; if it hasn't, close the issue or move the card yourself.
     - Delete the merged branch (remote and local) and the task's worktree (`git worktree remove`), switch to `main` and pull, and check CI passes on `main`.
     - Report back with what was merged and the board state.
- Never commit directly to `main`: it is protected and only accepts PRs. This includes changes to CLAUDE.md and docs, which go on a `docs/<slug>` branch.
- Godot rewrites `project.godot` in its own format when the editor saves it. If it shows as modified with no real setting changes, commit it separately as a normalise commit.
- Don't add new issues to the board yourself. Suggest follow-ups and bugs to the user instead.
- Useful commands:
  - List items: `gh project item-list 1 --owner Adam-Higginson`
  - New issues in the repo are added to the board as Todo automatically (the board's auto-add workflow). Use the `Prototype` milestone (greybox 3D prototype) or `MVP: Prologue`.
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

## Keeping the user in the loop
Claude writes the code, all of it: nothing is left as an exercise. The user is learning Godot and wants to understand everything that goes in, so every code PR includes:
- **How it works** (in the PR body): the scene tree, which script does what, how signals and data flow, and any new Godot concept in plain terms.
- **An editor tour** (in the test steps): click-by-click where to look. Open this scene, select this node, see this Inspector setting, watch the Remote tree while it runs.
- **Glossary updates:** add each new Godot concept to `docs/godot-notes.md` (what it is in two lines, and where it's used in our code).

## Testing
- Unit tests use the gdUnit4 plugin (`addons/gdUnit4`, v6.2.1). Don't edit files in `addons/`.
- Tests live in `tests/`, mirroring the script path: `scripts/player.gd` → `tests/scripts/player_test.gd`. Each suite `extends GameTestSuite` and has typed `func test_<behaviour>() -> void` cases.
- Test gameplay logic directly (storage, arms, money, recipes, the clock). Use `scene_runner(...)` with the `GameTestSuite` helpers for behaviour that needs a running scene. Don't test visuals.
- Suites extend `GameTestSuite` (`tests/game_test_suite.gd`), not `GdUnitTestSuite` directly. Use its helpers: `physics_ticks(runner, n)` to wait, `walk(runner, action, ticks)` to move the player, `place_player(runner, pos)` to position it. Add new shared helpers there rather than copying them between suites.
- When a test waits for movement or physics (areas, collisions), wait on physics ticks (`physics_ticks`), never `simulate_frames`. Rendered frames vary with machine speed, so frame-based waits can pass locally and fail in CI.
- Run all tests from the command line (Git Bash): `./run_tests.sh`. It takes about 25 seconds. Run one folder or suite with `./run_tests.sh -a res://tests/scripts/sea`.
  - With no arguments it splits the suites across several copies of Godot at once (three for every four processor cores; set `JOBS=4 ./run_tests.sh` to choose), balanced by how long each suite took last time, and prints any failures and one combined summary. Each copy's full output is in `reports/shard_<n>.log`. Always run the whole suite this way rather than `-a res://tests`, which runs one copy and takes over two minutes.
  - Each copy gets a `TEST_SHARD` number and its own save file (`GameTestSuite.test_save`). Anything else tests write to disk must include it too, or two copies will write the same file.
  - It runs gdUnit's own command with `--fixed-fps 60`. Every frame still advances exactly 1/60 s of game time, but Godot doesn't wait for the real clock between frames, with one frame per physics tick. A higher number isn't faster: tests wait for a number of ticks, and Godot already runs them as fast as one core can. CI runs one copy the same way, also headless (`--headless` in the workflow), so nothing is drawn on the CPU-only runner.
  - It always passes `-c`, which turns off gdUnit's default fail-fast (otherwise each suite stops at its first failing test), and `--headless --ignoreHeadlessMode`. Input simulation works headless in this project.
  - Reports go to `reports/`, which is gitignored.
- CI (`.github/workflows/tests.yml`) runs the tests on every PR and on pushes to `main`. A PR is only ready for review when the tests pass both locally and in CI.
  - The workflow installs Godot and runs gdUnit's command itself (not through gdUnit4-action). If Godot hangs, which it now and then has on the Linux runner after every test passed, it's stopped after 4 minutes: gdb prints every thread's stack, then SIGSEGV makes Godot's crash handler print its backtrace (if it's still on); the log and reports are kept as the `godot-log` artifact. If CI fails with "Godot hung", read the backtrace before re-running.

## Seeing the game (godot-ai, #237)
The [godot-ai](https://github.com/hi-godot/godot-ai) plugin (`addons/godot_ai/`, v4.4.2) connects Claude Code to a Godot editor: screenshots of the running game or the editor's view, frame-timed input, pausing and stepping, and the live scene tree. Use it to check looks and feel; it doesn't replace the user playing.
- **Look and play only.** Changes still go through files on a branch and a PR. `.mcp.json` starts the server with the editing tool groups excluded, and `.claude/settings.json` denies the editing tools left (creating, changing or deleting nodes, saving scenes). Don't use `project_manage` for anything but `stop`.
- **Open an editor on the checkout you're working in:** `tools/godot_ai/open_editor.sh` (the current checkout, or pass a folder). It starts Godot through Windows Explorer: an editor started directly from the Claude desktop app gets the app's private copy of `AppData\Local`, so its key file is somewhere the server can't read. Wait for the editor to connect (`editor_state` answers), and if several are open, pick the right one with `session_activate`.
- **Close it when done:** `tools/godot_ai/close_editor.sh` closes only the editor on that folder, and politely, so the plugin stops its server. Never force-close every Godot: the user may have their own open.
- **Running a scene:** `project_run` with `mode="custom"`, the scene's path and `autosave=False` (otherwise open scenes are saved first). Keep `input_sequence` short (tens of frames): a game running behind the editor drops to a low frame rate, and a long sequence hits the 30-second limit.
- **After using it,** run `git status`: opening a project can make the editor rewrite `project.godot` or `.import` files. Revert anything you didn't mean to change.
- **Each PC needs, once:** `uv` installed, and in Godot's Editor Settings, `godot_ai/telemetry_enabled` off and `godot_ai/excluded_domains` set to the same list as `--exclude-domains` in `.mcp.json`. If they differ, the server refuses Claude Code's connection. MCP servers load when a Claude Code session starts, so approve `godot-ai` in a new session.
- **Updating it:** use the dock's Update button (it checks the release's signature), update the version and arguments in `.mcp.json` to match, and commit the new `addons/godot_ai/` as its own commit.

## Builds
- Players download builds from the repo's Releases page (#143). The user publishes one by hand (*Actions > Publish build > Run workflow* on `main`); never start a publish run yourself unless asked. How it works is in `docs/GDD.md` under *Publishing builds*.
- Every file the game loads by a path in a string is found by `ExportList` (`scripts/build/`) as long as the full `res://assets/third_party/...` path is written in a scene, resource, script or `.dlg` file. A path built up in code (joined from pieces) isn't seen: add it to `ExportList` or the build won't have it.
- A new kind of plain-text (non-resource) file the game reads, like `.dlg`, must be added to both presets' `include_filter` in `export_presets.cfg`.
- To try a build locally: `tools/build/export.sh` in Git Bash (needs the art and the 4.7.2 export templates). A PR that touches `export_presets.cfg`, `project.godot`, `scripts/build/`, `tools/build/`, `CREDITS.txt` or the publish workflow does a dry-run build in CI, kept as a download on the run.
- Add a credit to `CREDITS.txt` whenever a new pack, font or sound comes in.

## Code style
Follow the official GDScript style guide. Godot enforces some of it: in project settings, missing types and unsafe calls/casts are **errors**, and unused or shadowed variables are warnings. `tests/code_standards_test.gd` loads every script under `scripts/`, `ui/` and `tests/`, so CI fails if any script breaks these rules. It also fails on a tab after a line's indent: a long line whose `\` and line break were lost when it was edited by a script, joining the next line on.
- **Naming:** `snake_case` files, variables and functions. `PascalCase` for `class_name` and node names. `CONSTANT_CASE` for constants and enum values. Prefix private members with `_`.
- **Signals** are named in the past tense: `order_placed`, `dish_served`, `money_changed`.
- **Script order:** `class_name`, `extends`, a `##` doc comment, signals, enums, constants, `@export` vars, public vars, private vars, `@onready` vars, built-in callbacks (`_ready`, `_physics_process`, ...), public functions, private functions.
- **Formatting:** tabs for indentation. Two blank lines between functions. Lines under about 100 characters.
- **Types:** type everything explicitly (`var speed: float = 80.0`), including loop variables (`for item: Ingredient in items`) and typed arrays (`Array[Dish]`). Avoid `Variant` unless something truly can be any type. Cast with `as` from a concrete type, not from a `Variant`.
- **Comments:** `##` doc comments on classes and on public members that aren't obvious. Otherwise comment why, not what.
- **Nodes:** reference child nodes with `@onready var _x: Type = $X`, not `get_node` scattered through the code. Connect signals in code, not the editor, so wiring is visible in scripts.
