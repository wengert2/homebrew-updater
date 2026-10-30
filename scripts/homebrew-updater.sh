#!/bin/sh
# Homebrew updater maintenance. Safe to publish; no machine-specific paths.

set -eu

LOG_DIR="$HOME/Library/Logs"
LOG_FILE="$LOG_DIR/homebrew-updater.log"
mkdir -p "$LOG_DIR"

# Send all output to a local log, not to the public repository.
exec >>"$LOG_FILE" 2>&1

echo
echo "===== Homebrew updater: $(date) ====="

# Locate Homebrew on Apple Silicon or Intel, with PATH as a fallback.
if [ -x /opt/homebrew/bin/brew ]; then
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

# Opt in by setting HOMEBREW_AUTO_UPGRADE=1 in this script's environment.
AUTO_UPGRADE="${HOMEBREW_AUTO_UPGRADE:-0}"
if [ "$AUTO_UPGRADE" = "1" ]; then
    echo
    echo "Automatic upgrades enabled."
    "$BREW" upgrade
    "$BREW" cleanup
else
    echo
    echo "Check-only mode; no packages were upgraded."
fi

echo "===== Finished: $(date) ====="
