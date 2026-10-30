# proton-apps-updater

Install, update and remove Proton's Linux apps on [Omarchy](https://omarchy.org/) from **official sources only**: Proton's own release feeds or Arch's official repos. Nothing comes from the AUR, and AUR builds you already have are switched to the official ones automatically.

| App | Source | Installed as |
|---|---|---|
| Proton Mail | Proton's official `.deb` | `proton-mail-official` |
| Proton Pass | Proton's official `.deb` | `proton-pass-official` |
| Proton Authenticator | Proton's official `.deb` | `proton-authenticator-official` |
| Proton Meet | Proton's official `.deb` | `proton-meet-official` |
| Proton Drive (CLI) | Proton's official binary | `proton-drive-cli-official` |
| Proton Pass (CLI) | Proton's official binary | `proton-pass-cli-official` |
| Proton VPN | Arch `extra` repo | `proton-vpn-gtk-app` |
| Proton VPN (CLI) | Arch `extra` repo | `proton-vpn-cli` |
| Proton Mail Bridge | Arch `extra` repo | `protonmail-bridge` |

Proton publishes `.deb` and `.rpm` builds but no Arch package for most of its apps. `proton-apps-update` downloads the newest **Stable** release from Proton's feed and verifies its checksum (SHA512, or SHA256 for the Pass CLI) against the feed. It then repackages it as a normal pacman package, closes the running app, installs the update and reopens whatever was open.

Proton VPN and Bridge are built by Arch in its official repos, so they're installed with `pacman -S` (via Omarchy's `omarchy-pkg-add`) and kept current by your normal system update (`omarchy update`). Omarchy's own package repo has no Proton packages at the moment. Proton Drive has no Linux desktop app yet; only Proton's official command-line tool (`proton-drive`) is available.

It adds **Install**, **Update** and **Remove → Proton Apps** to the Omarchy menu.

## Requirements

- Omarchy (or Arch with Hyprland and `uwsm`, though the menu entries are Omarchy-specific)
- `curl`, `jq`, `base-devel` (for `makepkg`), all present on a stock Omarchy install

## Install

```bash
git clone https://github.com/badenpiland/proton-apps-updater.git
cd proton-apps-updater
./install.sh
```

This copies `proton-apps-update` to `~/.local/bin/` and adds `install.proton`, `update.proton` and `remove.proton` entries to `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Your existing entries are kept, a timestamped backup is made first, and running it again won't add duplicates.

## Usage

### Installing Proton apps

**Menu → Install → Proton Apps**, or:

```bash
proton-apps-update --install
```

This shows a checklist of every Proton app that isn't installed yet. Mark apps with tab and confirm with enter.

```
Select Proton apps to install (tab to select, enter to confirm)
> [ ] Proton Mail
  [ ] Proton Pass — replaces proton-pass-bin
  [ ] Proton Authenticator
  [ ] Proton Meet
  [ ] Proton Drive (CLI)
  [ ] Proton Pass (CLI)
  [ ] Proton VPN — from Arch repos
  [ ] Proton Mail Bridge — from Arch repos
```

### Switching from the AUR is automatic

If an app is installed as an AUR build, both `--install` and the normal update switch it to the official build with no extra prompts:

| App | AUR builds that get replaced |
|---|---|
| Proton Mail | `proton-mail`, `proton-mail-bin`, `proton-mail-git` |
| Proton Pass | `proton-pass`, `proton-pass-bin`, `proton-pass-git` |
| Proton Authenticator | `proton-authenticator`, `proton-authenticator-bin`, `proton-authenticator-git` |
| Proton Meet | `proton-meet`, `proton-meet-bin` |
| Proton Drive (CLI) | `proton-drive-cli`, `proton-drive-cli-bin`, `proton-drive-cli-git` |
| Proton Pass (CLI) | `proton-pass-cli`, `proton-pass-cli-bin` |
| Proton Mail Bridge | `protonmail-bridge-bin` (Proton's own PKGBUILD) |

- For Proton's own downloads, the official package declares a conflict with these builds. The install runs as `pacman -U --noconfirm --ask=4`, so the AUR build is removed and the official one installed **in a single transaction**: if anything fails, nothing is removed.
- For Bridge, Arch's package declares no conflict, so `protonmail-bridge-bin` is removed first and then `protonmail-bridge` is installed from the repo.
- App data (`~/.config/...`) is kept in both cases.

Differently patched builds such as `protonmail-bridge-free` or `protonmail-bridge-nokeychain` are left alone on purpose.

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

### Removing Proton apps

**Menu → Remove → Proton Apps**, or:

```bash
proton-apps-update --remove
```

1. Pick apps from a checklist of every installed Proton app (official, repo or AUR builds).
2. A second checklist asks which apps' **data** to delete as well: logins, settings and caches. Nothing is selected by default, so pressing enter keeps all data.
3. After you confirm, running apps are closed and the packages are removed with `omarchy-pkg-drop` (`pacman -Rns`). The data folders you picked are deleted.

| App | Data folders offered for deletion |
|---|---|
| Proton Mail | `~/.config/Proton Mail` |
| Proton Pass | `~/.config/Proton Pass` |
| Proton Authenticator | `~/.local/share/me.proton.authenticator`, `~/.config/…`, `~/.cache/…` |
| Proton Meet | `~/.config/Proton Meet` |
| Proton VPN / VPN CLI | `~/.config/Proton/VPN`, `~/.cache/Proton/VPN`, `~/.local/state/Proton/VPN` |
| Proton Mail Bridge | `~/.config/protonmail/bridge-v3`, `~/.local/share/protonmail/bridge-v3`, `~/.cache/protonmail/bridge-v3` |

Only folders that exist are offered. The Drive and Pass CLIs aren't listed because Proton doesn't document where they store data. Log out with the CLI first (e.g. `pass-cli logout`) if you want its session cleared.

## How it works

| App | Release feed |
|---|---|
| Proton Mail | `https://proton.me/download/mail/linux/version.json` |
| Proton Pass | `https://proton.me/download/PassDesktop/linux/x64/version.json` |
| Proton Authenticator | `https://proton.me/download/authenticator/linux/version.json` |
| Proton Meet | `https://proton.me/download/meet/linux/version.json` |
| Proton Drive (CLI) | `https://proton.me/download/drive/cli/version.json` |
| Proton Pass (CLI) | `https://proton.me/download/pass-cli/versions.json` |

1. Picks the highest-versioned release with `CategoryName == "Stable"` (the Pass CLI feed only lists its current release) (Early Access, Beta and Alpha builds are ignored).
2. Compares it with the installed version using `vercmp`.
3. Writes a small `PKGBUILD` to `~/.cache/proton-apps-update/<app>/` and runs `makepkg`. The PKGBUILD downloads the file from proton.me, checks it against the feed's checksum and unpacks the `.deb` contents (or installs the binary) as-is.
4. Closes desktop apps, including copies minimised to the tray, by matching processes whose executable belongs to the app's package.
5. Installs with `sudo pacman -U` (replacing AUR builds as described above), then reopens the apps that were open using `uwsm-app`.

Build logs are kept in `~/.cache/proton-apps-update/<app>/build.log`.

**Security note:** the packages contain exactly the files from Proton's `.deb`s, including Electron's setuid `chrome-sandbox`, just like Proton's own Debian/Fedora packages. Downloads come only from `proton.me` and are checksum-verified before anything is installed. Repo apps come from Arch's signed official repositories.

## Uninstall

```bash
./uninstall.sh
```

This removes the script and all three menu entries and offers to delete the download cache. Installed Proton apps stay. Run `proton-apps-update --remove` first if you want them gone too.

## Related projects

As of October 2026 I couldn't find another tool that installs, updates and removes the whole Proton suite from official sources. These cover parts of it:

- **AUR packages** such as `proton-pass-bin`, `proton-mail-bin`, `proton-authenticator-bin`, `proton-meet-bin`, `proton-drive-cli-bin` and `proton-pass-cli-bin`. These are community PKGBUILDs, one per app, installed through an AUR helper. This tool replaces them with packages built from Proton's own downloads.
- **Proton's Bridge PKGBUILD** ([proton.me/download/bridge/PKGBUILD](https://proton.me/download/bridge/PKGBUILD)), Proton's own Arch recipe for Bridge only.
- **[686f6c61/omarchy-proton-mail](https://github.com/686f6c61/omarchy-proton-mail)** sets Proton Mail up as an Omarchy web app with an unread-count bar widget. It's a different approach that works alongside this tool.
- **[lajosdeme/protonvpn-omarchy-wg](https://github.com/lajosdeme/protonvpn-omarchy-wg)** is an Omarchy bar widget for Proton VPN over WireGuard.

## Disclaimer

This is an unofficial community tool, not affiliated with or endorsed by Proton AG. Proton and its product names are trademarks of Proton AG.

## License

[MIT](LICENSE)
