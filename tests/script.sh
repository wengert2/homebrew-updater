#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)
script="$repo_dir/scripts/homebrew-updater.sh"
brew="$tmp/bin/brew"
brew_log="$tmp/brew.log"

cleanup() {
    rm -rf "$tmp"
}
trap cleanup 0

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

pass() {
    printf 'ok - %s\n' "$*"
}

assert_file() {
    [ -f "$1" ] || fail "expected file: $1"
}

assert_contains() {
    grep -Fq "$2" "$1" || fail "expected '$2' in $1"
}

assert_not_contains() {
    if grep -Fq "$2" "$1"; then
        fail "did not expect '$2' in $1"
    fi
}

assert_matches() {
    grep -Eq "$2" "$1" || fail "expected pattern '$2' in $1"
}

assert_not_matches() {
    if grep -Eq "$2" "$1"; then
        fail "did not expect pattern '$2' in $1"
    fi
}

mkdir -p "$tmp/bin"
cat > "$brew" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$BREW_LOG"
if [ -n "${BREW_SLEEP:-}" ]; then
    sleep "$BREW_SLEEP"
fi
case "$1" in
    update) exit "${BREW_UPDATE_EXIT:-0}" ;;
    outdated) exit "${BREW_OUTDATED_EXIT:-0}" ;;
    upgrade|cleanup) exit "${BREW_UPGRADE_EXIT:-0}" ;;
esac
EOF
chmod 755 "$brew"

run() {
    name=$1
    home=$2
    expected=$3
    shift 3
    mkdir -p "$home"
    : > "$brew_log"
    status=0
    env HOME="$home" BREW_BIN="$brew" BREW_LOG="$brew_log" \
        BREW_UPDATE_EXIT=0 BREW_OUTDATED_EXIT=0 BREW_UPGRADE_EXIT=0 BREW_SLEEP= \
        "$@" "$script" || status=$?
    [ "$status" -eq "$expected" ] || fail "$name: expected exit $expected, got $status"
    log="$home/Library/Logs/homebrew-updater.log"
    assert_file "$log"
    pass "$name"
}

run "default mode" "$tmp/home-default" 0 HOMEBREW_AUTO_UPGRADE=0
assert_matches "$brew_log" '^update$'
assert_matches "$brew_log" '^outdated --verbose$'
assert_not_matches "$brew_log" '^upgrade( |$)'
assert_not_matches "$brew_log" '^cleanup$'
assert_contains "$log" "Check-only mode; no packages were upgraded."
pass "default mode checks without upgrading"

run "auto-upgrade mode" "$tmp/home-auto" 0 HOMEBREW_AUTO_UPGRADE=1
assert_matches "$brew_log" '^upgrade --no-ask --no-quit$'
assert_matches "$brew_log" '^cleanup$'
assert_contains "$log" "Automatic upgrades enabled."
pass "auto-upgrade mode upgrades non-interactively and cleans up"

config_home="$tmp/home-config"
mkdir -p "$config_home/.config/homebrew-updater"
printf 'HOMEBREW_AUTO_UPGRADE=1\n' > "$config_home/.config/homebrew-updater/config"
run "auto-upgrade from config" "$config_home" 0 HOMEBREW_AUTO_UPGRADE=
assert_matches "$brew_log" '^upgrade --no-ask --no-quit$'
assert_contains "$log" "Automatic upgrades enabled."
pass "config enables auto-upgrade"

run "outdated failure continues" "$tmp/home-outdated" 0 HOMEBREW_AUTO_UPGRADE=0 BREW_OUTDATED_EXIT=1
assert_contains "$log" "Check-only mode; no packages were upgraded."
pass "outdated failure does not abort the run"

run "update failure aborts" "$tmp/home-update-fail" 1 HOMEBREW_AUTO_UPGRADE=0 BREW_UPDATE_EXIT=1
assert_not_contains "$log" "Outdated packages:"
pass "update failure aborts before checking outdated packages"

home="$tmp/home-invalid"
mkdir -p "$home"
status=0
env HOME="$home" BREW_BIN="$tmp/no-such-brew" HOMEBREW_AUTO_UPGRADE=0 "$script" || status=$?
log="$home/Library/Logs/homebrew-updater.log"
[ "$status" -eq 127 ] || fail "invalid BREW_BIN: expected exit 127, got $status"
assert_contains "$log" "ERROR: BREW_BIN is not executable"
pass "invalid BREW_BIN exits with an error"

lock_home="$tmp/home-lock"
mkdir -p "$lock_home"
: > "$brew_log"
env HOME="$lock_home" BREW_BIN="$brew" BREW_LOG="$brew_log" \
    HOMEBREW_AUTO_UPGRADE=0 BREW_UPDATE_EXIT=0 BREW_OUTDATED_EXIT=0 BREW_UPGRADE_EXIT=0 \
    BREW_SLEEP=2 "$script" &
first_pid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if [ -s "$brew_log" ]; then
        break
    fi
    sleep 0.1
done
[ -s "$brew_log" ] || fail "first run did not start"
status=0
env HOME="$lock_home" BREW_BIN="$brew" BREW_LOG="$brew_log" \
    HOMEBREW_AUTO_UPGRADE=0 BREW_UPDATE_EXIT=0 BREW_OUTDATED_EXIT=0 BREW_UPGRADE_EXIT=0 \
    BREW_SLEEP= "$script" || status=$?
[ "$status" -eq 0 ] || fail "overlapping run: expected exit 0, got $status"
log="$lock_home/Library/Logs/homebrew-updater.log"
assert_contains "$log" "Another run is already in progress; exiting."
wait "$first_pid"
[ "$(grep -c '^update$' "$brew_log")" -eq 1 ] || fail "lock did not prevent a second brew run"
pass "overlapping run is skipped"
