# Immersive Identification: Player Guide for AI Assistants

> **Mod version:** 4.4.0. **Game:** S.T.A.L.K.E.R. Anomaly / G.A.M.M.A.
>
> **Players:** upload or paste this whole file into ChatGPT, Claude, Gemini, or any other AI
> chat, then ask your question in plain words. For example: "How do I make identification
> instant?", "Why don't I see the rank?", or "Which settings make it feel more hardcore?"

---

## Instructions for the AI reading this file

You are helping a **player** (not a modder) use the Immersive Identification mod. Treat this
file as the full and authoritative description of the mod.

- **Use only what this file says.** If an option or behaviour is not described here, say you
  don't know. Don't invent settings, console commands, or file edits.
- **Use the in-game names.** Players see the captions in the MCM menu, not internal ids. Write
  "**Instant identify** (General page)", not `instant_identify`. Every setting below lists its
  caption, MCM page, default, range, and the internal id in brackets for reference.
- **Give the menu path.** Settings are under: *Esc → Mod Configuration Menu (MCM) →
  Immersive Identification → page → (sub-page)*. The UI Style page has sub-pages.
- **Give exact values.** "Set **Scan delay (s)** to 0.20" is better than "lower the scan delay".
- **Prefer a preset** when the player describes a whole play style (§5).
- **Know the hard limits** (§9) so you don't promise something the mod can't do. The biggest
  one: **mutants and monsters are never identified**, only human stalkers.
- Keep answers short. Players are usually mid-game.

---

## 1. What the mod does

The player looks at a human NPC and presses the **Identify key** (default **X**). A small
rotating **spinner** appears on the target while it "scans". Then a label fades in on the
target's body in the 3D world, showing who they are. It stays for a few seconds, then fades
out. The label tracks the target as you and they move.

What a label can show (each part can be turned off):

- **Faction**: the faction name and the faction patch/emblem.
- **Name**: the NPC's personal name.
- **Rank**: novice, trainee, experienced, professional, veteran, expert, master, legend.
- **Weapon / caliber**: the weapon the NPC is holding and its ammo caliber.
- **Relation**: how they feel about you. Red = enemy, green = friend, tan/grey = neutral.

The mod replaces static HUD faction indicators (like the separate *FactionID* mod) with an
in-world label.

### The key design rule: no randomness

Identification **always succeeds** if the target is valid, alive, in range, and visible.
There is **no RNG**. Difficulty only changes **how long the scan takes**. Distance, rank,
darkness, weather, combat, held weight, foliage, binoculars, scopes, the perception skill,
and having met someone before all make the scan faster or slower. None of them make it fail.

---

## 2. Basic use

1. **Aim at or near a stalker.** You don't need a pixel-perfect hit. If you aren't exactly
   on someone, the mod picks the nearest visible stalker inside an invisible circle around
   your aim point (the **target-assist radius**). Targets behind walls are skipped.
2. **Press the Identify key** (default **X**). You can rebind it, and optionally require
   Ctrl, Shift, or Alt (General page).
3. **Wait for the scan.** The spinner rotates for the scan time (default 0.35 s, longer
   with penalties).
4. **Read the label.** It fades in (0.45 s), stays fully visible (4 s by default), then fades
   out.

Other basics:

- **Pressing the key again** on an already-identified target restarts its reveal.
- **Up to 12 targets** can be labelled at once. A manual identify replaces the oldest one if
  all 12 are in use.
- **Looking away and back** at a target re-runs its scan. If you held it continuously
  (auto modes), the label just refreshes.
- **Out of sight:** with **Drop tag when out of sight** on (default), a label is removed
  shortly after its target goes behind cover.
- **Opening the PDA** (raised to the face, or the classic fullscreen PDA) blocks
  identification and clears all labels. When you lower it, targets need scanning again.
  Merely holding the 3D PDA low doesn't block anything.
- **When you die**, all labels are removed.
- **Already-met stalkers** are remembered across saves and scan faster the next time
  (Familiarity, §4.9).

### Ways to identify, besides the key

All of these are off by default and can be combined with the key:

| Mode | Where | How it triggers |
|---|---|---|
| **Auto-identify visible targets** | Targeting | Continuously labels every visible stalker on screen and in range. No key, no aiming. |
| **Hipfire Auto Identification** | Hipfire | Keep a target under your hip aim for the hold time (default 1.0 s). |
| **ADS Auto Identification** | Aim Down Sight | Keep a target under your aim while aiming down sights for the hold time (default 0.6 s). |
| **Binoculars Auto Identification** | Binoculars | Hold the binoculars steady while zoomed in for the steady time (default 0.6 s). |

For the hipfire and ADS modes, aiming at empty air does nothing, and you can track a moving
target. In the binoculars mode, you only need to hold the view steady near a target.

### Binoculars and scopes help automatically

- **Binoculars** (raised and zoomed in): scans take **40%** of the normal time, and range is
  **4.4×** the base distance. Works with the normal key too. Setting: **Binoculars boost
  identification**.
- **Aiming down sights**: scans take **60%** of the normal time. Range scales with the
  scope's magnification (a 4× scope reaches about 4× as far). Setting: **ADS boosts
  identification**.
- Binocular and ADS boosts never stack with each other.
- With a **Picture-in-Picture (PiP) scope** engine, small markers are drawn inside the scope
  lens as well.

---

## 3. The eight UI styles

Choose under **UI Style → General → UI style**.

| Style | What it looks like | Shows |
|---|---|---|
| **Card** (default) | A dark plate beside the target, joined by a leader line to a coloured dot on their chest. | Faction patch, faction, name, rank, weapon. The richest style. If it gets too small (see **Mini mode cutoff**), it shrinks to just the dot. |
| **Minimal** | A faction-coloured dot plus a small relation sign: `-` red enemy, `+` green friend, `o` tan neutral. | Faction colour and relation only. |
| **Bodycam** | An unfilled rectangle around the head (or whole body), with name and weapon text beside it. | Name, faction, weapon. No rank line. Pairs well with auto-identify. |
| **Simple 2** | Over the head: a faction-coloured circle, a relation-coloured triangle, and a thin rank-coloured bar above them (grey for novice, gold for legend). | Faction, relation, and rank as a colour only. No text. |
| **Simple** | A horizontal strip above the head: relation dot, faction logo, then the name. | Relation, faction logo, name. |
| **Crooks** | Not on the target. A single fixed readout in a screen corner showing the **last** identified stalker. | Faction logo, name, and rank. |
| **Minimal 2** | A single bare dot, no glow, coloured by relation. | Relation only. |
| **Patch** | The faction patch alone, with a relation-coloured outline around it. | Faction patch and relation. No text. |

The Minimal 2, Patch, Simple, and Simple 2 styles always shrink with distance and grow when
you zoom in. Minimal does this only when **Minimal: scale dot with distance** is on. Card and
Bodycam text stays a fixed size.

Other mods can add their own styles to this list. If the player sees a style not listed here,
it comes from another add-on.

---

## 4. Every MCM setting

The format is: **Caption** [internal_id]. *Default. Range.* Then what it does.

### 4.1 General page

The preset dropdown is on this page (§5).

- **Enable identification** [enabled]. *On.* Master switch for the whole mod.
- **Identify key** [key_dik]. *X.* Click the box, then press any keyboard key or mouse button.
- **Modifier** [modifier_index]. *None. Options: None / Ctrl / Shift / Alt.* A key that must be
  held together with the Identify key.
- **Instant identify** [instant_identify]. *Off.* Skips the scan entirely, so labels appear at
  once. Overrides Scan delay and every scan-time penalty. Can be excluded per mode (Hipfire,
  ADS, Binoculars pages).
- **Scan delay (s)** [scan_time]. *0.35. Range 0 to 2.* Base scan time before any multipliers.
- **Fade duration (s)** [fade_time]. *0.45. Range 0 to 2.* Fade-in and fade-out time of the
  label.
- **Identification visibility (s)** [hold_time]. *4.0. Range 1 to 15.* How long the label stays
  fully visible.
- **Drop tag when out of sight** [hide_unseen]. *On.* Removes a label about 0.15 s after its
  target goes behind cover or off-screen.
- **Base identification distance (m)** [max_dist]. *50. Range 10 to 250.* The base range
  before binocular or scope scaling. It is not a hard maximum. For a hard cap, use the "Max
  identification distance" setting on the Hipfire, ADS, or Binoculars page.

### 4.2 UI Style → General

- **UI style** [ui_style]. *Card.* See §3.
- **Show name** [show_name]. *On.* The name line.
- **Show faction** [show_faction]. *On.* The faction line. In Minimal it toggles the faction
  dot. In Patch it toggles the patch.
- **Show rank** [show_rank]. *On.* The rank line (Card, Crooks) or rank bar (Simple 2).
- **Show relation** [show_relation]. *On.* Whether the label says friend, enemy, or neutral at
  all. When off:
  - Minimal drops its sign and Simple 2 drops its triangle.
  - Card and Simple use a neutral tint.
  - Patch drops its outline.
  - Bodycam and Minimal 2 use the faction colour instead.
- **Custom faction patches** [custom_patches]. *Off.* Use replacement faction patch art
  instead of the game's own faction icons. Needs a patch source (an installer option, §7)
  **and** this switch on. With only one of the two, nothing changes. Factions without
  replacement art show no patch.
- **Show weapon / caliber** [show_weapon]. *On.* The held weapon and caliber line (Card,
  Bodycam).
- **Colour by relation** [color_by_relation]. *On.* Tints labels red, green, or tan by relation.
  Off gives a flat neutral tint. This setting only changes colour. To remove the relation cue
  entirely, use **Show relation**.
- **Minimal: scale dot with distance** [mini_dist_scale]. *On.* In Minimal style, distant dots
  get smaller.
- **Dot scale** [dot_scale]. *1.00. Range 0 to 3.* Size of the dot markers. 0 hides them.
- **Glow scale** [glow_scale]. *1.00. Range 0 to 3.* Size of the soft glow behind dots. 0 hides
  it.
- **Loading spinner scale** [spinner_scale]. *1.00. Range 0 to 3.* Size of the scan spinner. 0
  hides it.
- **UI offset X (px)** [ui_offset_x]. *0. Range −200 to 200.* Moves labels left (negative) or
  right.
- **UI offset Y (px)** [ui_offset_y]. *0. Range −200 to 200.* Moves labels up (negative) or
  down.
- **Anchor position** [anchor_basis]. *Head. Options: Head / Torso / Feet.* Where on the body
  the label attaches. The Bodycam box has its own area setting.

### 4.3 UI Style → Card

- **Card scale** [card_scale]. *1.00. Range 0.5 to 2.* Overall size multiplier. Despite the
  name, it affects **every** style.
- **Faction patch size** [card_icon_scale]. *1.25. Range 0.5 to 3.* Size of the emblem on the
  card.
- **Mini mode cutoff** [mini_scale_cutoff]. *0.40. Range 0.1 to 1.* Below this card scale,
  only the relation dot is shown instead of the card.

### 4.4 UI Style → Simple

- **Faction patch size** [simple_icon_scale]. *1.25. Range 0.5 to 3.* Size of the emblem in the
  Simple strip.

### 4.5 UI Style → Bodycam

- **Bodycam box area** [box_area]. *Head / face. Options: Head / face, Full body.*
- **Bodycam box colour** [box_color_source]. *Faction colour. Options: Faction colour,
  Relationship.*
- **Box outline thickness** [box_thickness]. *2. Range 1 to 6 px.*
- **Box padding** [box_padding]. *0.20. Range 0 to 1.* Margin around the model, as a fraction
  of the box size.
- **Box opacity** [box_opacity]. *1.00. Range 0.1 to 1.* Opacity of the box only. Text is not
  affected.
- **Box text gap** [box_text_gap]. *8. Range 0 to 40 px.* Space between the box and its text.

### 4.6 UI Style → Crooks

- **Crooks: screen position** [crooks_pos]. *Bottom left. Options: Bottom left, Bottom middle,
  Bottom right.*
- **Crooks: X offset** [crooks_x]. *0. Range −500 to 500.* Positive moves right.
- **Crooks: Y offset** [crooks_y]. *0. Range −100 to 700.* Positive moves up.
- **Faction patch size** [crooks_icon_scale]. *1.25. Range 0.5 to 3.* Emblem size. Large values
  may need a higher Y offset.
- **Faction patch gap** [crooks_icon_gap]. *10. Range 0 to 40 px.* Space between the emblem and
  the text.

### 4.7 UI Style → Patch

- **Patch size** [patch_size]. *13. Range 8 to 64.* Patch size at the reference distance.
- **Patch outline thickness** [patch_thickness]. *2. Range 0 to 5.* 0 removes the outline,
  leaving the bare patch.
- **Patch outline gap** [patch_padding]. *0. Range 0 to 12.* Space between the patch and its
  outline.
- **Patch outline opacity** [patch_ring_opacity]. *1.00. Range 0 to 1.*

### 4.8 UI Style → Opacity

Each slider runs from 0 (invisible) to 1 (solid) and defaults to 1.00. They work in every
style. Hiding an element doesn't move the others.

- **Name opacity** [opacity_name]. The name text.
- **Faction text opacity** [opacity_faction]. The faction text line.
- **Rank text opacity** [opacity_rank]. The rank text line.
- **Weapon text opacity** [opacity_weapon]. The weapon and caliber line.
- **Background opacity** [opacity_background]. The Card's dark plate and shadow. At 0, the text
  floats on its own.
- **Markers and shapes opacity** [opacity_markers]. Dots, glows, the Minimal sign, the Simple 2
  shapes, the Card accent bar, and the in-scope marker.
- **Faction patch opacity** [opacity_patch]. The faction emblem or patch.
- **Leader line opacity** [opacity_line]. The Card's line from the body dot to the card.
- **Scan spinner opacity** [opacity_spinner]. The scan spinner.

### 4.9 Targeting page

- **FOV target assist** [fov_assist]. *On.* When you don't aim directly at someone, pick the
  nearest stalker inside the assist circle. Off means you must aim directly at the target.
- **Free-aim target assist** [freeaim_assist]. *Off.* For free-aim and bodycam setups: centre
  the assist on where the weapon actually points instead of the screen centre. Firearms work on
  any engine. A knife or binoculars need the custom bodycam engine. Otherwise this setting is
  harmless.
- **Target-assist radius (px)** [fov_radius]. *35. Range 0 to 90.* Size of the assist circle. 0
  means a direct hit only.
- **Scale assist radius with zoom** [fov_zoom_scaling]. *On.* Shrinks the circle when zoomed, so
  the assist doesn't become grabby through a scope.
- **Identify all in assist radius** [fov_identify_all]. *On.* For the auto modes (hipfire, ADS,
  binoculars): label every stalker in the circle at once. Off labels only the one nearest your
  aim. The manual key always picks the nearest.
- **Require line of sight** [require_los]. *On.* Only identify stalkers you can actually see.
- **Block ID through transparent surfaces** [los_block_seethrough]. *Off.* Treat fences, glass,
  foliage, and invisible clip walls as solid.
- **Block ID through foliage** [los_block_foliage]. *Off.* Block only bushes, trees, and grass.
  Fences and glass still let identification through. Matching is best-effort by material name.
- **Exclude hostiles in combat** [exclude_hostile]. *Off.* Enemies that are actively attacking
  you can't be identified, and their existing labels are removed.
- **Only show overlay while aimed** [hide_off_aim]. *Off.* Only the target you're aiming at
  keeps a label. Looking away drops it, and looking back re-scans it.
- **Auto-identify visible targets** [auto_identify]. *Off.* Continuously labels every visible
  stalker on screen and in range. No key needed. Line of sight is always required for this mode.

### 4.10 Hipfire page

- **Auto Identification** [hipfire_mode]. *Off.* Auto-identify while hip-firing once a target
  stays under your aim (or inside the assist circle) for the hold time.
- **Hipfire hold time (s)** [hipfire_hold_time]. *1.0. Range 0 to 3.* 0 means instant.
- **Exclude hipfire from instant identify** [instant_exclude_hipfire]. *Off.* With Instant
  identify on, hipfire still uses the normal scan.
- **Max identification distance (m)** [hipfire_max_dist]. *0. Range 0 to 1000.* Hard range cap
  when hip-firing. 0 means no cap.

### 4.11 Binoculars page

- **Auto Identification** [binocular_mode]. *Off.* Auto-identify by holding raised, zoomed
  binoculars steady.
- **Require binoculars** [require_binoculars]. *Off.* Identification (key and auto) only works
  through raised binoculars.
- **Steady-aim time (s)** [steady_time]. *0.6. Range 0 to 3.* How long to hold steady.
- **FOV assist with binoculars** [fov_assist_binoc]. *On.* Off requires a direct hit through
  binoculars.
- **Binoculars boost identification** [binoc_boost]. *On.* Faster scans and longer range with
  binoculars.
- **Binoculars scan speed multiplier** [binoc_scan_mult]. *0.40. Range 0.1 to 1.* Lower is
  faster. 0.40 means 40% of the normal time.
- **Binoculars max distance multiplier** [binoc_range_mult]. *4.4. Range 1 to 5.* Range
  multiplier with binoculars.
- **Scale range by magnification** [binoc_zoom_scaling]. *Off.* Use the binoculars' real zoom
  as the range multiplier instead of the flat value above.
- **Clear tags when lowering binoculars** [binoc_clear_on_lower]. *Off.* Lowering the binoculars
  wipes every label. Labels beyond your normal range are always removed when you lower them.
- **Exclude binoculars from instant identify** [instant_exclude_binoc]. *Off.*
- **Max identification distance (m)** [binoc_max_dist]. *0. Range 0 to 1000.* Hard cap. 0
  means no cap.

### 4.12 Aim Down Sight page

- **Auto Identification** [ads_mode]. *Off.* Auto-identify while aiming down sights once a
  target stays on your aim for the hold time.
- **ADS hold time (s)** [ads_hold_time]. *0.6. Range 0 to 3.* 0 means instant.
- **ADS boosts identification** [ads_boost]. *On.*
- **ADS scan speed multiplier** [ads_scan_mult]. *0.60. Range 0.1 to 1.* Lower is faster.
- **ADS max distance multiplier (x1 base)** [ads_range_mult]. *1.0. Range 1 to 5.* Range
  multiplier for a 1× sight.
- **Scale range by scope magnification** [ads_zoom_scaling]. *On.* Higher-power scopes reach
  further (base × magnification).
- **Hide main-view UI while aiming** [ads_hide_main]. *Off.* Hides all labels while aiming, for
  a clean sight picture. In-scope markers still draw.
- **Block identification through thermal scopes** [ads_block_thermal]. *Off.* No identification
  through an active thermal image (S3DS). Switchable scopes still work in normal mode.
- **Exclude ADS from instant identify** [instant_exclude_ads]. *Off.*
- **Max identification distance (m)** [ads_max_dist]. *0. Range 0 to 1000.* Hard cap. 0 means
  no cap.

### 4.13 PiP Scope page

These settings need a Picture-in-Picture scope engine. Without one they do nothing.

- **Identification markers in scope** [pip_markers]. *On.* Draws small markers inside the scope
  lens. The markers have no text.
- **Hide main-view UI when scope is up** [pip_hide_main]. *Off.* Shows only the in-scope markers
  while the scope is up.

### 4.14 Scan Time page (penalties and bonuses)

Each factor multiplies the scan time. Above 1 means slower, below 1 means faster.

**Distance Penalty**
- **Distance slows identification** [dist_penalty]. *On.*
- **Max distance slowdown** [dist_penalty_max]. *5.0. Range 1 to 6.* Multiplier at the edge
  of your range. It rises evenly from 1× point-blank. Because binoculars extend the range, they
  also reduce this penalty.

**Rank Penalty**
- **Rank slows identification** [rank_penalty]. *On.*
- **Max rank slowdown** [rank_penalty_max]. *3.0. Range 1 to 6.* Multiplier for a legend. The
  other ranks get a fixed share of the extra time:

  | Rank | Share | Multiplier at default |
  |---|---|---|
  | novice | 0% | 1× |
  | trainee | 8% | 1.16× |
  | experienced | 20% | 1.4× |
  | professional | 35% | 1.7× |
  | veteran | 50% | 2× |
  | expert | 68% | 2.36× |
  | master | 85% | 2.7× |
  | legend | 100% | 3× |

**Target Visibility Penalty**
- **Low visibility slows identification** [night_penalty]. *On.* Uses how lit the target
  actually is. Shadows and night slow the scan, and flashlights or other lights speed it up.
- **Ignore penalty if NVG active** [night_ignore_nvg]. *On.* No visibility penalty while your
  night-vision goggles are on.
- **Max low-visibility slowdown** [night_penalty_max]. *2.0. Range 1 to 6.* Multiplier in total
  darkness.
- **Fully visible luminance** [night_luminance_threshold]. *0.50. Range 0.05 to 1.* Light level
  where the penalty ends (0 is pitch dark, 1 is bright).

**Weather Visibility**
- **Weather slows identification** [weather_penalty]. *On.* Rain and storms apply only while
  you're outdoors and exposed. Fog scales with the target's distance. The strongest single
  effect counts. Effects don't multiply together.
- **Max visibility slowdown** [weather_penalty_max]. *2.0. Range 1 to 6.*
- **Wet visor slows identification** [visor_water_penalty]. *On.* Water droplets on a worn gas
  mask (Anomaly/GAMMA visor drops) count too. Wiping the mask clears them.
- **Wet visor threshold** [visor_water_threshold]. *0.35. Range 0 to 0.95.* Droplet level where
  the visor penalty starts.

**Combat Pressure**
- **Combat slows identification** [combat_penalty]. *On.* Applies while enemies are fighting
  you, and for about 10 s after.
- **Combat slowdown** [combat_penalty_mult]. *1.5. Range 1 to 6.*
- **Under-fire slowdown** [combat_pressure_mult]. *2.5. Range 1 to 6.* Replaces the combat
  slowdown right after you're hit or a hostile bullet passes close by.
- **Under-fire duration (s)** [combat_pressure_duration]. *5.0. Range 0.5 to 15.* Each new hit or
  near miss extends it.
- **Near-miss radius (m)** [combat_near_miss_radius]. *3.0. Range 0.5 to 10.* Near-miss detection
  needs the demonized engine. Without it, hits and general combat still count.

**Weight Penalty** (off by default)
- **Held-item weight penalty** [weight_penalty]. *Off.* Heavier held items make scanning slower.
- **Max weight slowdown** [weight_penalty_max]. *2.0. Range 1 to 6.*
- **Reference weight (kg)** [weight_penalty_ref]. *6.0. Range 1 to 20.* Weight at which the
  penalty is at its maximum.

**Foliage Penalty** (off by default)
- **Through-foliage penalty** [foliage_penalty]. *Off.* Scanning through bushes, trees, or
  grass takes longer. This is a soft alternative to blocking.
- **Foliage slowdown** [foliage_penalty_max]. *2.5. Range 1 to 6.*

**Familiarity**
- **Remember identified stalkers** [familiarity_boost]. *On.* Stalkers you've identified before
  are remembered across saves and scan faster.
- **Familiar target speed multiplier** [familiarity_scan_mult]. *0.60. Range 0.1 to 1.*

**Skill System (Perception)**. Needs the Skill System mod plus its installer option (§7).
- **Perception skill integration** [perception_compat]. *On.*
- **Speed bonus per level** [perception_scan_mult]. *0.04. Range 0 to 0.1.* Scan time drops by
  4% per perception level, down to a minimum of 15% of normal.
- **Perception XP per identify** [perception_xp]. *20. Range 0 to 100.* XP for the first
  identification of each stalker, once per stalker.
- **Perception XP per loot** [perception_loot_xp]. *20. Range 0 to 100.* Bonus XP for the first
  time you loot a corpse you had identified.

**How scan time is calculated:**
Scan delay × distance × rank × weight × foliage × visibility × binocular-or-ADS boost ×
perception × combat × weather × familiarity.

For example, with defaults, a veteran at half your range in daylight takes
0.35 × 3.0 × 2.0 = **2.1 s**. Through binoculars at the same spot, the 4.4× range makes the
distance factor smaller, and the 0.4 boost applies on top. **Instant identify** skips the
whole calculation.

### 4.15 Audio page

- **Audio volume (%)** [audio_volume]. *100. Range 0 to 200.* Master volume for all of the
  mod's sounds.
- **Vibration cue when scan starts** [scan_start_sound]. *Off.* Plays a low buzz when a scan
  begins. There's no buzz with Instant identify.
- **Scan-start cue: manual identification only** [scan_start_manual_only]. *Off.* Silences the
  buzz for auto modes.
- **Neutral beep when identification completes** [identify_done_sound]. *Off.*
- **Completion beep: manual identification only** [identify_done_manual_only]. *Off.*
- **Hostile faction warning sound** [wd_hostile_sound]. *Off.* Needs the Wearable Devices
  installer option and an active scanner. Plays a faction-specific warning when a hostile target
  is identified. Loner, Duty, Mercenary, Clear Sky, and Sin have clips. Other factions are
  silent.
- **Hostile warning: manual identification only** [wd_hostile_manual_only]. *Off.*

### 4.16 Debug page

Leave these off for normal play.

- **Log aim debug** [debug_log]. *Off.* Writes diagnostics to
  `appdata/logs/immersive_identification.log`. This includes a "display gates" block that
  explains why a line (rank, weapon, and so on) is shown or hidden.
- **Debug draw** [debug_draw]. *Off.* Draws on screen:
  - the assist circle (yellow) and the aim point (red);
  - dots on the bones of nearby stalkers, green if in range and red if out of range;
  - an info panel with a timing breakdown of every scan factor, and why the aimed stalker is or
    isn't being identified.
- **Simulate stock engine** [debug_sim_stock]. *Off.* Testing only. Acts as if the custom engine
  features were missing.

### 4.17 Wearable Devices page

This page only appears if the **Wearable Devices Compatibility** installer option is installed.

- **Ignore Wearable Devices entirely** [wd_ignore]. *Off.* Turns the integration off, so the mod
  works as if WD weren't installed.
- **Require scanner kit to identify** [wd_require_kit]. *On.* With this on, nothing can be
  identified until the full kit is assembled. Off means normal identification works without the
  kit, and the kit only enhances it.
- **Identification notification scale** [wd_notify_scale]. *1.00. Range 0.5 to 2.* Size of the
  pop-up cards on the Promin screen.
- **Tier 1 / 2 / 3 scan time (s)** [wd_proc_t1/t2/t3]. *1.5 / 1.0 / 0.5. Range 0.1 to 5.* Base
  scan time for each process module tier. This replaces Scan delay.
- **Tier 1 / 2 / 3 penalty strength** [wd_penalty_t1/t2/t3]. *1.00 / 0.75 / 0.50. Range 0 to 2.*
  How much of each scan penalty applies. 0 means none, 1 means full, 2 means double.
- **Tier 1 / 2 / 3 range (m)** [wd_scan_t1/t2/t3]. *10 / 20 / 30. Range 5 to 100.* Identify range
  for each scanner tier.
- **Faction / Distance / Relationship / Rank / Weapon unlock tier** [wd_feat_*]. *1 / 1 / 2 / 2 /
  3.* The process module tier that reveals each piece of information.
- **Binocular support / Scope-ADS support / Magnification boost / No visibility penalty tier**
  [wd_scanner_binoc/ads/mag/nonight]. *1 / 2 / 2 / 3.* The scanner tier that unlocks each
  feature.

### 4.18 Colors page

- **Use custom colors** [custom_colors]. *Off.* When on, the sliders below replace the built-in
  colours. Changes apply live.
- Each colour has three sliders, **Red / Green / Blue**, from 0 to 255:
  - **Relation:** enemy, friend, neutral.
  - **Factions:** Loner, Bandit, Duty, Freedom, Clear Sky, Ecologist, Mercenary, Military,
    Monolith, Renegade, Zombified, Sin, Trader, Monster, UNISG, Arena.
  - **Ranks:** novice through legend.

---

## 5. Presets

The presets are in the dropdown at the top of the **General** page. A preset only changes the
settings it lists. Everything else keeps your values.

| Preset | What it sets |
|---|---|
| **Default settings** | Resets every setting to default. Colours reset separately with the "Use custom colors" switch. |
| **Classic Card** | Card style; name, faction, and weapon on; colour by relation; normal 0.35 s scan; 4 s visibility; auto-identify off. |
| **Minimal Dot** | Minimal style; normal scan; auto-identify off. |
| **Tactical Bodycam** | Bodycam style with a full-body box at 85% opacity; instant identify; auto-identify on; drop tag when out of sight. |
| **Immersive (Hardcore)** | Card style; slower 0.6 s scan; 3 s visibility; **no target assist** (aim directly); line of sight required; distance, rank, visibility, weather, visor, and combat penalties on; auto-identify off. |
| **Crooks (Instant, all modes)** | Crooks corner readout; instant identify; free-aim assist on; tighter 22 px radius; only the aimed target is kept; hipfire, ADS, and binocular auto modes all on with zero wait. |

---

## 6. Common requests and how to do them

| The player wants… | Tell them to… |
|---|---|
| No waiting at all | Turn on **Instant identify** (General). |
| Instant for the key, but scanning when scoped | Instant identify on, then **Exclude ADS from instant identify** (ADS page). |
| Labels without pressing anything | **Auto-identify visible targets** (Targeting), or the **Tactical Bodycam** preset. |
| Identify just by aiming | **Auto Identification** on the Hipfire and/or ADS page. Set the hold time to 0 for instant. |
| A harder, more realistic feel | The **Immersive (Hardcore)** preset. Optionally add **Weight** and **Foliage** penalties, **Require binoculars**, and **Block ID through foliage**. |
| A cleaner screen | Pick **Minimal**, **Minimal 2**, or **Patch**. Or lower **Card scale**, or set **Background opacity** to 0. |
| Labels lasting longer | Raise **Identification visibility (s)**, and turn off **Drop tag when out of sight**. |
| Identify from further away | Raise **Base identification distance (m)**. Binoculars and scopes multiply it. |
| A stop to absurd binocular range | Set **Max identification distance (m)** on the Binoculars page (for example 200). |
| No hints about friend or foe | Turn off **Show relation**. |
| No help from the target assist | Turn off **FOV target assist**, or set **Target-assist radius** to 0. |
| Labels that only stay while aiming | **Only show overlay while aimed** (Targeting). |
| Identification only with binoculars | **Require binoculars** (Binoculars page). |
| A different key | **Identify key** (General). Add a **Modifier** if X clashes with another mod. |
| The label higher, lower, or on the feet | **UI offset Y**, or **Anchor position** = Torso or Feet. |
| A bigger or smaller label | **Card scale** (affects every style). Use the **Faction patch size** sliders for emblems. |
| Sound feedback | Turn on the cues on the **Audio** page. |
| No two faction indicators at once | Reinstall with the **Neutralize FactionID HUD** option (§7). |

---

## 7. Installer (FOMOD) options

The base mod is always installed. The optional parts are below.

**Compatibility** (choose any):
- **Neutralize FactionID HUD** (pre-checked). Silences the separate *FactionID* mod's HUD so you
  don't see two faction indicators. Harmless if FactionID isn't installed.
- **Skill System: Perception**. Adds a **Perception** skill to the *Skill System* (haru_skills)
  mod. It levels up from identifying (and looting identified corpses) and speeds up scanning.
  Only install it if you have Skill System.
- **Wearable Devices Compatibility (WD 0.9.2)**. Ties identification to scanner gear from
  *st-wearable-devices*. Only for WD version 0.9.2; other versions may crash. Details below.

**Custom faction patches** (choose at most one). Each also needs **Custom faction patches**
switched on in UI Style → General.
- **HD Faction Patches**. Bundled artwork based on Leekos' HD Faction Patches. Works on its own.
- **GRIP Patches**. Uses Kos' GRIP icon pack art. GRIP must be installed.
- **GAMMA Patches**. Uses G.A.M.M.A. UI's art. G.A.M.M.A. UI must be installed.
- If you pick the wrong one of GRIP or GAMMA for the atlas your load order actually uses, every
  patch shows cropped to a corner. Switch to the other option.
- Traders, mutants, and Arena have no patch in any of these sources.

### Wearable Devices system, in short

The WD option adds several new items:
- a **Promin Antenna** module;
- **Process modules** (tiers 1 to 3);
- **OSD Scanner modules** (tiers 1 to 3);
- a worn **AR Scanner** (tiers 1 to 3).

There are two independent ways to make identification work:

- **AR (labels on targets):** wear the bracer, the AR Scanner, and a powered Promin with the
  Antenna and a Process module installed.
- **OSD (Promin screen readout):** install an OSD Scanner module and a Process module in a
  powered, worn Promin. Results then appear on a new **IDENTIFICATION** page of the Promin (number
  key 3 while the Promin is raised, or 4 with WD's map module), and as pop-up cards on the other
  Promin pages. In OSD-only mode, no labels are drawn on targets.

The tiers work like this:
- The **process tier** sets the base scan time and penalty strength, and unlocks what's shown:
  faction and distance at tier 1, relation and rank at tier 2, weapon at tier 3.
- The **scanner tier** sets the range (10, 20, or 30 m) and unlocks binoculars (tier 1), scopes
  and magnification boost (tier 2), and no visibility penalty (tier 3).
- While WD drives identification, the binocular and ADS speed boosts, perception skill,
  familiarity, and instant identify **don't speed up scans**. Perception XP is still awarded.
- All values are on the **Wearable Devices** MCM page. The item art is placeholder.

---

## 8. Troubleshooting

| Problem | Likely cause and fix |
|---|---|
| Pressing X does nothing | (1) **Enable identification** is off. (2) A **Modifier** is set but not held. (3) **Require binoculars** is on. (4) The target is a **mutant**, which can't be identified. (5) It's out of range. (6) Line of sight is blocked, including by foliage or glass if the blocking options are on. (7) The PDA is raised. (8) With WD installed and **Require scanner kit** on, the kit is incomplete. (9) **Exclude hostiles in combat** is on and the target is attacking you. (10) **Block identification through thermal scopes** is on and you're using a thermal sight. |
| The key conflicts with another mod | Rebind **Identify key**, or add a **Modifier**. |
| Wrong target picked | Lower **Target-assist radius**, or turn off **Identify all in assist radius** for auto modes. |
| Identification takes too long | Check the Scan Time penalties. Turn on **Debug draw** to see which factor is slow. Or use **Instant identify**. |
| Rank line missing | **Show rank** is off. Or the style has no rank line: Bodycam has none, and Simple 2 shows rank as a colour bar only. Or a WD process tier below the Rank unlock tier is active. |
| Weapon line missing | **Show weapon / caliber** is off, the style doesn't show it (only Card and Bodycam do), or the WD process tier is below the Weapon unlock tier. |
| No relation colour | **Show relation** or **Colour by relation** is off, or the WD tier is too low. |
| No faction patch / an empty square | With **Custom faction patches** on, no patch source is installed, or that faction has no art. Turn the option off, or install a patch option. |
| Patches cropped to a corner | The wrong GRIP/GAMMA option for your atlas. Reinstall with the other one. |
| Two faction indicators on screen | Reinstall with **Neutralize FactionID HUD**. |
| Labels vanish when lowering binoculars | Distant labels beyond your normal range always disappear, because the magnified range is gone. To clear all labels, turn on **Clear tags when lowering binoculars**. |
| Labels vanish behind cover | **Drop tag when out of sight**. Turn it off to keep labels for the full visibility time. |
| Labels don't show while scoped | **Hide main-view UI while aiming** or **Hide main-view UI when scope is up** is on. |
| No markers inside the scope | Needs a PiP scope engine, and **Identification markers in scope** must be on. |
| Perception skill not appearing | Needs the Skill System mod **and** the "Skill System: Perception" installer option. |
| The Wearable Devices page is missing | The WD installer option isn't installed. |
| MCM crashes on the Immersive Identification menu | The mod's script failed to load, usually because of a conflict or a bad install. Check the game log for `ii_identify` errors and reinstall. |

When reporting a bug to the author, turn on **Log aim debug** and attach
`appdata/logs/immersive_identification.log` along with the game's `xray_*.log`.

---

## 9. Hard limits (don't promise these)

- **Mutants and monsters are never identified.** The game has no faction data for them.
- Identification never fails at random. It only takes longer.
- Text inside PiP scopes isn't possible. Scopes show only coloured markers.
- Card and Bodycam text doesn't shrink with distance.
- A custom faction patch exists only for factions the art source covers.
- There is no per-faction show or hide filter.
- Without the WD option, there's no gear requirement. Identification is always available.
- Settings can only be changed through MCM, which is strongly recommended. Without MCM, the mod
  runs on its defaults.
