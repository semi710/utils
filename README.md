# utils

Personal utility scripts packaged as a [Nix flake](https://flake.parts/) -
Hyprland, Yabai, Aerospace, Rofi, Waybar, and more. Extracted from
[ndots](https://github.com/semi710/ndots) for reuse across machines.

---

<h3>📚 <a href="https://utils.semi.sh">utils.semi.sh</a> - Full Documentation</h3>

<sub>Packages · Usage · Architecture · Integration Examples · Development</sub>

---

## Quick start

```nix
{
  # Name it `putils`, not `utils` - `utils` conflicts with flake-parts
  inputs.putils.url = "github:semi710/utils";

  outputs = { self, nixpkgs, putils, ... }@inputs: {
    # Reference packages:
    # inputs.putils.packages.${pkgs.system}.focus
  };
}
```

```bash
nix run github:semi710/utils#fast
nix run github:semi710/utils#volume -- up
nix run github:semi710/utils#walogram
```

---

## Related

- **[ndots](https://github.com/semi710/ndots)** - NixOS + nix-darwin config using these scripts
- **[nix-wire](https://github.com/semi710/nix-wire)** - Flake auto-wiring library
- **[center-align](https://github.com/niksingh710/center-align)** - Terminal output centering
- **[basic-battery-stat](https://github.com/niksingh710/basic-battery-stat)** - Battery status with KDE Connect
