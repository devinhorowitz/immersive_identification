# Immersive Identification — st-wearable-devices Compatibility

Optional FOMOD component. Install **only** alongside both **Immersive Identification**
and **st-wearable-devices** (WD). It gates identification behind wearable scanner gear
and a module tier system. See `SPEC.md` §7.3 for the full design.

## What it adds

- **Promin Antenna Module** — establishes the scanner↔Promin link (required).
- **Promin Process Module (Tier 1/2/3)** — sets scan speed, reduces every enabled penalty to
  100% / 75% / 50% strength by default, and gradually unlocks the data shown: faction +
  distance (T1), + relationship + rank (T2), + weapon (T3).
- **AR Scanner (Tier 1/2/3)** — a **worn** bracer device; identification is shown **on
  entities** the usual way (tags/overlays). Sets range (10/20/30 m) and unlocks scope/ADS
  support + a magnification range boost (T2) and no-target-visibility-penalty (T3). Needs the antenna
  + a process module in the Promin.
- **OSD Scanner Module (Tier 1/2/3)** — a **Promin module** (not worn); identification is
  shown **only on the Promin IDENTIFICATION page** — no on-entity UI at all (no tags, no
  in-scope markers). Same 3 tiers as the AR scanner. It sits in its own Promin bay (`ii_osd`,
  added by this component — see below), so it can be installed **alongside** the antenna.
  The OSD path needs **only the OSD scanner module + a process module** (no antenna, no worn
  scanner, no bracer). The AR and OSD channels are independent — with both installed you get
  entity overlays *and* the Promin readout. The Promin IDENTIFICATION page is the OSD
  channel: it exists only while an OSD scanner is installed.

With either channel's kit assembled — **AR**: Promin worn & powered + antenna + a process
module installed + a worn AR scanner + bracer; **OSD**: Promin worn & powered + an OSD
scanner module + a process module (no antenna, no worn scanner, no bracer) — identification
runs on the tiers. Tune every default on the **Wearable Devices** page of the Immersive
Identification MCM. `wd_require_kit` (default on) blocks identification entirely without a
kit; turn it off to keep normal identification when neither kit is complete and let the
tiers only enhance it.

## How the modules install

Wear the Promin, then install the modules (antenna, process, OSD scanner) through **WD's
own system** — the item's use menu (**"Install module"**) or the **bracer customize
screen**, where they show in the module cells with their icons. Remove them via the
Promin's own remove option (WD's use3). Each occupies its own bay (see below); only one
module per bay fits at a time, so installing a different **process** tier — or a different
**OSD scanner** tier — **swaps out** the current one, returning it to your pack (WD's
`install_module` does that).

The Promin ships three module bays: `map` (navigation), `conn` and `side`. In WD 0.9 `side`
holds WD's environmental modules, while `conn` still does nothing, so the **antenna** goes in
`conn` and this component **adds two bays**: `ii_osd` for the OSD scanner and `ii_proc` for the
process module. WD's own modules are untouched. All three of our bays work on a tier-1 Promin
too.

The two extra bays need a shipped **override of WD's `ui_wd_customize.xml`** — WD's customize
screen builds one cell per bay and only ships XML for three, so an extra bay is otherwise a
fatal `XML node module_open_4 not found`. Our copy adds cells 4 and 5, side by side under WD's
module column. (Re-sync it if WD updates that file.) The extra bays render WD's placeholder
null mesh on the Promin.

Because the antenna and OSD scanner sit in separate bays, the **AR and OSD channels are
independent**: install both (plus a worn AR scanner) to get on-entity overlays *and* the
Promin readout at the same time.

## Identification notifications

While the Promin shows the **COMMUNICATIONS**, **BIOMONITOR** or **NAVIGATION** page and a
target is identified, a card pops up in the **bottom-right** and stacks upward (up to four,
expiring after a few seconds), drawn like WD's own panels: faction emblem, name and distance,
then faction and rank. Nothing shows on the IDENTIFICATION page itself (the full readout is
already there). Rendered by `d_ii_promin_notify.script`. The **Identification notification
scale** slider on II's Wearable Devices MCM page resizes the cards from 0.5× to 2×.

## Promin IDENTIFICATION page

Installing an **OSD scanner** module adds the **IDENTIFICATION** page to the Promin's number
keys, after WD's own pages: key **3**, or **4** when WD's map module is installed (WD's header
only draws keys 1-3, but key 4 still selects the page). The page is built the way WD 0.9 builds
its own: WD's frame, clock, battery and keys, WD's font, colours and brightness, and WD's
**Default Large** theme. The big box shows the **last-identified target**: a **portrait** (the
NPC's `character_icon`), name, faction with WD's emblem, rank, then **distance**, **position**
and **weapon**, and a **scan bar** while a scan is in progress. Faction and rank appear once the
process tier unlocks them (the same gating as the on-screen tags); locked rows read `-`. Before
the first identification it reads NO CONTACT. The sidebar shows the **scanner kit**: process, OSD
scanner, antenna and AR scanner tiers, and the identify range in force.

No WD file is replaced for this: `ii_wd_promin.script` adds the page to WD's page table and
drives the notification cards from WD's own Promin window. The page title is drawn from WD's
JetBrains Mono font atlas, like WD's own titles.

## Placeholder art

This component ships **no bespoke art or models**; the tier *logic* is complete, but:

- **Item icons**: each item family has its own generated 50×50 icon —
  `icon_ii_wd_antenna.dds` (mast + broadcast waves), `icon_ii_wd_process.dds` (an IC
  chip), `icon_ii_wd_ar_scanner.dds` (target in AR viewfinder brackets, for the AR
  scanner), and `icon_ii_wd_scanner.dds` (a radar scan display, for the OSD scanner
  modules). `icon_ii_wd_null.dds` remains as the base fallback.
- **Scanner is invisible**: it attaches no worn model on purpose (reusing a mesh showed a
  duplicate bracer on the arm). It's a logical device — worn state + tier only. To ship a
  real model later, re-enable the attach in `d_ii_scanner.sync_attachment` (a commented
  template is there) and tune the transforms in `d_ii_scanner_config.script`.

## Checked in game

With WD 0.9.2, on a save carrying the full kit (OSD scanner, process module and antenna
installed, AR scanner worn): the installed modules survive loading, the customize screen shows
cells 4 and 5, the IDENTIFICATION page renders in both themes, and an identification drives the
scan bar, the readout and a notification card. WD is coupled by section/table names — if WD
updates its device/slot/UI internals, this component may need matching updates.
