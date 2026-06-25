# Walogram

Generate a Telegram desktop theme (`.tdesktop-theme`) from Stylix colors,
optionally bundling a blurred wallpaper as the chat background.

Packages: `walogram`, `walogram-test`

---

## Overview

```
src/walogram/
├── default.nix
├── bin/
│   └── walogram               # the generator script
└── share/
    └── colors.wal-constants    # ~400-line Telegram color mapping template
```

Walogram takes 16 base colors (`color0`–`color15`) and a wallpaper image, then
produces a `stylix.tdesktop-theme` file in `~/.cache/stylix-telegram-theme/`.
The theme file maps every Telegram UI color to one of your 16 base colors or
a computed lighter/darker/alpha variant.

## How it works

### 1. Color injection

The `walogram` script ships with default Gruvbox colors (`color0`–`color15`).
At build time, `substituteInPlace` replaces two placeholder lines with the
`image` path and the `colors` override:

```bash
color0="#202020"
color1="#2a2827"
# ...
color15="#bd6f3e"

# {{IMAGE}}      ← replaced with the image path
# {{COLORS}}     ← replaced with color overrides
```

### 2. Variant generation (`gencolors`)

The `gencolors` function computes lighter, darker, and alpha variants for each
of the 16 colors:

- **Lighter** (`colorLighterN_XX`): adds `division/10` of the channel value,
  clamped to 255, for divisions 10–90.
- **Darker** (`colorDarkerN_XX`): subtracts the same fraction.
- **Alpha** (`colorAlphaN_XX`): appends a 2-digit hex alpha (00–ee).

```bash
for i in "${colors[@]}"; do
  for division in "${divisions[@]}"; do
    c_r=$((c_rgb_12d + (c_rgb_12d * (division / 10) / 10)))
    # ... clamped, converted to hex
  done
done
```

This produces ~16 × (9 lighter + 9 darker + 15 alpha) = ~528 named color
variables.

### 3. Theme assembly

The generated color variables are concatenated with `share/colors.wal-constants`
— a ~400-line mapping file that assigns every Telegram theme key to a base
color or variant:

```
windowBg: color0;
windowFg: color7;
activeButtonBg: color2;
msgInBg: colorDarker7_70;
msgOutBg: colorDarker8_60;
```

### 4. Background (optional)

If an `IMAGE` is provided, it's resized to 1920×1080, blurred (`-blur 0x16`),
and zipped together with the color file into `stylix.tdesktop-theme`. Without
an image, only the color file is produced (renamed to the theme name).

```bash
if [ "$IMAGE" != "" ]; then
  magick "$IMAGE" -resize 1920x1080 -blur 0x16 "$tempdir/background.jpg"
  zip -j -FS "$dir/$themeName" "$tempdir"/*
else
  cp -f "$tempdir/colors.tdesktop-theme" "$dir/$themeName"
fi
```

### 5. Output

The theme is written to `$HOME/.cache/stylix-telegram-theme/stylix.tdesktop-theme`.
Import it in Telegram Desktop via **Settings → Chat Background → From File**.

---

## Build overrides

| Argument | Default | Description |
|----------|---------|-------------|
| `image` | `""` | Path to a wallpaper image (resized, blurred, bundled as background) |
| `colors` | `""` | Shell snippet defining `color0`–`color15` (overrides the defaults) |

### `walogram-test`

A pre-configured variant with a hardcoded test image from the nix store:

```nix
walogram-test = (pkgs.callPackage ./src/walogram { }).override {
  image = "/nix/store/1mfdyd874ib7rzn2y7gflhnpfc6gxnja-dock.png";
};
```

---

## Runtime dependencies

| Dependency | Used for |
|------------|----------|
| `imagemagick` (`magick`) | Resize + blur the wallpaper |
| `zip` | Bundle color file + background into `.tdesktop-theme` |

## Output location

```
~/.cache/stylix-telegram-theme/stylix.tdesktop-theme
```

---

## Usage

### Basic (colors only, no background)

```bash
nix run github:semi710/utils#walogram
```

### With Stylix integration

```nix
{ pkgs, lib, inputs, config, ... }:
let
  walogram = inputs.utils.packages.${pkgs.system}.walogram.override {
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
  # Run on home-manager activation (after everything else)
  home.activation.tg-theme = lib.hm.dag.entryAfter [ "" ]
    ''run ${lib.getExe walogram}'';
}
```

!!! tip "Materialgram"
    The README recommends `materialgram` (a Telegram fork) — the generated
    theme works with both standard Telegram Desktop and Materialgram.

!!! note "Brightness variants"
    The `colors.wal-constants` file uses many `colorDarkerN_XX` and
    `colorLighterN_XX` variants (e.g. `colorDarker7_70` for message
    backgrounds, `colorLighter7_40` for active text). These are all computed
    at runtime by `gencolors` — you only need to provide the 16 base colors.
