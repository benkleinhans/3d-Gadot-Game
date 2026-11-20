# P — Pathogen Prototype (Godot 4.8)

A modular third-person movement and gameplay foundation. It is intentionally a graybox: no final player model, animations, materials, or environment art are included.

## Open the project

1. Install Godot 4.8.
2. Extract this folder.
3. In Godot Project Manager choose **Import** and select `project.godot`.
4. Open the project and run it (F6 for the current scene, F5 for the project main scene).

The main scene is `scenes/testing/movement_test.tscn`. It contains the player and four stationary capsule enemies.

## Current controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD | Left stick |
| Look | Mouse | Right stick |
| Run | Tap Shift to toggle | Tap left-stick press |
| Flow | Hold Shift for 5 seconds | Hold left-stick press for 5 seconds |
| Exit Flow | Tap Shift again is not required; use Flow toggle below | Same |
| Jump / charge jump | Space: press and release | A: press and release |
| Dash / air dash | Right mouse button | Right bumper |
| Lock on | Q | — |
| Toggle melee mode | Middle mouse | — |
| Attack | Left mouse | X |
| Toggle launcher mode | F | — |
| Freefly debug | G; E/Q vertical | — |
| Release mouse | Esc | — |

**Run/Flow input note:** the same physical Shift / left-stick press is mapped to both `run_toggle` and `flow_hold`. A tap toggles run. Holding it for five seconds activates Flow. To exit Flow, tap Shift again (release first, then press). Flow ends on the next press and automatically returns to Run. If you prefer Flow to end automatically on release, change `FlowComponent` logic.

## Important implementation notes

- Player movement is camera-relative and analog magnitude is preserved.
- Lock-on rotates the player toward the nearest node in the `enemies` group; movement input remains camera-relative.
- Flow has a five-second hold threshold, three-times walk speed, hover correction, and left/right steering.
- Dash has an inspector-configurable cooldown, duration, speed, and air-dash count.
- Jump supports two jumps by default and variable charge strength. The maximum charge duration and bonus are Inspector properties.
- Health is signal-driven. Player death triggers a delayed checkpoint respawn and restores health.
- Enemies are stationary capsule test targets with health bars and shared health logic.
- Combat and Piercer components expose signals and cooldowns, but actual damage hitboxes, projectiles, IK aiming, and attack animation events are intentionally integration points—not finished combat gameplay.
- AnimationComponent is ready to receive an AnimationTree. No Mixamo animation assets are bundled.

## Mixamo model setup

1. Download your character from Mixamo as **FBX Binary**. For the first import, include skin. Use the same skeleton for every animation download.
2. Put the FBX under `models/player/` (create the folder if needed).
3. Drag the imported scene into `Player/Model` in `scenes/player/player.tscn`.
4. Ensure the imported model faces Godot's forward direction (-Z) and its feet align with the floor. Adjust the model node transform, not the CharacterBody3D root.
5. Keep the `Collider` on the player root. Do not replace it with the imported model's collision.
6. For animation-only FBX downloads, use the same Mixamo rig/skeleton settings. Import them, then use the imported AnimationPlayer's animation library to copy/retarget animations to the player rig as needed. Skeleton compatibility depends on the exact Mixamo rig and import settings.

## AnimationTree setup

1. Select the imported model's AnimationPlayer and confirm all animation clips appear.
2. Add an `AnimationTree` under `Model` and set its `anim_player` path to the model's AnimationPlayer.
3. Create a root `AnimationNodeStateMachine` with states such as `Locomotion`, `Jump`, `Fall`, `Dash`, `Flow`, and `Attack`.
4. Create a `BlendSpace2D` for locomotion. Use X for strafe (left/right) and Y for forward/back. Add clips at:
   - (0, 0): idle
   - (0, 1): walk/run forward
   - (0, -1): backward
   - (-1, 0): left
   - (1, 0): right
   Add diagonal clips if available. Configure the BlendSpace's `sync` and transition cross-fade to taste.
5. Create a second BlendSpace2D for lock-on strafing with forward, backward, left, and right clips. Connect it as a separate state or use a blend node to crossfade between locomotion and strafe.
6. Add upper-body attack layering using an `AnimationNodeBlendTree` and `AnimationNodeBlend2`, with an `AnimationNodeOneShot` or additive layer. Use a `SkeletonModificationStack3D` / `Modifier`-based IK setup (Godot 4.8) for the arms once the model's bone names are known.
7. Assign the AnimationTree to `Components/AnimationComponent` in the Inspector.

The script attempts to set common AnimationTree parameter paths (`parameters/Locomotion/blend_position`, `parameters/Strafe/blend_position`, and condition flags). These are optional integration paths: make your AnimationTree node names match them, or adjust `animation_component.gd` to your chosen graph. Until the tree is assigned, movement works without animation.

## Adding an enemy

Instance `scenes/enemies/enemy_base.tscn`. Set `enemy_size` and `health_multiplier` in the Inspector. It automatically joins the `enemies` group and can be selected by player lock-on.

## Component tuning

Select the corresponding child under `Player/Components`:
- MovementComponent: walk speed, run multiplier, flow multiplier, acceleration, rotation speed.
- JumpComponent: max jumps, jump velocity, maximum charge duration, charge bonus.
- DashComponent: dash speed, duration, cooldown, maximum air dashes.
- FlowComponent: activation hold seconds, hover height/strength, turn speed.
- HealthComponent: maximum and starting health.
- LockOnComponent: max distance and target group.
- PiercerComponent: launcher cooldown and dual-charge time.

## Next integration work

1. Connect actual melee hitboxes and enemy damage receiver.
2. Add projectile scene and raycast/laser aiming for single/dual Piercer.
3. Add IK target nodes after Mixamo bone names are confirmed.
4. Add audio players for glass-like impact/clink, jump, dash, and Flow.
5. Add enemy AI state transitions and navigation using NavigationAgent3D.
6. Add checkpoint Area3D nodes and call `CheckpointComponent.set_checkpoint()` when entered.

## Known prototype limitations

This is a foundation, not a finished game. The provided enemy health bar is a basic SubViewport UI; customize it after testing. Launcher aiming currently changes camera FOV only. The lock-on camera target is exposed but does not yet orbit/track the target. The Flow input is shared with Run as requested; release and re-press Shift to exit Flow. Actual Mixamo retargeting, IK, animation clips, hit reactions, and audio require your imported assets.
