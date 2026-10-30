#!/bin/bash
# Remove proton-apps-update and its Omarchy menu entry. Installed Proton apps are left alone.

set -euo pipefail

MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/proton-apps-update"

rm -f "$HOME/.local/bin/proton-apps-update"
echo "Removed $HOME/.local/bin/proton-apps-update"

if [[ -f $MENU ]] && grep -q '"update.proton"' "$MENU"; then
  backup="$MENU.bak.$(date +%s)"
  cp "$MENU" "$backup"

  # Drop the update.proton block, then any trailing comma left before the closing brace
  awk '
    /^[[:space:]]*"update\.proton"[[:space:]]*:/ {
      # Single-line entry ends on this line; multi-line ends at its own closing brace
      if ($0 !~ /}[[:space:]]*,?[[:space:]]*$/) skip = 1
      next
    }
    skip { if ($0 ~ /^[[:space:]]*},?[[:space:]]*$/) skip = 0; next }
    { lines[++n] = $0 }
    END {
      close_line = 0
      for (i = n; i > 0; i--) if (lines[i] ~ /^[[:space:]]*}[[:space:]]*$/) { close_line = i; break }
      for (i = close_line - 1; i > 0; i--) if (lines[i] !~ /^[[:space:]]*(\/\/.*)?$/) { sub(/,[[:space:]]*$/, "", lines[i]); break }
      for (i = 1; i <= n; i++) print lines[i]
    }' "$backup" >"$MENU"

  if sed 's|^[[:space:]]*//.*||' "$MENU" | jq -e . >/dev/null 2>&1; then
    echo "Removed Proton Apps from the Update menu (backup: $backup)"
  else
    cp "$backup" "$MENU"
    echo "Couldn't safely edit $MENU — left it unchanged. Remove the \"update.proton\" entry by hand." >&2
  fi
fi

if [[ -d $CACHE_DIR ]]; then
  read -rp "Delete download cache $CACHE_DIR? [y/N] " reply
  [[ $reply == [yY]* ]] && rm -rf "$CACHE_DIR" && echo "Deleted $CACHE_DIR"
fi

echo "Done. Proton Mail and Proton Pass are still installed; remove them with pacman if you want."
