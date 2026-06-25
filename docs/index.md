# utils

Personal utility scripts packaged as a [Nix flake](https://flake.parts/),
extracted from [ndots](https://ndots.semi.sh) <a href="https://github.com/semi710/ndots" target="_blank">:fontawesome-brands-github:</a> for reuse across
machines.

> Originally, these lived inline as Nix `''` strings. Moving them to standalone
> scripts makes them easier to edit, test, and reuse.

---

## What it is

`utils` is a flake that exposes a collection of small, focused shell scripts as
proper Nix packages. Each script is wrapped with its dependencies via
`pkgs.writeShellApplication` or `stdenv.mkDerivation`, so they are fully
reproducible and can be run anywhere with `nix run` or added to a system / Home
Manager configuration.

## Platforms

| Platform | Focus |
|----------|-------|
| **NixOS / Linux** | Hyprland-focused window manager utilities, Rofi menus, Waybar widgets, audio/brightness controls |
| **macOS** | Yabai window manager helpers, Aerospace helpers |
| **Universal** | Cross-platform tools (`myip`, `cat`, `icpu`, `img-annotate`) |

## Supported systems

The flake builds for four systems:

- `x86_64-linux`
- `aarch64-linux`
- `aarch64-darwin`
- `x86_64-darwin`

!!! note
    Scripts that call Linux-only tools (Hyprland, WirePlumber, brightnessctl,
    etc.) will only be useful on Linux. macOS-only scripts (Yabai, Aerospace,
    Hammerspoon) only make sense on Darwin. The packages still build on every
    system - they just won't do anything useful at runtime if the underlying
    tool is missing.

---

## Package overview

### Hyprland - Linux

| Package | Script | Description |
|---------|--------|-------------|
| `fast` | [`fast`](https://github.com/semi710/utils/tree/main/src/hypr/fast) | Toggle animations & rounding for snappiness |
| `focus` | [`focus`](https://github.com/semi710/utils/tree/main/src/hypr/focus) | Directional focus (tiled/floating aware) |
| `move` | [`move`](https://github.com/semi710/utils/tree/main/src/hypr/move) | Directional move with `HYPR_MOVE_VAL` tuning |
| `fullscreen` | [`fullscreen`](https://github.com/semi710/utils/tree/main/src/hypr/fullscreen) | Cycle: tiled → maximized → fullscreen → tiled |
| `zoom` | [`zoom`](https://github.com/semi710/utils/tree/main/src/hypr/zoom) | Cursor zoom in/out/reset |
| `toggle-group` | [`toggle-group`](https://github.com/semi710/utils/tree/main/src/hypr/toggle-group) | Toggle window grouping / enter group submap |
| `lid-down` | [`lid-down`](https://github.com/semi710/utils/tree/main/src/hypr/lid-down) | Handle laptop lid close |
| `quick-term` | [`quick-term`](https://github.com/semi710/utils/tree/main/src/hypr/quick-term) | Drop-down terminal (Yakuake-style) |
| `monitor` | [`monitor`](https://github.com/semi710/utils/tree/main/src/hypr/monitor) | Auto-assign workspaces to monitors |
| `clients` | [`clients`](https://github.com/semi710/utils/tree/main/src/hypr/clients) | Rofi window list - focus or pull |

### Yabai - macOS

| Package | Script | Description |
|---------|--------|-------------|
| `yabai-space-cycle` | `space-cycle` | Cycle spaces on current display |
| `yabai-next-display-idx` | `next-display-idx` | Compute next/prev display index (helper) |
| `yabai-cycle-display` | `cycle-display` | Focus next/previous display |
| `yabai-cycle-move-display` | `cycle-move-display` | Move window to next display and focus it |
| `yabai-cycle-focus` | `cycle-focus` | Directional window focus with cross-display fallback |
| `yabai-cycle-move` | `cycle-move` | Swap/warp windows directionally |
| `yabai-focus-window` | `focus-window` | Fuzzy window picker (choose-gui) |
| `yabai-get-window` | `get-window` | Pull window from any space to current |
| `yabai-toggle-app` | `toggle-app` | Open → focus → hide cycle |
| `yabai-warp-cursor` | `warp-cursor` | Center cursor on focused window |
| `yabai-resize` | `resize` | Grow/shrink window (floating & tiled) |
| `yabai-resize-dir` | `resize-dir` | Directional resize (h/j/k/l) |

### Aerospace - macOS

| Package | Script | Description |
|---------|--------|-------------|
| `aerospace-focus-choose` | `aero.focus.choose` | choose-gui window switcher |
| `aerospace-focus-fzf` | `aero.focus.sh` | fzf window switcher |

### Rofi menus - Linux

| Package | Script | Description |
|---------|--------|-------------|
| `powermenu-rofi` | `rofi-powermenu` | Shutdown / reboot / suspend / lock / logout menu |
| `menus` | `audio-sink`, `audio-source`, `bluetooth`, `network`, `rofimoji` | Audio devices, bluetooth, network, emoji picker |
| `fullmenu` | `menu` | Fullscreen application launcher |

### System controls - Linux

| Package | Script | Description |
|---------|--------|-------------|
| `volume` | `volume` | Volume up / down / mute / mic-mute |
| `brightness` | `brightness` | Screen brightness up / down |
| `icpu` | `icpu` | CPU info (freq / temp / usage / turbo / governor) |

### Theming & misc - Universal

| Package | Script | Description |
|---------|--------|-------------|
| `walogram` | `walogram` | Generate Telegram theme from Stylix colors |
| `cat` | `cat` | `bat` wrapper with sane defaults |
| `myip` | `myip` | Local/global IP with `-l` / `-g` flags |
| `img-annotate` | `img-annotate` | Clipboard → Swappy annotation |
| `waybar-utils` | `colorpicker`, `recorder` | Waybar color-picker & screen-recording widgets |

### External flake inputs

| Package | Source |
|---------|--------|
| `center-align` | [`niksingh710/center-align`](https://github.com/niksingh710/center-align) - terminal output centering |
| `bstat` | [`niksingh710/basic-battery-stat`](https://github.com/niksingh710/basic-battery-stat) - battery status with KDE Connect support |

---

## Real-world usage

See [ndots](https://ndots.semi.sh) <a href="https://github.com/semi710/ndots" target="_blank">:fontawesome-brands-github:</a> for a complete NixOS + nix-darwin
configuration that consumes this flake - Hyprland keybindings, Yabai/skhd
configs, Rofi menus, Waybar widgets, and Stylix + Walogram integration.

!!! example
    ndots adds `putils` as a flake input and references packages across
    NixOS modules and Home Manager configs. Browse the
    [modules](https://github.com/semi710/ndots) to see it in action.

### Run directly

```bash
nix run github:semi710/utils#fast
nix run github:semi710/utils#volume -- up
nix run github:semi710/utils#walogram
```

### Add as a flake input

```nix
{
  inputs.putils.url = "github:semi710/utils";

  outputs = { self, nixpkgs, putils, ... }@inputs: {
    # Then reference packages:
    # inputs.putils.packages.${pkgs.system}.focus
  };
}
```

!!! warning "Name it `putils`, not `utils`"
    If you use `flake-parts`, the input name `utils` will conflict with
    `flake-parts`' internal `utils` library. Always alias it as `putils`.

See [Usage](usage.md) for full integration examples, and
[Architecture](architecture.md) for how the flake is structured.
