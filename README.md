# Homebrew Updater

A small user-level `launchd` job that checks Homebrew weekly on macOS. Requires
Homebrew and a logged-in user session.

## What it does

By default, it runs `brew update` and `brew outdated` every Sunday at 10:00 AM.
It does not install upgrades.

## Install

```sh
./install.sh
```

This installs the updater and LaunchAgent, and creates
`~/.config/homebrew-updater/config`.

## Run and inspect

```sh
"$HOME/.local/bin/homebrew-updater.sh"
tail -n 100 "$HOME/Library/Logs/homebrew-updater.log"
```

Only one run can happen at a time.

## Enable upgrades

> **Warning:** Automatic upgrades install new software without review. They can
> break packages or apps, and `brew cleanup` removes older versions that could
> be used to roll back. Test in check-only mode first and keep backups.

Edit `~/.config/homebrew-updater/config` and set:

```sh
HOMEBREW_AUTO_UPGRADE=1
```

The installer does not overwrite an existing config. For a one-off run:

```sh
HOMEBREW_AUTO_UPGRADE=1 "$HOME/.local/bin/homebrew-updater.sh"
```

Upgrades run non-interactively with `--no-ask`, leave running apps alone
(`--no-quit`), and finish with `brew cleanup`. Regular casks are included;
greedy, latest-version, and auto-updating casks are not. Restart an app after a
cask upgrade if needed.

## Schedule

The default is Sunday at 10:00 AM (`Weekday` 0). To change it, edit
`launchd/com.example.homebrew-updater.plist` and run `./install.sh` again.

## Test

```sh
./tests/run.sh
```

Tests use a temporary home directory, fake `launchctl`, and mock `brew`.

## Uninstall

```sh
./uninstall.sh
```

This removes the agent and script. The log and config are left in place.

## Notes

- A missed run may start after the Mac wakes from sleep.
- Reinstalling keeps your config and removes any older `homebrew-weekly`
  install.

## License

MIT. See [LICENSE](LICENSE).
