#!/bin/sh
# Install the user LaunchAgent and maintenance script.

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"
AGENT_DIR="$HOME/Library/LaunchAgents"
CONFIG_DIR="$HOME/.config/homebrew-updater"
CONFIG_FILE="$CONFIG_DIR/config"
SCRIPT_DEST="$BIN_DIR/homebrew-updater.sh"
PLIST_DEST="$AGENT_DIR/com.example.homebrew-updater.plist"
LABEL="com.example.homebrew-updater"
OLD_LABEL="com.example.homebrew-weekly"
OLD_SCRIPT="$BIN_DIR/homebrew-weekly.sh"
OLD_PLIST="$AGENT_DIR/$OLD_LABEL.plist"

mkdir -p "$BIN_DIR" "$AGENT_DIR" "$HOME/Library/Logs" "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    printf 'HOMEBREW_AUTO_UPGRADE=0\n' > "$CONFIG_FILE"
    chmod 644 "$CONFIG_FILE"
fi
cp "$REPO_DIR/scripts/homebrew-updater.sh" "$SCRIPT_DEST"
chmod 755 "$SCRIPT_DEST"
cp "$REPO_DIR/launchd/com.example.homebrew-updater.plist" "$PLIST_DEST"
chmod 644 "$PLIST_DEST"

plutil -lint "$PLIST_DEST"

# Reload cleanly if this agent is already loaded.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_DEST"

launchctl bootout "gui/$(id -u)/$OLD_LABEL" 2>/dev/null || true
rm -f "$OLD_PLIST" "$OLD_SCRIPT"

echo "Installed and loaded $LABEL."
echo "Config: $CONFIG_FILE"
echo "Logs: $HOME/Library/Logs/homebrew-updater.log"
echo "Run now with: \"$SCRIPT_DEST\""
