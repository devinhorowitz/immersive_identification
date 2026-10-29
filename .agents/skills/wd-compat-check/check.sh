#!/usr/bin/env bash
# Mechanical half of the wd-compat-check skill: diff the "WD Compatibility" FOMOD component
# against a local st-wearable-devices checkout. Exit status is the number of problem classes
# found (0 = nothing flagged); the skill's SKILL.md covers the judgement calls.
set -uo pipefail

II_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
WD_ROOT="${1:-$HOME/code/lua/st-wearable-devices}"
COMPAT="$II_ROOT/WD Compatibility/gamedata"
MARKER_FILE="$COMPAT/configs/ui/ui_wd_customize.xml"
problems=0

say() { printf '\n## %s\n' "$*"; }
flag() { printf '  !! %s\n' "$*"; problems=$((problems + 1)); }

[ -d "$WD_ROOT/.git" ] || { echo "WD checkout not found at $WD_ROOT (pass its path as \$1)"; exit 99; }
wd() { git -C "$WD_ROOT" "$@"; }

say "Versions"
wd_ver="$(cat "$WD_ROOT/VERSION" 2>/dev/null)"
synced="$(grep -ohm1 'WD-SYNCED: [0-9.]*' "$MARKER_FILE" | awk '{print $2}')"
echo "  WD checkout : $wd_ver ($(wd log -1 --format='%h %ad' --date=short))"
echo "  II synced to: ${synced:-<no WD-SYNCED marker>}"

# Resolve the baseline commit: the newest commit whose VERSION file equals the synced version.
base=""
if [ -n "$synced" ]; then
	for c in $(wd log --format=%h -- VERSION); do
		if [ "$(wd show "$c:VERSION" 2>/dev/null | tr -d '[:space:]')" = "$synced" ]; then base="$c"; break; fi
	done
fi
[ -n "$base" ] || { flag "cannot resolve baseline commit for '${synced}'; falling back to HEAD~1"; base="$(wd rev-parse --short HEAD~1)"; }
echo "  baseline    : $base"
for f in "$COMPAT/configs/ui/ui_wd_customize.xml" "$II_ROOT/fomod/ModuleConfig.xml"; do
	grep -q "WD-SYNCED: $synced" "$f" || flag "${f#"$II_ROOT"/} does not say WD-SYNCED: $synced"
done
grep -q "Wearable Devices Compatibility (WD $synced)" "$II_ROOT/fomod/ModuleConfig.xml" ||
	flag "fomod/ModuleConfig.xml plugin name is not 'Wearable Devices Compatibility (WD $synced)'"
if [ "$base" != "$(wd rev-parse --short HEAD)" ]; then
	echo "  WD changes since baseline:"
	wd log --format='    %h %s' "$base..HEAD"
fi

say "VFS overrides (compat files that shadow a WD file at the same path)"
while IFS= read -r -d '' f; do
	rel="${f#"$COMPAT"/}"
	[ -f "$WD_ROOT/gamedata/$rel" ] || continue
	if wd diff --quiet "$base" HEAD -- "gamedata/$rel"; then
		echo "  ok   $rel (unchanged upstream since baseline)"
	else
		flag "$rel CHANGED upstream since baseline -- re-sync our override:"
		wd diff --stat "$base" HEAD -- "gamedata/$rel" | sed 's/^/       /'
	fi
	case "$rel" in *.dds | *.ogg | *.ogf) continue ;; esac
	# Upstream lines missing from our copy (ignoring whitespace) = content our override drops.
	missing="$(diff -wB "$WD_ROOT/gamedata/$rel" "$f" | grep -c '^<')"
	[ "$missing" -eq 0 ] || echo "       note: $missing upstream line(s) absent/altered in our copy (review: diff -wB \"$WD_ROOT/gamedata/$rel\" \"$f\")"
done < <(find "$COMPAT" -type f -print0)

say "WD symbols referenced by compat + base-mod scripts"
scripts=("$COMPAT"/scripts/*.script "$II_ROOT"/gamedata/scripts/*.script)
# A class (`class("UIPromin")(CUIScriptWnd)`) counts too: ii_wd_promin hooks d_promin_ui.UIPromin.
defined() { grep -qE "^[[:space:]]*(local[[:space:]]+)?function[[:space:]]+$2\b|^$2[[:space:]]*=|^class[[:space:]]*\(?[[:space:]]*\"$2\"" "$WD_ROOT/gamedata/scripts/$1.script"; }
check_ref() {
	local mod="$1" sym="$2"
	[ -f "$WD_ROOT/gamedata/scripts/$mod.script" ] || return 0
	defined "$mod" "$sym" || flag "$mod.$sym no longer defined in WD"
}
refs="$(grep -ohE '\b(d_|wd_)[a-z0-9_]+\.[A-Za-z_][A-Za-z0-9_]*\b' "${scripts[@]}" | grep -v '\.script$' | sort -u)"
alias_tmp="$(mktemp)"
# Aliased access: `local X = rawget(_G, "wd_mod")` then `X.sym`.
for f in "${scripts[@]}"; do
	while read -r alias mod; do
		grep -ohE "\b$alias\.[A-Za-z_][A-Za-z0-9_]*" "$f" | sed "s/^$alias\./$mod./"
	done < <(grep -oE 'local [A-Za-z_]+ = rawget\(_G, "(d_|wd_)[a-z0-9_]+"\)' "$f" | sed -E 's/local ([A-Za-z_]+) = rawget\(_G, "([a-z0-9_]+)"\)/\1 \2/')
done > "$alias_tmp"
refs="$(printf '%s\n%s\n' "$refs" "$(sort -u "$alias_tmp")" | sort -u)"
rm -f "$alias_tmp"
count=0
while IFS=. read -r mod sym; do
	[ -n "$mod" ] || continue
	[ -f "$WD_ROOT/gamedata/scripts/$mod.script" ] && count=$((count + 1))
	check_ref "$mod" "$sym"
done <<< "$refs"
echo "  checked $count WD symbol reference(s)"

say "WD scripts we call into that changed since baseline (read these diffs)"
mods="$(printf '%s\n' "$refs" | cut -d. -f1 | sort -u)"
any=0
for m in $mods; do
	[ -f "$WD_ROOT/gamedata/scripts/$m.script" ] || continue
	if ! wd diff --quiet "$base" HEAD -- "gamedata/scripts/$m.script"; then
		echo "  changed: $m.script ($(wd diff --shortstat "$base" HEAD -- "gamedata/scripts/$m.script" | sed 's/^ //'))"
		any=1
	fi
done
[ "$any" -eq 1 ] || echo "  none"

say "Static checks"
if (cd "$II_ROOT" && nix run .#check-xml >/dev/null 2>&1); then echo "  ok   check-xml"; else flag "check-xml failed (run: nix run .#check-xml)"; fi
# nix prints fetch progress on stderr too, so keep only luac's own diagnostics.
luac_out="$(nix shell nixpkgs#lua5_1 --command sh -c 'for f; do luac -p "$f"; done' _ "$COMPAT"/scripts/*.script 2>&1 | grep '^luac:')"
if [ -z "$luac_out" ]; then echo "  ok   luac -p (compat scripts)"; else flag "luac errors:"; echo "$luac_out" | sed 's/^/       /'; fi

say "Result"
if [ "$problems" -eq 0 ]; then echo "  no mechanical problems flagged"; else echo "  $problems problem(s) flagged"; fi
exit "$problems"
