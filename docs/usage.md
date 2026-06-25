# Usage

How to consume the `utils` flake - as a flake input in your config, or ad-hoc
via `nix run`.

---

## As a flake input

Add the flake to your inputs:

```nix
{
  inputs.putils.url = "github:semi710/utils";
}
```

!!! warning "Name it `putils`, not `utils`"
    If you use `flake-parts`, the input name `utils` will conflict with
    `flake-parts`' internal `utils` library. Always alias it as `putils` (or
    any name other than `utils`).

Then reference individual packages by system:

```nix
{ pkgs, inputs, ... }:
{
  home.packages = [
    inputs.putils.packages.${pkgs.system}.focus
    inputs.putils.packages.${pkgs.system}.volume
    inputs.putils.packages.${pkgs.system}.brightness
  ];
}
```

!!! tip "Using `lib.getExe`"
    When wiring scripts into keybindings, prefer `lib.getExe` to get the
    absolute store path:
    ```nix
    "${lib.getExe inputs.putils.packages.${pkgs.system}.focus} l"
    ```

## Running directly

Every package can be run ad-hoc without adding it to any config:

```bash
# No arguments
nix run github:semi710/utils#fast

# With arguments (after --)
nix run github:semi710/utils#volume -- up
nix run github:semi710/utils#volume -- down
nix run github:semi710/utils#volume -- mute
nix run github:semi710/utils#volume -- mic-mute

nix run github:semi710/utils#brightness -- up
nix run github:semi710/utils#brightness -- down

nix run github:semi710/utils#zoom -- in
nix run github:semi710/utils#zoom -- out
nix run github:semi710/utils#zoom -- reset

nix run github:semi710/utils#focus -- l
nix run github:semi710/utils#focus -- r
nix run github:semi710/utils#focus -- u
nix run github:semi710/utils#focus -- d

nix run github:semi710/utils#myip -- -g
nix run github:semi710/utils#myip -- -l

nix run github:semi710/utils#icpu -- freq
nix run github:semi710/utils#icpu -- temp
```

---

## Integration examples

### Hyprland keybindings

```nix
{ inputs, pkgs, ... }:
let
  u = inputs.putils.packages.${pkgs.system};
in
{
  wayland.windowManager.hyprland.settings.bind = [
    ", XF86AudioRaiseVolume, exec, ${pkgs.lib.getExe u.volume} up"
    ", XF86AudioLowerVolume, exec, ${pkgs.lib.getExe u.volume} down"
    ", XF86AudioMute,        exec, ${pkgs.lib.getExe u.volume} mute"
    ", XF86AudioMicMute,     exec, ${pkgs.lib.getExe u.volume} mic-mute"

    ", XF86MonBrightnessUp,   exec, ${pkgs.lib.getExe u.brightness} up"
    ", XF86MonBrightnessDown, exec, ${pkgs.lib.getExe u.brightness} down"

    "$mod, h, exec, ${pkgs.lib.getExe u.focus} l"
    "$mod, j, exec, ${pkgs.lib.getExe u.focus} d"
    "$mod, k, exec, ${pkgs.lib.getExe u.focus} u"
    "$mod, l, exec, ${pkgs.lib.getExe u.focus} r"

    "$mod SHIFT, h, exec, ${pkgs.lib.getExe u.move} l"
    "$mod SHIFT, j, exec, ${pkgs.lib.getExe u.move} d"
    "$mod SHIFT, k, exec, ${pkgs.lib.getExe u.move} u"
    "$mod SHIFT, l, exec, ${pkgs.lib.getExe u.move} r"

    "$mod, f, exec, ${pkgs.lib.getExe u.fullscreen}"
    "$mod, g, exec, ${pkgs.lib.getExe u.toggle-group}"
    "$mod, return, exec, ${pkgs.lib.getExe u.quick-term}"
  ];
}
```

### Yabai / skhd (macOS)

```nix
{ pkgs, lib, inputs, ... }:
let
  u = inputs.putils.packages.${pkgs.system};
in
{
  # modules/darwin/yabai/skhd.nix
  services.skhd.skhdConfig = ''
    ${mod} - h : ${lib.getExe u.yabai-cycle-focus} west
    ${mod} - j : ${lib.getExe u.yabai-cycle-focus} south
    ${mod} - k : ${lib.getExe u.yabai-cycle-focus} north
    ${mod} - l : ${lib.getExe u.yabai-cycle-focus} east

    ${mod} shift - h : ${lib.getExe u.yabai-cycle-move} west
    ${mod} shift - j : ${lib.getExe u.yabai-cycle-move} south
    ${mod} shift - k : ${lib.getExe u.yabai-cycle-move} north
    ${mod} shift - l : ${lib.getExe u.yabai-cycle-move} east
  '';
}
```

### Stylix + Walogram

```nix
{ pkgs, lib, inputs, config, ... }:
let
  walogram = inputs.putils.packages.${pkgs.system}.walogram.override {
    image = config.stylix.image;
    colors = with config.lib.stylix.colors; ''
      color0="#${base00}"
      color1="#${base01}"
      color2="#${base02}"
      color3="#${base03}"
      color4="#${base04}"
      color5="#${base05}"
      color6="#${base06}"
      color7="#${base07}"
      color8="#${base08}"
      color9="#${base09}"
      color10="#${base0A}"
      color11="#${base0B}"
      color12="#${base0C}"
      color13="#${base0D}"
      color14="#${base0E}"
      color15="#${base0F}"
    '';
  };
in
{
  home.packages = [ pkgs.materialgram ];
  home.activation.tg-theme = lib.hm.dag.entryAfter [ "" ]
    ''run ${lib.getExe walogram}'';
}
```

### Rofi theme overrides

Most rofi packages accept a `*-theme-str` argument that lets you inject a
custom rasi theme fragment at build time:

```nix
{ pkgs, inputs, ... }:
let
  u = inputs.putils.packages.${pkgs.system};
in
{
  home.packages = [
    (u.clients.override {
      rofi-theme-str = ''
        * {
          background: #1e1e1e;
          foreground: #ffffff;
          selected: #62AEEF;
        }
      '';
    })
  ];
}
```

The `menus` package accepts three theme arguments:

```nix
u.menus.override {
  audio-theme-str = ''...'';
  network-theme-str = ''...'';
  bt-theme-str = ''...'';
}
```

And `fullmenu` accepts:

```nix
u.fullmenu.override {
  full-theme-str = ''...'';
}
```

---

## Development

```bash
git clone https://github.com/semi710/utils
cd utils
nix develop   # enters shell with pre-commit hooks (nixfmt-rfc-style)
```

Pre-commit runs `nixfmt-rfc-style` on all `.nix` files. With direnv, the
`.envrc` (`use flake`) will automatically enter the dev shell when you `cd`
into the repo.
