# utils

Personal utility scripts packaged as a Nix flake. Extracted from [ndots](https://github.com/niksingh710/ndots) for reuse across machines.

> Originally, these lived inline as Nix `''` strings. Moving them to standalone scripts makes them easier to edit, test, and reuse.

## Platforms

- **NixOS / Linux** — Hyprland-focused utilities
- **macOS** — Yabai window manager helpers, Aerospace helpers
- **Universal** — Cross-platform where possible

---

## Usage

### As a flake input

```nix
{
  inputs.utils.url = "github:niksingh710/utils";

  # In your configuration
  home.packages = [ inputs.utils.packages.${pkgs.system}.focus ];
}
```

### Running directly

```sh
nix run github:niksingh710/utils#fast
nix run github:niksingh710/utils#volume -- up
nix run github:niksingh710/utils#walogram
```

---

## Scripts

### Hyprland (Linux)

| Script | Description |
|--------|-------------|
| [`focus`](./src/hypr/focus) | Directional focus (tiled/floating aware) |
| [`move`](./src/hypr/move) | Directional move with `HYPR_MOVE_VAL` tuning |
| [`fullscreen`](./src/hypr/fullscreen) | Cycle: tiled → maximized → fullscreen → tiled |
| [`zoom`](./src/hypr/zoom) | Zoom in/out/reset |
| [`toggle-group`](./src/hypr/toggle-group) | Toggle window grouping |
| [`fast`](./src/hypr/fast) | Disable animations/rounding for snappiness |
| [`lid-down`](./src/hypr/lid-down) | Handle laptop lid close |
| [`quick-term`](./src/hypr/quick-term) | Drop-down terminal (Yakuake-style) |
| [`monitor`](./src/hypr/monitor) | Auto-assign workspaces to monitors |

### Yabai (macOS)

| Script | Description |
|--------|-------------|
| [`yabai-cycle-focus`](./src/yabai/cycle-focus) | Directional window focus with cross-display fallback |
| [`yabai-cycle-move`](./src/yabai/cycle-move) | Swap/warp windows directionally |
| [`yabai-space-cycle`](./src/yabai/space-cycle) | Cycle spaces on current display |
| [`yabai-cycle-display`](./src/yabai/cycle-display) | Focus next/previous display |
| [`yabai-cycle-move-display`](./src/yabai/cycle-move-display) | Move window to next display and focus it |
| [`yabai-focus-window`](./src/yabai/focus-window) | Fuzzy window picker (choose-gui) |
| [`yabai-get-window`](./src/yabai/get-window) | Pull window from any space to current |
| [`yabai-toggle-app`](./src/yabai/toggle-app) | Open → focus → hide cycle |
| [`yabai-warp-cursor`](./src/yabai/warp-cursor) | Center cursor on focused window |

### Aerospace (macOS)

| Script | Description |
|--------|-------------|
| [`aerospace-focus-choose`](./src/aerospace) | Choose-gui window switcher |
| [`aerospace-focus-fzf`](./src/aerospace/aero.focus.sh) | fzf window switcher |

### System Controls

| Script | Description | Platform |
|--------|-------------|----------|
| [`volume`](./src/volume) | Volume up/down/mute/mic-mute | Linux |
| [`brightness`](./src/brightness) | Screen brightness control | Linux |
| [`icpu`](./src/icpu) | CPU info | Linux |

### Rofi Menus (Linux)

| Script | Description |
|--------|-------------|
| [`powermenu-rofi`](./src/rofi/powermenu) | Shutdown/reboot/suspend menu |
| [`menus`](./src/rofi/menus) | Audio sink/source, bluetooth, network, emoji |
| [`clients`](./src/hypr/clients) | Window list — focus or pull |

### Theming & Misc

| Script | Description |
|--------|-------------|
| [`walogram`](./src/walogram) | Generate Telegram theme from Stylix colors |
| [`cat`](./src/cat) | `bat` wrapper with sane defaults |
| [`myip`](./src/myip) | Local/global IP with `-l`/`-g` flags |
| [`img-annotate`](./src/img-annotate) | Clipboard → Swappy annotation |
| [`waybar-utils`](./src/waybar) | Screen recording widget |

---

## Integration Examples

### Hyprland keymaps

```nix
",XF86AudioRaiseVolume,exec,${inputs.utils.packages.${pkgs.system}.volume} up"
",XF86AudioLowerVolume,exec,${inputs.utils.packages.${pkgs.system}.volume} down"
"$mod,h,exec,${inputs.utils.packages.${pkgs.system}.focus} l"
"$mod,j,exec,${inputs.utils.packages.${pkgs.system}.focus} d"
```

### Yabai / skhd

```nix
# modules/darwin/yabai/skhd.nix
${mod} - h : ${lib.getExe pkgs.putils.yabai-cycle-focus} west
${mod} - j : ${lib.getExe pkgs.putils.yabai-cycle-focus} south
```

### Stylix + Walogram

```nix
{ pkgs, lib, inputs, config, ... }:
let
  walogram = inputs.utils.packages.${pkgs.system}.walogram.override {
    image = config.stylix.image;
    colors = with config.lib.stylix.colors; ''
      color0="#${base00}"
      color1="#${base01}"
      ...
    '';
  };
in
{
  home.packages = [ pkgs.materialgram ];
  home.activation.tg-theme = lib.hm.dag.entryAfter [ "" ]
    ''run ${lib.getExe walogram}'';
}
```

### Rofi theming

```nix
inputs.utils.packages.${pkgs.system}.clients.override {
  rofi-theme-str = ''
    * { background: #1e1e1e; }
  '';
}
```

---

## Development

```sh
git clone https://github.com/niksingh710/utils
cd utils
nix develop  # enters shell with pre-commit hooks
```

Pre-commit runs `nixfmt-rfc-style` on all `.nix` files.

---

## Related

- [ndots](https://github.com/niksingh710/ndots) — Main NixOS/macOS configuration using these scripts
- [center-align](https://github.com/niksingh710/center-align) — Terminal output centering
- [basic-battery-stat](https://github.com/niksingh710/basic-battery-stat) — Battery status with KDE Connect support
