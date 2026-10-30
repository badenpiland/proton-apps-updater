#!/bin/bash
# Install proton-apps-update and add "Update → Proton Apps" to the Omarchy menu.

set -euo pipefail

cd "$(dirname "$0")"

BIN_DIR="$HOME/.local/bin"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

ENTRY='  "update.proton": {
    "icon": "󰒃",
    "label": "Proton Apps",
    "aliases": ["proton"],
    "description": "Update Proton Mail and Proton Pass from official releases",
    "action": "omarchy-launch-floating-terminal-with-presentation proton-apps-update"
  }'

valid_jsonc() {
  sed 's|^[[:space:]]*//.*||' "$1" | jq -e . >/dev/null 2>&1
}

install -Dm755 proton-apps-update "$BIN_DIR/proton-apps-update"
echo "Installed $BIN_DIR/proton-apps-update"

if [[ ! -f $MENU ]]; then
  mkdir -p "$(dirname "$MENU")"
  printf '{\n%s\n}\n' "$ENTRY" >"$MENU"
  echo "Created $MENU with the Proton Apps entry"
elif grep -q '"update.proton"' "$MENU"; then
  echo "Menu entry already present in $MENU"
else
  backup="$MENU.bak.$(date +%s)"
  cp "$MENU" "$backup"

  # Insert before the final closing brace, adding a comma after the previous
  # entry when the object isn't empty.
  awk -v entry="$ENTRY" '
    { lines[NR] = $0 }
    END {
      close_line = 0
      for (i = NR; i > 0; i--) if (lines[i] ~ /^[[:space:]]*}[[:space:]]*$/) { close_line = i; break }
      prev = 0
      for (i = close_line - 1; i > 0; i--) if (lines[i] !~ /^[[:space:]]*(\/\/.*)?$/) { prev = i; break }
      for (i = 1; i < close_line; i++) {
        line = lines[i]
        if (i == prev && line !~ /[{,][[:space:]]*$/) sub(/[[:space:]]*$/, ",", line)
        print line
      }
      print entry
      for (i = close_line; i <= NR; i++) print lines[i]
    }' "$backup" >"$MENU"

  if valid_jsonc "$MENU"; then
    echo "Added Proton Apps to the Update menu (backup: $backup)"
  else
    cp "$backup" "$MENU"
    echo "Couldn't safely edit $MENU — left it unchanged. Add this entry by hand:" >&2
    echo "$ENTRY" >&2
    exit 1
  fi
fi

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: $BIN_DIR is not on your PATH; the menu entry needs it to be." >&2 ;;
esac

echo "Done. Run 'proton-apps-update --check' or use Menu → Update → Proton Apps."
