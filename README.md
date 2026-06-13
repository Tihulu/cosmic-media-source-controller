# Tihulu Media Source Controller

A Pop!_OS / COSMIC media source controller for choosing exactly which media source your media controls target.

The app stores one active source and routes its own commands to that source. Hardware keyboard media keys also need to be bound to the app commands, otherwise COSMIC will keep sending them to its default MPRIS target.

## One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/Tihulu/tihulu-media-source-controller/main/scripts/install.sh | bash
```

The installer works on Pop!_OS and other apt-based distributions. It installs the required packages, builds the release binary, installs it to `/usr/bin`, and installs the COSMIC applet desktop entry to `/usr/share/applications`.

## Run the full GUI

```bash
tihulu-media-source-controller
```

or:

```bash
tihulu-media-source-controller gui
```

Use the GUI to choose the active source and test Previous / Play-Pause / Next / Stop routing.

## Make hardware media keys use the selected source

The app cannot magically override COSMIC's existing media-key routing just by being installed. Bind the keyboard media keys to these commands in COSMIC keyboard shortcuts:

| Hardware key | Command |
| --- | --- |
| Play / Pause | `tihulu-media-source-controller play-pause` |
| Next Track | `tihulu-media-source-controller next` |
| Previous Track | `tihulu-media-source-controller previous` |
| Stop | `tihulu-media-source-controller stop` |

Recommended extra shortcut:

| Action | Command |
| --- | --- |
| Next Source | `tihulu-media-source-controller cycle` |

After this, the physical Play/Pause key will run this app's router instead of relying on the desktop's default MPRIS target.

## Add it to the COSMIC panel

After installing, open:

```text
Settings → Desktop → Panel → Add applet
```

Search for:

```text
Tihulu Media Source Controller
```

If it does not appear immediately, restart the panel or log out and back in.

## Why this exists

On Linux desktops, media keys sometimes control the wrong player when multiple apps are open. For example, Spotify may be playing, but the keyboard Play/Pause key may affect Firefox, VLC, a paused player, or another MPRIS client.

This project is designed to make that behavior explicit and predictable:

- choose one active source
- route app commands to that source
- switch sources from the GUI or COSMIC panel popup
- bind hardware media keys to the router commands
- use notifications when the active target changes

## Current status

This repository contains a desktop GUI, a COSMIC applet popup, and a `playerctl`-based backend prototype.

The backend uses `playerctl` to target MPRIS players by name. Hardware media keys require keyboard shortcut binding until a deeper MPRIS proxy or compositor-level shortcut integration is implemented.

## Quick CLI usage

List available media sources:

```bash
tihulu-media-source-controller list
```

Select Spotify:

```bash
tihulu-media-source-controller set spotify
```

Control the selected source:

```bash
tihulu-media-source-controller play-pause
tihulu-media-source-controller next
tihulu-media-source-controller previous
tihulu-media-source-controller stop
```

Cycle to the next source:

```bash
tihulu-media-source-controller cycle
```

## Troubleshooting

Check that the applet desktop entry is installed:

```bash
ls /usr/share/applications/com.github.tihulu.TihuluMediaSourceController.desktop
```

Check that it is marked as a COSMIC applet:

```bash
grep -E 'Name|Exec|Categories|X-CosmicApplet|X-CosmicHoverPopup|MimeType' /usr/share/applications/com.github.tihulu.TihuluMediaSourceController.desktop
```

Expected output includes:

```text
Name=Tihulu Media Source Controller
Exec=tihulu-media-source-controller %F
Categories=COSMIC
X-CosmicApplet=true
X-CosmicHoverPopup=Auto
MimeType=
```

## Development

```bash
cargo fmt
cargo clippy --all-targets --all-features -- -D warnings
cargo build --release
```

## License

GPL-3.0-or-later
