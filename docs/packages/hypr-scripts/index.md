# Hyprland scripts

Standalone Hyprland window-manager utilities. Each is a single bash script
wrapped with `writeShellApplication` and its dependencies.

---

## `fast`

Toggle animations and corner rounding for a snappier feel. If animations are
**on**, it disables them (and rounding); if **off**, it reloads Hyprland
(restoring your config defaults).

```bash
state=$(hyprctl getoption animations:enabled -j | jq .int)

if [ "$state" -eq 0 ]; then
  hyprctl reload
else
  hyprctl keyword animations:enabled 0
  hyprctl keyword decoration:rounding 0
fi
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `jq`, `hyprctl` |
| **Package** | `fast` |

```bash
nix run github:semi710/utils#fast
```

---

## `focus`

Directional focus that is aware of floating vs. tiling windows.

```bash
# Special: cycle next/prev (no direction)
focus cyclenext        # cycle forward
focus cyclenext prev   # cycle backward

# Directional (l/r/u/d)
focus l
focus r
focus u
focus d
```

### Behavior

- **Floating window active**: uses `cyclenext` (with `prev` for left/up), then
  raises the newly focused window via `alterzorder top`.
- **Tiling window active**: uses `movefocus <dir>`, then raises with
  `alterzorder top`.

```bash
if [[ "$1" =~ ^(l|r|u|d)$ ]]; then
  floating=$(hyprctl activewindow -j | jq '.floating')
  if [ "$floating" = true ]; then
    arg=none
    [[ "$1" =~ ^(l|u)$ ]] && arg='prev'
    hyprctl dispatch cyclenext "$arg"
    # ... raises if still floating
  else
    hyprctl dispatch movefocus "$1"
    # ... raises
  fi
fi
```

| | |
|---|---|
| **Arguments** | `l` \| `r` \| `u` \| `d` \| `cyclenext` \[ `prev` \] |
| **Runtime deps** | `jq`, `hyprctl` |
| **Package** | `focus` |

---

## `move`

Directional window move. For floating windows, moves by a pixel delta
(controlled by `HYPR_MOVE_VAL`); for tiling windows, uses `movewindow`.

```bash
_curr_win_floating=$(hyprctl activewindow -j | jq -r '.floating')
val=${HYPR_MOVE_VAL:-50}

getVal() {
  case "$1" in
  "r") echo "$val 0" ;;
  "d") echo "0 $val" ;;
  "l") echo "-$val 0" ;;
  "u") echo "0 -$val" ;;
  esac
}

if [[ $_curr_win_floating == "true" ]]; then
  hyprctl dispatch moveactive $(getVal "$1")
else
  hyprctl dispatch movewindow "$1"
fi
```

| | |
|---|---|
| **Arguments** | `l` \| `r` \| `u` \| `d` |
| **Env vars** | `HYPR_MOVE_VAL` (default `50`) — pixel step for floating moves |
| **Runtime deps** | `jq`, `hyprctl` |
| **Package** | `move` |

```bash
HYPR_MOVE_VAL=100 nix run github:semi710/utils#move -- r
```

---

## `fullscreen`

Cycles through Hyprland's three fullscreen modes by incrementing modulo 3:

| Step | Mode | Value |
|------|------|-------|
| 0 | tiled (no fullscreen) | `0` |
| 1 | maximized | `1` |
| 2 | fullscreen | `2` |

```bash
fullscreenmode="$(hyprctl activewindow -j | jq '.fullscreenClient')"
result=$(((fullscreenmode + 1) % 3))
hyprctl dispatch fullscreen "$result"
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `jq`, `hyprctl` |
| **Package** | `fullscreen` |

---

## `zoom`

Cursor zoom control — increment, decrement, or reset the
`cursor:zoom_factor`.

```bash
zoom() {
  local zoom_curr
  zoom_curr=$(current_zoom_size)
  if [ "$1" == "0" ]; then
    hyprctl keyword cursor:zoom_factor "1.0"
  else
    zoom_value="$(echo "$zoom_curr" + "$1" | bc)"
    hyprctl keyword cursor:zoom_factor "$zoom_value"
  fi
}
```

| | |
|---|---|
| **Arguments** | `in` \| `out` \| `reset` |
| **Step** | ±0.1 per call |
| **Runtime deps** | `jq`, `bc`, `hyprctl` |
| **Package** | `zoom` |

```bash
nix run github:semi710/utils#zoom -- in
nix run github:semi710/utils#zoom -- out
nix run github:semi710/utils#zoom -- reset
```

---

## `toggle-group`

Toggle window grouping. If the active window is **not** grouped, it enables
grouping and notifies. If it **is** already grouped, it enters the `Group`
submap (for intra-group navigation).

```bash
isGroup="$(hyprctl activewindow -j | jq '.grouped | length')"

if [ "$isGroup" -eq "0" ]; then
  hyprctl dispatch togglegroup
  notify-send "Group enabled"
else
  hyprctl dispatch submap "Group"
  notify-send "Entered Submap"
fi
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `jq`, `libnotify`, `hyprctl` |
| **Package** | `toggle-group` |

!!! tip "Group submap"
    You need a `Group` submap defined in your Hyprland config for the second
    branch to do anything useful (e.g. `h/j/k/l` to navigate within the group).

---

## `lid-down`

Handle laptop lid close. If an external monitor is connected, it disables the
internal `eDP-1` (clamshell mode). If only the internal display is present,
it locks the session.

```bash
mon_count=$(hyprctl monitors -j | jq '. | length')

if [ "$mon_count" -gt 1 ]; then
  hyprctl keyword monitor "eDP-1, disable"
else
  loginctl lock-session
fi
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `jq`, `hyprctl`, `loginctl` |
| **Package** | `lid-down` |

Typically bound to a lid switch event:

```nix
services.acpid.lidEventCommands = "${lib.getExe u.lid-down}";
```

---

## `quick-term`

A Yakuake-style drop-down terminal. If a `quick-term` window already exists:

- **Focused** → kill it (toggle off)
- **Not focused** → focus it

If it doesn't exist, spawn one using `foot` or `kitty` (selectable via
`$TERMINAL`), attached to a persistent tmux session named `quick-term`.

```bash
TERMINAL="${TERMINAL:-foot}"

if [ "$_pid" != "" ]; then
  curr_focused="$(hyprctl activewindow -j | jq -r '.class')"
  if [ "$curr_focused" = "quick-term" ]; then
    kill -9 "$_pid"
  else
    hyprctl dispatch focuswindow pid:"$_pid"
  fi
else
  case "$TERMINAL" in
    "foot")
      foot -a "quick-term" sh -c "tmux new-session -A -s 'quick-term'" & ;;
    "kitty")
      kitty --class "quick-term" sh -c "tmux new-session -A -s 'quick-term'" & ;;
    *)
      echo "Unknown terminal: $TERMINAL"; exit 1 ;;
  esac
fi
```

| | |
|---|---|
| **Arguments** | none |
| **Env vars** | `TERMINAL` (default `foot`, supports `kitty`) |
| **Runtime deps** | `foot`, `jq`, `tmux`, `hyprctl` |
| **Package** | `quick-term` |

!!! note "Tmux session persistence"
    The terminal attaches to (or creates) a tmux session named `quick-term`
    via `tmux new-session -A`, so the terminal state persists across
    toggles. `TMUX_TMPDIR` is set to `XDG_RUNTIME_DIR` to avoid socket path
    issues.

---

## `monitor`

Auto-assign workspaces to monitors for a two-monitor setup. Workspaces 1–9
go to the primary monitor (id 1), workspace 10 goes to the secondary (id 0).
Then focuses workspace 1 on the primary.

```bash
mon_count=$(hyprctl monitors -j | jq ". | length")
[ "$mon_count" -eq 1 ] && exit 0

workspaces_on_primary=(1 2 3 4 5 6 7 8 9)
workspaces_on_secondary=(10)

primary=$(hyprctl monitors -j | jq ".[] | select(.id == 1) | .name" | tr -d '"')
secondary=$(hyprctl monitors -j | jq ".[] | select(.id == 0) | .name" | tr -d '"')

for i in "${workspaces_on_primary[@]}"; do
  hyprctl dispatch moveworkspacetomonitor "$i" "$primary"
done
for i in "${workspaces_on_secondary[@]}"; do
  hyprctl dispatch moveworkspacetomonitor "$i" "$secondary"
done

hyprctl dispatch workspace 1
hyprctl dispatch focusmonitor "$primary"
```

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `jq`, `hyprctl` |
| **Package** | `monitor` |

!!! warning "Two-monitor only"
    The script has a TODO for multi-monitor support — currently hard-coded to
    exactly 2 monitors (id 0 = secondary, id 1 = primary). With 3+ monitors
    only two will be configured.

---

## Usage summary

```nix
{ inputs, pkgs, lib, ... }:
let
  u = inputs.utils.packages.${pkgs.system};
in
{
  home.packages = [
    u.fast
    u.focus
    u.move
    u.fullscreen
    u.zoom
    u.toggle-group
    u.lid-down
    u.quick-term
    u.monitor
  ];
}
```
