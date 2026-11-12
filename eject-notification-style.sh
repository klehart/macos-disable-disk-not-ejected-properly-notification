#!/bin/bash

set -e

BUNDLE="_SYSTEM_CENTER_:com.apple.DiskArbitration.DiskArbitrationAgent"
PB=/usr/libexec/PlistBuddy
NAMES=("None" "Banners" "Alerts")

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PLIST="$TMP/ncprefs.plist"
defaults export com.apple.ncprefs "$PLIST"

INDEX=""
i=0
while ID=$("$PB" -c "Print :apps:$i:bundle-id" "$PLIST" 2>/dev/null) || "$PB" -c "Print :apps:$i" "$PLIST" >/dev/null 2>&1; do
  if [ "$ID" = "$BUNDLE" ]; then
    INDEX=$i
    break
  fi
  i=$((i + 1))
done

if [ -z "$INDEX" ]; then
  echo "Entry not found. The message must have appeared at least once."
  exit 1
fi

FLAGS=$("$PB" -c "Print :apps:$INDEX:flags" "$PLIST")
CURRENT=$(( (FLAGS >> 3) & 7 ))
CUR_LOCK=$(( ((FLAGS >> 12) & 1) == 0 ))

if [ "$CURRENT" -gt 2 ]; then
  echo "Unexpected style value ($CURRENT). This macOS version may store it differently. Nothing changed."
  exit 1
fi

yesno() { [ "$1" = 1 ] && echo "yes" || echo "no"; }

ask_yesno() {
  local answer
  while true; do
    read -r -p "$1 (y/n, Enter = keep \"$(yesno "$2")\"): " answer
    case "$answer" in
      y|Y|yes) echo 1; return ;;
      n|N|no)  echo 0; return ;;
      "")      echo "$2"; return ;;
      *)       echo "Please answer y or n." >&2 ;;
    esac
  done
}

echo "Notification settings for \"Disk Not Ejected Properly\""
echo
echo "  Style:               ${NAMES[$CURRENT]}"
echo "  Show on Lock Screen: $(yesno "$CUR_LOCK")"
echo

CHOICE="$1"
if [ -z "$CHOICE" ]; then
  echo "Style:"
  echo "  1) None     - no notification"
  echo "  2) Banners  - disappears automatically"
  echo "  3) Alerts   - stays until dismissed"
  read -r -p "Choice (1-3, Enter = keep \"${NAMES[$CURRENT]}\"): " CHOICE
fi

case "$CHOICE" in
  1|none)    STYLE=0 ;;
  2|banners) STYLE=1 ;;
  3|alerts)  STYLE=2 ;;
  "")        STYLE=$CURRENT ;;
  *)         echo "Invalid choice: $CHOICE"; exit 1 ;;
esac

echo
LOCK=$(ask_yesno "Show on Lock Screen?" "$CUR_LOCK")
echo

if [ "$STYLE" = "$CURRENT" ] && [ "$LOCK" = "$CUR_LOCK" ]; then
  echo "No changes. Nothing to do."
  exit 0
fi

NEWFLAGS=$(( (FLAGS & ~(7 << 3)) | (STYLE << 3) ))
if [ "$LOCK" != "$CUR_LOCK" ]; then
  NEWFLAGS=$(( (NEWFLAGS & ~(1 << 12)) | ((1 - LOCK) << 12) ))
fi

BACKUP="$HOME/Library/Preferences/com.apple.ncprefs.backup-$(date +%Y-%m-%d-%H%M%S).plist"
cp "$PLIST" "$BACKUP"
echo "Backup: $BACKUP"

"$PB" -c "Set :apps:$INDEX:flags $NEWFLAGS" "$PLIST"
defaults import com.apple.ncprefs "$PLIST"
killall usernoted NotificationCenter 2>/dev/null || true

echo "Done."
echo "  Style:               ${NAMES[$STYLE]}"
echo "  Show on Lock Screen: $(yesno "$LOCK")"
