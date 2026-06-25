# Hyprland clients

A Rofi-based window switcher for [Hyprland](https://hyprland.org/). Lists all
open clients, lets you focus one or pull it to your current workspace, and
optionally acts as a scratchpad picker.

Package: `clients`

---

## Overview

The `clients` package bundles five scripts plus two rasi theme files:

```
src/hypr/clients/
├── default.nix
├── bin/
│   ├── focus-clients     # rofi custom mode - emits client list, focuses selection
│   ├── get-client        # rofi dmenu - pull a client to current workspace
│   ├── list-clients      # jq filter - prints "class - pid - title" lines
│   ├── run-focus         # rofi combi launcher (clients + drun)
│   └── scratchpad-get    # rofi dmenu - pick from scratchpad
└── share/
    ├── conf.rasi         # shared rofi config (keybinds, font, layout)
    └── clients.rasi      # window/listview/element theme
```

## `run-focus` - main entry point

Launches a Rofi **combi** menu combining the custom `clients` mode (live window
list) with the standard `drun` mode (application launcher). Selecting a
window pulls it out of any group, moves it to the current workspace, and
raises it to the top.

```bash
CMD=(rofi -show combi -modes combi -combi-modes
  "clients:${SRC_DIR}/bin/focus-clients,drun"
  -no-show-mode -combi-display-format "\"{text}\"")

ROFI_CMD="${ROFI_CMD:-${CMD[@]} -config \
  $SRC_DIR/share/conf.rasi \
  -theme-str \"$ROFI_THEME_STR\"}"

_current_workspace="$(hyprctl monitors -j | jq '.[] | select(.focused==true)' | jq -j '.activeWorkspace.name')"

killall -q rofi && exit

out=$(eval "$ROFI_CMD")

[ "$out" = "" ] || {
  hyprctl dispatch moveoutofgroup "pid:$out" &>/dev/null
  hyprctl dispatch movetoworkspace "$_current_workspace,pid:$out" &>/dev/null
  hyprctl dispatch alterzorder top,"pid:$out" &>/dev/null
}
```

!!! warning "Kill-all on launch"
    `killall -q rofi && exit` at the top means: if rofi is already running,
    this invocation just kills it and exits (toggle behavior). The script only
    proceeds when no rofi is running.

## `focus-clients` - custom rofi mode

Implements a [rofi custom mode](https://github.com/davatorium/rofi/blob/next/doc/rofi-dmenu.5.markdown)
that emits the client list and handles selection. Receives the selected line
as `$1`, extracts the PID (3rd field), focuses the window, and raises it.

```bash
"${SRC_DIR}/bin/list-clients"
out=$(echo "$1" | awk '{print $3}')

[ "$out" = "" ] || {
  killall -q rofi &>/dev/null
  hyprctl dispatch focuswindow "pid:$out"
  hyprctl dispatch alterzorder top,"pid:$out"
}
```

## `get-client` - pull a window

A standalone dmenu that lists clients and **pulls** the selected one to the
current workspace (also removes it from any group and raises it).

```bash
out=$(
  "$SRC_DIR/bin/list-clients" |
    eval "$ROFI_CMD" |
    awk '{print $3}'
)

[ "$out" = "" ] || {
  hyprctl dispatch moveoutofgroup "pid:$out" &>/dev/null
  hyprctl dispatch movetoworkspace "$_current_workspace,pid:$out" &>/dev/null
  hyprctl dispatch alterzorder top,"pid:$out" &>/dev/null
}
```

## `list-clients` - the jq filter

The core data source. Queries all Hyprland clients, keeps only **mapped**
windows, excludes special workspaces (except `special:comms`), and prints
`class - pid - title`:

```bash
hyprctl clients -j | jq -r '.[]
  | select(.mapped==true)
  | select((.workspace.name | contains("special") | not) or (.workspace.name == "special:comms"))
  | .class + " - " + (.pid|tostring) + " - " + .title'
```

!!! note "Special workspace handling"
    Windows on special workspaces (e.g. `special:scratchpad`) are hidden from
    the list, except `special:comms` which is deliberately included.

## `scratchpad-get` - scratchpad picker

Delegates to an external `scratchpad` binary (expected in PATH), passing the
rofi dmenu config and the `-g` (get) flag:

```bash
scratchpad -m "$ROFI_CMD" "$@" -g
```

---

## Build overrides

| Argument | Default | Description |
|----------|---------|-------------|
| `rofi-theme-str` | `""` | Rasi fragment injected as `ROFI_THEME_STR` env var |
| `uwsm` | `false` | Currently unused - would wrap rofi to launch via `uwsm app --` |

```nix
inputs.utils.packages.${pkgs.system}.clients.override {
  rofi-theme-str = ''
    * {
      background: #1e1e1e;
      selected: #62AEEF;
    }
  '';
}
```

## Runtime dependencies

| Dependency | Used for |
|------------|----------|
| `rofi-wayland` | The menu itself (overridden to optionally use uwsm) |
| `jq` | Parsing `hyprctl` JSON output |
| `killall` | Toggle behavior (kill existing rofi) |
| `hyprctl` | Querying/focusing/moving clients (runtime, not in PATH wrapper) |
| `scratchpad` | Only for `scratchpad-get` (expected in user PATH) |

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ROFI_THEME_STR` | from build arg | Inline rasi theme override |
| `ROFI_CMD` | per-script default | Override the full rofi command |

## Theme files

### `conf.rasi` - shared config

Sets the keybinds (`Ctrl+h/j/k/l` for navigation, `Return` to accept, mouse
click to select), font (`JetBrainsMono Nerd Font 12`), and imports
`clients.rasi` as the theme.

### `clients.rasi` - window theme

A right-anchored panel (450px wide, full height) with a reversed listview
(latest at bottom), 6 visible lines, icon size 32px, and a dark palette:

```rasi
* {
    background:     #000000FF;
    background-alt: #101010FF;
    foreground:     #FFFFFFFF;
    selected:       #62AEEFFF;
    active:         #98C379FF;
    urgent:         #E06B74FF;
}
```

---

## Usage

```bash
# Direct - launch the combi menu
nix run github:semi710/utils#clients

# Or bind individual scripts
nix run github:semi710/utils#clients -- run-focus
```

### Hyprland keybinding

```nix
{ inputs, pkgs, lib, ... }:
let
  u = inputs.utils.packages.${pkgs.system};
in
{
  wayland.windowManager.hyprland.settings.bind = [
    "$mod, tab, exec, ${lib.getExe u.clients}"
  ];
}
```
