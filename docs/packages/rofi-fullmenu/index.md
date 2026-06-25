# Rofi - full menu

A fullscreen Rofi application launcher (`drun` mode) with a pre-themed grid
layout. Designed to be the primary app launcher in a Hyprland setup.

Package: `fullmenu`

---

## Overview

```
src/rofi/fullmenu/
├── default.nix
├── bin/
│   └── menu           # launches rofi in drun mode with the bundled config
└── share/
    ├── conf.rasi      # rofi config (keybinds, font, drun settings)
    └── full.rasi      # fullscreen grid theme (8 columns × 4 rows)
```

## `menu` - the launcher

```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$(dirname "$SCRIPT_DIR")"

ROFI_THEME_STR="${ROFI_THEME_STR:-}"

killall -q rofi

rofi -show drun -config "$SRC_DIR/share/conf.rasi"
```

Simple by design: kill any existing rofi (toggle behavior), then launch `drun`
with the bundled config.

| | |
|---|---|
| **Arguments** | none |
| **Runtime deps** | `rofi-wayland`, `killall` |
| **Package** | `fullmenu` |
| **Main program** | `menu` |

---

## Theme

### `conf.rasi`

Standard keybind config (`Ctrl+h/j/k/l` navigation, mouse click select,
`Return` accept) plus drun-specific settings:

```rasi
modi:                       "drun";
show-icons:                 true;
display-drun:               "";
drun-display-format:        "{name}";
```

Quick-select keys are enabled: `l` (1st), `s` (2nd), `e` (3rd), `r` (4th),
`S` (5th).

### `full.rasi` - grid layout

A centered, fullscreen window (1366×768) with a translucent black background
(`black / 10%`). The listview is an **8-column × 4-row grid** with vertical
orientation, 72px icons, and rounded 15px element corners. The input bar is
centered with a 10px rounded border.

!!! tip "Theme injection"
    The first line of `full.rasi` is `{{full-theme-str}}` - a placeholder
    replaced at build time with the `full-theme-str` argument. This is where
    color variables (`@selected`, `@foreground`, etc.) are injected, typically
    from Stylix.

---

## Build overrides

| Argument | Default | Description |
|----------|---------|-------------|
| `full-theme-str` | `""` | Rasi fragment substituted into `full.rasi` (color variables) |

```nix
inputs.utils.packages.${pkgs.system}.fullmenu.override {
  full-theme-str = ''
    * {
      selected: #62AEEF;
      foreground: #ffffff;
      background-alt: #101010;
    }
  '';
}
```

## Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ROFI_THEME_STR` | `""` | Additional inline theme override (currently unused by the script but available) |

---

## Usage

```bash
# Direct
nix run github:semi710/utils#fullmenu

# In config
{ inputs, pkgs, lib, ... }:
let u = inputs.utils.packages.${pkgs.system};
in {
  wayland.windowManager.hyprland.settings.bind = [
    "$mod, space, exec, ${lib.getExe u.fullmenu}"
  ];
}
```

### With Stylix colors

```nix
{ inputs, pkgs, config, ... }:
let
  u = inputs.utils.packages.${pkgs.system};
  fullmenu = u.fullmenu.override {
    full-theme-str = with config.lib.stylix.colors; ''
      * {
        selected: #${base0D};
        foreground: #${base05};
        background-alt: #${base01};
      }
    '';
  };
in
{
  home.packages = [ fullmenu ];
}
```
