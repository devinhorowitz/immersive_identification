---
name: wd-compat-check
description: Check whether a (newly pulled) st-wearable-devices (WD) version is still compatible with Immersive Identification's "WD Compatibility" FOMOD component, and re-sync it if not. Invoke when the user pulls/updates st-wearable-devices, asks "is the new WD version compatible", or changes anything in "WD Compatibility/" that touches WD internals (d_promin*, d_bracer*, wd_* scripts, ui_wd_* XML, Promin textures). Optional arg: path to the WD checkout (default ~/code/lua/st-wearable-devices).
---

# WD compatibility check

The **WD Compatibility** component (`WD Compatibility/gamedata/`) couples to st-wearable-devices
in three ways, each of which breaks differently when WD updates:

1. **VFS overrides** — files at the *same path* as a WD file replace it (last-mod-wins). Today:
   `configs/ui/ui_wd_customize.xml` only. If WD changes its original, our stale copy silently
   reverts WD's change — and if WD's script starts needing a new XML node, our older XML is a
   **fatal crash** (`XML node <x> not found`). This is the most likely break.
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
   WD 0.9) and appends `ii_osd`/`ii_proc` bays; the customize XML has hard-coded cells 4 and 5;
   the ident page reuses WD's comms page background and assumes WD's 1100x600 layout.

The synced WD version is recorded as `WD-SYNCED: <ver>` in the header of the customize XML
override and is advertised to users in the FOMOD plugin name/description (`fomod/ModuleConfig.xml`).

## Procedure

1. Run the mechanical check (pass the WD path if not the default):
   ```
   .agents/skills/wd-compat-check/check.sh [~/code/lua/st-wearable-devices]
   ```
   It resolves the baseline commit from `WD-SYNCED`, lists WD commits since then, flags every
   override whose upstream changed, verifies every WD symbol our scripts reference (incl.
   `local X = rawget(_G, "d_...")` aliases) still exists, lists WD scripts we call into that
   changed, and runs `check-xml` + `luac -p`. Exit code = number of problem classes.
   - The "N upstream line(s) absent/altered" note is expected for intentional edits (e.g. the
     taller `cont_modules` in the customize XML) — review, don't panic.
2. **Read the WD diffs it lists** (`git -C <wd> diff <baseline> HEAD -- <file>`), focusing on
   the "changed" scripts and overrides. Look for: new XML node names a script now `InitStatic`s,
   changed `register_device`/`wd_worn.new` spec fields, changed `MODULES`/`BAYS` entry shapes,
   renamed page ids in `d_promin_ui`, new blacklists/registries our items should join (e.g.
   `mod_backpack_stash_wearables.ltx`).
3. **Re-sync each changed override** by replaying our additions onto the new upstream file —
   don't hand-merge:
   ```
   git -C <wd> show <baseline>:gamedata/<rel> > old; git -C <wd> show HEAD:gamedata/<rel> > new
   diff -u old "WD Compatibility/gamedata/<rel>" > ours.patch; patch new < ours.patch
   ```
   (use the scratchpad for temp files). Check the result keeps cells 4 and 5 and the header
   comment.
4. Bump the supported version to the WD `VERSION` everywhere it is stated: `WD-SYNCED: <ver>`
   in the override header, and in `fomod/ModuleConfig.xml` both the plugin name
   `Wearable Devices Compatibility (WD <ver>)` and the `WD-SYNCED: <ver>` in its description
   (check.sh flags any mismatch). Then re-run
   `check.sh` until it exits 0, plus `nix run .#check-format` if any `.script` changed.
5. Report to the user: WD version checked, what broke and why (crash vs. silent revert vs.
   fine), what you re-synced, anything needing in-game verification or new art. Don't commit
   unless asked.
