# Rofi - menus

A bundle of Rofi-based utility menus: **audio sink/source switcher**,
**bluetooth**, **network manager**, and **emoji picker**.

Package: `menus`

---

## Overview

```
src/rofi/menus/
├── default.nix
├── bin/
│   ├── audio-sink      # switch output device
│   ├── audio-source    # switch input device
│   ├── bluetooth       # rofi-bluetooth wrapper
│   ├── network          # networkmanager-dmenu wrapper
│   └── rofimoji        # emoji picker wrapper
└── share/
    ├── bt.rasi          # bluetooth menu theme (with placeholder)
    ├── clients.rasi     # shared window/listview theme
    ├── conf.rasi        # shared rofi config
    ├── nm.ini          # networkmanager-dmenu config (with placeholders)
    └── rofimoji.rasi    # emoji picker theme
```

---

## `audio-sink` - switch output device

Lists all PipeWire audio sinks (output devices), excludes loopbacks and
Easy Effects sinks, marks the current default with 🔊, and lets you pick a
new default via Rofi.

```bash
getSinks() {
  pw-dump | jq 'map(select(.info.props."media.class" == "Audio/Sink"
    and (.info.props."node.description" | test("^(?!Loopback|Easy Effects Sink).*"))))
    | map({ id, "node.name": ..., "node.description": ... })'
}

getListedSinks() {
  getSinks | jq -r '.[] | "\(.id) \(.["node.description"])"' | while read -r id name; do
    if [[ "$id" == "$(getDefaultSinkId)" ]]; then
      echo "🔊 $name"
    else
      echo "$id $name"
    fi
  done
}
```

On selection, calls `wpctl set-default <id>` and notifies with the new device
name. If only one device exists, it notifies "Single Audio Device" and exits.

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `rofi-wayland`, `jq`, `libnotify`, `pipewire` (`pw-dump`), `wireplumber` (`wpctl`) |
| **Env vars** | `ROFI_THEME_STR`, `ROFI_CMD` |

---

## `audio-source` - switch input device

Identical to `audio-sink` but for **sources** (input devices - microphones).
Includes `Audio/Source` and `Audio/Source/Virtual` classes, marks the current
default with 🎤.

```bash
getSources() {
  pw-dump | jq 'map(select((.info.props."media.class" == "Audio/Source"
    or .info.props."media.class" == "Audio/Source/Virtual")
    and (.info.props."node.description" | test("^(?!Loopback).*"))))
    | map(...))'
}
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | same as `audio-sink` |

---

## `bluetooth` - bluetooth device picker

A thin wrapper around [`rofi-bluetooth`](https://github.com/nickclyde/rofi-bluetooth):

```bash
killall rofi &>/dev/null
rofi-bluetooth -i -config "$SRC_DIR/share/bt.rasi"
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `rofi-wayland`, `rofi-bluetooth`, `killall`, `bluetoothctl` (via rofi-bluetooth) |

---

## `network` - network manager

A thin wrapper around [`networkmanager-dmenu`](https://github.com/firecat53/networkmanager-dmenu)
(provided via the flake's `networkmanager` input):

```bash
killall rofi &>/dev/null
networkmanager_dmenu
```

The `NM_DMENU_CONFIG` env var is set in the wrapper to point at the bundled
`nm.ini`, which configures the dmenu command, wifi characters (`▂▄▆█`), and
passphrase obscuring.

```ini
[dmenu]
dmenu_command = rofi -dmenu -i -l 10 -config {{config}} -theme-str {{network-theme-str}}
compact = True
wifi_chars = ▂▄▆█
active_chars = 

[dmenu_passphrase]
obscure = True

[editor]
terminal = foot
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `rofi-wayland`, `networkmanager-dmenu` (flake input), `killall`, `NetworkManager` |

---

## `rofimoji` - emoji picker

A wrapper around [`rofimoji`](https://github.com/Nurry1/rofimoji) configured
for Wayland:

```bash
rofimoji \
  --action copy type \
  --files emojis emoticons kaomoji nerd \
  --skin-tone moderate \
  --selector=rofi \
  --clipboarder=wl-copy \
  --typer=wtype \
  --selector-args="-theme $SRC_DIR/share/rofimoji.rasi" \
  --hidden-descriptions
```

### Behavior

- **Action**: copy to clipboard **and** type the selected character
- **Sources**: emojis, emoticons, kaomoji, nerd fonts
- **Skin tone**: moderate
- **Clipboard**: `wl-copy` (Wayland)
- **Typer**: `wtype` (Wayland)

The emoji picker theme (`rofimoji.rasi`) is a 9-column × 7-row grid with
horizontal flow, Noto Color Emoji font at 24px, and a rounded 8px window.

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `rofimoji`, `rofi-wayland`, `wl-clipboard` (`wl-copy`), `wtype`, `killall` |

---

## Build overrides

| Argument | Default | Description |
|----------|---------|-------------|
| `audio-theme-str` | `""` | Rasi fragment for `audio-sink` / `audio-source` (via `ROFI_THEME_STR`) |
| `network-theme-str` | `""` | Rasi fragment for the network menu (substituted into `nm.ini`) |
| `bt-theme-str` | `""` | Rasi fragment for the bluetooth menu (substituted into `bt.rasi`) |

```nix
inputs.utils.packages.${pkgs.system}.menus.override {
  audio-theme-str = ''...'';
  network-theme-str = ''...'';
  bt-theme-str = ''...'';
}
```

!!! info "How theme injection works"
    - `audio-theme-str` → exported as `ROFI_THEME_STR` in the wrapper (`--run`)
    - `network-theme-str` → `substituteInPlace` into `nm.ini` (newlines
      flattened to spaces)
    - `bt-theme-str` → `substituteInPlace` into `bt.rasi`

## Environment variables

| Variable | Set by | Description |
|----------|--------|-------------|
| `ROFI_THEME_STR` | build arg | Inline rasi theme for audio menus |
| `NM_DMENU_CONFIG` | wrapper | Path to bundled `nm.ini` |
| `ROFI_CMD` | per-script | Override the full rofi command (audio scripts) |

---

## Usage

```bash
# Individual menus
nix run github:semi710/utils#menus -- audio-sink
nix run github:semi710/utils#menus -- audio-source
nix run github:semi710/utils#menus -- bluetooth
nix run github:semi710/utils#menus -- network
nix run github:semi710/utils#menus -- rofimoji
```

```nix
{ inputs, pkgs, lib, ... }:
let u = inputs.utils.packages.${pkgs.system};
in {
  home.packages = [ u.menus ];

  wayland.windowManager.hyprland.settings.bind = [
    "$mod, p, exec, ${lib.getExe' u.menus "audio-sink"}"
    "$mod, b, exec, ${lib.getExe' u.menus "bluetooth"}"
    "$mod, n, exec, ${lib.getExe' u.menus "network"}"
    "$mod, e, exec, ${lib.getExe' u.menus "rofimoji"}"
  ];
}
```
