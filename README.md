# Homebrew Updater

A small, user-level `launchd` job for checking Homebrew on a set cadence on macOS.

## Defaults

By default, the job runs `brew update` and `brew outdated` every Sunday at
10:00 AM local time. It **does not install upgrades**.

To enable unattended upgrades, set `HOMEBREW_AUTO_UPGRADE=1` in the installed
script's environment/configuration (see below). Greedy cask upgrades are
intentionally not enabled.

## Requirements

- macOS
- Homebrew installed for the current user
- A login session for the user LaunchAgent to run

## Install

Clone this repository, then run:

```sh
./install.sh
```

The installer copies the maintenance script to `~/.local/bin` and installs
the LaunchAgent in `~/Library/LaunchAgents`.

## Enable automatic upgrades (optional)

Edit `~/.local/bin/homebrew-updater.sh` and change:

```sh
AUTO_UPGRADE="${HOMEBREW_AUTO_UPGRADE:-0}"
```

to:

```sh
AUTO_UPGRADE="${HOMEBREW_AUTO_UPGRADE:-1}"
```

This enables ordinary `brew upgrade`; it does not use `--greedy`.

## Run manually / inspect logs

```sh
"$HOME/.local/bin/homebrew-updater.sh"
tail -n 100 "$HOME/Library/Logs/homebrew-updater.log"
```

## Change the schedule

Edit `launchd/com.example.homebrew-updater.plist` before installing.
The included schedule is Sunday at 10:00 AM. `Weekday` uses `0` for Sunday.

After changing the plist, run `./install.sh` again to reload the job.

## Uninstall

```sh
./uninstall.sh
```

The uninstall script removes the LaunchAgent and installed script. It leaves
the log file in `~/Library/Logs` so you can inspect or delete it yourself.

## Notes

- A LaunchAgent runs in the logged-in user's session; it is not a system daemon.
- If the Mac is asleep at the scheduled time, `launchd` may run the missed
  calendar event after wake, subject to macOS scheduling behavior.
- The script discovers Homebrew in the standard Apple Silicon and Intel paths,
  then falls back to `brew` on `PATH`.
- The script writes logs locally, outside this repository.
- No credentials, API keys, or personal data are needed.
