# Wearable Devices Compatibility — Feature Set

What the **st-wearable-devices (WD)** compatibility component currently brings to
**Immersive Identification**. Optional FOMOD component; install only alongside both mods.
It turns identification into a diegetic, gear-gated system built out of Promin modules and
a worn scanner, with a tier progression and a dedicated Promin readout screen.

---

## 1. Two identification channels

You build either channel, or both: they are **independent** (the antenna and the OSD scanner
sit in separate Promin bays). With both ready, the better scanner tier sets range and
capability, and the on-entity UI shows as usual; it is suppressed only while the OSD channel is
the only one ready.

| | **AR channel** | **OSD channel** |
|---|---|---|
| Where results show | **On entities** — the usual floating tags / bodycam overlays | **Only on the Promin** — the IDENTIFICATION page and its pop-up cards; no on-entity UI at all |
| Scanner form | **AR Scanner** — a worn bracer device | **OSD Scanner Module** — a Promin module |
| Requires | antenna + process module (Promin) **+ worn AR scanner + bracer** | OSD scanner module + process module **only** (no antenna, no bracer, no worn device) |
| Promin worn & powered | yes | yes |

Face redaction (the censor-over-faces feature) is independent of the scanner channel.

---

## 2. Items (10)

All installed/removed through WD's own systems and shown in the bracer customize screen.

**Promin modules** (install via the item use-menu or the customize screen; consumed on
install, returned on removal):

| Item | Bay | Cost |
|---|---|---|
| Promin Antenna Module | `conn` | 4 500 |
| Promin Process Module — Tier 1 / 2 / 3 | `ii_proc` (added) | 5 000 / 9 000 / 16 000 |
| OSD Scanner Module — Tier 1 / 2 / 3 | `ii_osd` (added) | 7 000 / 13 000 / 22 000 |

**Worn device** (mounts on the bracer via its own logical slot):

| Item | Cost |
|---|---|
| AR Scanner — Tier 1 / 2 / 3 | 7 000 / 13 000 / 22 000 |

Only one module fits per bay: installing a different process or OSD scanner tier **swaps out**
the current one and returns it to your pack.

---

## 3. Tier progression

**Process module** — sets scan speed and progressively unlocks *what data* is shown:

| Process tier | Base scan time | Penalty strength | Unlocks (cumulative) |
|---|---|---|---|
| Tier 1 | ~1.5 s | 100% | Faction, Distance |
| Tier 2 | ~1.0 s | 75% | + Relationship, + Rank |
| Tier 3 | ~0.5 s | 50% | + Weapon & caliber |

**Scanner** (AR or OSD, same tier behaviour) — sets *range and capability*:

| Scanner tier | Identify range | Unlocks |
|---|---|---|
| Tier 1 | 10 m | — |
| Tier 2 | 20 m | Scope / ADS support, magnification range boost |
| Tier 3 | 30 m | + No target-visibility scan-time penalty |

With the kit assembled, the process tier supplies the base time and attenuates every enabled base
penalty: distance, rank, held weight, foliage, target lighting, combat, weather, and visor water.
Only each multiplier's slowdown above 1× is scaled, so 100% preserves it, 50% halves it, and 0%
removes it. Scanner tiers continue to drive range, ADS/magnification, and the complete
target-visibility bypass; process tiers continue to drive per-field display gates.
`wd_require_kit` (default on) blocks identification entirely without the kit; turn it off to keep
normal identification and let the kit only *enhance* it.

---

## 4. Promin IDENTIFICATION screen

Installing an OSD scanner module adds an **IDENTIFICATION** page to the Promin's number keys,
after WD's own pages: key 3, or 4 with WD's map module (WD's header draws keys 1-3 only; key 4
still selects the page). It is built like WD 0.9's own pages, with WD's frame, font, colours,
brightness and both themes, and shows the **last-identified target**:

- **Portrait** of the target (its `character_icon`; monsters have none)
- **Name**, **faction** with WD's emblem, and **rank**; faction and rank stay hidden until the
  process tier unlocks them (same gating as the on-entity tags)
- **Distance, position and weapon** (`-` when locked or unknown), and a **scan bar** while a
  scan runs
- A sidebar with the kit: process, OSD scanner, antenna and AR scanner tiers, and the
  identify range

On WD's other pages an identification pops up a card instead (emblem, name, distance, faction
and rank).

---

## 5. MCM — "Wearable Devices" page

Every tier value is tunable on the Wearable Devices page of the Immersive Identification MCM:

- **Require Scanner kit to identify** (master gate)
- **Identification notification scale** — resize the Promin's identification cards live
- **Process scan times** — Tier 1 / 2 / 3
- **Process penalty strengths** — Tier 1 / 2 / 3 (defaults 100% / 75% / 50%)
- **Scanner ranges** — Tier 1 / 2 / 3
- **Feature-unlock tiers** — which process tier reveals Faction / Distance / Relationship /
  Rank / Weapon
- **Scanner capability tiers** — which scanner tier unlocks ADS support / magnification boost
  / no-target-visibility-penalty

The rest of the Immersive Identification MCM (UI style, colours, keybind, …) applies as usual.

---

## 6. Crafting

Recipes for all 10 items, mirroring WD's own recipe format. Tool-tier gated:

- **Tier 1** items (and the antenna) — **basic** tools
- **Tier 2** items — **advanced** tools
- **Tier 3** items — **expert** tools

Higher tiers consume the previous tier plus Promin tech (`wd_promin_upgrade_kit`) and common
electronic parts.

---

## 7. Art

Custom generated 50×50 inventory icons:

- **Antenna** — mast + broadcast waves
- **Process module** — IC chip
- **AR Scanner** — target silhouette in AR viewfinder brackets
- **OSD Scanner** — radar scan display

The AR scanner's *worn* model is intentionally **invisible** (a placeholder mesh showed a
duplicate bracer on the arm); it's a logical device — worn state + tier only.

---

## 8. Engineering / robustness

- **Non-invasive:** every WD/base-mod call is `rawget`/`pcall`-guarded, so the component is
  inert (returns "not driving") when WD or Immersive Identification is absent, and never
  throws into the per-frame identify path.
- **Tier seam:** drives the base mod through a single `ii_identify.tier_provider` hook,
  snapshotted once per frame; the driver's WD-state read is cached (~250 ms).
- **Bays (WD 0.9):** the antenna uses WD's empty `conn` bay; the OSD scanner and process
  module get bays of their own (`ii_osd`, `ii_proc`), since WD 0.9's `side` bay holds its
  environmental modules. WD's modules are untouched. The extra bays come with customize-screen
  cells 4 and 5 in our `ui_wd_customize.xml` override (a missing cell is a fatal
  `module_open_4` XML crash).
- **Ident page and cards without replacing WD files:** `ii_wd_promin` adds the page to WD's
  file-local page table through `UIPromin.ensure_page`'s upvalues and drives the cards from
  WD's own `UIPromin.Update`; both are built from WD's chrome and panel kit, so they follow
  WD's font, palette, brightness and themes. If WD reshapes that code, they switch off with a
  log line instead of crashing.

---

## 9. Fixes since first cut

- Modules now install/appear correctly in the Promin (a dead `actor_on_first_update`
  callback previously stopped registration).
- OSD scanner converted from a worn item to a **Promin module**; the OSD channel no longer
  requires the antenna (only the OSD module + a process module).
- AR scanner worn model made invisible (was spawning a duplicate bracer).
- Item descriptions: fixed the missing line break after **FEATURES:** (an engine text-parser
  quirk dropped a `\n` placed right after a colour tag).
- **Require Scanner kit** toggle: disabling it no longer blocks identification (the checkbox
  marshalled as the number `0`, which is truthy in Lua; now coerced to a real boolean).
- AR scanner tiers now restore from the worn scanner's saved section. Removing an OSD module after
  loading no longer reveals a stale T1 AR tier or disables T2/T3 capabilities until re-equipping.
- Distinct AR-scanner icon added; OSD scanner keeps the radar icon.

---

## Status / caveats

Checked in game with WD 0.9.2 on a save carrying the full kit: modules survive loading, the
customize screen shows cells 4 and 5, the IDENTIFICATION page renders in both WD themes, and an
identification drives the scan bar, the readout and a notification card. WD is coupled by
section/table names; a WD update to its device/slot/module/UI internals may require matching
changes here.
