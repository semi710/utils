# Yabai helpers

macOS [Yabai](https://github.com/koekeishiya/yabai) tiling window manager
helpers — directional focus/move with cross-display fallback, display cycling,
fuzzy window pickers, cursor warping, app toggling, and directional resize.

All scripts use `set -euo pipefail` and parse Yabai's JSON output with `jq`.

---

## Package list

| Package | Script | Description |
|---------|--------|-------------|
| `yabai-space-cycle` | `space-cycle` | Cycle spaces on current display |
| `yabai-next-display-idx` | `next-display-idx` | Compute next/prev display index |
| `yabai-cycle-display` | `cycle-display` | Focus next/previous display |
| `yabai-cycle-move-display` | `cycle-move-display` | Move window to next display + focus |
| `yabai-cycle-focus` | `cycle-focus` | Directional focus (stack-aware, cross-display fallback) |
| `yabai-cycle-move` | `cycle-move` | Directional swap/warp (floating-aware) |
| `yabai-focus-window` | `focus-window` | Fuzzy window picker (choose-gui) |
| `yabai-get-window` | `get-window` | Pull window from any space to current |
| `yabai-toggle-app` | `toggle-app` | Open → focus → hide cycle |
| `yabai-warp-cursor` | `warp-cursor` | Center cursor on focused window (Hammerspoon) |
| `yabai-resize` | `resize` | Grow/shrink window (floating & tiled) |
| `yabai-resize-dir` | `resize-dir` | Directional resize (h/j/k/l, split-aware) |

---

## `yabai-space-cycle`

Cycle through spaces on the **current display**. Wraps around at the ends.

```bash
dir="${1:-next}"
info=$(yabai -m query --spaces --display)
count=$(echo "$info" | jq 'length')

case "$dir" in
  next)
    last=$(echo "$info" | jq '.[-1]."has-focus"')
    if [ "$last" = "false" ]; then
      yabai -m space --focus next
    else
      yabai -m space --focus "$(echo "$info" | jq -r '.[0].index')"
    fi ;;
  prev)
    # ... mirror logic for prev
  ;;
esac
```

| | |
|---|---|
| **Arguments** | `next` (default) \| `prev` |
| **Runtime deps** | `yabai`, `jq` |

---

## `yabai-next-display-idx`

A helper that computes the **index** of the next or previous display (1-based),
with wrap-around. Used by `cycle-display` and `cycle-move-display`.

```bash
dir="${1:-next}"
count=$(yabai -m query --displays | jq 'length')
cur_idx=$(yabai -m query --displays --display | jq -r '.index')

case "$dir" in
  next) echo $(( (cur_idx % count) + 1 )) ;;
  prev) echo $(( ( (cur_idx - 2 + count) % count ) + 1 )) ;;
  *)    echo "$cur_idx" ;;
esac
```

| | |
|---|---|
| **Arguments** | `next` (default) \| `prev` |
| **Output** | display index (integer) |
| **Runtime deps** | `yabai`, `jq` |

!!! note "Pure helper"
    This script only prints an index — it doesn't focus anything. It's used
    as a `runtimeInput` by `cycle-display` and `cycle-move-display`.

---

## `yabai-cycle-display`

Focus the next or previous display. Delegates index computation to
`next-display-idx`.

```bash
dir="${1:-next}"
next_idx=$(next-display-idx "$dir")
[ -n "$next_idx" ] && yabai -m display --focus "$next_idx"
```

| | |
|---|---|
| **Arguments** | `next` (default) \| `prev` |
| **Runtime deps** | `yabai`, `jq`, `next-display-idx` (from this flake) |

---

## `yabai-cycle-move-display`

Move the focused window to the next/previous display **and** focus that
display.

```bash
dir="${1:-next}"
next_idx=$(next-display-idx "$dir")
if [ -n "$next_idx" ]; then
  yabai -m window --display "$next_idx"
  yabai -m display --focus "$next_idx"
fi
```

| | |
|---|---|
| **Arguments** | `next` (default) \| `prev` |
| **Runtime deps** | `yabai`, `jq`, `next-display-idx` |

---

## `yabai-cycle-focus`

The most sophisticated focus script. Directional window focus that is **stack-layout
aware** and falls back to **cross-display** focus when nothing is in the
requested direction on the current space.

### Arguments

| Argument | Maps to |
|----------|---------|
| `next` | `east` |
| `prev` | `west` |
| `east` / `west` / `north` / `south` | literal direction |

### Stack layout

If the current space uses `stack` layout, focus cycles through the stack by
`stack-index` (wrapping):

```bash
if [ "$layout" = "stack" ]; then
  windows=$(yabai -m query --windows --space | jq -r 'sort_by(."stack-index") | [.[] | select(."is-visible" == true)] | .[].id')
  # ... finds current, cycles east/south = +1, west/north = -1
fi
```

### BSP layout (directional with angle constraint)

For tiled (BSP) layouts, it finds the **closest visible window** in the
requested direction using a 45° cone constraint — the squared distance in the
primary axis must exceed the squared distance in the secondary axis, so a
window that's mostly east/west won't be picked when pressing north/south:

```bash
target=$(yabai -m query --windows --space | jq -r \
  --arg dir "$dir" \
  '[.[] | select(.id != $cid and ."is-visible" == true)]
   | map(select(
       ($dir == "west" and .frame.x + .frame.w/2 < $cx and
        (($cx - ...)²) > (($cy - ...)²))) or ...))
   | sort_by(...) | .[0].id // empty')
```

### Cross-display fallback

If no window is found in the direction on the current space, for east/west it
falls back to focusing the next/previous display:

```bash
case "$dir" in
  east|west) yabai -m display --focus "$dir" ;;
esac
```

| | |
|---|---|
| **Runtime deps** | `yabai`, `jq` |

---

## `yabai-cycle-move`

Directional window swap/warp. Floating-aware: floating windows get a 20px
relative move; tiled windows use `--warp`.

```bash
is_floating=$(echo "$cur_json" | jq -r '."is-floating"')

if [ "$is_floating" = "true" ]; then
  case "$dir" in
    west)  yabai -m window --move rel:-20:0 ;;
    east)  yabai -m window --move rel:20:0 ;;
    north) yabai -m window --move rel:0:-20 ;;
    south) yabai -m window --move rel:0:20 ;;
  esac
else
  yabai -m window --warp "$dir" 2>/dev/null || true
fi
```

| | |
|---|---|
| **Arguments** | `west` \| `east` \| `north` \| `south` |
| **Floating step** | 20px |
| **Runtime deps** | `yabai`, `jq` |

---

## `yabai-focus-window`

A fuzzy window picker using [choose-gui](https://github.com/chipsenkbeil/choose).
Lists all windows (excluding `-wrapped` apps), lets you pick one, and focuses
it — or launches the app if no window is found.

```bash
choice=$(yabai -m query --windows \
  | jq -r '.[] | select(.app | endswith("-wrapped") | not) | "\(.id)|\(.app): \(.title)"' \
  | awk -F'|' '{print $2 "\t" $1}' \
  | choose -n 15 -w 120 -f "Monaspace Radon Var" -s 26 -c FF9800 -b a9a9a9 -p "󰖰  Focus window:")

id=$(echo "$choice" | awk '{print $NF}')
app=$(echo "$choice" | awk -F':' '{print $1}' | sed 's/^\[[0-9]*\] //')

if [ -n "$id" ]; then
  yabai -m window --focus "$id"
else
  open -a "$app"
fi
```

| | |
|---|---|
| **Runtime deps** | `yabai`, `jq`, `choose-gui` |
| **Picker** | choose-gui (Monaspace Radon font, orange accent) |

!!! note "`-wrapped` exclusion"
    Nix-installed macOS apps sometimes appear as `AppName-wrapped`. The jq
    filter excludes these to avoid duplicate entries.

---

## `yabai-get-window`

Like `focus-window` but **pulls** the selected window to the current space
instead of just focusing it:

```bash
if [ -n "$id" ]; then
  current_space=$(yabai -m query --spaces --space | jq '.index')
  yabai -m window "$id" --space "$current_space" || open -a "$app"
fi
```

| | |
|---|---|
| **Runtime deps** | `yabai`, `jq`, `choose-gui` |

---

## `yabai-toggle-app`

A smart app launcher/focuser/hider. The **open → focus → hide** cycle:

1. If the app is **frontmost** → hide it.
2. If it's **running** (pgrep / yabai) → focus its most recently focused window.
3. If it's **not running** → launch it.

### Priority chain for focusing a running app

```bash
# 1. yabai window focus (most reliable for Nix apps)
wid=$(echo "$windows_json" | jq -r "[.[] | select(.app == \"$app\")] | sort_by(.last_focused) | reverse | first | .id // empty")
yabai -m window --focus "$wid"

# 2. osascript activate
osascript -e "tell application \"$app\" to activate"

# 3. System Events frontmost
osascript -e "tell application \"System Events\" to set frontmost of first ... whose name is \"$app\" to true"

# 4. open -a (last resort)
open -a "$app"
```

### Arguments

| Argument | Description |
|----------|-------------|
| `--process <name>` | Override the pgrep process name (defaults to app name) |
| `<app>` | The application name (positional, required) |

```bash
toggle-app Slack
toggle-app --process "Telegram" Telegram
```

| | |
|---|---|
| **Runtime deps** | `yabai`, `jq` (optional but used if available), `osascript`, `pgrep`, `open` |

!!! tip "Why so many fallbacks?"
    Nix-managed macOS apps often don't register properly with the standard
    `osascript` activation. The yabai-first approach finds windows by app
    name and sorts by `last_focused` to pick the right one, which is more
    reliable than AppleScript for these cases.

---

## `yabai-warp-cursor`

Center the mouse cursor on the currently focused window using Hammerspoon:

```bash
yabai -m query --windows --window \
  | jq -r '.frame | "hs.mouse.absolutePosition({x=\(.x + .w/2), y=\(.y + .h/2)})"' \
  | xargs -I{} osascript -e 'tell application "Hammerspoon" to execute lua code "{}"'
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `yabai`, `jq`, [Hammerspoon](https://www.hammerspoon.org/) (running) |

!!! note "Hammerspoon required"
    This script executes Lua code via Hammerspoon's AppleScript API. You
    need Hammerspoon installed and running for cursor warping to work.

---

## `yabai-resize`

Grow or shrink the focused window. Floating and tiled windows are handled
differently.

### Floating

Computes a symmetric delta (factor 1.02) and resizes from both corners to
keep the window centered:

```bash
case "$direction" in
  bigger)
    dx=$(echo "($w * $factor - $w) / 2" | bc | cut -d. -f1)
    yabai -m window --resize "bottom_right:${dx}:${dy}"
    yabai -m window --resize "top_left:-${dx}:-${dy}" ;;
  smaller)
    # ... mirror with negative deltas
  ;;
esac
```

### Tiled

Uses edge-based resize with a 20px delta:

```bash
case "$direction" in
  smaller)
    yabai -m window --resize right:-20:0 2>/dev/null || yabai -m window --resize left:20:0 ;;
  bigger)
    yabai -m window --resize right:20:0 2>/dev/null || yabai -m window --resize left:-20:0 ;;
esac
```

| | |
|---|---|
| **Arguments** | `bigger` \| `smaller` |
| **Floating factor** | 1.02 (2% per call) |
| **Tiled delta** | 20px |
| **Runtime deps** | `yabai`, `jq`, `bc` |

---

## `yabai-resize-dir`

Directional resize using vim keys (`h/j/k/l`). For tiled windows, it **probes
with 1px** to detect which edge is the split boundary, then applies the full
delta — inverting direction for right/bottom windows.

### Floating

Symmetric resize (half the delta from each side):

```bash
case "$direction" in
  h) yabai -m window --resize "top_left:${half}:0"; yabai -m window --resize "bottom_right:-${half}:0" ;;
  l) yabai -m window --resize "top_left:-${half}:0"; yabai -m window --resize "bottom_right:${half}:0" ;;
  k) yabai -m window --resize "top_left:0:${half}"; yabai -m window --resize "bottom_right:0:-${half}" ;;
  j) yabai -m window --resize "top_left:0:-${half}"; yabai -m window --resize "bottom_right:0:${half}" ;;
esac
```

### Tiled (split-aware probe)

For each direction, the script:

1. Records the current width/height.
2. Probes with a 1px resize on the right/bottom edge.
3. Checks if the window grew or shrank.
4. If it grew → left/top window, split is on the right/bottom → apply remaining
   delta normally.
5. If it shrank → right/bottom window, split is on the left/top → invert the
   direction.

```bash
# Example: move boundary left (h)
before=$(echo "$window" | jq -r '.frame.w' | cut -d. -f1)
yabai -m window --resize "right:-1:0" 2>/dev/null || true
after=$(yabai -m query --windows --window | jq -r '.frame.w' | cut -d. -f1)
if [ "$after" -lt "$before" ]; then
  # Left window — right edge is boundary, shrink works
  remaining=$((delta - (before - after)))
  [ "$remaining" -gt 0 ] && yabai -m window --resize "right:-${remaining}:0"
else
  # Right window — left edge is boundary, moving left = GROW
  yabai -m window --resize "left:-${delta}:0"
fi
```

| | |
|---|---|
| **Arguments** | `h` \| `j` \| `k` \| `l` |
| **Tiled delta** | 20px |
| **Runtime deps** | `yabai`, `jq`, `bc` |

!!! tip "Why the probe?"
    Yabai doesn't tell you which side of a split a window is on. The 1px probe
    is a clean way to detect it: if shrinking the right edge makes the window
    smaller, you're the left window (right edge is the split). If not, you're
    the right window and need to resize the left edge instead.

---

## Usage

```nix
{ inputs, pkgs, lib, ... }:
let
  u = inputs.utils.packages.${pkgs.system};
in
{
  home.packages = [
    u.yabai-space-cycle
    u.yabai-cycle-display
    u.yabai-cycle-move-display
    u.yabai-cycle-focus
    u.yabai-cycle-move
    u.yabai-focus-window
    u.yabai-get-window
    u.yabai-toggle-app
    u.yabai-warp-cursor
    u.yabai-resize
    u.yabai-resize-dir
  ];
}
```

### skhd keybindings

```bash
# Focus
alt - h : yabai-cycle-focus west
alt - j : yabai-cycle-focus south
alt - k : yabai-cycle-focus north
alt - l : yabai-cycle-focus east

# Move/warp
alt + shift - h : yabai-cycle-move west
alt + shift - j : yabai-cycle-move south
alt + shift - k : yabai-cycle-move north
alt + shift - l : yabai-cycle-move east

# Displays
alt - 1 : yabai-cycle-display next
alt + shift - 1 : yabai-cycle-move-display next

# Spaces
ctrl - l : yabai-space-cycle next
ctrl - h : yabai-space-cycle prev

# Resize
alt - r : yabai-resize-dir h
alt + shift - r : yabai-resize-dir l

# Fuzzy pickers
alt - tab : yabai-focus-window
alt + shift - tab : yabai-get-window
```
