# proton-apps-updater

Install and update Proton's Linux apps on [Omarchy](https://omarchy.org/) from **official sources only**: Proton's own release feeds or Arch's official repos. Nothing comes from the AUR.

| App | Source | Installed as |
|---|---|---|
| Proton Mail | Proton's official `.deb` | `proton-mail-official` |
| Proton Pass | Proton's official `.deb` | `proton-pass-official` |
| Proton Authenticator | Proton's official `.deb` | `proton-authenticator-official` |
| Proton Meet | Proton's official `.deb` | `proton-meet-official` |
| Proton Drive (CLI) | Proton's official binary | `proton-drive-cli-official` |
| Proton VPN | Arch `extra` repo | `proton-vpn-gtk-app` |
| Proton VPN (CLI) | Arch `extra` repo | `proton-vpn-cli` |
| Proton Mail Bridge | Arch `extra` repo | `protonmail-bridge` |

Proton publishes `.deb` and `.rpm` builds but no Arch package for most of its apps. `proton-apps-update` downloads the newest **Stable** release from Proton's feed and verifies its SHA512 checksum against the feed. It then repackages it as a normal pacman package, closes the running app, installs the update and reopens whatever was open.

Proton VPN and Bridge are built by Arch in its official repos, so they're installed with `pacman -S` and kept current by your normal system update (`omarchy update`). Proton Drive has no Linux desktop app yet; only Proton's official command-line tool (`proton-drive`) is available.

It adds **Install → Proton Apps** and **Update → Proton Apps** to the Omarchy menu.

## Requirements

- Omarchy (or Arch with Hyprland and `uwsm`, though the menu entries are Omarchy-specific)
- `curl`, `jq`, `base-devel` (for `makepkg`), all present on a stock Omarchy install

## Install

```bash
git clone https://github.com/badenpiland/proton-apps-updater.git
cd proton-apps-updater
./install.sh
```

This copies `proton-apps-update` to `~/.local/bin/` and adds `install.proton` and `update.proton` entries to `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Your existing entries are kept, a timestamped backup is made first, and running it again won't add duplicates.

## Usage

### Installing Proton apps

**Menu → Install → Proton Apps**, or:

```bash
proton-apps-update --install
```

This shows a checklist of every Proton app that isn't installed yet. Select apps with space and confirm with enter.

```
Select Proton apps to install (space to select, enter to confirm)
> [ ] Proton Mail
  [ ] Proton Pass — replaces proton-pass-bin
  [ ] Proton Authenticator
  [ ] Proton Meet
  [ ] Proton Drive (CLI)
  [ ] Proton VPN — from Arch repos
  [ ] Proton Mail Bridge — from Arch repos
```

**Switching from the AUR:** if an app is already installed from the AUR (such as `proton-pass-bin`), it's listed with "replaces …". The official package declares a conflict, so pacman asks to remove the AUR build. Your app data in `~/.config` is untouched.

### Updating

**Menu → Update → Proton Apps**, or:

```bash
proton-apps-update            # check, confirm, install updates
proton-apps-update --check    # only report installed vs. latest
proton-apps-update --yes      # don't ask before installing
```

Example:

```
Proton Mail: 1.14.0 is up to date
Proton Pass: 1.40.2 → 1.43.0
Proton VPN (CLI): 1.0.5 (updated with system updates)
Install 1 update(s)? Yes
Downloading and packaging Proton Pass 1.43.0...
Closing Proton Pass...
Installing...
Restarting proton-pass...
Done.
  Proton Pass 1.43.0
```

Your sudo password is requested *before* any app is closed, so cancelling leaves everything running.

## How it works

| App | Release feed |
|---|---|
| Proton Mail | `https://proton.me/download/mail/linux/version.json` |
| Proton Pass | `https://proton.me/download/PassDesktop/linux/x64/version.json` |
| Proton Authenticator | `https://proton.me/download/authenticator/linux/version.json` |
| Proton Meet | `https://proton.me/download/meet/linux/version.json` |
| Proton Drive (CLI) | `https://proton.me/download/drive/cli/version.json` |

1. Picks the highest-versioned release with `CategoryName == "Stable"` (Early Access, Beta and Alpha builds are ignored).
2. Compares it with the installed version using `vercmp`.
3. Writes a small `PKGBUILD` to `~/.cache/proton-apps-update/<app>/` and runs `makepkg`. The PKGBUILD downloads the file from proton.me, checks it against the feed's SHA512 and unpacks the `.deb` contents (or installs the binary) as-is.
4. Closes desktop apps, including copies minimised to the tray, by matching processes whose executable is the app's main binary.
5. Installs with `sudo pacman -U`, then reopens the apps that were open using `uwsm-app`.

Build logs are kept in `~/.cache/proton-apps-update/<app>/build.log`.

**Security note:** the packages contain exactly the files from Proton's `.deb`s, including Electron's setuid `chrome-sandbox`, just like Proton's own Debian/Fedora packages. Downloads come only from `proton.me` and are checksum-verified before anything is installed. Repo apps come from Arch's signed official repositories.

## Uninstall

```bash
./uninstall.sh
```

This removes the script and both menu entries and offers to delete the download cache. Installed Proton apps stay; remove them with `sudo pacman -R <package>` from the table above.

## Disclaimer

This is an unofficial community tool, not affiliated with or endorsed by Proton AG. Proton and its product names are trademarks of Proton AG.

## License

[MIT](LICENSE)
