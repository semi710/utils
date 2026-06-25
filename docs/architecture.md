# Architecture

How the `utils` flake is structured, how scripts are packaged, and the
conventions used throughout.

---

## Flake structure

```
utils/
├── flake.nix            # flake-parts definition — all outputs
├── flake.lock           # pinned inputs
├── README.md
├── .envrc               # use flake (direnv)
└── src/
    ├── hypr/            # Hyprland scripts + clients/ package
    │   ├── fast
    │   ├── focus
    │   ├── move
    │   ├── ...
    │   └── clients/
    │       ├── default.nix
    │       ├── bin/      # focus-clients, get-client, list-clients, run-focus, scratchpad-get
    │       └── share/    # conf.rasi, clients.rasi
    ├── yabai/           # macOS Yabai helpers (flat scripts)
    ├── aerospace/       # macOS Aerospace helpers
    │   ├── default.nix
    │   ├── aero.focus.choose
    │   ├── aero.focus.sh
    │   └── aero.grab.choose
    ├── rofi/            # Rofi menus (three sub-packages)
    │   ├── conf.rasi
    │   ├── powermenu/
    │   ├── menus/
    │   └── fullmenu/
    ├── walogram/        # Telegram theme generator
    │   ├── default.nix
    │   ├── bin/walogram
    │   └── share/colors.wal-constants
    ├── waybar/          # Waybar widgets
    │   ├── default.nix
    │   └── bin/         # colorpicker, recorder
    └── *.               # standalone scripts (volume, brightness, icpu, cat, myip, img-annotate)
```

## Flake outputs

The flake uses [`flake-parts`](https://flake.parts/) to define per-system
outputs. All packages are exposed under `packages.<system>.<name>`.

```nix
outputs =
  inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
    imports = [ inputs.git-hooks-nix.flakeModule ];
    perSystem = { inputs', config, pkgs, ... }: { ... };
  };
```

### Outputs provided

| Output | Description |
|--------|-------------|
| `packages.<system>.<name>` | One package per script (see home page for the full list) |
| `devShells.<system>.default` | Development shell with pre-commit hooks |
| `pre-commit.settings` | `nixfmt-rfc-style` auto-formatter |

## Inputs

| Input | Purpose |
|-------|---------|
| [`flake-parts`](https://github.com/hercules-ci/flake-parts) | Flake structure / per-system outputs |
| [`nixpkgs`](https://github.com/NixOS/nixpkgs) | Package set (unstable) |
| [`center-align`](https://github.com/niksingh710/center-align) | Re-exported as a package |
| [`bstat`](https://github.com/niksingh710/basic-battery-stat) | Re-exported as a package |
| [`networkmanager`](https://github.com/firecat53/networkmanager-dmenu) | Used by the `menus` rofi package |
| [`git-hooks-nix`](https://github.com/cachix/git-hooks.nix) | Pre-commit hooks in dev shell |

---

## Two packaging patterns

The flake uses **two** ways to turn a shell script into a Nix package. The
choice depends on whether the script needs bundled data files (rasi themes,
config) or is a standalone script.

### Pattern 1 — `writeShellApplication` (inline scripts)

Used for standalone scripts with no bundled data. The script source is read
with `builtins.readFile` and wrapped with `pkgs.writeShellApplication`, which
automatically:

- Sets the shebang to a pinned bash
- Runs `shellcheck` at build time
- Wraps `runtimeInputs` into `PATH`

```nix
let
  mkShellApplication =
    name: runtimeInputs: text:
    pkgs.writeShellApplication { inherit name text runtimeInputs; };
in
{
  packages.fast = mkShellApplication "fast" [ pkgs.jq ]
    (builtins.readFile ./src/hypr/fast);
}
```

!!! tip "Why `writeShellApplication`?"
    It handles shebang generation, shellcheck, and PATH wrapping in one call.
    The `mkShellApplication` helper is a thin curried wrapper that keeps the
    `packages` attrset readable.

### Pattern 2 — `stdenv.mkDerivation` (bundled packages)

Used when a package needs multiple scripts **and** data files (rasi themes,
ini configs). Each sub-package has its own `default.nix` that:

1. Copies `bin/*` to `$out/bin/` and `share/*` to `$out/share/`
2. Uses `makeWrapper` to inject `runtimeInputs` into `PATH`
3. Uses `substituteInPlace` to inject theme overrides at build time

```nix
pkgs.stdenv.mkDerivation rec {
  pname = "clients";
  version = "1.0";
  src = builtins.path { path = ./.; name = "source"; };
  nativeBuildInputs = [ pkgs.makeWrapper ];
  runtimeInputs = pkgs.lib.makeBinPath [ ... ];
  installPhase = ''
    mkdir -p $out/bin $out/share
    cp bin/* $out/bin/ && chmod +x $out/bin/*
    cp share/* $out/share/
  '';
  postFixup = ''
    wrapProgram $out/bin/run-focus \
      --run "export ROFI_THEME_STR=\"${rofi-theme-str}\"" \
      --prefix PATH : ${runtimeInputs}
  '';
}
```

### Theme injection convention

Most rofi packages accept a `*-theme-str` argument (defaulting to `""`) that
gets injected into the wrapper via `--run "export ROFI_THEME_STR=..."` and/or
`substituteInPlace` into `.rasi` files. This lets the consumer (e.g. ndots
with Stylix colors) override themes without patching the package source.

| Package | Theme argument | Mechanism |
|---------|-----------------|-----------|
| `clients` | `rofi-theme-str` | `ROFI_THEME_STR` env var in wrapper |
| `fullmenu` | `full-theme-str` | `substituteInPlace` into `full.rasi` |
| `menus` | `audio-theme-str`, `network-theme-str`, `bt-theme-str` | env var + `substituteInPlace` |
| `powermenu-rofi` | — | fixed theme, no override |
| `walogram` | `image`, `colors` | `substituteInPlace` into `walogram` script |

---

## Development shell

The dev shell is the pre-commit shell with a custom name:

```nix
devShells.default = config.pre-commit.devShell.overrideAttrs (oa: {
  name = "utils";
});
pre-commit.settings.hooks.nixfmt-rfc-style.enable = true;
```

Enter it with:

```bash
nix develop
```

This gives you `nixfmt-rfc-style` as a pre-commit hook for all `.nix` files.

---

## Adding a new script

!!! example "Minimal addition"
    1. Write the script under `src/<category>/<name>` (no `.sh` extension, like
       the existing ones).
    2. Add a package entry in `flake.nix` using `mkShellApplication`.
    3. If it needs data files, create a `default.nix` in a subdirectory and use
       `pkgs.callPackage ./src/<category>/default.nix { }`.

```nix
# For a standalone script:
packages.my-script = mkShellApplication "my-script" [ pkgs.jq ]
  (builtins.readFile ./src/my-script);
```
