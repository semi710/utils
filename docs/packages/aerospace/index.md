# Aerospace helpers

macOS [Aerospace](https://github.com/nikitabiryukov/tmux-aerospace) window
manager helpers - fuzzy window switchers built on `choose-gui` and `fzf`.

---

## Packages

| Package name | Script | Picker |
|--------------|--------|--------|
| `aerospace-focus-choose` | `aero.focus.choose` | [choose-gui](https://github.com/chipsenkbeil/choose) |
| `aerospace-focus-fzf` | `aero.focus.sh` | [fzf](https://github.com/junegunn/fzf) |

Both are macOS-only - they call `aerospace` to list and focus windows.

---

## `aerospace-focus-choose`

A `choose-gui`-based window switcher. Lists all windows across all spaces,
lets you pick one, focuses it, and recenters the mouse.

### Source

```bash
#!/usr/bin/env bash

font="Menlo"
# {{font}}

window_output="$(aerospace list-windows --all | choose \
    -u \
    -f "$font" \
    -p 'Select a window to focus'
)"
echo "$window_output"
window_id="$(echo "$window_output" | cut -d'|' -f1 | tr -cd '[:digit:]')"
aerospace focus --window-id "$window_id"
aerospace move-mouse window-lazy-center || aerospace move-mouse monitor-lazy-center
```

### How it works

1. `aerospace list-windows --all` lists every window as `id|app: title`.
2. `choose` opens a native macOS picker with the given font.
3. The window ID is extracted (digits before the first `|`).
4. `aerospace focus --window-id` focuses the window.
5. `aerospace move-mouse window-lazy-center` recenters the cursor (falls back
   to `monitor-lazy-center` if window-center fails).

### Build overrides

| Argument | Default | Description |
|----------|---------|-------------|
| `font` | `"Menlo"` | Font used by the `choose` picker, injected via `substituteInPlace` |

```nix
inputs.utils.packages.${pkgs.system}.aerospace-focus-choose.override {
  font = "Monaco";
}
```

### Runtime dependencies

- `aerospace` (expected in PATH at runtime)
- `choose-gui` (pinned to v1.5.0 via an override in `default.nix`)

!!! note "choose-gui pinning"
    The package overrides `choose-gui` to fetch from
    `github:chipsenkbeil/choose@1.5.0` because the nixpkgs version was
    outdated. A TODO notes this should switch to the nixpkgs version once
    [PR #423701](https://github.com/NixOS/nixpkgs/pull/423701) merges.

---

## `aerospace-focus-fzf`

An `fzf`-based window switcher with two actions: **focus** (`Enter`) and
**move window to current workspace** (`Space`).

### Source

```bash
#!/usr/bin/env bash

FOCUS_KEY="enter"
MOVE_KEY="space"

HEADER="$FOCUS_KEY   - Focus window
$MOVE_KEY   - Move window to current workspace
"

window_output="$(aerospace list-windows --all | fzf \
    --prompt='Select a window: ' \
    --header="$HEADER" \
    --header-first \
    --expect="$FOCUS_KEY,$MOVE_KEY" \
)"

key=$(echo "$window_output" | head -n1)
selection=$(echo "$window_output" | tail -n +2)

if [ -z "$selection" ]; then
  echo "No window selected."
  exit 1
fi

window_id="$(echo "$selection" | cut -d'|' -f1 | tr -cd '[:digit:]')"

case "$key" in
  "$FOCUS_KEY")
    aerospace focus --window-id "$window_id"
    ;;
  "$MOVE_KEY")
    current_workspace="$(aerospace list-workspaces --focused)"
    aerospace move-node-to-workspace \
      --focus-follows-window \
      --fail-if-noop \
      --window-id "$window_id" \
      "$current_workspace" || aerospace focus --window-id "$window_id"
    ;;
  *)
    echo "Unhandled key: $key"
    ;;
esac
```

### Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Focus the selected window |
| `Space` | Move the selected window to the current workspace (then focus it) |

### Runtime dependencies

- `aerospace` (expected in PATH at runtime)
- `fzf`

---

## `aero.grab.choose`

A third script bundled in the same package (`aerospace-focus-choose`). Like
`aero.focus.choose` but **grabs** the window - moves it to the current
workspace instead of just focusing.

```bash
current_workspace="$(aerospace list-workspaces --focused)"
aerospace move-node-to-workspace \
  --focus-follows-window \
  --fail-if-noop \
  --window-id "$window_id" \
  "$current_workspace" || aerospace focus --window-id "$window_id"
```

!!! info "Grab vs focus"
    - `aero.focus.choose` - switches focus to the window's current workspace.
    - `aero.grab.choose` - pulls the window to *your* current workspace.

---

## Usage

```bash
# Direct
nix run github:semi710/utils#aerospace-focus-choose
nix run github:semi710/utils#aerospace-focus-fzf

# In config
home.packages = [
  inputs.utils.packages.${pkgs.system}.aerospace-focus-choose
];
```

### skhd integration

```bash
# .config/skhd/skhdrc
alt - space : aerospace-focus-choose
alt + shift - space : aerospace-focus-fzf
```
