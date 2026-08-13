# Session Log — 2026-08-12

Build log for the first working session on this project: a 3D apocalyptic
survival/escape game in Godot 4.7 where the player scavenges parts, rebuilds a
car at an abandoned gas station, and drives away.

The project began this session as an empty Godot scaffold (`project.godot`, an
icon, and nothing else) and ended with a playable loot-and-rebuild loop.

---

## 1. First-person controller and level blockout — `6e014ea`

- `scenes/player/player.tscn` — `CharacterBody3D`, capsule collider, `Camera3D`
  at head height.
- `scenes/player/player.gd` — WASD movement, jump, mouse look with pitch clamped
  to ±89°, mouse captured on launch and toggled with Escape.
- `scenes/levels/main_level.tscn` — CSG floor, directional light, sky.
- Input actions (WASD/Space) and main scene wired into `project.godot`.

Crouch (Ctrl) and a forward interaction `RayCast3D` were added alongside the
gas-station level in the same pass.

## 2. Physics interaction system — `2dc9920`

- `scripts/interactable.gd` — one component with three modes: `PICKABLE`,
  `DOOR` (swings), `DRAWER` (slides). Doors/drawers interpolate toward a target
  transform each physics frame.
- Pickup reparents the body to a hold point in front of the camera, freezes it
  and zeroes its collision so it can't push the world around. `E` picks
  up/drops, `G` throws. Released objects inherit player velocity.
- Placeholder props: tire, gas jug, metal pipe, plus a storage drawer whose
  drawer is an `AnimatableBody3D`.

## 3. Car assembly mechanic — `f6b0bd3`, `72f217c`

- `scenes/vehicles/car.gd` — tracks `has_engine`, `has_gas`, and four wheel
  slots; exposes `can_drive()`.
- Walking up with a matching part and pressing `E` snaps it onto the nearest
  empty slot; empty-handed at the driver's door (once fully built) hands control
  to the car with WASD driving.
- `72f217c` fixed a parse error: `player` is typed `Node`, so `:=` could not
  infer the return type of `take_held_part()`.

## 4. Environment art pass — `cec186a`, `d86a3ba`, `435454b`

- Rebuilt the gas station: store moved beside the canopy across a shared
  concrete apron, two-lane road with dashed centre line, detailed canopy with
  cross-beams and dual pump islands, twilight sky, fog + volumetric fog, glow,
  warm canopy spotlights and emissive signage.
- **Bug found in passing:** the store building was a solid `CSGBox3D` with no
  opening — the interior (and the drawer puzzle inside it) was never reachable.
  Hollowed it out and cut a real doorway with CSG subtraction.
- Engine prop rebuilt from primitives, then replaced with an imported OBJ.

## 5. Display settings — `9cf544f`

Borderless fullscreen at 1920×1080, scoped with `.debug` suffixes so it applies
to editor Play sessions without affecting release exports.

## 6. Imported art: car, station, character — `2ce2028`

Real assets replaced the blockout. Model internals were read by parsing each
glTF file's JSON chunk directly, so scale, node names and landmark positions
came from measurement rather than guesswork.

- **Car** (`Duke_69.glb`) — placed at true scale (5.24 m). The model ships with
  its own hood and wheels, so those meshes are hidden at startup and revealed as
  the player installs each part.
- **Station** (`OldGasStation.glb`) — 69 named meshes, authored in centimetres,
  so scaled ×0.01. Collision is generated at runtime rather than hand-placed.
- **Player character** — attached as a visual body (static mesh, no rig).
- Road-signs pack staged in `assets/models/props/` for later use.

## 7. Objectives HUD — `2ce2028`

- `Objectives` autoload holding an ordered checklist.
- HUD panel; completed objectives get a hand-jittered pencil strike-through
  animation plus a synthesized scribble sound.

## 8. Procedural sound effects — `2ce2028`

No audio assets were available at this point, so `Sfx` + `sfx_voice.gd`
synthesize noise/tone bursts at runtime: footsteps (surface-aware), pickup/drop
per material, tire bounce, wrench install, hood and drawer open/close, engine
install, gas pour, jump, land, throw, engine start.

## 9. Compile and rendering fixes — `6eeedb4`, `2164c98`

- `Interactable` extends `PhysicsBody3D`, so `self is RigidBody3D` was rejected
  at parse time. That single failure cascaded — `car.gd`, `hud.gd` and
  `player.gd` all failed to compile and the Hood node silently lost its script.
- `lerp()` returns `Variant`, so inferring from it tripped the treat-warnings-as
  -errors setting; switched to `lerpf()`.
- The first-person camera sits inside the character mesh, filling the view with
  the model's interior. The body now renders shadows-only: still grounded by its
  own shadow, never occluding the camera.

## 10. Recorded audio, sliced to gameplay timing — `48e734c`, `2d6861d`, `ffd0652`, `9695742`

Supplied clips are long continuous takes, so playing them whole would ignore the
game's own timing. `scripts/audio/sliced_sfx_player.gd` seeks to a measured
onset, lets it ring, then stops before the next hit in the recording.

Onsets were **measured, not eyeballed**: with no ffmpeg or audio libraries
available, each clip was routed through a muted Godot bus with an
`AudioEffectCapture` tap and its amplitude envelope extracted.

- **Footsteps** — source walks at a fixed ~0.68 s/step against the player's
  0.42 s stride. Pitching the loop up 1.6× would have wrecked the timbre, so
  individual steps are triggered on the game's cadence instead.
- **Landing** — takes are *take-off scuff → landing thud*, with a varying gap
  (in one take the impact lands 0.43 s after the burst begins). Slices are
  anchored to each take's loudest moment so the thud plays, not the scuff.
- **Jump grunt** — three takes, rotating so consecutive jumps differ.
- Slices are cut mid-decay, so a short fade-out was added; without it the hard
  stop clicked on hits still ringing at the cut.
- Levels were balanced by measurement: the grunt was ~14× a footstep's peak.

## 11. "Where is the car?" — three bugs — `6ef3e74`

The car was unfindable and unusable. Diagnosing it headless turned up three
independent causes:

1. **The hood was ejecting the car.** The `Hood` is an `AnimatableBody3D` nested
   inside the car's chassis collision box; a kinematic body embedded in a
   dynamic one made the solver fling the car ~8 m sideways and through the
   floor. Confirmed by dropping a plain `RigidBody3D` and a bare
   `VehicleBody3D` at the same spot — both rested fine. The hood now sits on its
   own collision layer.
2. **The model faces +Z**, so the car drove backwards and the hood/engine slot
   sat over the trunk. Rotated 180° and repositioned every slot, wheel and the
   driver camera onto landmarks measured from the mesh.
3. **The player spawned inside the car's footprint**, facing away from it. Two
   tires also spawned overlapping the chassis.

Also replaced `create_trimesh_collision()` with hand-built shapes so backface
collision could be enabled: the station's ground is zero-thickness geometry
facing away from the play area, which rays and the kinematic player resolved
against but rigid bodies fell straight through.

---

## Verification approach

The Godot binary was found locally partway through the session, which changed
the workflow: instead of reasoning about correctness, changes were checked by
running the project headless and measuring.

What that caught, which inspection alone had not:

- The car sinking (`y: 0.1 → −1.84`) and tires free-falling to `y ≈ −17`.
- Which physics node was actually at fault, via controlled comparison.
- That every car-model part name resolves (hood + four wheels).
- That the engine refuses to install with the hood shut and installs once open.
- That every audio slice contains real audio, with no silent slices and no
  abrupt tails.

**A gap this exposed:** a startup-only smoke run proved nothing about code paths
that need input. A stale `play_step()` call survived a clean run because
headless never walks (`ffd0652`). Driving real input — walk, jump, land,
crouch-walk — now exercises those paths.

## Known caveats

- The character model is unrigged: no walk/idle animation, and its facing was
  never visually confirmed (it renders shadows-only, so a 180° error would only
  show in the shadow).
- Dirt and grass footsteps/landings still use the synthesized fallback; only
  concrete has recorded audio.
- Audio levels were balanced by measured amplitude, not by ear.
- Volumetric fog plus several shadow-casting lights is GPU-heavy and may want
  tuning.
- Prop placement inside the station was derived from bounding-box landmarks and
  has not been play-tested for reachability.
