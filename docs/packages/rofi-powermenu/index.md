# Rofi — power menu

A themed Rofi power menu: **lock**, **suspend**, **logout**, **reboot**,
**shutdown** — with uptime display and quick-select keys.

Package: `powermenu-rofi` (binary: `rofi-powermenu`)

---

## Overview

```
src/rofi/powermenu/
├── default.nix
├── bin/
│   └── menu              # the power menu script
└── share/
    ├── conf.rasi         # rofi config with quick-select keys
    └── powermenu.rasi    # fullscreen centered theme with feather icons
```

## `menu` — the power menu

Lists five actions as Nerd Font icons, shows uptime + hostname as a message,
and dispatches the selected action:

```bash
shutdown='󰐦'
reboot='󰑓'
lock=''
suspend='󰒲'
logout='󰿅'

uptime="$(uptime | sed -e 's/up //g' | cut -f2 -d ' ')"
ifhost=$(hostname)

rofi_cmd() {
  rofi -dmenu \
    -p "Goodbye ${USER}" \
    -mesg "Uptime $ifhost: $uptime" \
    -config "${SRC_DIR}/share/conf.rasi"
}

run_rofi() {
  echo -e "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}
```

### Actions

| Icon | Action | Command |
|------|--------|---------|
| 󰐦 | shutdown | `systemctl poweroff` |
| 󰑓 | reboot | `systemctl reboot` |
|  | lock | `loginctl lock-session` (after 0.5s sleep) |
| 󰒲 | suspend | `systemctl suspend` |
| 󰿅 | logout | `uwsm stop` + `sudo pkill -9 -u $(whoami)` |

### Quick-select keys

The `conf.rasi` binds single keys to each option (no modifier needed):

| Key | Option |
|-----|--------|
| `l` | lock |
| `s` | suspend |
| `e` | logout |
| `r` | reboot |
| `S` (Shift+s) | shutdown |

### Direct logout flag

Passing `-l` skips the menu and logs out immediately:

```bash
[[ $1 == "-l" ]] && logout_fn && exit 0
```

!!! warning "Logout is aggressive"
    The `logout_fn` runs `uwsm stop` then `sudo pkill -9 -u $(whoami)` — this
    kills all your user processes. It requires passwordless `sudo` for
    `pkill` to work non-interactively.

---

## Theme

### `conf.rasi`

Same keybind layout as other rofi packages (`Ctrl+h/j/k/l`, mouse click,
`Return`), plus the five quick-select keys above. Imports `powermenu.rasi`.

### `powermenu.rasi` — centered fullscreen

A fullscreen, transparent overlay (`black / 5%`) centered on screen. The
listview is a single row of 5 circular elements (`border-radius: 100%`) using
the **feather** icon font at 64px, with generous spacing (50px between
elements, 100px margins). The prompt uses `JetBrains Mono Nerd Font Bold
Italic 64`.

```rasi
* {
    mainbox-margin:              100px 300px;
    element-padding:             55px 60px;
    element-border-radius:       100%;
    element-text-font:           "feather 64";
    background-window:           black/5%;
    background-normal:           white/5%;
    background-selected:         white/15%;
}
```

| | |
|---|---|
| **Arguments** | none (or `-l` for direct logout) |
| **Runtime deps** | `rofi-wayland`, `killall`, `systemctl`, `loginctl`, `uwsm` (for logout) |
| **Package** | `powermenu-rofi` |
| **Main program** | `rofi-powermenu` |

---

## Usage

```bash
# Interactive menu
nix run github:semi710/utils#powermenu-rofi

# Direct logout (skip menu)
nix run github:semi710/utils#powermenu-rofi -- -l
```

```nix
{ inputs, pkgs, lib, ... }:
let u = inputs.utils.packages.${pkgs.system};
in {
  home.packages = [ u.powermenu-rofi ];

  wayland.windowManager.hyprland.settings.bind = [
    "$mod SHIFT, q, exec, ${lib.getExe u.powermenu-rofi}"
  ];
}
```

!!! note "No theme override"
    Unlike `clients` and `menus`, the power menu has a fixed theme with no
    `*-theme-str` override argument. Colors are baked into the rasi file.
