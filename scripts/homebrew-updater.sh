#!/bin/sh
# Homebrew updater maintenance. Safe to publish; no machine-specific paths.

set -eu

LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/homebrew-updater.log"
LOCK_FILE="$LOG_DIR/homebrew-updater.lock"
CONFIG_FILE="$HOME/.config/homebrew-updater/config"
mkdir -p "$LOG_DIR"

# Send all output to a local log, not to the public repository.
exec >>"$LOG_FILE" 2>&1

exec 9>>"$LOCK_FILE"
if ! /usr/bin/lockf -s -t 0 9; then
    echo "Another run is already in progress; exiting."
    exit 0
fi

echo
echo "===== Homebrew updater: $(date) ====="

_HOMEBREW_UPDATER_ENV_AUTO_UPGRADE="${HOMEBREW_AUTO_UPGRADE:-}"
if [ -f "$CONFIG_FILE" ]; then
    . "$CONFIG_FILE"
fi
if [ -n "$_HOMEBREW_UPDATER_ENV_AUTO_UPGRADE" ]; then
    HOMEBREW_AUTO_UPGRADE="$_HOMEBREW_UPDATER_ENV_AUTO_UPGRADE"
fi
unset _HOMEBREW_UPDATER_ENV_AUTO_UPGRADE
AUTO_UPGRADE="${HOMEBREW_AUTO_UPGRADE:-0}"

# Locate Homebrew on Apple Silicon or Intel, with PATH as a fallback.
if [ -n "${BREW_BIN:-}" ]; then
    if [ ! -x "$BREW_BIN" ]; then
        echo "ERROR: BREW_BIN is not executable: $BREW_BIN"
        exit 127
    fi
    BREW="$BREW_BIN"
elif [ -x /opt/homebrew/bin/brew ]; then
    BREW="/opt/homebrew/bin/brew"
elif [ -x /usr/local/bin/brew ]; then
    BREW="/usr/local/bin/brew"
elif command -v brew >/dev/null 2>&1; then
    BREW="$(command -v brew)"
else
    echo "ERROR: Homebrew was not found."
    exit 127
fi

echo "Using: $BREW"
"$BREW" update

echo
echo "Outdated packages:"
"$BREW" outdated --verbose || true

if [ "$AUTO_UPGRADE" = "1" ]; then
    echo
    echo "Automatic upgrades enabled."
    "$BREW" upgrade --no-ask --no-quit
    "$BREW" cleanup
else
    echo
    echo "Check-only mode; no packages were upgraded."
fi

echo "===== Finished: $(date) ====="
