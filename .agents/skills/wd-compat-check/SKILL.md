---
name: wd-compat-check
description: Check whether a (newly pulled) st-wearable-devices (WD) version is still compatible with Immersive Identification's "WD Compatibility" FOMOD component, and re-sync it if not. Invoke when the user pulls/updates st-wearable-devices, asks "is the new WD version compatible", or changes anything in "WD Compatibility/" that touches WD internals (d_promin*, d_bracer*, wd_* scripts, ui_wd_* XML, Promin textures). Optional arg: path to the WD checkout (default ~/code/lua/st-wearable-devices).
---

# WD compatibility check

The **WD Compatibility** component (`WD Compatibility/gamedata/`) couples to st-wearable-devices
in three ways, each of which breaks differently when WD updates:

1. **VFS overrides** — files at the *same path* as a WD file replace it (last-mod-wins). Today:
   **none**. Keep it that way: a stale copy silently reverts WD's later changes, and if WD's
   script starts needing a new XML node, our older XML is a **fatal crash**
   (`XML node <x> not found`). Edit WD's XML through DXML instead, as below.
   **DXML edit** — `modxml_ii_wd_customize` adds the customize-screen cells for our extra bays
   to WD's `ui_wd_customize.xml` as it loads, copying WD's last `module_open_<n>`,
   `module_restricted_<n>` and `cont_modules` `cell_<n>`. If WD renames those nodes or changes
   how `wd_customize.script` names a bay's cell, the copy finds nothing and WD's screen hits the
   fatal again.
2. **Script API** — calls into WD globals (`d_promin.*`, `d_promin_config.MODULES/BAYS/TIERS`,
   `d_promin_chrome_ui.build/new_kit/get_emblem_id`, `wd_panel`'s kit, `d_bracer.is_worn`,
   `wd_slots.register_device`, `wd_worn.new`, ...). Renames/removals → nil-call errors;
   **shape changes** (new required fields in a spec table, changed arg meaning, a kit method
   that takes different units) are not caught by any grep, only by reading the diff.
3. **Hooks into file locals** — `ii_wd_promin` adds the `ident` page to `d_promin_ui`'s
   file-local `THEME_BUILDERS` through the upvalues of `UIPromin.ensure_page`, and wraps
   `UIPromin.Update`/`repaint` for the identification cards. If WD renames that table or those
   methods, the page and cards switch off with one log line (no crash) — check that the log has
   no `Immersive Identification: no page table` line and the page still shows.
4. **Data assumptions** — e.g. `ii_wd_modules` puts the antenna in WD's `conn` bay (empty in
   WD 0.9) and appends `ii_osd`/`ii_proc` bays, whose customize cells sit in one row under WD's
   module column; the ident page reuses WD's comms page background and assumes WD's 1100x600
   layout.

The synced WD version is recorded as `WD-SYNCED: <ver>` in the FOMOD description and advertised
in the plugin name (`fomod/ModuleConfig.xml`).

## Procedure

1. Run the mechanical check (pass the WD path if not the default):
   ```
   .agents/skills/wd-compat-check/check.sh [~/code/lua/st-wearable-devices]
   ```
   It resolves the baseline commit from `WD-SYNCED`, lists WD commits since then, flags any
   override (there should be none), checks that WD's customize XML still has the nodes the DXML
   cells copy, verifies every WD symbol our scripts reference (incl.
   `local X = rawget(_G, "d_...")` aliases) still exists, lists WD scripts we call into that
   changed, and runs `check-xml` + `luac -p`. Exit code = number of problem classes.
2. **Read the WD diffs it lists** (`git -C <wd> diff <baseline> HEAD -- <file>`), focusing on
   the "changed" scripts and overrides. Look for: new XML node names a script now `InitStatic`s,
   changed `register_device`/`wd_worn.new` spec fields, changed `MODULES`/`BAYS` entry shapes,
   renamed page ids in `d_promin_ui`, new blacklists/registries our items should join (e.g.
   `mod_backpack_stash_wearables.ltx`).
3. **If WD's customize XML or `wd_customize.script` changed**, check the DXML cells still land:
   the customize screen opens with cells 4 and 5 under WD's module column. Anything new WD's
   files need goes in through DXML too, never a copy of a WD file.
4. Bump the supported version to the WD `VERSION` everywhere it is stated: in
   `fomod/ModuleConfig.xml` both the plugin name `Wearable Devices Compatibility (WD <ver>)` and
   the `WD-SYNCED: <ver>` in its description (check.sh flags any mismatch), and the WD option's
   line in `LLM_GUIDE.md`. Then re-run
   `check.sh` until it exits 0, plus `nix run .#check-format` if any `.script` changed.
5. Report to the user: WD version checked, what broke and why (crash vs. silent revert vs.
   fine), what you re-synced, anything needing in-game verification or new art. Don't commit
   unless asked.
