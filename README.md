# proton-apps-updater

Keep **Proton Mail** and **Proton Pass** up to date on [Omarchy](https://omarchy.org/) using Proton's official Linux releases. No AUR involved.

Proton publishes `.deb` and `.rpm` builds but no Arch package. `proton-apps-update` checks Proton's release feeds, downloads the newest **Stable** `.deb` and verifies its SHA512 checksum against the feed. It then repackages the `.deb` as a normal pacman package, closes the running app, installs the update and reopens whatever was open.

It also adds **Update → Proton Apps** to the Omarchy menu.

## Requirements

- Omarchy (or Arch with Hyprland and `uwsm`, though the menu entry is Omarchy-specific)
- `curl`, `jq`, `base-devel` (for `makepkg`), all present on a stock Omarchy install
- Proton Mail and/or Proton Pass installed as **`proton-mail-official`** / **`proton-pass-official`**

The script only *updates* apps installed under those package names. It skips anything installed another way, such as the AUR's `proton-pass-bin`, and tells you so.

### Switching from an AUR package

The packages this tool builds declare conflicts with `proton-mail-bin` and `proton-pass-bin`, so pacman will offer to replace them. To switch, build and install the official package once. For example, for Pass:

```bash
mkdir -p ~/.cache/proton-apps-update/proton-pass && cd "$_"
# Copy the PKGBUILD template from the build_package() function in proton-apps-update,
# filling in pkgver, the .deb URL and its Sha512CheckSum from the feed below
makepkg -si
```

After that, `proton-apps-update` keeps it current.

## Install

```bash
git clone https://github.com/badenpiland/proton-apps-updater.git
cd proton-apps-updater
./install.sh
```

This copies `proton-apps-update` to `~/.local/bin/`. It also adds an `update.proton` entry to `~/.config/omarchy/extensions/omarchy-menu.jsonc`. Your existing entries are kept, a timestamped backup is made first, and running it again won't add a duplicate.

## Usage

From the menu: **Update → Proton Apps**

From a terminal:

```bash
proton-apps-update            # check, confirm, install updates
proton-apps-update --check    # only report installed vs. latest
proton-apps-update --yes      # don't ask before installing
```

Example:

```
proton-mail: 1.14.0 is up to date
proton-pass: 1.40.2 → 1.43.0
Install 1 update(s)? Yes
Downloading and packaging proton-pass 1.43.0...
Closing proton-pass...
Installing...
Restarting proton-pass...
Done.
  proton-pass 1.43.0
```

Your sudo password is requested *before* any app is closed, so cancelling leaves everything running.

## How it works

| App | Release feed |
|---|---|
| Proton Mail | `https://proton.me/download/mail/linux/version.json` |
| Proton Pass | `https://proton.me/download/PassDesktop/linux/x64/version.json` |

1. Picks the highest-versioned release with `CategoryName == "Stable"` (Early Access, Beta and Alpha builds are ignored).
2. Compares it with the installed version using `vercmp`.
3. Writes a small `PKGBUILD` to `~/.cache/proton-apps-update/<app>/` and runs `makepkg`. The PKGBUILD downloads the `.deb` from proton.me, checks it against the feed's SHA512 and unpacks it into `/usr/lib/<app>`.
4. Closes the app, including copies minimised to the tray, by matching processes whose executable is under `/usr/lib/<app>/`.
5. Installs with `sudo pacman -U`, then reopens the apps that were open using `uwsm-app`.

Build logs are kept in `~/.cache/proton-apps-update/<app>/build.log`.

**Security note:** the packages are byte-for-byte Proton's `.deb` contents, including Electron's setuid `chrome-sandbox`, just like Proton's own Debian/Fedora packages. Downloads come only from `proton.me` and are checksum-verified before anything is installed.

## Uninstall

```bash
./uninstall.sh
```

This removes the script and the menu entry and offers to delete the download cache. Proton Mail and Proton Pass stay installed.

## Disclaimer

This is an unofficial community tool, not affiliated with or endorsed by Proton AG. Proton, Proton Mail and Proton Pass are trademarks of Proton AG.

## License

[MIT](LICENSE)
