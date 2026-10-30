#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d)

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

assert_exec() {
    [ -x "$1" ] || fail "expected executable: $1"
}

assert_missing() {
    [ ! -e "$1" ] || fail "expected missing: $1"
}

assert_contains() {
    grep -Fq "$2" "$1" || fail "expected '$2' in $1"
}

home="$tmp/home"
stub_dir="$tmp/bin"
old_label="com.example.homebrew-weekly"
old_script="$home/.local/bin/homebrew-weekly.sh"
old_plist="$home/Library/LaunchAgents/$old_label.plist"

mkdir -p "$home/.local/bin" "$home/Library/LaunchAgents" "$stub_dir"
printf 'old\n' > "$old_script"
printf 'old\n' > "$old_plist"

cat > "$stub_dir/launchctl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$HOME/launchctl.log"
EOF
chmod 755 "$stub_dir/launchctl"

export HOME="$home"
export PATH="$stub_dir:$PATH"

"$repo_dir/install.sh" > "$tmp/install.out"

script="$home/.local/bin/homebrew-updater.sh"
plist="$home/Library/LaunchAgents/com.example.homebrew-updater.plist"
label="com.example.homebrew-updater"
log="$home/Library/Logs/homebrew-updater.log"
config="$home/.config/homebrew-updater/config"

assert_file "$script"
assert_exec "$script"
assert_file "$plist"
assert_file "$config"
assert_contains "$config" "HOMEBREW_AUTO_UPGRADE=0"
assert_contains "$tmp/install.out" "$label"
assert_contains "$tmp/install.out" "$log"
assert_contains "$tmp/install.out" "$config"
[ "$(plutil -extract Label raw "$plist")" = "$label" ] || fail "unexpected plist label"
[ "$(plutil -extract ProgramArguments.2 raw "$plist")" = 'exec "$HOME/.local/bin/homebrew-updater.sh"' ] || fail "unexpected plist program"
assert_contains "$home/launchctl.log" "bootstrap gui/$(id -u) $plist"
assert_missing "$old_script"
assert_missing "$old_plist"
assert_contains "$home/launchctl.log" "bootout gui/$(id -u)/$old_label"
pass "install creates config, migrates old files, and loads the agent"

printf 'HOMEBREW_AUTO_UPGRADE=1\n' > "$config"
"$repo_dir/install.sh" > "$tmp/install-again.out"
assert_contains "$config" "HOMEBREW_AUTO_UPGRADE=1"
[ "$(grep -c "bootstrap gui/$(id -u)" "$home/launchctl.log")" -eq 2 ] || fail "install is not repeatable"
pass "install can run twice and preserves config"

printf 'old\n' > "$old_script"
printf 'old\n' > "$old_plist"
printf 'keep\n' > "$log"
"$repo_dir/uninstall.sh" > "$tmp/uninstall.out"
assert_missing "$script"
assert_missing "$plist"
assert_missing "$old_script"
assert_missing "$old_plist"
assert_file "$log"
assert_file "$config"
assert_contains "$tmp/uninstall.out" "$label"
assert_contains "$tmp/uninstall.out" "$config"
pass "uninstall removes installed and old files while keeping log and config"

"$repo_dir/uninstall.sh" > "$tmp/uninstall-again.out"
pass "uninstall succeeds when nothing is installed"
