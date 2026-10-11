# Immersive Identification — Technical Specification

> **Version:** 2.55.1 &nbsp;•&nbsp; **Engine:** X-Ray / xray-monolith (S.T.A.L.K.E.R. Anomaly / GAMMA), Lua 5.1
> **Repo:** https://github.com/dxshie/immersive_identification

This document describes how the mod is architected and behaves. It is derived
from a full read of the source; file:line citations point into the current tree.

---

## 1. What the mod does

The player aims at an NPC, creature, or stalker and presses an identify key
(default `DIK_X`). After a brief "scanning" pulse, a **world-anchored floating
card** appears attached to the target's body, naming its **faction, personal
name, rank**, and optionally its **held weapon**. The card fades in, holds for a
configurable duration, then fades out.

It replaces static HUD faction indicators (e.g. the FactionID mod) with a
diegetic, in-world label that tracks the target as it and the camera move.

Eight visual styles:

- **Card** (`ui_style = 1`): dark plate + faction icon + text lines + a leader
  line connecting to a colored dot on the target's chest.
- **Minimal** (`ui_style = 2`): just a faction-colored dot plus a relation glyph
  (`-` enemy / `+` friend / `o` neutral). The two elements reuse the existing content
  toggles — the dot honours `show_faction`, the sign honours `show_relation`; if both are off
  a neutral locator dot is drawn so the tag never fully vanishes. With `mini_dist_scale` on, the
  dot and glow follow camera depth and zoom (near = bigger, far = smaller), without a
  far-distance size floor. The relation glyph retains its native font size.
- **Simple** (`ui_style = 5`): a compact horizontal strip above the head — the
  Card style's relation-colored dot + glow, then the faction logo, then the name
  (`draw_slot`'s `ui_style == 5` branch). The dot, glow, logo, and spacing follow camera
  depth and zoom. The graphical group is centred on the anchor; the fixed-font name
  follows to its right, so name length cannot move the marker off the entity.
- **Simple 2** (`ui_style = 4`): a compact over-the-head cluster — a
  faction-colored circle (`ii_dot`) and a relation-colored triangle (`ii_tri`,
  pointing at relation) side by side, with a thin rank-colored bar above them
  (`rank_color`, novice grey → legend gold). Distance-scaled and anchored above
  the head like the PiP marker (`draw_slot`'s `ui_style == 4` branch). All shapes,
  including the rank bar, shrink continuously with camera depth and grow with zoom;
  no minimum pixel dimensions. With `show_relation` off the triangle is dropped entirely and
  the row (and the rank bar spanning it) closes up around the circle alone.
- **Bodycam** (`ui_style = 3`): an unfilled faction-colored rectangle outline
  locked to the target's **head bone**, auto-scaled with distance so it stays a
  constant real-world size around the head (a bounding box with padding). Four
  thin `ii_white` strips per edge (`draw_rect_outline`, shared with Patch style), with the target **name** and
  **weapon/caliber** (`e.weap`, includes caliber) stacked as shadowed text just to
  the right of the box (reusing the card's `tag_name`/`tag_weap` widgets). The box
  covers the head or the full body per **`box_area`** (`area_box_for`). The head box is the **screen bounding box of the head's four
  projected corners** (`screen_box`: `center ± cam_right*BOX_HALF_W ±
  cam_top*BOX_HALF_H`), perspective-correct at any screen position — a
  single-axis extent shortcut mis-sizes/mis-centres near the screen edges (the
  "slips off at the corners" bug). The centre is `bip01_head` lifted `HEAD_LIFT`
  (0.09 m) to the face (the bone sits at the skull base, so an unlifted box rides
  low over the neck). Distance scaling falls out of the projection (no `UI_KX`
  squeeze). With `box_color_source = relation` and `show_relation` off the box falls back to
  the **faction** colour — like Minimal 2, the box is the style's only cue, so a neutral box
  would say nothing. Pairs naturally with **Auto-identify** below.
- **Crooks** (`ui_style = 6`): not a per-entity tag at all — a single **static** screen-space
  readout of the **last-identified** stalker (faction **logo** + name, + rank if `show_rank`),
  anchored to a screen corner (`crooks_pos`) with X/Y offsets, the emblem sized by
  `crooks_icon_scale` and spaced from the text by `crooks_icon_gap` (`draw_crooks`).
- **Minimal 2** (`ui_style = 7`): the most stripped-down marker — a single bare **dot, no glow**,
  coloured purely by **relation** (red enemy / green friend / tan neutral, always relation-based
  regardless of `color_by_relation`). No sign, no text. With `show_relation` off it falls back to
  the **faction** colour rather than a flat neutral dot — this style carries nothing else, so a
  neutral dot would say nothing at all. **Always** distance-scales (near = bigger,
  far = smaller), like Simple / Simple 2, and follows camera zoom. Its centre stays
  at the projected anchor plus the configured offset, without a distance-based nudge.
- **Patch** (`ui_style = 8`): the **faction patch alone**, ringed by a **relation-colored
  outline** — "who they are" plus "friend or foe", with no text and no dot (`draw_slot`'s
  `ui_style == 8` branch). The patch is the same `<community>_icon` texture the Card style
  uses, drawn on the reused `tag_icon` static; the ring is four `tag_box_*` strips via the
  shared `outline` primitive. The ring colour is **always** relation-based (like Minimal 2's
  dot), regardless of `color_by_relation`. The ring is this style's **only** relation cue, so
  `show_relation` off **removes it entirely** rather than recolouring it — a neutral ring would
  be decoration claiming to carry meaning — and the layout closes up as if no ring were
  configured. `show_faction` off drops the patch, so with both off the style draws nothing,
  which is what the player asked for. **Always** distance-scales (near = bigger, far = smaller)
  and follows camera zoom, like Simple / Simple 2 / Minimal 2 — patch size, ring thickness, and
  the gap between them all scale together, so the marker keeps its proportions at any range.
  Sized by `patch_size` / `patch_thickness` / `patch_padding` (virtual px at the reference
  distance; defaults 13 / 2 / 0). A thickness of **0** also drops the ring and stops it padding the
  layout, leaving the bare patch. Patch width and horizontal padding are `UI_KX`-corrected so
  the patch stays square on wide screens. Sits just above the head anchor, like Simple 2.

Optionally, **Auto-identify** (`auto_identify`, default off) continuously reveals
every target in the player's view and in range, without a keypress or aiming. The target
directly under the crosshair identifies **immediately** (a cheap per-frame direct-hit pick), while
the rest of the scene is swept on a ~250 ms throttle (`level.iterate_nearest` → `identify_target`).
A swept target must be **on screen** (`in_view`: head anchor or feet projects inside the viewport,
so targets behind the camera never take tag slots) and have LOS. The sweep is independent of
`fov_identify_all`. When `hide_off_aim` is on, the sweep is aim-scoped (only targets inside
`fov_radius`).
Line of sight is always required for it. Works with any style.

Identification difficulty is expressed **entirely as reveal delay** (scan time),
not as pass/fail. **There is no RNG anywhere** — the outcome is fully
deterministic; distance, rank, darkness, weather visibility, combat pressure, binoculars,
perception skill, and prior familiarity only speed up or slow down how long the scan takes.

---

## 2. Repository layout

```
gamedata/
  scripts/
    ii_identify.script          Coordinator: modes, target selection, callbacks
    ii_api.script               PUBLIC add-on API: third-party UI style registration
    ii_config.script            Defaults, menu lists, live configuration loading
    ii_frame.script             Reusable per-update camera/object/bone/query cache
    ii_visibility.script        Transparency-aware geometric LOS and ray scratch
    ii_weather.script           Rain/storm/fog and optional visor-droplet scan severity
    ii_combat.script            Combat-state, direct-hit, and hostile near-miss pressure
    ii_tracking.script          Admission, stable slots, refresh and reveal phases
    ii_ui.script                Widget pool, measurement, placement, drawing
    ii_mcm.script               MCM settings-menu definition (~207 lines)
  configs/
    text/eng/st_ii_texts.xml    String table (windows-1251)
    ui/ii_tags.xml              CUIStatic widget templates (card/minimal/bodycam/simple2/debug)
    ui/textures_descr/ii_textures.xml   Texture id -> file registration
    presets/                    includes.ltx + presets_ii.ltx (MCM preset values)
  textures/ui/*.dds             ii_white, ii_dot, ii_node, ii_spinner, ii_shadow, ii_tri, ii_ring
  shaders/r3/*.ps               bodycam svp-marker / overlay (custom exe)
fomod/
  info.xml                      Name/Author/Version 2.55.1/Website
  ModuleConfig.xml              Installer: base + optional compatibility components
FactionID Neutralized/          Optional: no-op override of FactionID's HUD script
GRIP Patches/                   Optional: maps ii_patch_* onto Kos' GRIP's faction atlas
GAMMA Patches/                  Optional: same, for G.A.M.M.A. UI's (different) atlas
HD Faction Patches/             Optional: bundled Leekos HD atlas + ii_patch_* mapping
Perception Skill Integration/   Optional: adds a "perception" skill to Skill System
examples/                       Example add-ons: two UI styles + a faction-patch template
types/                          EmmyLua engine stubs for the LSP
flake.nix, .luarc.json          Nix dev tooling (xmllint / LuaLS / packaging)
```

The mod installs as a `gamedata/` overlay merged over the base game via Mod
Organizer 2's virtual file system. Compatibility add-ons are pure VFS overlays —
neither edits a host mod's files.

---

## 3. Runtime architecture (`ii_identify.script`)

`ii_identify` remains the public entry point for MCM and compatibility components.
It re-exports `ii_config`'s defaults and menu lists, owns the callbacks and external
readouts, and wires the helper modules together with explicit references. Helpers
register no callbacks and do not depend back on the coordinator.

`ii_frame` starts one cache epoch per `actor_on_update`, ending it on every return
path. Camera, active-item and aim-mode queries are shared within that update;
key callbacks outside it read live state. Object records and bone-sample tables
are pooled, with results invalidated each update. Missing bone IDs are rejected
before `bone_position` can silently substitute the root bone. Cached vectors are
read-only; lifted anchors use separate scratch vectors. Body-to-aim distance and
geometric LOS results are shared by acquisition and rendering within the update.
LOS is still refreshed every frame; no extra cross-frame visibility delay is added.

### 3.1 Lifecycle / entry points

`on_game_start()` (4398-4414) is the sole bootstrap:

1. `read_config()` — load MCM/defaults (4399)
2. `install_key_hook()` — wrap `level_input.on_key_press` (4400)
3. Register the multi-subscriber callbacks (4401-4413): `actor_on_update`,
   `actor_on_before_death`, `on_option_change`, `save_state`, `load_state`,
   `actor_on_hit_callback`, optional `bullet_on_update`, and
   `actor_on_weapon_zoom_in`/`actor_on_weapon_zoom_out` (the latter two are
   anonymous one-liners that set/clear `_ads.zoomed`, the ADS flag — kept anonymous
   so they add no top-level locals against Lua 5.1's 200-per-chunk limit).

- **Key hook** (`install_key_hook`, 2487): monkey-patches
  `level_input.on_key_press`, saving the previous handler and chaining to it via
  `pcall` so it **cooperates** with other mods rather than seizing the single
  native slot. On a matching DIK + modifier (and `not disabled`) it calls
  `try_identify()`.
- **Per-frame driver** (`actor_on_update`, 4323-4355): always runs
  `update_fov_baseline()`; polls actor death → `teardown_ui()`; then when enabled
  runs `ensure_tags()`, `update_binocular_scan()`, `update_auto_identify()`,
  `update_ads_range_snapshot()`, `update_binoc_clear()`, `update_loot_xp()`, and `render()`.
- **Render surface** (`ensure_tags`, 3631): lazily creates the `IiTags`
  (`CUIScriptWnd`) dialog and registers it with `get_hud():AddDialogToRender()`.
  There is **no separate render callback** — drawing is done by repositioning
  persistent widgets each `actor_on_update` frame.
- **`on_option_change`** (4384-4386) re-reads config live when MCM changes.
- **`actor_on_before_death`** (4393-4396) tears the UI down at the moment of death
  (the death screen can freeze `actor_on_update` with the last frame's tags still
  drawn), backed up by the `actor_on_update` death poll.
- **`save_state` / `load_state`** (4369-4379) persist `xp_awarded`, `remembered`,
  `loot_xp_awarded`. Live reveal state (`tracked`) is intentionally not saved.
  Callbacks are declared `local` to avoid clobbering same-named globals in other
  scripts.

### 3.2 State machine

Central table `tracked` (owned by `ii_tracking`): `[obj_id] = { slot, t0, last_seen_tg, col, fcol, sign, header, name,
icon, rank, rank_col, weap, scan_ms, max_dist, fade_ms, hold_ms }`, capped at
`MAX_TAGS = 12`. Each entry owns a stable widget slot until removal. Scene sweeps
refresh existing entries and fill free slots in nearest-first order, without evicting
active scans when a crowd exceeds capacity. Manual picks and directly aimed targets
may replace the oldest entry (lowest `t0`, ties resolved by slot order). Capacity and
continuous-refresh checks precede scan-penalty computation, so an ordinary refresh
does not repeat rank, weight, foliage, target-light, or skill work. (There is no distance-based fade — the `fade_dist` property was removed; tags
stay full-opacity to the range cutoff.)

`hide_unseen` removes a tracked entry after 150 ms of continuous geometric
occlusion; it does not merely hide the widgets while retaining the reveal timer.
An identification trigger must acquire the target again after removal.

Each entry runs a **time-based state machine** keyed on
`elapsed = time_global() - t0`, evaluated every frame in `render()` (3969).
`total = scan_ms + fade_ms + hold_ms + fade_ms`:

| Phase | Condition | Visual |
|---|---|---|
| Scanning | `elapsed < scan_ms` | rotating spinner only, alpha 0 |
| Fade-in | `< scan_ms + fade_ms` | alpha ramps 0 → 1 |
| Hold | `< scan_ms + fade_ms + hold_ms` | full card, alpha 1 |
| Fade-out | else | alpha 1 → 0 |
| Removed | `elapsed > total`, or object gone/dead | — |

**Snapshot-at-identify:** all timing/range params are frozen into the `tracked`
entry at identify time (`identify_target`, 2097) and read from the entry during
render, so live MCM edits or lowering binoculars mid-reveal never retroactively
distort an in-progress card.

**Re-identify while tracked** (`identify_target`): keyed on the gap since the target was last
identified (`last_seen_tg`). A **look-away-and-back** (gap ≥ `REIDENTIFY_GAP_MS`, longer than the
~250 ms continuous auto/dwell cadence) drops the entry and re-scans from scratch; a **continuous**
re-touch (auto/dwell holding a target) stays under the gap and just refreshes — so the spinner
doesn't strobe while a target is held, but a genuine re-look re-runs the scan. A revealed tag past
its hold restarts its **fade-in** rather than popping to full.

**`hide_off_aim` ("Only show overlay while aimed")** turns this into a strict list-membership gate:
while on, a target not under the aim (outside `fov_radius` and not the direct mesh hit) is **removed
from `tracked`** each frame, and auto-identify is aim-scoped — so aiming away drops the target and
aiming back re-runs the whole scan.

### 3.3 Target selection

`get_target_obj(max_dist, allow_fov)` — a cascade:

1. Weapon-aligned trace: `get_target_obj(ETraceTarget.Weapon)` — the barrel-accurate
   pick (global enum; reflects free aim for firearms), tried **first** so it wins over the
   swayed render-camera trace below. A **fresh** (not-yet-tracked) hit here wins immediately.
2. Direct **model raycast**: `aim_model_target(max_dist)` — the stalker whose MODEL
   the crosshair is directly on (mesh raycast along the true aim ray; works for knife/binoculars
   too via the fire ray — §10). "Identify what I'm aiming AT", so it takes **priority over a
   merely-nearby FOV-cone pick** and is returned even if already tracked (a re-aim refreshes it).
3. Camera trace fallback: `level.get_target_obj()`.
4. FOV fallback: `find_nearest_in_fov(max_dist)` — **only if `allow_fov`**.
   `try_identify` passes `allow_fov` = `fov_assist_binoc` through raised binoculars, `fov_assist`
   otherwise. With it off, identification is direct-hit only.

Candidates are **LOS-gated** via `accept()` → `has_los()` because the engine's crosshair pick
sees *through* semi-transparent geometry and can return an occluded object.

**`has_los` — geometry is the authority** (the `db.actor:see()` AI-vision gate was **removed**):
`see()` is a visual-memory lookup limited by AI vision *range*, an *FOV cone*, and target
*luminosity* (driven by the AI head, not the render camera), so it false-negated on exactly this
mod's cases — a distant scoped/glassed target, a peripheral one, or one in shadow, all clearly on
the player's screen. So `has_los` is now:

1. **Direct mesh hit** (the target the crosshair is on this frame, `aim_model_target`, cached per
   `time_global`) → clear. The aim ray already proved a line to the model past any opaque blocker.
2. Otherwise **`has_clear_ray(target)`** — a **transparency-aware** `ray_pick` march (rqtStatic)
   from the target's body points toward the render camera. It **skips see-through** hits
   (fences/foliage/glass and wide invisible **clip meshes**, via the material's
   `fVisTransparencyFactor`) and only an **opaque** surface blocks. Samples multiple real bones —
   **head + shoulders** first (peek detection), then spine/pelvis/calves; the real head bone (not
   a lifted anchor that can clip a ceiling); any clear ray = visible. A non-`bip01` rig falls
   back to the lifted anchor point.

**See-through / foliage blocking** (opt-in, `los_block_seethrough` / `los_block_foliage`): the
march normally *skips* see-through hits, but these toggles make them block. `los_block_seethrough`
blocks **all** see-through surfaces (fences/glass/foliage/clip). `los_block_foliage` blocks only
hits whose `material_name` matches a plant token (`_los.foliage`, best-effort substring set) — so
plants block but fences/glass still pass. When either is on, `has_los` **skips the mesh-hit
override** and always runs the march (the mesh pick sees through exactly these surfaces, so it
can't be trusted to enforce the block). Debug draw's info panel shows the `front:` material name +
transparency of the first surface to the aimed target, for tuning the foliage token list.

Fails open (returns visible) on an engine error or absent `ray_pick`. `tag_visible` (the
`hide_unseen` drop) uses the same pure-geometry check for the same reason.

`find_nearest_in_fov` iterates `level.iterate_nearest`; a candidate must be
non-actor, `is_npc` (i.e. `IsStalker` — see "Mutants are never targets" below), alive, have a non-empty
`character_community`, (if `require_los`) pass LOS, and (if `exclude_hostile`) not be hostile-and-
engaging. It selects the candidate **nearest to the aim point** within the assist tolerance, not
nearest in world space. Already-tracked targets are held as a runner-up and only returned if
nothing else qualifies.

**Mutants are never targets.** Every admission point (`find_nearest_in_fov`,
`get_target_obj`'s `accept`, `aim_model_target`'s `accept_npc`, both auto-identify sweeps and the
debug overlays) goes through **`is_npc(obj)` = `IsStalker(obj)`**, so a `CBaseMonster` is dropped
before anything reads it. The reason is the engine: a monster is neither a `CInventoryOwner` nor a
`CAI_Stalker`, and `character_community` / `character_name` / `character_icon` / `rank_name` /
`best_weapon` answer such an object by writing `"<call> available only for InventoryOwner"` **plus
a full Lua stack dump** to the log and returning nil — via `script_log`
(`src/xrGame/script_game_object_inventory_owner.cpp:1039`, `script_storage.cpp`'s
`print_stack`), *not* a raised error, so `pcall`/`safe_call` cannot swallow it. A mutant therefore
has no community to put on a tag, and admitting one only produced log spam. The `monster`
entries that remain in `FACTION_NAMES` / `FACTION_COLOR` / the icon atlas mapping are inert.

**Assist radius** (`assist_radius()`, the single source for every `fov_radius` comparison —
selection, the `aimed`/`under_aim` dwell tests, and the debug ring): `fov_radius` is a screen-px
tolerance measured to the target's **silhouette**, so a fixed pixel count is *not* a fixed amount
of forgiveness — at 4x the same 35 px spans a four-times-wider world cone, making the assist
grabbier exactly where the player aims most precisely. With **`fov_zoom_scaling`** on (default)
the radius is divided by the live `scope_magnification()`, holding the forgiveness constant in
world terms. It stays usable at high zoom because the silhouette it is measured from grows by the
same factor the radius shrinks by. Floored at `_ZOOMCFG.assist_min_px` (4) so an extreme optic (a
binocular's raw angular ratio runs ~19x) cannot collapse it to direct-hit-only; `fov_radius = 0`
means the player disabled the assist and stays 0. Off = the pre-existing flat screen radius at
every zoom level. The debug-draw ring and its label both show the **effective** radius, with the
configured value and magnification appended whenever zoom has shrunk it.

**Exclude hostiles** (`exclude_hostile`, off by default): `is_hostile_engaging(obj)` returns true
when the NPC's AI combat target is the actor (`best_enemy()`, guarded) OR it is enemy-disposed
(`relation == enemy`) AND currently sees the actor (`see()`) — i.e. it has pulled aggro and will
attack. When on, such entities are filtered out of selection (so the assist picks another target)
AND rejected at the `identify_target` choke point (so no path — key / auto / dwell / sweep — can
identify one). A target identified BEFORE combat that later turns hostile is also **dropped from
`tracked` per-frame** in the render loop (alongside `hide_unseen`/`hide_off_aim`), so its tag
disappears the moment you engage it — consistent with never being able to acquire one. All engine
calls are guarded, so a missing binding degrades to "not hostile".

**Reading the PDA — unconditional block** (`pda_focused()`, no setting): identification is an act of
*looking at the target*, so a player looking at the PDA screen instead identifies nothing. The state
is read from the PDA window's own input flag — `ActorMenu.get_pda_menu():IsShown()` **and**
`:IsEnabled()` — which tracks exactly the right thing:

- **3D PDA** (`g_3d_pda`, GAMMA's default) comes up *shown but disabled* (`CPda::UpdateCL`:
  `ShowDialog(false)` then `Enable(false)`) — the device sits low, the world is still in view, so
  identification stays live while you merely hold it.
- **Right-click** (`kWPN_ZOOM`), **left-click** (`kWPN_FIRE`) and **R** (`kWPN_RELOAD`, the zoom
  toggle) each call `pda->Enable(true)` and raise it to the face (`CPda::Action`) — that's the block.
  `m_bZoomed` moves in lockstep with the flag (zoom implies `Enable(true)`; losing `Enable` clears
  `m_bZoomed` in `UpdateHudAdditional`), and `m_bZoomed` itself is unreachable from Lua — `CPda` is
  bound with **no methods at all** (`torch_script.cpp`: `class_<CPda, CGameObject>`, constructor
  only) — so the window flag is both the proxy and the exact signal.
- **Classic fullscreen PDA** (3D PDA off) never enters the hands; `ShowPdaMenu()` shows a dialog that
  is enabled by default, so the same test covers it.

While it holds: the `identify_target` choke point rejects every path, `update_auto_identify` returns
early, and `update_binocular_scan` **disarms** the ADS / hipfire dwells and the binocular steady
anchor (so unzooming can't fire a dwell that "held" for as long as the map was open). `render`
also **clears `tracked`** and hides every slot, the Crooks readout and the in-scope markers (one
empty `svp_ui_markers_begin`/`commit` pair, or the render thread would keep drawing the last scoped
frame's). So raising the PDA *drops* what was identified rather than leaving cards pinned to a world
the player isn't looking at, and lowering it re-scans from scratch instead of restoring a stale set —
the same reasoning as disarming the dwells rather than pausing them. (`familiarity_boost` makes the
re-scan of an already-known target quick.) Debug draw is deliberately left running, and its info
panel shows `PDA focused: identification blocked` while it applies.

**The assist is a straight screen-pixel radius** around the aim point (no angular
cone):

- `aim_center()` / `weapon_aim_ui()` give the aim point on screen — the weapon's real
  aim point when free-aim assist is on and available, otherwise the fixed screen centre.
- `screen_dist_to_body(obj, cx, cy)` returns the smallest screen-pixel distance from the
  aim point to any sampled `BODY_BONES` point projected via `project_world` (head/torso/
  pelvis/limbs — so aiming anywhere on the entity counts); a vertical span at the origin
  backs up non-`bip01` rigs.
- A candidate matches when `screen_dist_to_body(obj) ≤ fov_radius` (fov_radius in
  1024×768 virtual px).

When nothing falls inside the radius, `find_nearest_in_fov` falls back to
`aim_model_target(max_dist)` — a mesh raycast along the **true aim ray** (the bodycam
first-eye fire ray when available, else the standard `get_target_obj(ETraceTarget.Weapon)`
barrel trace), range-gated by `max_dist` — so aiming directly at a target's model still
identifies it even if it's too close, or the crosshair sits just off the projected silhouette.
This is the same direct-aim pick used when FOV assist is off. (The earlier angular-cone approach
was removed; the screen radius is simpler and fits this mod's use better.)

### 3.4 Scan-time computation

`try_identify()` (2244) resolves the target and hands it to `identify_target`
(2097), which commits immediately; the visible delay `eff_scan_ms` is `SCAN_MS`
multiplied through a chain of factors (or skipped entirely when `instant_identify`
is on):

| Factor | Function | Range |
|---|---|---|
| Distance | `distance_scan_mult` | 1× point-blank → `dist_penalty_max` at cutoff (vs `eff_max_dist`) |
| Rank | `rank_scan_mult` | 1× novice → `rank_penalty_max` legend |
| Weight | `weight_scan_mult` | 1× at 0 kg → `weight_penalty_max` at `weight_penalty_ref` kg (held item's `inv_weight`); **off by default** |
| Foliage | inline (`_los.saw_foliage`) | flat `foliage_penalty_max` if the sightline to the target crosses a foliage material; one LOS march at commit; **off by default** |
| Target visibility | `target_visibility_scan_mult` | target renderer luminance 0 → `night_penalty_max`, easing to 1× at `night_luminance_threshold`; responds to shadow and dynamic lights, falls back to clock darkness, optional NVG bypass |
| Binoculars / ADS | `scan_mult` from `boost_params` | flat multiplier while raised/aiming (if the matching `*_boost`) |
| Perception | `perception_scan_mult` | `1 − perception_scan_mult × level`, floored |
| Combat | `ii_combat.scan_mult` | `combat_penalty_mult` while engaged; `combat_pressure_mult` for a timed window after a direct combat hit or hostile near miss |
| Weather visibility | `ii_weather.scan_mult` | 1× clear view → `weather_penalty_max`; strongest of exposed rain, storm rain/wind, fog at target distance, and optional visor water |
| Familiarity | `familiarity_scan_mult` | applied if `remembered[id]` |

`instant_identify` zeroes the wait, but the **per-mode excludes** (`instant_exclude_hipfire/ads/binoc`)
keep the normal scan wait for a chosen aim mode. Under the WD tier system, every enabled penalty
applies to the process tier's fixed base time, with its slowdown above 1× scaled by that process
tier's configurable penalty strength (§7.4).

Target visibility samples `obj:get_luminocity()` once when the scan commits. The demonized engine
binding exposes the renderer's 0..1 object-lighting value, including ambient, sun, shadowing, and
dynamic lights. Severity is `1 − clamp(luminance / night_luminance_threshold)`, so a flashlight can
reduce the same penalty that darkness creates. Missing or failed bindings fall back to the world-clock
`darkness_factor`; active NVGs and the WD no-night scanner tier force the resulting multiplier to 1×.

`ii_weather` samples interpolated engine weather only when a scan commits. Fog follows the
renderer’s linear fog interval at the target distance. Rain and storm wind apply only while the
actor is exposed. The optional wet-visor integration reads Anomaly/GAMMA's persisted
`r2_drops_control` droplet strength when a gas mask is active. These sources describe overlapping
visibility loss, so the strongest severity sets one capped multiplier instead of multiplying them
together. Missing script APIs safely contribute zero.

`ii_combat` polls Anomaly's `xr_combat_ignore.fighting_with_actor_npcs` registry at 250 ms
intervals and keeps a 10-second combat inertia after the last active attacker. A confirmed positive
hit from a non-actor attacker starts the stronger pressure window through
`actor_on_hit_callback`. Demonized's `bullet_on_update` starts the same
window when a non-actor bullet passes within `combat_near_miss_radius`; outside established combat,
the shooter must be enemy-disposed toward the actor. The callback does only a squared-distance test
until a bullet is actually near the actor. Repeated hits and near misses extend the configured window.
If the custom bullet callback is unavailable, general combat and direct-hit pressure continue to work;
only near-miss detection is absent.

Gating (`try_identify`): `enabled` + actor exists; if `require_binoculars`,
`is_binoc_active()` must be true; target exists, is not the actor, is alive, has a
community, and is within `eff_max_dist`.

### 3.5 Binoculars

- `is_binoc_held()` (1521): `active_item():section()` contains
  `BINOC_SECTION = "wpn_binoc_inv"`.
- `is_binoc_active()` (1571): additionally requires camera FOV to have dropped
  below `FOV_ZOOM_RATIO (0.7) × _fov_baseline`; the baseline self-calibrates each
  frame from the widest FOV seen while binoculars aren't held
  (`update_fov_baseline`, 1560).
- `binoc_boost` widens `eff_max_dist` by `binoc_range_mult` (default **4.4**) and speeds the scan
  (`boost_params`). With `binoc_zoom_scaling` **on**, the range multiplier is instead the
  binocular's **real current magnification** (`binoc_magnification`: the SVP/PiP engine value read
  directly, else the camera-FOV ratio); **off** uses the flat `binoc_range_mult`. The effective
  range is then clamped by `binoc_max_dist` (0 = no cap).
- **Steady auto-identify** (`update_binocular_scan`, 2445): when `binocular_mode` is
  active, tracks a "steady" camera direction against an anchor
  (`STEADY_MAX_D2 = 0.002`, ~2.6°); held steady for `steady_time` it fires a
  **sweep** (`sweep_identify_in_fov`, if `fov_assist_binoc` **and** `fov_identify_all`) or a direct
  `try_identify(true)` (otherwise — nearest to aim), throttled by `STEADY_SWEEP_MS` so it keeps
  re-sweeping while held. ADS uses a separate dwell trigger (§3.5b).

**`fov_identify_all`** (default on) governs the automatic paths' all-vs-nearest choice: the
hipfire/ADS/binocular dwell sweeps (`sweep_identify_in_fov`, all in the assist ring) run only when
it's on **and** the relevant `fov_assist*` is on — otherwise they identify the single nearest to
the aim (`try_identify(true)`). Auto-identify is **not** affected (it sweeps everything in view
regardless). The manual keypress always identifies the nearest (unaffected).

### 3.5b Aim Down Sight (ADS)

Mirrors the binocular boost for regular weapons. `is_ads_active()` (1590) detects
aiming down sight on **any exe**, in priority order:

1. **PRIMARY: `_ads.zoomed`** — a flag driven by the stock
   `actor_on_weapon_zoom_in`/`_out` callbacks (registered in `on_game_start`). This
   works on any engine and catches **1× optics** that change no FOV — the case the
   heuristics below can't see. Self-heals a stuck flag: if it's set but the actor has
   no active item in hand (holstered/switched), it resets and reports hipfire.
2. `bodycam.get_state().ads` — only trusted while the bodycam logic is **active**
   (`st.active`); when disabled the field is stale/false.
3. A live PiP scope (`is_svp_active()`) — a scope narrows the *second* viewport, not
   the main FOV, so the heuristic below can't see it.
4. FOV-zoom heuristic: `device().fov < _fov_baseline × ADS_ZOOM_RATIO (0.85)`.

Binoculars are excluded (`is_binoc_held` checked first) so ADS and binocular boosts
never stack. `boost_params()` returns
`(binoc, ads, boosted, eff_max_dist, scan_mult)` — binoc takes
priority, then ADS, each carrying its own `*_scan_mult` / `*_range_mult` from its
MCM section; `identify_target` applies the returned `scan_mult`. The effective range is then
clamped by the **active mode's hard cutoff** (`apply_mode_cap`: `hipfire_max_dist` /
`ads_max_dist` / `binoc_max_dist`; 0 = no cap) so runaway magnification can't over-extend it. Its
own MCM section: `ads_mode`, `ads_hold_time`, `ads_boost`, `ads_scan_mult`, `ads_range_mult`
(x1 base, **default 1.0**), `ads_zoom_scaling`, `ads_hide_main`, `ads_block_thermal`, `ads_max_dist`,
`instant_exclude_ads`.

**ADS auto-identify is dwell-on-target** (`update_ads_dwell`, 2394), distinct from
the binocular *steadiness* trigger: it requires a valid target to be **continuously
present under the aim** — directly, or inside the FOV-assist cone when `fov_assist`
is on — for `ads_hold_time` seconds, then auto-identifies (and keeps identifying,
throttled, while a target stays there). Holding still on empty air does nothing; you
*can* track a moving target. `fov_assist` on → `sweep_identify_in_fov` (all targets
in the cone); off → `try_identify(true)` (just the one under the aim). The presence
raycast is throttled to 100 ms; the dwell timer uses `time_global` so it stays exact.

**Thermal-scope block** (`ads_block_thermal`, off by default): while ADS, the live S3DS
`s3ds_param_3` image type is read from the console parameter. Image types 2 (thermal) and 3
(coloured thermal) reject every manual/automatic path at the `identify_target` choke point and
cancel an in-progress scan before it reveals, as well as disarming the ADS dwell. Because the live
parameter is used, a switchable optic in its normal-image mode is not blocked. Existing revealed
tags are left alone.

**Zoom-scaled range**: with `ads_zoom_scaling` on, the ADS range multiplier is
scaled by the current scope magnification — `range_mult = ads_range_mult × mag` —
so higher-power optics reach further (`ads_range_mult` is the x1 base). The magnification is **hybrid**, so it works with or without a PiP engine and
tracks dynamic zoom live in both: (1) on a PiP engine the zoom lives in the second
viewport (main FOV unchanged), so the new engine binding `svp_scope_magnification()`
— which returns the SVP `svp_mag` "zoom scaled trigger" (1.0=1x .. ~8x, -1 when not
scoped) — is the only accurate source; (2) with no PiP (or when the binding reports
nothing), a non-PiP optic narrows the **main-camera FOV**, so magnification is
recovered as `_fov_baseline / device().fov`. Iron sights / un-magnified aim stay at
the x1 base (`MAG_FOV_MIN = 1.05`).

**Out-of-range cull** (in `render`'s tracked loop, every frame): a tag whose target now sits
beyond the **live** `boost_params()` range is dropped. Per-instance `e.max_dist` is the range
snapshotted at identify time, so on its own it can never notice the range shrinking underneath
it — and the range shrinks by the *whole zoom factor* the moment magnification goes away (scope
lowered, binoculars down), which would otherwise strand every distant tag you had just earned.
Also covers either party simply walking apart. Measured against the same range identification
uses, so what stays tagged is exactly what could be re-acquired right now.

**Zoom-out range re-snapshot** (`update_ads_range_snapshot`): on the ADS-boost active→inactive
edge, surviving tags' `e.max_dist` is re-snapshotted to the base range, keeping it (and the draw
gate that reads it) coherent. It no longer *drops* anything — the per-frame cull above owns that
for every cause, which is also why binoculars need no special case here any more.

**Steady auto-trigger uses auto semantics**: `try_identify(auto_mode)` — the
steady-aim trigger (binocular / ADS mode) passes `true`, so `identify_target`
refreshes an already-revealed target's hold window instead of restarting its
reveal. Without this, ADS combat aim (constant micro-adjustment re-arms the steady
trigger) re-scanned already-identified targets every re-fire — the "double
identification" retrigger, most visible in-scope as the marker flicking back to
the scanning spinner. A manual keypress (`nil`) still restarts on purpose.

**PiP toggles**: `pip_markers` gates the whole in-scope UI path (`pip_active =
pip_markers and PIP_AVAILABLE and is_svp_active()`) — off reverts to normal
HUD/main-pass behavior.

**Suppress main-view drawing**: `suppress_main = (ads_hide_main and is_ads_active())
or (pip_hide_main and pip_scope)` hides ALL main-view tag drawing (adds to the
`pip_active or suppress_main` hide-slots-and-return). The in-scope UI is unaffected, so with a
PiP scope up you get in-scope-only rendering. `pip_scope` is the physical scope
state (independent of `pip_markers`), so this also covers `pip_markers`-off.

### 3.6 UI rendering

`IiTags : CUIScriptWnd`, rect 1024×768, is declared by the coordinator; `ii_ui.install`
supplies its widget methods. It parses `ii_tags.xml` via `CScriptXmlInit`.
`InitControls` builds `MAX_TAGS` slots of widgets in draw
order (shadow → line → plate → accent → icon → text → node/glow → spinner →
bodycam box edges → Simple 2 circle/triangle/bar), plus the debug dot/text pool. Patch style
reuses `tag_icon` for the patch and the `tag_box_*` edges for its relation ring.

- **Rendering data flow:** the coordinator fills a reused render record in each
  tracked entry's stable slot, then calls `draw_slot(slot, record, time)`. Card
  measurement is cached separately from placement and widget updates. Style/scan
  transitions reset the slot's widget set; unchanged text and visibility do not
  repeat native setter calls. Bodycam's missing lines/boxes still hide immediately.
  Distance-label strings are rebuilt only when the rounded distance changes.
- **Suppressed views:** PiP-only, hidden-main, OSD-only, and Crooks modes skip
  unused per-entity HUD layout. Identification phases and external readout snapshots
  continue.
- **World-to-screen:** `anchor_pos(obj)` picks the first of `ANCHOR_BONES`
  (`bip01_head`, `bip01_spine2/1`, `bip01_spine`) within 3m and lifts by
  `ANCHOR_LIFT = 0.12`; a rig without those bones falls back to `position().y + 1.3`. `project_world`
  calls `game/level.world2ui`, rejecting `x < -9000` (off-screen/behind). The render tag anchor
  goes through **`ui_anchor_pos(obj)`**, which honours the `anchor_basis` list — Head (default;
  = `anchor_pos`), Torso (`bip01_spine2/1`), or Feet (`position()`) — for the card + all dot
  styles + the in-scope marker. `anchor_pos` itself stays head-biased for LOS/foliage geometry
  regardless; the Bodycam box uses its own `box_area`.
- **Relation gating** (`show_relation`): folded in at snapshot time like the other content
  toggles — `show_rel` (MCM toggle **and** the WD tier's `ft.relationship` gate) drives both
  `col` (→ `COL_NEUTRAL`) and `sign` (→ **`nil`**, not `"o"`). Field *absence* is the signal, the
  same idiom as `name`/`rank`/`weap`, and every `SIGN_COLOR[sign]` lookup degrades to
  `COL_NEUTRAL` for free (indexing with a nil key is legal in Lua and returns nil). Card and
  Simple then go neutral automatically via `col`; the styles whose *only* cue is relation fall
  back to something that still says something — Minimal drops the glyph, Simple 2 drops the
  triangle and re-centres the row, Minimal 2 and Bodycam switch to the faction colour, and Patch
  drops its ring outright, since the ring is that style's only relation cue and a neutral one
  would be decoration claiming to carry meaning. Because it is snapshotted, an already-revealed
  tag keeps its old relation state until re-identified (as with every `show_*` toggle).
- **Faction patch ids** (`faction_icon_id` / `custom_patch_id`): the emblem every style draws is
  a registered **texture id**, not a path. By default `<community>_icon` — the convention the
  game's own character/relations UI uses (`UICharacterInfo.cpp`) — so the mod ships no emblem art
  and inherits whatever the modpack has. With **`custom_patches`** on it is
  `ii_patch_<community>`, which the player registers in their own `configs/ui/textures_descr`
  XML; `examples/custom_faction_patches/` is a template. Nothing ships for those ids and there is
  no engine call to ask whether a texture id exists, so the option is deliberately
  **all-or-nothing** rather than per-faction: an unregistered id draws nothing. Both ids are
  built once per identify (`icon`, `icon_custom` on the tracked entry) and the choice is made
  **per frame** in `render`, so the toggle applies to tags already on screen — what makes
  iterating on patch art bearable — without a per-target, per-frame string concatenation. Every
  consumer is covered: the Card/Simple/Patch tags, the Crooks readout and the OSD snapshot all
  read the same field.
- **Patch aspect ratio** (`texture_aspect` / `set_patch` / `place_fit`): the emblem is drawn
  **fitted**, never stretched. `set_patch` swaps the texture and, only on a real id change, reads
  `CUIStatic:GetTextureRect()` — which returns the *region* declared in `textures_descr`, so it is
  the art's true shape even for one tile of an atlas — and caches the ratio on the slot.
  `place_fit` then letterboxes that ratio inside the box the style allotted and applies the
  `UI_KX` width correction on top. Letterbox rather than the engine's `tmCover`, which would crop
  a patch's edges off. Two distortions are removed at once: a square patch stretched by the
  anisotropic virtual→screen stretch (Card and the Crooks readout never corrected for it), and
  non-square art squashed into a square box. The drawn size never exceeds the box (`UI_KX` ≤ 1
  above 4:3), so callers that reserved layout space — the Card's icon span, Simple's row slot —
  stay valid, and a nil aspect falls back to filling the box. Covers all four emblem sites:
  Card, Simple, Patch and Crooks.
- **UI styles** (`ui_style`): 1 Card, 2 Minimal, 3 Bodycam, 4 Simple 2, 5 Simple, 6 Crooks, 7 Minimal 2 (bare relation dot), 8 Patch (faction patch + relation ring).
- **`draw_slot`** branches: for **Crooks** (`ui_style==6`) it hides the per-entity slot and bails
  (Crooks is a single static readout — see below, which carries its own scan spinner); otherwise
  scanning spinner only → minimal
  (node+glow+glyph, `ui_style==2`) → **Minimal 2** (bare relation dot, `ui_style==7`) →
  **Simple** (dot+glow, faction logo, name strip, `ui_style==5`) → **bodycam** (head-outline
  box, `ui_style==3`) → **Simple 2** (circle+triangle+rank bar, `ui_style==4`) → **Patch**
  (faction patch + relation ring, `ui_style==8`) → mini fallback below `mini_scale_cutoff`
  (node+glow; its internal mode sentinel is `-1`, deliberately outside the real `ui_style`
  range so a style switch still resets the slot's widgets) → full card (measured text,
  plate, accent, icon, shadowed text lines, node/glow, leader line). The bodycam box's
  centre/extents (`box_cx/cy/hw/hh`) are precomputed per target in `render` (via `area_box_for`)
  since `draw_slot` has no world access.
- **Crooks** (`draw_crooks`, called once per frame from `render`): a single **static** screen-space
  readout of the **last-identified** target — faction **logo** + name (+ rank if `show_rank`),
  anchored to a screen corner (`crooks_pos`) with `crooks_x`/`crooks_y` offsets, its emblem scaled
  by `crooks_icon_scale`, spaced by `crooks_icon_gap` (which is NOT scaled with it), and centred
  on the WHOLE readout (name, or name + rank), not on the name
  line alone. Shows only while
  its target is still in `tracked` (the reveal-window linger, or — under `hide_off_aim` — only
  while aimed), following your gaze via the per-frame direct-hit id.
  While a scan is in progress **on the aimed target** the block instead shows the rotating scan
  spinner (`tag_spinner`, its own widget in the Crooks block) in the emblem slot at the same
  anchor — same corner preset, same `crooks_x`/`crooks_y`, sized from `crooks_icon_scale` ×
  `spinner_scale` — and the previous target's readout is hidden for the duration, so the block
  never shows a stale name beside a spinner. The flag that drives it (`_last_id.crooks_scan`,
  set in `render`'s per-target loop) is scoped to the **aimed** target, unlike `scan_frac`: an
  auto-identify scan resolving off to the side must not blank the readout of whoever you are
  looking at. The scan spinner itself lives in one shared primitive (`draw_spinner`, exported on
  `_ui`) used by both this block and `draw_slot`'s scanning branch.
- **Distance scaling / offsets:** Minimal (when `mini_dist_scale` is on), Minimal 2, Patch,
  Simple, and Simple 2 derive their graphical scale from a camera-up metre projected
  beside the anchor (`mini_dist_scale_factor`). Each reference layout unit represents
  `MARKER.unit_m = 0.03` metres before the `card_scale` multiplier. This uses the same
  camera projection as the anchor, so size follows view depth and zoom rather than
  actor distance. There is no far-distance scale floor or minimum pixel dimension;
  positions and sizes retain fractional pixels. The projection scale is capped at
  `MARKER.max_scale = 4` for graphics near the camera, before applying `card_scale`.
  `dot_scale`, `glow_scale`, and `spinner_scale` then multiply only their respective rendered
  diameters; none changes the projected centre, world anchor, distance scale, or offset calculation.
  User X/Y offsets use the uncapped projection scale (X also uses `UI_KX`), keeping
  the offset attached in the camera-facing plane. There is no additional downward
  distance correction. Simple's graphical group is centred independently of its
  fixed-font name. Minimal's relation glyph also keeps its native font size.
  Card, Bodycam, Crooks, and the engine PiP path retain their existing sizing;
  Minimal with `mini_dist_scale` off retains its fixed size and virtual-pixel offsets.
- **Aspect correction** `UI_KX` (assigned 375): `(h/w)/(768/1024)`; the X of any
  KX-distorted static (node, glow, line, Simple 2 shapes, the Patch patch + its ring gap) is pre-corrected so circles
  stay round and angles stay true under the engine's anisotropic virtual→screen
  stretch. The spinner is deliberately kept square (rotation doesn't commute with
  non-uniform scale).
- **Overlap avoidance** (`render` 2nd pass, ~4222): a card whose anchor is within
  `STACK_DIST_X=140` / `STACK_DIST_Y=90` of an earlier card is pushed
  `stack × STACK_STEP (58)` px higher.
- **Picture-in-Picture scope path** (in `render`, 3969): gated on `PIP_AVAILABLE`
  (soft existence check via `rawget` of `is_svp_active` / `svp_ui_markers_*`). When a
  scope is raised it submits in-scope world markers and hides the normal HUD slots so
  a mis-projected main-camera card doesn't clash with the scope view.

### 3.7 Rewards / familiarity

- First identify of a target awards `perception_xp` once (`xp_awarded` gate) and
  sets `remembered[id]` (in `identify_target`, 2097).
- `update_loot_xp` (2064) awards `perception_loot_xp` the first time you loot a
  corpse you had already identified, detected by polling `get_talking_npc()` for a
  set→cleared transition (`loot_xp_awarded` gate).
- `award_perception_xp` (2012) writes `haru_skills.skills_levels.perception
  .experience` directly (deliberately not `increase_skill`, which would throw on a
  non-base skill).

### 3.8 Notable functions

`read_config` (322) • `active_dik` (330) • `modifiers_ok` (348) •
`faction_label/color` (380/395) • `display_name` (402) • `rank_binding/rank_id` (464/476, the
engine-binding probe + the single rank reader, `ranks.script` first — see §3.9) • `rank_color/label`
(436/502) • `held_weapon_label` (553) • `relation_color/sign` (600/618) •
`anchor_pos` (632) • `project_world` (666) • `screen_box` (734) • `has_los` (1113) •
`find_nearest_in_fov` (1193) • `get_target_obj` (1326) • `is_binoc_active` (1460) •
`is_ads_active` (1479) • `scope_magnification` (1548) • `screen_dist_to_body` •
`aim_model_target` • `distance_scan_mult` (1709) •
`rank_scan_mult` (1759) • `darkness_factor` (1802) • `target_visibility_scan_mult` • `perception_scan_mult` (1890) •
`perception_hint_stats` (1926, exposed as a global for the Skill System tooltip) •
`update_loot_xp` (2038) • `identify_target` (2071) • `boost_params` (2248) •
`try_identify` (2326) • `update_auto_identify` (2389) • `sweep_identify_in_fov`
(2492) • `update_ads_dwell` (2541) • `update_binocular_scan` (2644) •
`install_key_hook` (2688) • `IiTags:draw_debug` (2787) • `ensure_tags` (3156) •
`head_box_for` (3197) • `body_box_for` (3259) • `render` (3437) •
`teardown_ui` (3754) • `update_ads_range_snapshot` (3774) • `update_binoc_clear` (3794) •
`actor_on_update` (3814) •
`on_game_start` (3907).

In `ii_ui.script`: `IiTags:InitControls` (22) • `draw_head_box` (264) •
`IiTags:draw_slot` (512).

### 3.9 Diagnosing a "line is missing / line shouldn't be there" report

A field can be absent from a card for five unrelated reasons that look identical in game, so
`debug_log` writes a `---- display gates ----` block to `immersive_identification.log` on every
**committed** identify (not per frame), walking them in decision order:

1. `target:` — the raw rank id, its `RANK_LEVEL`, the resolved label, and `src=` (which rank
   source answered — see below). `NONE (source has no rank for this object)` means the object has
   no rank; `UNAVAILABLE (no rank source on this install)` means neither source exists.
2. `tier:` — whether the WD tier layer is actually driving, and if not, **which** of the four
   configurations means it isn't: no provider registered (component absent), `wd_ignore` on,
   the provider returned `nil` (WD API unreachable, **or** an incomplete kit with
   `wd_require_kit` off), or active-but-no-`feat`-table. All four fall back to the plain MCM
   toggles, i.e. **no tier gating at all** — which is what "weapon shown below tier 3" usually
   is. When it *is* driving, the line prints each `feat` gate plus the configured unlock tiers
   (nothing enforces `wd_feat_rank ≤ wd_feat_weapon`, so inverted sliders show here).
3. `mcm:` / `gated:` — the `show_*` toggles, then the gate results actually folded into the
   snapshot.
4. `style:` — the active style and which lines it renders (`ii_config.STYLE_LINES`). A field can
   survive every gate and still never be drawn: bodycam has no rank line, Simple 2 renders rank
   as the colour bar only.

The Debug-draw panel carries the same rank chain live for the aimed candidate (`rank:` +
`show:`), for when a screenshot is easier to get than a log file.

**Where the rank comes from.** `rank_id(obj)` is the single reader, returning the raw id plus
which of two sources answered, so `rank_color` / `rank_label` / `rank_scan_mult` / the
`rank_level` snapshot and both diagnostics always agree:

1. **`ranks.get_obj_rank_name(obj)`** (preferred) — Anomaly's own Lua rank ladder in
   `ranks.script`, base game: the engine itself reaches for `ranks.get_player_rank_name`
   (`Actor.cpp:1442`). It maps the base-engine-bound **numeric** `obj:character_rank()` to a rank
   id, so it works on **any** exe and honours a mod that retunes the ladder. This is the source
   Crook's Faction Identification UI uses.
2. **`obj:rank_name()`** (fallback) — the direct engine export, which is **not in the Anomaly
   1.5.1 base engine**; it landed in xray-monolith in commit `3e1d4be8` (2026-06-03). Probed once
   by `rank_binding()` and memoised in `RANK_SRC.binding` (pcall'd — an absent luabind member may
   raise rather than answer nil).

Both return the same lowercase ids. Only if **neither** source exists is a rank impossible, and
that case logs `!![ii] no rank source on this install` once rather than leaving a permanently
rankless card looking like a display gate. Historical note: relying on (2) alone meant that on a
pre-2026-06-03 exe the rank line never appeared and `rank_penalty` was silently a no-op, while
name / faction / relation / weapon — all base-engine calls — kept working. That asymmetry is the
signature of a missing rank *source*, not of a display gate.

---

## 4. Configuration (MCM — `ii_mcm.script`)

MCM auto-discovers `on_mcm_load` only in files ending `mcm.script`, so the menu
lives here while logic stays in `ii_identify.script`. **Single source of truth:**
defaults, the modifier dropdown, and the UI-style dropdown are read from
`ii_identify.DEFAULTS` / `MODIFIER_LIST` / `UI_STYLE_LIST` (11-25). The key-bind
default is resolved here (not in `DEFAULTS`) because `DIK_keys` isn't populated
when `ii_identify.script` is first parsed (27-31).

**Presets:** the General leaf page carries a `presets = { "ii_default", "ii_card",
"ii_minimal", "ii_bodycam", "ii_immersive", "ii_crooks" }` list, which makes MCM show a
preset dropdown (it applies across all pages, not just General). `ii_crooks` is the
Crooks readout with instant identify (and `scan_time = 0` as a fallback) and zero-dwell auto-trigger in all three modes
(hipfire, ADS, binoculars), with no per-mode instant exclusions. Names resolve from `ui_mcm_prst_<id>`
strings; **values live in LTX**, not Lua — MCM reads `configs/presets/includes.ltx`
(which we ship with a wildcard `#include "presets_*.ltx"` so other mods coexist) →
`presets_ii.ltx`, whose `[<preset_id>]` sections key options by their storage path
(`ii/<page>/<id>` — see the multi-page note below; values by type: check→bool,
track/list→number). A preset only overrides the options it lists. Adding an option
to a preset = one LTX line; no code change.

**Tree:** root node `id="ii"` (no `sh`) → **one leaf page (`sh=true`) per section**,
each rendering as its own tab (tab label = `ui_mcm_menu_<page_id>`): **general**,
**uistyle**, **targeting**, **binoc**, **ads**, **pip**, **scantime**
(the distance/rank/target-visibility/familiarity/perception modifier sub-headers), **audio**, **debug**, and
**colors** (the per-faction/rank/relation RGB overrides, generated from
`ii_identify.COLOR_DEFS`). Because an option's MCM storage path is
`ii/<page>/<option_id>`, options are NOT all under `ii/main/*` — `read_config` looks up
each key's path in this tree and asks MCM for that path alone (MCM logs every path it
doesn't know); only if the tree can't be built does it try every page in `MCM_PAGES`
(first non-nil wins). The preset LTX paths use the per-page ids. Three MCM traps
encoded in comments:
the top node must **not** carry `sh` (only the leaf page does); an option's
**`hint` is the BARE base id** (`"ii_<id>"`) — MCM resolves its caption from
`ui_mcm_<hint>` and its **hover tooltip** from `ui_mcm_<hint>_desc`, so passing a
`_desc`-suffixed hint mis-renders the label and kills the tooltip; and `text` is
only read for slide headers, not option captions. The `opt_check/opt_track/
opt_list` helpers set `hint = "ii_" .. id` mechanically.

### Setting inventory

Listed in MCM display order (`ii_mcm.script`); ranges are `(min, max, step, prec)`.

Pages: `general`, `uistyle` (a **container** with sub-pages `uistyle/general`, `uistyle/card`,
`uistyle/simple`, `uistyle/bodycam`, `uistyle/crooks`, `uistyle/patch`, `uistyle/opacity`), `targeting`, `hipfire`,
`binoc`, `ads`, `pip`, `scantime`, `audio`, `debug`, `wdcompat`, `colors`. These path prefixes must stay
in sync with `MCM_PAGES` in `ii_identify.script` and with `presets_ii.ltx`.

| id | type | default | range | controls |
|---|---|---|---|---|
| **General** | | | | |
| `enabled` | check | true | — | master on/off |
| `key_dik` | key_bind | `DIK_X` | — | identify key |
| `modifier_index` | list | None | None/Ctrl/Shift/Alt | required held modifier |
| `instant_identify` | check | false | — | skip the scan wait — reveal immediately |
| `scan_time` | track | 0.35 | 0, 2, 0.05, 2 | base scan pulse (s) |
| `fade_time` | track | 0.45 | 0, 2, 0.05, 2 | fade in/out (s) |
| `hold_time` | track | 4.0 | 1, 15, 0.5, 1 | full-visible hold (s) |
| `hide_unseen` | check | true | — | hide a tag while its target is out of sight |
| `max_dist` | track | 50 | 10, 250, 5 | **Base identification distance** (m) — the base, before scaling up/down |
| **UI Style → General** (`uistyle/general`) | | | | |
| `ui_style` | list | Card | Card/Minimal/Bodycam/Simple 2/Simple/Crooks/Minimal 2/Patch | which visual style |
| `show_name` | check | true | — | show name line |
| `show_faction` | check | true | — | show faction line |
| `show_rank` | check | true | — | show rank line (Card/Bodycam/Crooks) |
| `show_relation` | check | true | — | show the enemy/friend/neutral cue at all — see **Relation gating** below |
| `custom_patches` | check | false | — | ask for `ii_patch_<community>` texture ids instead of the game's `<community>_icon` — see **Faction patch ids** below |
| `show_weapon` | check | true | — | show weapon+caliber line |
| `color_by_relation` | check | true | — | tint by relation vs flat neutral (colour only; `show_relation` is the content gate) |
| `mini_dist_scale` | check | true | — | Minimal dot: scale with distance |
| `dot_scale` | track | 1.0 | 0, 3, 0.05, 2 | built-in dot/node size after style and distance scaling; 0 hides it; does not move the anchor |
| `glow_scale` | track | 1.0 | 0, 3, 0.05, 2 | independent dot-halo size after style and distance scaling; 0 hides it; does not move the anchor |
| `spinner_scale` | track | 1.0 | 0, 3, 0.05, 2 | main-view, Crooks-readout and PiP scan-spinner size after style and distance scaling; 0 hides it; does not move the anchor |
| `ui_offset_x` | track | 0 | -200, 200, 5 | horizontal nudge for on-screen UI (px) |
| `ui_offset_y` | track | 0 | -200, 200, 5 | vertical nudge for on-screen UI (px) |
| `anchor_basis` | list | Head | Head/Torso/Feet | where the tag/marker anchors on the target (`ui_anchor_pos`); Bodycam box keeps its own `box_area` |
| **UI Style → Card** (`uistyle/card`) | | | | |
| `card_scale` | track | 1.0 | 0.5, 2, 0.05, 2 | flat size multiplier — despite the name it scales **every** style, multiplying on top of the distance scale where that applies |
| `card_icon_scale` | track | 1.25 | 0.5, 3, 0.05, 2 | Card: faction emblem size multiplier; the plate widens to match and the emblem is capped to plate height |
| `mini_scale_cutoff` | track | 0.4 | 0.1, 1, 0.05, 2 | Card only: below this scale → relation dot instead of the card |
| **UI Style → Simple** (`uistyle/simple`) | | | | |
| `simple_icon_scale` | track | 1.25 | 0.5, 3, 0.05, 2 | Simple: faction emblem size multiplier; the strip re-centres around it |
| **UI Style → Bodycam** (`uistyle/bodycam`) | | | | |
| `box_area` | list | Head | Head/Body | bodycam outline rectangle region |
| `box_color_source` | list | faction | faction/relation | bodycam box colour source |
| `box_thickness` | track | 2 | 1, 6, 0.5, 1 | bodycam outline edge thickness (px) |
| `box_padding` | track | 0.2 | 0, 1, 0.05, 2 | bodycam outline margin (fraction) |
| `box_opacity` | track | 1.0 | 0.1, 1, 0.05, 2 | bodycam outline opacity |
| `box_text_gap` | track | 8 | 0, 40, 1, 0 | Bodycam: px from the box edge to the name/faction/weapon text |
| **UI Style → Crooks** (`uistyle/crooks`) | | | | |
| `crooks_pos` | list | bottom_left | BL/BM/BR | Crooks readout screen corner |
| `crooks_x` | track | 0 | -500, 500, 5 | Crooks X offset (px) |
| `crooks_y` | track | 0 | -100, 700, 5 | Crooks Y offset (px, + = up) |
| `crooks_icon_scale` | track | 1.25 | 0.5, 3, 0.05, 2 | Crooks: faction emblem size multiplier (text unaffected; the emblem stays centred on the readout, so large values may need `crooks_y` raised) |
| `crooks_icon_gap` | track | 10 | 0, 40, 1, 0 | Crooks: px between emblem and text; independent of `crooks_icon_scale`, so spacing holds as the emblem resizes |
| **UI Style → Patch** (`uistyle/patch`) | | | | |
| `patch_size` | track | 13 | 8, 64, 1, 0 | Patch style: faction-patch size (px at the reference distance) |
| `patch_thickness` | track | 2 | 0, 5, 0.5, 1 | Patch style: relation-ring edge thickness (px at the reference distance); **0 = no ring**, bare patch |
| `patch_padding` | track | 0 | 0, 12, 0.5, 1 | Patch style: gap between the patch and its ring (px at the reference distance) |
| `patch_ring_opacity` | track | 1.0 | 0, 1, 0.05, 2 | Patch style: relation-ring opacity |
| **UI Style → Opacity** (`uistyle/opacity`) | | | | Each multiplies the fade alpha of one element class in every built-in style (and is on `ctx.config` for add-ons); 0 = invisible, layout unchanged. Text sliders also scale that line's shadow. |
| `opacity_name` | track | 1.0 | 0, 1, 0.05, 2 | name text (Card, Simple, Bodycam, Crooks) |
| `opacity_faction` | track | 1.0 | 0, 1, 0.05, 2 | faction text line (Card, Bodycam) |
| `opacity_rank` | track | 1.0 | 0, 1, 0.05, 2 | rank text line (Card, Crooks); Simple 2's rank bar is a shape |
| `opacity_weapon` | track | 1.0 | 0, 1, 0.05, 2 | weapon + calibre line (Card, Bodycam) |
| `opacity_background` | track | 1.0 | 0, 1, 0.05, 2 | Card plate + drop shadow |
| `opacity_markers` | track | 1.0 | 0, 1, 0.05, 2 | dots + halos, Minimal relation sign, Simple 2 circle/triangle/rank bar, Card accent bar, PiP in-scope marker |
| `opacity_patch` | track | 1.0 | 0, 1, 0.05, 2 | faction emblem/patch (Card, Simple, Patch, Crooks) |
| `opacity_line` | track | 1.0 | 0, 1, 0.05, 2 | Card leader line |
| `opacity_spinner` | track | 1.0 | 0, 1, 0.05, 2 | scan spinner (main view, Crooks, PiP) |
| **Targeting** | | | | |
| `fov_assist` | check | true | — | master FOV target-assist; off = direct-hit aim only |
| `freeaim_assist` | check | false | — | bodycam/free-aim: aim from the weapon barrel/first-eye ray |
| `fov_radius` | track | **35** | 0, 90, 5 | target-assist **screen radius** (virtual px; 0 = off) — the *unmagnified* value, see `fov_zoom_scaling` |
| `fov_zoom_scaling` | check | true | — | shrink the assist radius by the live magnification, so it covers a constant **world** cone at any zoom (`assist_radius`) |
| `fov_identify_all` | check | true | — | hipfire/ADS/binocular auto-triggers reveal ALL targets in the assist radius; off = only the one nearest the aim (manual key always nearest; Auto-identify unaffected) |
| `require_los` | check | true | — | require line of sight |
| `los_block_seethrough` | check | false | — | LOS: treat see-through surfaces (fences/glass/foliage/clip) as opaque — no ID through them |
| `los_block_foliage` | check | false | — | LOS: block ID through foliage only (best-effort by material name) |
| `exclude_hostile` | check | false | — | never target an entity actively hostile + engaging you (in combat / pulled aggro) |
| `hide_off_aim` | check | false | — | only track the aimed target (membership gate: drop on aim-away, re-scan on aim-back) |
| `auto_identify` | check | false | — | continuously identify every in-view, in-range target, no keypress or aiming (LOS always required) |
| **Hipfire** | | | | |
| `hipfire_mode` | check | false | — | **Auto Identification** — dwell auto-identify while hip-firing |
| `hipfire_hold_time` | track | 1.0 | 0, 3, 0.1, 1 | dwell time before auto-ID (s; 0 = instant) |
| `instant_exclude_hipfire` | check | false | — | keep the scan wait for hipfire under Instant identify |
| `hipfire_max_dist` | track | 0 | 0, 1000, 5 | hard cap on effective range (m; 0 = none) |
| **Binoculars** | | | | |
| `binocular_mode` | check | false | — | **Auto Identification** — steady-aim auto-identify via binocs |
| `require_binoculars` | check | false | — | restrict identify to raised binocs |
| `steady_time` | track | 0.6 | 0, 3, 0.1, 1 | steady-aim hold time (s; 0 = instant) |
| `fov_assist_binoc` | check | true | — | FOV assist while looking through raised binoculars |
| `binoc_boost` | check | true | — | binocs speed up + extend range |
| `binoc_scan_mult` | track | 0.4 | 0.1, 1, 0.05, 2 | scan-speed mult w/ binocs |
| `binoc_range_mult` | track | 4.4 | 1, 5, 0.1, 1 | range mult w/ binocs (when zoom-scaling off) |
| `binoc_zoom_scaling` | check | false | — | scale range by the binocular's real magnification |
| `binoc_clear_on_lower` | check | false | — | lowering the binoculars wipes **every** tag, near ones included (distant ones already go via the out-of-range cull) |
| `instant_exclude_binoc` | check | false | — | keep the scan wait for binocs under Instant identify |
| `binoc_max_dist` | track | 0 | 0, 1000, 5 | hard cap on effective range (m; 0 = none) |
| **Aim Down Sight (ADS)** | | | | |
| `ads_mode` | check | false | — | **Auto Identification** — dwell-on-target auto-identify while ADS |
| `ads_hold_time` | track | 0.6 | 0, 3, 0.1, 1 | dwell time before auto-ID (s; 0 = instant) |
| `ads_boost` | check | true | — | ADS speeds up + extends range |
| `ads_scan_mult` | track | 0.6 | 0.1, 1, 0.05, 2 | scan-speed mult while ADS |
| `ads_range_mult` | track | **1.0** | 1, 5, 0.1, 1 | range mult while ADS (x1 base) |
| `ads_zoom_scaling` | check | true | — | scale ADS range by scope magnification |
| `ads_hide_main` | check | false | — | hide all main-view drawing while aiming down sight |
| `ads_block_thermal` | check | false | — | block every identification path while ADS with an active S3DS thermal image; switchable normal-image modes remain usable |
| `instant_exclude_ads` | check | false | — | keep the scan wait for ADS under Instant identify |
| `ads_max_dist` | track | 0 | 0, 1000, 5 | hard cap on effective range (m; 0 = none) |
| **PiP Scope** | | | | |
| `pip_markers` | check | true | — | draw identification markers in a PiP scope |
| `pip_hide_main` | check | false | — | hide all main-view drawing while a scope is up |
| **Scan Time** (`scantime`) | | | | |
| `dist_penalty` | check | true | — | distance slows scan |
| `dist_penalty_max` | track | 5.0 | 1, 6, 0.1, 1 | scan mult at max range |
| `rank_penalty` | check | true | — | rank slows scan |
| `rank_penalty_max` | track | 3.0 | 1, 6, 0.1, 1 | scan mult for legend |
| `night_penalty` | check | true | — | low per-target luminance slows scan |
| `night_ignore_nvg` | check | true | — | ignore target-visibility slowdown while the actor's NVGs are switched on |
| `night_penalty_max` | track | 2.0 | 1, 6, 0.1, 1 | scan mult at zero target luminance |
| `night_luminance_threshold` | track | 0.5 | 0.05, 1, 0.05, 2 | target luminance at which the slowdown reaches 1× |
| `weather_penalty` | check | true | — | exposed rain, storms, and fog at the target distance slow scan |
| `weather_penalty_max` | track | 2.0 | 1, 6, 0.1, 1 | shared maximum scan mult for weather and visor obstruction |
| `visor_water_penalty` | check | true | — | use Anomaly/GAMMA's accumulated gas-mask droplets when available |
| `visor_water_threshold` | track | 0.35 | 0, 0.95, 0.05, 2 | droplet strength where visor slowdown begins |
| `combat_penalty` | check | true | — | combat and recent incoming fire slow identification |
| `combat_penalty_mult` | track | 1.5 | 1, 6, 0.1, 1 | scan mult during general combat |
| `combat_pressure_mult` | track | 2.5 | 1, 6, 0.1, 1 | total scan mult during the stronger hit/near-miss window |
| `combat_pressure_duration` | track | 5.0 | 0.5, 15, 0.5, 1 | stronger pressure duration after each event (s) |
| `combat_near_miss_radius` | track | 3.0 | 0.5, 10, 0.5, 1 | hostile-bullet proximity that triggers pressure (m) |
| `weight_penalty` | check | false | — | held-item weight slows scan |
| `weight_penalty_max` | track | 2.0 | 1, 6, 0.1, 1 | scan mult at the reference weight |
| `weight_penalty_ref` | track | 6.0 | 1, 20, 0.5, 1 | held weight (kg) that maxes the penalty |
| `foliage_penalty` | check | false | — | identifying through foliage slows scan |
| `foliage_penalty_max` | track | 2.5 | 1, 6, 0.1, 1 | scan mult when the sightline crosses foliage |
| `familiarity_boost` | check | true | — | remember identified stalkers |
| `familiarity_scan_mult` | track | 0.6 | 0.1, 1, 0.05, 2 | scan mult for familiar target |
| `perception_compat` | check | true | — | Skill System perception integration |
| `perception_scan_mult` | track | 0.04 | 0, 0.1, 0.01, 2 | scan reduction per level |
| `perception_xp` | track | 20 | 0, 100, 5 | XP per identify |
| `perception_loot_xp` | track | 20 | 0, 100, 5 | bonus XP for first loot |
| **Audio** | | | | |
| `audio_volume` | track | 100 | 0, 200, 5 | master percentage gain for every identification sound |
| `scan_start_sound` | check | false | — | play the bundled low vibration cue when a non-instant scan starts |
| `scan_start_manual_only` | check | false | — | suppress the start cue for auto-identify and automatic aiming triggers |
| `identify_done_sound` | check | false | — | play the bundled neutral beep on the first completed reveal |
| `identify_done_manual_only` | check | false | — | suppress the completion beep for auto-identify and automatic aiming triggers |
| `wd_hostile_sound` | check | false | — | with the WD scanner active, play the detected hostile faction's warning clip (§7.4) |
| `wd_hostile_manual_only` | check | false | — | suppress hostile warnings for auto-identify and automatic aiming triggers |
| **Debug** | | | | |
| `debug_log` | check | false | — | write aim/trace diagnostics to a dedicated log file, plus a `---- display gates ----` block per committed identify (see below) |
| `debug_draw` | check | false | — | on-screen target-assist visualiser: the FOV ring (one stretched `ii_ring` circle outline), bone dots, and a bottom-right info panel (perf CPS + mod-loop ms; identify trace — active triggers, the last commit's source/target, exact before/after timing for distance/rank/weight/foliage/target-light/aim/perception/combat/weather/familiarity/instant factors, raw target luminance/darkness/source and bypass, combat state/source/enemy count/pressure time, rain/storm/fog/visor severities, raw visor-droplet level and threshold, and the winning weather-visibility source, plus a live "gate" line explaining why the aimed candidate is / isn't being identified, and a live `rank:` readout for that candidate — raw `rank_name` id, resolved label, `RANK_LEVEL`, and whether that rank will actually be drawn (gate off / WD tier locked / the active style has no rank line, per `ii_config.STYLE_LINES`); aim mesh-hit see/ray/LOS + front material; the FOV-radius target list) |
| `debug_sim_stock` | check | false | — | pretend the custom engine bindings are absent (test stock fallbacks) |
| **Wearable Devices** (page `wdcompat`; only bites when the WD compat add-on is installed, §7.4; the page is hidden otherwise) | | | | |
| `wd_ignore` | check | false | — | master toggle: bypass the WD compat entirely (identify as if WD isn't installed); disables the rest of this page |
| `wd_require_kit` | check | true | — | block identification entirely unless the full scanner kit is worn/assembled |
| `wd_notify_scale` | track | 1.0 | 0.5, 2, 0.05, 2 | Promin BIOMONITOR/NAVIGATION identification-card scale; applies live to the full layout |
| `wd_proc_t1/t2/t3` | track | 1.5 / 1.0 / 0.5 | 0.1, 5, 0.1, 1 | process-module tier base scan time (s) |
| `wd_penalty_t1/t2/t3` | track | 1.0 / 0.75 / 0.5 | 0, 2, 0.05, 2 | process-tier share of every enabled penalty's slowdown above 1× |
| `wd_scan_t1/t2/t3` | track | 10 / 20 / 30 | 5, 100, 5 | scanner tier identify range (m) |
| `wd_feat_faction/distance/relationship/rank/weapon` | track | 1/1/2/2/3 | 1, 3, 1 | process tier that unlocks each data feature |
| `wd_scanner_ads/mag/nonight` | track | 2/2/3 | 1, 3, 1 | scanner tier that unlocks scope-ADS / mag-boost / no-night |

The `wd_*` keys back the tier system's defaults and are exposed to the add-on via the
`ii_identify.get_wd_tier_cfg()` global (the add-on's driver can't read the local `C`).
See §7.4.

---

## 5. Assets & data files

### 5.1 UI templates (`ii_tags.xml`)

Root `<w>`; technique mirrors Immersive Quest Markers' card style. **Every image
widget uses `stretch="1"`** — this is load-bearing, not cosmetic: `stretch="0"`
is engine `tmNative` mode which ignores `SetWndSize()` and draws textures at
native pixel size (the historical "dot is huge" bug). Most textures ship white
and are tinted at runtime via `SetTextureColor`.

Image widgets: `tag_shadow` (80×40, ii_shadow), `tag_plate` (80×40, ii_white,
charcoal 24/22/19), `tag_accent` (3×26, relation bar), `tag_icon` (20×20, swapped
to `<community>_icon` -- or `ii_patch_<community>` under `custom_patches` -- at runtime),
`tag_line`/`tag_line_sh` (64x2, leader line),
`tag_glow` (40×40, ii_dot), `tag_node` (10×10, ii_node, baked black ring),
`tag_spinner` (20×20, ii_spinner; a second instance lives in the Crooks block), `tag_box_top`/`tag_box_bottom`/`tag_box_left`/
`tag_box_right` (thin ii_white strips forming the Bodycam head-outline box and the
Patch style's relation ring, sized
per frame), `tag_s2_circle` (12×12, ii_dot — Simple 2 faction circle),
`tag_s2_tri` (13×11, ii_tri — Simple 2 relation triangle), `tag_s2_bar` (28×3,
ii_white — Simple 2 rank bar), and the debug widgets `dbg_ring` (ii_ring, sized to
2*`fov_radius` per frame), the `dbg_dot` pool (ii_dot) and
`dbg_text`/`dbg_status` (letterica16). Text widgets (each with a `_sh` shadow twin):
`tag_head` (letterica16, faction), `tag_name` (letterica18, personal name),
`tag_rank` (letterica16, hidden when the engine reports no rank), `tag_weap` (letterica16),
`tag_sign` (letterica18, centered relation glyph for Minimal style).

### 5.2 Textures (`ii_textures.xml` → `textures/ui/*.dds`)

Each registers the whole file as one region. `ii_white` (32×32 solid),
`ii_dot` (64×64 soft AA circle, glow/pulse), `ii_node` (64×64 white fill with a
**baked black outline ring** so the ring survives any tint), `ii_spinner`
(128×128 comet-tail ring), `ii_shadow` (64×64 feathered rounded box), `ii_tri`
(64×64 up-pointing triangle, shape in the alpha channel, tinted at runtime — Simple
2 relation marker), `ii_ring` (256×256 AA circle outline, stroke centreline at
120/128 of the half-width — the Debug-draw FOV ring). All ship white with the shape carried in alpha and are tinted at
runtime via `SetTextureColor`. Textures ship in-mod so the tag draws with zero
external dependency.

### 5.3 String table (`st_ii_texts.xml`, windows-1251)

MCM menu labels; a `ui_mcm_ii_<id>` label + `ui_mcm_ii_<id>_desc` hint pair per
setting; section titles; dropdown entry ids (`ii_main_<option>_lst_<label>`); and
16 faction display names `st_ii_faction_<community>` (Loner, Bandits, Duty,
Freedom, Clear Sky, Ecologists, Mercenaries, Military, Monolith, Renegades,
Zombified, Sin, Trader, Mutant, UNISG, Arena).

---

## 6. Installer & optional components (`fomod/`)

**info.xml:** Immersive Identification, **v2.55.1**, group Gameplay.

**ModuleConfig.xml** (ModConfig 5.0):

- **Required:** `gamedata → gamedata` (self-contained drop-in, no required
  choices).
- **Two groups.** "Compatibility" (`SelectAny`) holds the three soft-compat plugins; "Custom
  faction patches" (**`SelectAtMostOne`**) holds the three patch sources, which are mutually
  exclusive because they register the same `ii_patch_*` ids (§7.2).
  1. **Neutralize FactionID HUD** → `FactionID Neutralized/gamedata`. `type = Recommended`, so
     it is **pre-checked** — nearly every target setup (GAMMA included) ships FactionID, and
     leaving it on means two faction indicators at once. Deselectable, and inert without
     FactionID (§7.1).
  2. **Skill System: Perception** → `Perception Skill Integration/gamedata`. `Optional`.
  3. **st-wearable-devices Compatibility** → `WD Compatibility/gamedata` (§7.4). `Optional`.
  4. **HD Faction Patches** → `HD Faction Patches/gamedata`. `Optional`. Bundled Leekos atlas (§7.2).
  5. **GRIP Patches** → `GRIP Patches/gamedata`. `Optional`. Kos' GRIP's atlas (§7.2).
  6. **GAMMA Patches** → `GAMMA Patches/gamedata`. `Optional`. G.A.M.M.A. UI's atlas (§7.2).
---

## 7. Compatibility add-ons

### 7.1 FactionID Neutralized

A single file `factionID_hud_mcm.script` that **overrides** FactionID's own
same-path script (VFS "last-mod-wins") with an inert stub — every public function
(`activate_hud`, `identify`, `actor_on_update`, `on_mcm_load`, `on_game_start`, …)
redefined as a no-op, `HUD = nil`. This suppresses FactionID's on-screen HUD so
you don't get two overlapping faction indicators, while leaving the rest of that
mod harmlessly loaded. Only relevant if FactionID is installed — without it the stub is an orphan
script that shadows nothing, registers no callbacks and returns nil from `on_mcm_load` (a path MCM
already takes in the intended case, since the stub replaces FactionID there too), which is why it
is safe to ship pre-checked.

### 7.2 Faction patch components (HD / GRIP / GAMMA)

Each component registers the mod's **`ii_patch_<community>`** ids (the ones `custom_patches`
switches to — see §3's *Faction patch ids*) against a faction-patch atlas. **HD Faction Patches**
bundles Leekos' 1024×512 universal atlas as `ui\ii_hd_faction_patches.dds`, keeping it isolated
from other UI mods. GRIP and GAMMA only reference `ui\ui_mm_faction_patches` supplied by their
source mod, so those two are inert without the matching atlas.

**They are alternatives, not additive.** All three register the same `ii_patch_*` ids. GRIP and
GAMMA additionally ship the same source filename with the same `ui_mm_faction_*` ids but
**different atlases**:

| component | source mod | atlas | tiles |
|---|---|---|---|
| **HD Faction Patches** | Leekos' HD Faction Patches 2.4, bundled | 1024×512 | 128×128 |
| **GRIP Patches** | Kos' GRIP ([link](https://discord.com/channels/912320241713958912/1530072690155585688/1530072690155585688)) | 1024×512 | 128×128 |
| **GAMMA Patches** | G.A.M.M.A. UI | 512×256 | 64×64 |

The FOMOD puts all three in one **`SelectAtMostOne`** group because installing multiple mappings
would leave whichever XML parsed last silently winning. For GRIP and GAMMA, picking the component
that does *not* match the atlas your load order resolves renders every patch cropped to a corner
(see §3's *Faction patch ids* for why that is the signature). The HD component is self-contained
and does not depend on either shared atlas.

Two things must both be true for any component to show: the component installed, **and**
`custom_patches` switched on in MCM. Neither alone does anything, which the FOMOD descriptions
say explicitly.

Mapping notes, identical in all three: the tile these sources label `army` is registered as
**`military`**, the actual Anomaly community id; zombified stalkers have no tile of their own so
they reuse the atlas' greyed `stalker_inactive`; and **`trader`, `monster` and `arena` have no
tile in either atlas and therefore show no patch** — the all-or-nothing limit from §3, since
there is no engine call to test whether a texture id resolves.

### 7.3 Perception Skill Integration

A soft-compat overlay for the third-party **Skill System (`haru_skills`)** mod.
Ships **no scripts** — all logic is in `ii_identify.script`; these are pure
config/asset files plugged in through haru_skills' own wildcard `#include` VFS
overlays, with **zero edits** to the host mod:

- `skills/skill_perception.ltx` — `[perception]` `max_level=15`,
  `base_requirement=600` (picked up by `#include "skill_*.ltx"`); an inert
  `[perception_stats]` block exists only because haru_skills reads a
  `<skill>_stats` section for every skill.
- `skills/ui_settings/stats_perception.ltx` — wires the stat to a live functor
  `functor = ii_identify, perception_hint_stats` (via `#include "stats_*.ltx"`).
- `text/eng/st_ii_skill_perception_texts.xml` — `st_player_skills_perception`,
  its hint, the level-up toast, and a dynamic `st_ii_perception_hint_stats`
  template (`$level`, `$t1..$t4` filled by `perception_hint_stats()` showing live
  scan times at point-blank / max-range / binocular combos).
- `ui/textures_descr/ii_skill_perception_textures.xml` + `ii_skill_perception.dds`
  — registers `ui_skills_icon_perception` (96×96) on a standalone file following
  haru_skills' `ui_skills_icon_<skill>` convention.

Without this component (and the host mod) there is no XP and no effect.

### 7.4 st-wearable-devices Compatibility (`WD Compatibility/`)

Gates identification behind wearable scanner gear from the **st-wearable-devices**
(WD) mod, via a small **provider seam** in core: `ii_identify` calls the optional
global `ii_identify.tier_provider()` once per `actor_on_update` and snapshots the
result into `_tier`. Every override point reads `_tier`; when it's `nil` the mod
behaves exactly as normal, so core stays inert without this add-on. The provider
returns one of: `nil` (don't intervene), `{ active = false }` (installed but the kit
isn't assembled → identification **blocked** at the single `identify_target` choke
point), or `{ active = true, scan_base, penalty_scale, max_dist, ignore_night, allow_ads,
mag_boost, feat = {...} }` (tier params drive identification). When active, `scan_base`
replaces the normal base time; distance, rank, weight, foliage, target-light, combat, and
weather/visor penalties still use their base-MCM enable/max settings. Each resulting multiplier
is attenuated as `1 + (mult − 1) × penalty_scale`, defaulting to 100% / 75% / 50% for process
tiers 1 / 2 / 3. Four factors are **dropped** rather than attenuated — the binoculars/ADS aim
boost, the **perception skill**, familiarity, and instant-identify (`if not tier then` in
`identify_target`): the device's speed is the process tier's job, not the actor's. Perception XP
is still awarded for a device identify, so the skill trains without affecting the scan.
Range, ADS/magnification, the scanner's no-visibility tier, and the
faction/distance/relationship/rank/weapon display gates remain tier-driven. The rest of the MCM
(UI style, colours, key bind, boosts, …) is untouched.

**New items** (all placeholder art — see the component `README`):
- **Promin modules** — antenna, **OSD Scanner Module T1/T2/T3**, and process T1/T2/T3 —
  real WD Promin bay-modules, installed via WD's own system (item use menu / bracer
  customize screen), so they appear in the customize cells with their icons.
  `ii_wd_modules.register()` **repurposes WD's two functionally-empty bays** (drops WD's
  do-nothing `conn`/`side` `MODULES` entries) **and adds a fourth bay** so all four modules
  fit at once:
  - `conn` bay: the **antenna**.
  - `side` bay: a **process** tier.
  - `ii_osd` bay (added to `d_promin_config.BAYS`): an **OSD scanner** tier.
  - (`map` bay: WD's own navigation module.)

  The 4th bay requires a shipped **override of WD's `ui_wd_customize.xml`** (a 4th
  `module_open_4`/`module_restricted_4`/`cell_4`) — WD's customize screen builds one cell per
  `d_promin_config.BAYS` entry and ships XML for only three, so a 4th bay is otherwise a fatal
  `module_open_4 not found`. All install through `ii_wd_modules.install`, which evicts any
  module already in the target bay first (WD's `install_module` appends without checking).
  All three of our bays are made active on every Promin tier so the kit works on a tier-1
  Promin. WD persists the installed set; detection is
  `d_promin.has_module("ii_ant"/"ii_osd_tN"/"ii_proc_tN")`.
- **AR Scanner T1/T2/T3** — a **worn** bracer device (`d_ii_scanner.script`, mirroring WD's
  `d_vektor`/`d_bracer`: `wd_worn` + `wd_slots.register_device` + `wd_exo`), 3 tiers
  (range/ADS/mag/night). Shows identification on entities (the usual tags). Attaches **no
  worn model** (invisible — a placeholder mesh showed a duplicate bracer) and registers its
  own callbacks from `on_game_start` (this component isn't in WD's hardcoded `wd_boot` list,
  and `wd_core.start()` wires only once). Its functional tier is derived directly from
  `wd_worn`'s persisted section; the load callback also restores `d_ii_scanner_config`'s active
  tier so removing an OSD module after reload cannot expose a stale T1 AR fallback.

**Two INDEPENDENT channels** (separate bays, both installable at once):
- **AR** = antenna installed + a worn AR scanner + bracer worn + Promin worn & powered →
  identification on entities (the usual overlays).
- **OSD** = an OSD scanner module installed + a process module + Promin worn & powered
  (no antenna, no worn scanner, no bracer) → the Promin ident-page readout.

`osd_only` (core suppresses **all** on-entity identification UI — main tags *and* in-scope
markers) is set only in **pure OSD mode** (OSD ready and AR not).
With both channels' gear, entity overlays *and* the Promin readout show together. The Promin
ident page is gated on the OSD scanner module being installed.

**Driver** (`ii_wd_compat.script`): polls WD state — `d_ii_scanner.worn_tier()`,
`ii_wd_modules.process_tier()` / `osd_scanner_tier()` / `has_antenna()`, `d_bracer.is_worn()`,
`d_promin.is_worn()/is_powered()` — and the user's tier values via
`ii_identify.get_wd_tier_cfg()`, then builds the override table (cached, refreshed every
~250 ms). Identification runs if either channel is ready; the scanner tier used is the best
(max) of whichever are ready → `max_dist` + `allow_binoc` (T1) + `allow_ads` (T2) +
`mag_boost` (T2) + `ignore_night` (T3); process tier → `scan_base` + `penalty_scale` + the
display-feature unlocks. **Binoculars** count under the tier system when the scanner unlocks them
(`allow_binoc`, T1 by default): raised binoculars extend the tier's identify range by
`binoc_range_mult` (`boost_params` tier branch), for both channels. All WD calls are `rawget`/`pcall`-guarded so the component is inert (returns `nil`)
when WD or II is absent, and never throws into core's per-frame path.

**Bootstrap gotcha** (fixed): `on_game_start` is auto-called by the engine for every
script, but `actor_on_first_update` is a callback that must be wired via
`RegisterScriptCallback` — an early version defined it as a bare global, so its body never
ran. All wiring now happens in `on_game_start`.

**Promin IDENTIFICATION tab**: installing an **OSD scanner** module adds a third Promin
screen page (`pages = {"ident"}` on the OSD scanner modules → WD's `get_available_pages`
puts it in the tab cycle). It mirrors the NAVIGATION page — reuses `d_promin_health_ui.build_chrome`
(bg `ii_wd_tab_bg_ident`) + `build_bio` to keep the frame + left biomonitor, and draws the
last-identified target in the **right panel** (the map's region, design rect
`572,85,425,450`): a **portrait** (`obj:character_icon()`) + name/faction/rank/position/
distance/weapon (locked fields `---`) + a **scanning spinner**
(`ii_wd_spinner.dds`, frame-cycled) shown over the portrait while a scan is in progress
(driven by `ii_identify.get_scan_progress()`). The **IDENTIFICATION tab is a real baked tab**:
the strip (IDENTIFICATION / BIOMONITOR / NAVIGATION, active one highlighted) is baked into
the page background art — the ident page has its own `tablet_ui_main_ident.dds`, and WD's
biomonitor + navigation backgrounds (`tablet_ui_main.dds`, `tablet_ui_main_map.dds`) are
**overridden** so the third tab shows on every page (DXT5, matching WD's format). Data comes
from `ii_identify.get_last_identified()` (a persistent snapshot written at scan *completion*
in the render loop, respecting the tier feature gates, so the readout honours scan time). The Promin CRT
screen has **no font** (WD renders numbers as pre-baked digit textures), so this ships a
**monospace glyph atlas** (`ii_wd_font.dds` + a `textures_descr` mapping one id per ASCII
code) + a compositor (`ii_wd_text.script`) that draws strings by binding per-character
glyph textures onto slot widgets — the same mechanism as WD's clock. WD's page-builder
table is a file-local with no seam, so the page needs a **VFS override of
`d_promin_ui.script`** (verbatim copy + marked `II-COMPAT` additions: the `ident` page
builder, a second `ctx.init_ii` for our own node xml, and the notification overlay below) —
re-sync on a WD update.

**Identification notifications**: when a target is identified while the player is on the
BIOMONITOR or NAVIGATION page (not the ident page, where it's already shown), a card pops up
bottom-right and stacks upward (`d_ii_promin_notify.script`): faction emblem, name +
distance, and the rank as a level ("Rank 1".."Rank 8", `ii_identify.RANK_LEVEL`). Cards
expire after a few seconds. `wd_notify_scale` (0.5–2.0, default 1.0) resizes the card, emblem,
glyphs, and stack spacing together and applies live. The `d_promin_ui` override eager-builds the
biomonitor/navigation pages before the overlay so it draws on top; the card art is
`ii_wd_notif_card.dds`.

**Untestable / placeholder** (flagged in the component `README`): the scanner is invisible
(no worn model — re-enable + tune the attach in `sync_attachment` for real art); the
scanner/module icons are generated placeholders; the IDENTIFICATION page's screen layout
(coordinates in the 1100×600 design space) and glyph sizing are best-guess and will likely
need in-game tuning. None affects the tier **logic**.

**Identification audio.** The Audio page's `audio_volume` slider applies 0–200% gain to every
cue after `sound_object:play()` creates its feedback (`sound_object.volume` is a writable engine
binding); it defaults to 100%. The base mod ships two 2D mono 44.1 kHz Vorbis cues under
`gamedata/sounds/ii/`: `scan_start_vibration.ogg` plays only when a committed scan has a nonzero
wait, and `identify_done_beep.ogg` plays on its first completed reveal. Each is off by default and
has an independent manual-only toggle. `identify_target` snapshots `auto_mode` into the tracked
entry so the later completion edge knows whether the Identify key or an automatic trigger started
that scan. Manual-only therefore excludes both continuous auto-identify and automatic aiming
triggers without changing scan admission or timing.

**Hostile faction warning sound** (`wd_hostile_sound`, default off; now on the Audio page). The component ships
`gamedata/sounds/ii/<faction>_hostile.ogg`; when a scan's result first appears
(`first_reveal`: the `osd_done` edge, deliberately *not* the Crooks re-aim capture) for a target
that is **enemy-disposed** toward the actor, `play_hostile_sound` plays that faction's clip once
as a 2D sound. Details that matter:

- **Gated on `tier_active()`** — the audio ships with this component, so outside the WD scanner
  path there is nothing to play.
- `wd_hostile_manual_only` uses the same snapshotted `auto_mode` to suppress automatic results.
- **Hostility is read live** (`obj:relation(db.actor) == game_object.enemy`), *not* from the
  snapshotted `sign`, which is nil whenever `show_relation` is off — the warning is a safety cue,
  not a display detail, and must not go silent because the tag chose not to draw relation.
- **Files are named by display faction** (`loner`, `duty`, `merc`, `clearsky`, `sin`), not by
  community id, so `AUDIO_SND.file` maps `stalker→loner`, `dolg→duty`, `killer→merc`,
  `csky→clearsky`, `greh→sin`. Communities with no file — `ecolog`, `zombied`, `trader`,
  `monster`, `arena` — stay silent.
- **Must be Ogg Vorbis.** The engine's loader strips any extension and appends `.ogg`
  (`SoundRender_Source_loader.cpp:169`); an `.mp3` silently resolves to `$no_sound`. The files
  arrived as MP3 and were converted (mono, 44.1 kHz, Vorbis q5).
- One `sound_object` per community is built on first use and cached; a failed build caches
  `false`, so a missing file is attempted once rather than on every identify.

---


## 8. Public add-on API (`ii_api.script`)

> Modder-facing guide: **[MODDERS.md](./MODDERS.md)**. Two complete example add-ons:
> **[examples/](./examples)**. This section is the terse contract.

Third-party mods add their own UI styles without editing this mod. Anomaly makes every
`<name>.script` a global table, so `ii_api.script` **is** the public object — no require, no
shared state, no patching.

**Register from a function, never a script's top level** — at top level the load order of the
two scripts decides whether `ii_api` exists yet. `on_game_start` runs before MCM builds its menu
and before the tag widgets are created, so it is visible to both.

`ii_api.API_VERSION` is `1`. It bumps only when a hook's signature or contract *changes*; new
optional `def` fields and new `ctx` members are additive and do not bump it.

### 8.1 `ii_api.register_style(def)` → `true`, or `false, reason`

| field | | meaning |
|---|---|---|
| `id` | **required** | unique, `[a-z0-9_]`. Also the MCM dropdown's string-table suffix — ship `ii_uistyle_general_ui_style_lst_<id>` in your own string table or the menu shows the raw id. |
| `on_draw` | **required** | `function(state, a, ctx, slot)` — every frame, per visible target, while your style is selected. |
| `on_create` | optional | `function(state, ctx, slot)` — once per slot, lazily, just before its first `on_draw`. Create widgets here. |
| `on_hide` | optional | `function(state, ctx, slot)` — when the slot stops drawing (target lost, style switched away). Hide your widgets; anything left shown stays on screen. |
| `dist_scale` | optional | `true` = `a.scale` follows camera depth/zoom like Minimal / Simple, instead of the flat `card_scale`. |
| `want_box` | optional | `true` = also fill `a.box_*` with head/body box extents (the Bodycam geometry). Draw code cannot derive these itself — it has no world access. |

`state` is a per-slot scratch table, yours to keep widgets in. Other queries: `ii_api.get(id)`,
`ii_api.registered()` (stable sorted array — same table each call, safe per-frame),
`ii_api.count()`.

### 8.2 The render record (`a`)

`hx`, `hy` (anchor, virtual px) · `a` (alpha 0-255) · `scale` · `scanning` · `header` (faction
label) · `name` · `rank` · `weap` · `icon` (faction emblem texture id) · `col` (relation-tinted
colour) · `fcol` (faction colour) · `rank_col` · `sign` (`"-"`/`"+"`/`"o"`, **`nil` when
`show_relation` is off** — see §3's relation gating) · `stack_offset` · and, with `want_box`,
`box_cx` / `box_cy` / `box_hw` / `box_hh` (nil when the target does not project this frame).
Also `dist` (metres to the target) and `id` (its engine object id) — neither is used by a
built-in style; both exist so an add-on can fade by range or look the object up.

Text fields are `nil` when their `show_*` toggle is off, so presence *is* the show decision —
the same idiom the built-in styles use. Honour them and your style inherits the content toggles
for free.

### 8.3 The context (`ctx`)

**Drawing primitives** — the same code the built-in styles run every frame, which is why they
are exported rather than reimplemented: `place(w, x, y, width, height, col, alpha)` (size +
position + tint + show, top-left, raw px) · `place_mid(…)` (centred) · `place_kx(…)` (centred and
width aspect-corrected, so `_ui_kx` never reaches the caller) · `outline(edges, cx, cy, hw, hh,
thickness, col, alpha)` (four-strip rectangle, corners butted, vertical edges corrected — Bodycam
and Patch draw with it) · `dot(node, glow, cx, cy, size, col, alpha, snap)` (round marker plus
optional 2.8×/55% halo, `snap` for markers that do not distance-scale — Card, Minimal and Simple
draw with it) · `draw_shadowed_text(main, sh, x, y, alpha, r, g, b, shadow_a)`. `col` is a
`{r,g,b}`, matching `a.fcol` / `a.col` / `a.rank_col` / `sign_colors` directly.

**Everything else** — `opacity(alpha, key)` (`alpha` × one `opacity_*` setting, floored) ·
`relation_color(a, fallback)` (relation colour, or the fallback when
`sign` is nil) · `show(w, bool)` and `set_text(w, str)` (change-guarded: they skip the native
call when nothing changed) · `config` (the **live** settings table; `_ui_kx` plus every MCM
option) · `xml` (this mod's parsed `ii_tags.xml`, to reuse `tag_icon`, `tag_node`, `tag_box_*`,
…) · `parent` (the `IiTags` window) · `position(x, y)` / `size(w, h)` (the reused `vector2`
helpers — do **not** cache their return) · `neutral` · `sign_colors` · `api_version`.

> **Population order matters.** `API_CTX` is a table literal near the top of `install()`; a
> member assigned there from a helper defined *further down* silently stores nil, because at
> that line the identifier is not a local yet and resolves as an absent global. `outline`, `dot`
> and `draw_shadowed_text` are therefore attached after their definitions. The API test harness
> asserts every documented member is non-nil, which is how this was caught.

### 8.4 What the mod still does for you

The scanning spinner (your `on_draw` only ever sees revealed targets), target acquisition, LOS,
range and relation gating, fade/hold timing, slot assignment, and hiding on style switch. Hooks
run behind `pcall` — a style that throws is logged **once** and skipped for that slot rather
than taking the HUD down.

### 8.5 Index stability

`ui_style` stores an **index**. Built-ins hold 1..`ii_config.BUILTIN_STYLE_COUNT` (8) and are
never affected. Add-on styles occupy the range above that, sorted by `id`, so a given set of
installed add-ons always yields the same indices regardless of script load order. Installing or
removing an add-on does reshuffle that range — unavoidable while the option stores a number. An
index pointing past the end (an add-on the player removed) falls through to the Card style.

### 8.6 Worked example

```lua
-- gamedata/scripts/my_ii_style.script -- a faction-coloured bar under the target.
local function on_create(state, ctx)
    state.bar = ctx.xml:InitStatic("tag_s2_bar", ctx.parent) -- reuse a built-in template
end

local function on_draw(state, a, ctx)
    local w, h = 30 * a.scale * ctx.config._ui_kx, 4 * a.scale
    state.bar:SetWndSize(ctx.size(w, h))
    state.bar:SetWndPos(ctx.position(a.hx - w / 2, a.hy + 10 * a.scale))
    local c = a.sign and ctx.sign_colors[a.sign] or a.fcol -- nil sign = Show relation is off
    state.bar:SetTextureColor(GetARGB(a.a, c[1], c[2], c[3]))
    ctx.show(state.bar, true)
end

local function on_hide(state, ctx)
    ctx.show(state.bar, false)
end

function on_game_start()
    ii_api.register_style({
        id = "my_bar",
        on_create = on_create,
        on_draw = on_draw,
        on_hide = on_hide,
        dist_scale = true,
    })
end
```

Plus, in the add-on's own string table:

```xml
<string id="ii_uistyle_general_ui_style_lst_my_bar"><text>My Bar</text></string>
```

---

## 9. Dev tooling

- **`flake.nix`** — `devShells.default` provides `xmllint` (libxml2),
  `lua-language-server`, `lua5_1`, `stylua`, `p7zip`. Apps: **`check-xml`** runs
  `xmllint --noout` over all mod XML (guards the recurring bare-`--`-in-XML-comment
  crash), **`check-lua`** runs LuaLS headless at Warning level, **`format`** /
  **`check-format`** run StyLua over the `.script` sources (write / verify), and
  **`package`** reads `<Version>` from `info.xml` and zips a FOMOD bundle.
- **`stylua.toml`** — StyLua config: tabs, wide column (120), `AutoPreferDouble`,
  `call_parentheses="Always"`. StyLua globs `.lua`, so the format apps pass the
  `.script` files explicitly via `find`.
- **`.luarc.json`** — Lua 5.1 runtime, `workspace.library=["types"]` for the
  EmmyLua engine stubs, and the key association trick
  `"files.associations": { "*.script": "lua" }` so LuaLS treats Anomaly's
  `.script` files as Lua and gives them diagnostics/completion.

---

## 10. Design principles (cross-cutting)

- **No RNG — difficulty is reveal delay.** Every "penalty" is a scan-time
  multiplier; identification always succeeds if the target is valid and in range.
- **Snapshot-at-identify.** Timing/range are frozen per-tag so live setting or
  binocular changes never distort an in-progress reveal.
- **Cooperative, not exclusive, hooks.** `level_input.on_key_press` is chained;
  binocular/loot detection uses polling and an FOV baseline instead of contended
  single-slot native callbacks.
- **Soft dependencies, two ways.** Engine C++ globals (`svp_*` PiP) are checked
  via `rawget` at load; Lua script globals (`haru_skills`) are nil-chained at call
  time (load order isn't guaranteed).
- **Single source of truth.** MCM, string ids, and dropdown entry ids are all
  derived from `ii_identify.script`'s `DEFAULTS`/lists and MCM's id-resolution
  rules.
- **Compat via pure VFS overlays.** FactionID via same-path script override;
  Perception via haru_skills' wildcard includes and naming conventions — neither
  edits a host mod.

---

## 11. Free-aim support (bodycam engine)

The `freeaim_assist` setting makes the FOV target-assist circle follow where the
weapon actually points on a free-aim / bodycam engine
(`asuparabekon/xray-monolith-bodycam`) instead of the fixed screen center.

The aim direction comes from **two sources, in order** — the second is a fallback for the
first, and the split is what makes free-aim work for *every* held item:

1. **`bodycam.get_fire_ray()`** (custom engine binding) — the actor's **first-eye aim
   camera** (`CActor::cam_FirstEye()`), which reflects free aim for **any** held item:
   firearm, **knife**, or **binoculars** (not zoomed). Under bodycam the *render* camera
   (`device().cam_dir`, what `world2ui`/`TT_CAMERA` use) is a *swayed override* of the
   first-eye camera, so it's the only source that isn't offset by sway. Implemented in
   `src/xrGame/bodycam_script.cpp` (a pure read of `cam_FirstEye()`'s `vPosition`/
   `vDirection`); **not in the stock exe**, must be compiled in.
2. **`level.get_target_pos/obj(ETraceTarget.Weapon)`** (standard trace) — `g_get_target_pos(TT_WEAPON)`
   builds the point off the equipped item's `barrel_matrix`. For a **firearm** that's the
   real fire direction (accurate, and works on a **stock exe** with no custom binding); for a
   **knife/binoculars** it's the cosmetic HUD-model transform, **not** the aim — which is
   exactly why source 1 exists for those.
   NB: `ETraceTarget` is a **global** enum (engine registers it in `module(L)`,
   level_script.cpp:2595), **not** `level.ETraceTarget` — a namespace trap that hid this path
   for a while (`rawget(_G,"ETraceTarget")`).

- `weapon_aim_ui()` tries the fire ray first (project a far point → `project_world`), then the
  weapon trace; the result is the aim point `aim_center()` gives the screen-radius assist.
- `aim_model_target()` (§3.3) tries a `ray_pick` mesh raycast along the fire ray first, then
  `get_target_obj(ETraceTarget.Weapon)` — the direct-aim "are you on the model" fallback.

Both are `rawget`-guarded and fall back to screen centre / nothing when neither source is
available, so it's safe on every engine. Net: **firearms** work everywhere (stock or custom);
**knife/binoculars** need the custom binding.

Verify with `debug_log` on: the aim-debug dump should show `ETraceTarget` **found**, and the
assist should track a target while free-aiming with a knife or raised binoculars.

## 12. Face redaction — moved out

Face redaction (an engine post-process that censors the face of every humanoid in
range with a pixelated or black box) **used to live in this mod**. It never depended
on identification — no aiming, no keypress, its own range and its own membership
sweep — and its engine half already shipped in the bodycam fork, so the whole feature
now lives there instead:

    xray-monolith-bodycam/
      gamedata/scripts/bodycam_face_redaction.script       driver (sweep, face box, submit)
      gamedata/scripts/bodycam_face_redaction_mcm.script   MCM page ("bcredact/*")
      gamedata/configs/text/{eng,rus}/st_bodycam_redact.xml
      gamedata/shaders/r3/bodycam_redaction.ps             shader (already there)
      src/xrGame/bodycam_script.cpp                        bodycam.redaction_* bindings
      src/Layers/xrRenderPC_R4/                            phase_redaction, phase_svp_redaction

Nothing in this mod drives `bodycam.redaction_*` any more, and no `redact_*` option
remains in its MCM or presets. The two repos are independent: face redaction works
with this mod absent, and this mod works with it absent. The in-scope (SVP) redaction
pass described in §12 is likewise driven from there now.

## 13. In-scope (SVP/PiP) identification markers (engine)

The mod's `svp_ui_markers_begin/add/commit` + `is_svp_active` calls (gated by
`PIP_AVAILABLE`, a `rawget` existence check) draw identification markers **inside a
PiP scope**. These bindings were written against a PiP engine and **did not exist
in the bodycam fork** — only `is_svp_active` — so `PIP_AVAILABLE` was `false` and
the whole path was inert until Phase 1 built them.

**Phase 1 (engine, validated in-game):** a Lua→shared-buffer→render-pass→shader
pipeline. `svp_ui_markers_*` (registered in
`console_registrator_script.cpp` next to `is_svp_active`) stage a list of
WORLD-space markers into `g_bodycam_svp_markers[16×12]` (12 floats: world xyz, fill
rgba, radius, ring rgb, scanning). `CRenderTarget::phase_svp_markers` projects each
through the **SVP camera** (`Device.matrices[1]`, `mul(mProject,mView)` + clip
divide — the same recipe/source `svp_project_world_point_to_lens` and
`phase_svp_capture` use) and draws a small alpha sprite per marker.

Two placement facts were load-bearing (both cost a bringup cycle): the draw must
go into **`rt_Generic_0`** (the RT `phase_svp_capture` copies into `rt_secondVP`
for the lens to sample — not `rt_Color`/`rt_Generic`), and it must be injected at
the **top of `phase_svp_capture`** (svp_optics.cpp), not the `phase_combine` tail,
because `matrices[1]` is only the live scope camera at capture time. Viewport is
the SVP target's `Width`/`Height`. Shader `gamedata/shaders/r3/bodycam_svp_marker.ps`
(faction disc + relation ring + scanning arc; no in-scope text — infeasible in the
pass). Debug: console `r__bodycam_svp_marker_debug 1`. **No Lua changes** — the mod's
existing code drives it. Phase 2 (richer bracket/sign) not yet built.

**In-scope redaction** (same commit): the face redaction also runs in the scope.
`bodycam.redaction_add` gained WORLD box args (`wcx,wcy,wcz,whw,whh`, stored in
`g_bodycam_redaction_world[16×6]`); `phase_svp_redaction` (called in
`phase_svp_capture`, before the markers) reprojects each world box's 4 camera-facing
corners through the SVP camera to a scope-normalised rect and reuses
`bodycam_redaction.ps` **unchanged** (depth `0` = no viewmodel mask in-scope). Relies
on `SetActive` remapping `r2_RT_generic0`/`r2_RT_P` to the SVP RTs so the shader
samples the scope scene. The Lua that feeds those world boxes now lives in the bodycam
repo (§11); this mod's `head_box_for`/`body_box_for` still return a world centre +
world half-extents, used for the in-scope **markers**.

## 14. Notes on this document

- This spec was reconciled against the tree at **v2.55.1**. Line-number citations
  point into `ii_identify.script` at that revision — treat them as "near here",
  since the file changes often; the function names are the durable anchors. For a
  release-by-release view of behaviour changes, see **`CHANGELOG.md`**.
- **`README.md`** — verify its optional-component list matches the three components in
  `ModuleConfig.xml` (FactionID Neutralized, Perception Skill Integration,
  st-wearable-devices Compatibility).
