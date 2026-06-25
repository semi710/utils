# Packages

Every package exposed by the `utils` flake, grouped by category. Each page
documents the script's purpose, arguments, runtime dependencies, and usage
examples.

---

## How packages are built

The flake uses two patterns — see [Architecture](../architecture.md#two-packaging-patterns)
for details:

1. **`writeShellApplication`** — standalone scripts, read with `builtins.readFile`.
2. **`stdenv.mkDerivation`** — multi-file packages with bundled `share/` data.

## Categories

| Category | Platform | Packages |
|----------|----------|----------|
| [Aerospace helpers](aerospace/index.md) | macOS | `aerospace-focus-choose`, `aerospace-focus-fzf` |
| [Hyprland clients](hypr-clients/index.md) | Linux | `clients` |
| [Hyprland scripts](hypr-scripts/index.md) | Linux | `fast`, `focus`, `move`, `fullscreen`, `zoom`, `toggle-group`, `lid-down`, `quick-term`, `monitor` |
| [Rofi — full menu](rofi-fullmenu/index.md) | Linux | `fullmenu` |
| [Rofi — menus](rofi-menus/index.md) | Linux | `menus` |
| [Rofi — power menu](rofi-powermenu/index.md) | Linux | `powermenu-rofi` |
| [Walogram](walogram/index.md) | Universal | `walogram`, `walogram-test` |
| [Waybar utils](waybar/index.md) | Linux | `waybar-utils` |
| [System controls](system/index.md) | Linux | `volume`, `brightness`, `icpu`, `cat`, `myip`, `img-annotate` |
| [Yabai helpers](yabai/index.md) | macOS | 12 yabai-* packages |
| [External packages](external/index.md) | Universal | `center-align`, `bstat` |
