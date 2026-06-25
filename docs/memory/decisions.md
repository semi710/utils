# Key Decisions

## Extracted from ndots
Scripts originally lived as inline Nix `''` strings in ndots. Moved to standalone repo for easier editing, testing, and reuse across machines.

## Hyprland-focused
Most scripts are Hyprland-specific (waybar, rofi, hypr-clients). macOS utilities (aerospace, yabai) added later when darwin support was needed.

## Flake-based distribution
Distributed as a flake input rather than a traditional package — users add `inputs.utils.url = "github:semi710/utils"` and reference `inputs.utils.packages.${pkgs.system}.<name>`.
