# Waybar utils

Two Waybar widget scripts: a **color picker** (with history) and a **screen
recorder** (with audio, region or output selection).

Package: `waybar-utils`

---

## Overview

```
src/waybar/
├── default.nix
└── bin/
    ├── colorpicker    # hyprpicker + history + JSON output for waybar
    └── recorder       # wl-screenrec region/output recording with audio
```

---

## `colorpicker`

A screen color picker using `hyprpicker`. Picks a color, copies it to the
clipboard, stores the last 10 picks in `~/.cache/colorpicker/colors`, and can
output waybar-compatible JSON.

### Modes

| Invocation | Behavior |
|------------|----------|
| `colorpicker` (no args) | Pick a color → copy to clipboard → save to history → signal waybar |
| `colorpicker -l` | Print the saved color history |
| `colorpicker -j` | Output waybar JSON (current color as text, history as tooltip) |

### How it works

```bash
killall -q hyprpicker
color=$(hyprpicker)
echo "$color" | wl-copy

prevColors=$(head -n $((limit - 1)) "$loc/colors")
echo "$color" >"$loc/colors"
echo "$prevColors" >>"$loc/colors"
pkill -RTMIN+1 waybar
```

### Waybar JSON output (`-j`)

Produces a JSON object with the current color as `text` and the full history as
a `tooltip` (each color shown with a swatch span):

```json
{
  "text": "<span color='#62AEEF'></span>",
  "tooltip": "<b>   COLORS</b>\n\n<b>#62AEEF</b>  <span color='#62AEEF'></span>  \n..."
}
```

| | |
|---|---|
| **Arguments** | none, `-l` (list), or `-j` (json) |
| **History** | `~/.cache/colorpicker/colors` (last 10) |
| **Waybar signal** | `pkill -RTMIN+1 waybar` (real-time signal 1) |
| **Runtime deps** | `hyprpicker`, `wl-clipboard` (`wl-copy`), `killall`, `jq` |

### Waybar module config

```json
"custom/colorpicker": {
  "format": "{}",
  "exec": "colorpicker -j",
  "on-click": "colorpicker",
  "tooltip": true,
  "signal": 1
}
```

---

## `recorder`

A screen recording toggle using `wl-screenrec` with audio capture. Records to
`~/Videos/Screen/` with a timestamped filename.

### Behavior

- **If recording is active** → stop it, signal waybar, exit.
- **If idle and no args** → select an **output** (monitor) via `slurp -o`.
- **If idle with any arg** → select a **custom region** via `slurp`.
- Records with the default audio sink's monitor as the audio device.

```bash
if pgrep wl-screenrec &>/dev/null; then
  kill -s SIGINT "$(pgrep -x wl-screenrec)" && notify "Screen Recording Stopped" "..."
  pkill -RTMIN+4 waybar
  exit 0
fi

if [ $# -eq 0 ]; then
  dim="$(slurp -o)"       # output selection
else
  dim="$(slurp)"          # region selection
fi

audio_device="$(wpctl inspect @DEFAULT_AUDIO_SINK@ | grep "node.name" | cut -d"\"" -f2).monitor"

wl-screenrec \
  -f "$filename" \
  -g "$dim" \
  --audio --audio-device "$audio_device" \
  &
```

### Notifications

| Event | Notification |
|-------|-------------|
| Started | "Screen Recording Started" - "Recording to `<file>`" |
| Stopped | "Screen Recording Stopped" - "Recording Stopped" |
| Cancelled (no area) | "Screen Recording Cancelled" - "No Area Is Selected" |
| Failed | "Screen Recording Failed" - "Failed to start recording" |

| | |
|---|---|
| **Arguments** | none (output mode) or any arg (region mode) |
| **Output dir** | `~/Videos/Screen/` |
| **Filename** | `$(date +%b-%d-%Y_%H:%M:%S).mp4` |
| **Waybar signal** | `pkill -RTMIN+4 waybar` (real-time signal 4) |
| **Runtime deps** | `wl-screenrec`, `slurp`, `wireplumber` (`wpctl`), `libnotify`, `killall`, `jq` |

### Waybar module config

```json
"custom/recorder": {
  "format": "{icon}",
  "format-icons": ["", ""],
  "exec": "recorder -j 2>/dev/null || true",
  "on-click": "recorder",
  "on-click-right": "recorder region",
  "signal": 4
}
```

!!! note "Audio device"
    The recorder captures the **monitor** of the default audio sink - i.e. what
    you hear is what gets recorded. This is derived dynamically via
    `wpctl inspect @DEFAULT_AUDIO_SINK@`.

---

## Build overrides

None - `waybar-utils` has no override arguments.

## Usage

```bash
# Color picker
nix run github:semi710/utils#waybar-utils -- colorpicker
nix run github:semi710/utils#waybar-utils -- colorpicker -j
nix run github:semi710/utils#waybar-utils -- colorpicker -l

# Recorder
nix run github:semi710/utils#waybar-utils -- recorder
nix run github:semi710/utils#waybar-utils -- recorder region
```

```nix
{ inputs, pkgs, lib, ... }:
let u = inputs.utils.packages.${pkgs.system};
in {
  home.packages = [ u.waybar-utils ];
}
```
