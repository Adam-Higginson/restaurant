# Godot notes

A growing glossary of the Godot concepts this project uses: what each one is, in a couple of lines, and where to find it in our code. Each PR adds the new concepts it introduces.

## Basics

**Node and scene.** Everything in Godot is a tree of nodes. A scene (`.tscn`) is a saved tree that can be placed inside other scenes as a single node, like a prefab. *Ours:* `scenes/props/fridge.tscn` is one scene, placed many times.

**Script.** A GDScript file (`.gd`) attached to a node adds behaviour to it. `class_name` gives it a global type name, so other scripts can write `var arms: Arms`. *Ours:* everything under `scripts/`.

**Resource.** A data object saved as a file (`.tres`), edited in the Inspector, shared and never copied by accident. Good for definitions. *Ours:* every item, reaction and tool under `data/`.

**Signal.** A node or object announces "this happened" and anyone connected reacts, so the sender doesn't need to know who's listening. *Ours:* `VesselContents.reaction_finished`, `Arms.changed`. Signals are named in the past tense.

**Autoload.** A script Godot creates once at startup and makes available everywhere by name. *Ours:* `Game` (`scripts/state/game_state.gd`).

**`@onready` and `$Child`.** `$Name` finds a child node by its name. `@onready` waits until the node is in the tree before looking it up. *Ours:* `@onready var _x: Type = $X` in every scene script.

**`_process` and `_physics_process`.** Called every rendered frame, and every physics tick (60 per second), respectively. Movement and collisions go in `_physics_process`. *Ours:* player movement.

**Input Map.** Named actions ("interact", "move_left") bound to keys and controller buttons in Project Settings → Input Map, so code never checks a specific key. *Ours:* `project.godot`, `tests/input_map_test.gd`.

**Tween.** Animates a property from one value to another over time, created from code. *Ours:* `ui/screen_fade.gd`.

## Rendering

**Renderer: Compatibility vs Forward+.** Godot has three renderers. *Compatibility* (OpenGL) runs on almost anything, but has simple 3D lighting. *Forward+* (Vulkan/D3D12) supports many lights with shadows, glow, volumetric fog, screen-space effects and good water. The 3D look we want needs it. *Ours:* switched in #61.

## 3D

*Added as the prototype tickets introduce them: `Node3D`, `MeshInstance3D`, `CharacterBody3D`, `AnimatableBody3D`, `Area3D`, `SpringArm3D`, `Camera3D`, `WorldEnvironment`, `OmniLight3D`, ...*

## Testing

**gdUnit4.** The test framework (`addons/gdUnit4`). Suites extend our `GameTestSuite` and have `test_...` functions. `scene_runner` loads a scene and lets a test press inputs and wait physics ticks. *Ours:* `tests/`.
