#!/bin/bash
# Install proton-apps-update and add "Proton Apps" to the Omarchy Install and Update menus.

set -euo pipefail

cd "$(dirname "$0")"

BIN_DIR="$HOME/.local/bin"
MENU="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"

UPDATE_ENTRY='  "update.proton": {
    "icon": "󰒃",
    "label": "Proton Apps",
    "aliases": ["proton"],
    "description": "Update Proton apps from official releases",
    "action": "omarchy-launch-floating-terminal-with-presentation proton-apps-update"
  }'

INSTALL_ENTRY='  "install.proton": {
    "icon": "󰒃",
    "label": "Proton Apps",
    "aliases": ["proton-install"],
    "description": "Install Proton Mail, Pass, VPN, Drive and more from official releases",
    "action": "omarchy-launch-floating-terminal-with-presentation proton-apps-update --install"
  }'

valid_jsonc() {
  sed 's|^[[:space:]]*//.*||' "$1" | jq -e . >/dev/null 2>&1
}

# Adds a menu entry unless its id is already present
add_entry() {
  local id=$1 entry=$2 backup

  if [[ ! -f $MENU ]]; then
    mkdir -p "$(dirname "$MENU")"
    printf '{\n%s\n}\n' "$entry" >"$MENU"
    echo "Created $MENU with $id"
    return
  fi
  if grep -q "\"$id\"" "$MENU"; then
    echo "Menu entry $id already present"
    return
  fi

  backup="$MENU.bak.$(date +%s%N)"
  cp "$MENU" "$backup"

  # Insert before the final closing brace, adding a comma after the previous
  # entry when the object isn't empty.
  awk -v entry="$entry" '
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
    echo "Added $id to the menu (backup: $backup)"
  else
    cp "$backup" "$MENU"
    echo "Couldn't safely edit $MENU — left it unchanged. Add this entry by hand:" >&2
    echo "$entry" >&2
    exit 1
  fi
}

install -Dm755 proton-apps-update "$BIN_DIR/proton-apps-update"
echo "Installed $BIN_DIR/proton-apps-update"

add_entry install.proton "$INSTALL_ENTRY"
add_entry update.proton "$UPDATE_ENTRY"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: $BIN_DIR is not on your PATH; the menu entries need it to be." >&2 ;;
esac

echo "Done. Use Menu → Install → Proton Apps or Menu → Update → Proton Apps,"
echo "or run 'proton-apps-update --install' / 'proton-apps-update'."
