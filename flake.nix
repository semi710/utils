{
  description = "Utility scripts to be used by my NixOS configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    center-align.url = "github:niksingh710/center-align";
    bstat.url = "github:niksingh710/basic-battery-stat";
    networkmanager.url = "github:firecat53/networkmanager-dmenu";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [
        inputs.git-hooks-nix.flakeModule
      ];
      perSystem =
        {
          inputs',
          config,
          pkgs,
          ...
        }:
        let
          mkShellApplication =
            name: runtimeInputs: text:
            pkgs.writeShellApplication {
              inherit name text runtimeInputs;
            };
        in
        {
          devShells.default = config.pre-commit.devShell.overrideAttrs (oa: {
            name = "utils";
            buildInputs = (oa.buildInputs or [ ]) ++ [ pkgs.just ];
          });

          apps.docs =
            let
              env = pkgs.python3.withPackages (
                ps: with ps; [
                  mkdocs
                  mkdocs-material
                ]
              );
            in
            {
              type = "app";
              program = "${env}/bin/mkdocs";
            };

          pre-commit.settings.hooks.nixfmt-rfc-style.enable = true;
          packages =
            let
              next-display-idx = mkShellApplication "next-display-idx" [ pkgs.jq ] (
                builtins.readFile ./src/yabai/next-display-idx
              );
            in
            {
              center-align = inputs'.center-align.packages.default;
              bstat = inputs'.bstat.packages.default;
              fast = mkShellApplication "fast" [ pkgs.jq ] (builtins.readFile ./src/hypr/fast);

              icpu = mkShellApplication "icpu" [ pkgs.sysstat pkgs.lm_sensors ] (builtins.readFile ./src/icpu);

              img-annotate = mkShellApplication "img-annotate" (with pkgs; [
                libnotify
                wl-clipboard
                swappy
              ]) (builtins.readFile ./src/img-annotate);

              focus = mkShellApplication "focus" (with pkgs; [ jq ]) (builtins.readFile ./src/hypr/focus);

              move = mkShellApplication "move" (with pkgs; [ jq ]) (builtins.readFile ./src/hypr/move);

              fullscreen = mkShellApplication "fullscreen" (with pkgs; [ jq ]) (
                builtins.readFile ./src/hypr/fullscreen
              );

              zoom = mkShellApplication "zoom" (with pkgs; [
                jq
                bc
              ]) (builtins.readFile ./src/hypr/zoom);

              toggle-group = mkShellApplication "toggle-group" (with pkgs; [
                jq
                libnotify
              ]) (builtins.readFile ./src/hypr/toggle-group);

              lid-down = mkShellApplication "lid-down" (with pkgs; [ jq ]) (
                builtins.readFile ./src/hypr/lid-down
              );

              volume = mkShellApplication "volume" (with pkgs; [
                bc
                jq
                gawk
                libnotify
              ]) (builtins.readFile ./src/volume);

              brightness = mkShellApplication "brightness" (with pkgs; [
                libnotify
                brightnessctl
              ]) (builtins.readFile ./src/brightness);

              aerospace-focus-choose = pkgs.callPackage ./src/aerospace/default.nix { };
              aerospace-focus-fzf = mkShellApplication "aerospace-focus-fzf" (with pkgs; [
                fzf
              ]) (builtins.readFile ./src/aerospace/aero.focus.sh);

              quick-term = mkShellApplication "quick-term" (with pkgs; [
                foot
                jq
                tmux
              ]) (builtins.readFile ./src/hypr/quick-term);

              myip = mkShellApplication "myip" (with pkgs; [ dnsutils ]) (builtins.readFile ./src/myip);

              cat = mkShellApplication "cat" (with pkgs; [ bat ]) (builtins.readFile ./src/cat);

              monitor = mkShellApplication "monitor" (with pkgs; [ jq ]) (builtins.readFile ./src/hypr/monitor);

              # yabai (macOS tiling WM helpers)
              yabai-space-cycle = mkShellApplication "space-cycle" (with pkgs; [ jq ]) (
                builtins.readFile ./src/yabai/space-cycle
              );
              yabai-next-display-idx = mkShellApplication "next-display-idx" (with pkgs; [ jq ]) (
                builtins.readFile ./src/yabai/next-display-idx
              );
              yabai-cycle-display = mkShellApplication "cycle-display" (with pkgs; [
                jq
                next-display-idx
              ]) (builtins.readFile ./src/yabai/cycle-display);
              yabai-cycle-move-display = mkShellApplication "cycle-move-display" (with pkgs; [
                jq
                next-display-idx
              ]) (builtins.readFile ./src/yabai/cycle-move-display);
              yabai-cycle-focus = mkShellApplication "cycle-focus" (with pkgs; [ jq ]) (
                builtins.readFile ./src/yabai/cycle-focus
              );
              yabai-cycle-move = mkShellApplication "cycle-move" (with pkgs; [ jq ]) (
                builtins.readFile ./src/yabai/cycle-move
              );
              yabai-focus-window = mkShellApplication "focus-window" (with pkgs; [
                jq
                choose-gui
              ]) (builtins.readFile ./src/yabai/focus-window);
              yabai-get-window = mkShellApplication "get-window" (with pkgs; [
                jq
                choose-gui
              ]) (builtins.readFile ./src/yabai/get-window);
              yabai-warp-cursor = mkShellApplication "warp-cursor" (with pkgs; [ jq ]) (
                builtins.readFile ./src/yabai/warp-cursor
              );
              yabai-kbd-backlight = mkShellApplication "kbd-backlight" [ ] (
                builtins.readFile ./src/yabai/kbd-backlight
              );
              yabai-toggle-app = mkShellApplication "toggle-app" (with pkgs; [ ]) (
                builtins.readFile ./src/yabai/toggle-app
              );
              yabai-resize = mkShellApplication "resize" (with pkgs; [
                jq
                bc
              ]) (builtins.readFile ./src/yabai/resize);
              yabai-resize-dir = mkShellApplication "resize-dir" (with pkgs; [
                jq
              ]) (builtins.readFile ./src/yabai/resize-dir);

              walogram = pkgs.callPackage ./src/walogram { };
              walogram-test = (pkgs.callPackage ./src/walogram { }).override {
                image = "/nix/store/1mfdyd874ib7rzn2y7gflhnpfc6gxnja-dock.png";
              };
              powermenu-rofi = pkgs.callPackage ./src/rofi/powermenu/default.nix { };
              menus = pkgs.callPackage ./src/rofi/menus/default.nix { inherit inputs; };
              fullmenu = pkgs.callPackage ./src/rofi/fullmenu/default.nix { };
              clients = pkgs.callPackage ./src/hypr/clients/default.nix { };
              waybar-utils = pkgs.callPackage ./src/waybar/default.nix { };
            };
        };
    };
}
