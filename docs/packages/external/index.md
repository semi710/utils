# External packages

Two packages re-exported from external flake inputs. They are included in the
`utils` flake for convenience so consumers only need one input.

---

## `center-align`

Terminal output centering utility, from
[`niksingh710/center-align`](https://github.com/niksingh710/center-align).

```nix
center-align = inputs'.center-align.packages.default;
```

| | |
|---|---|
| **Source** | `github:niksingh710/center-align` |
| **Package** | `center-align` |

```bash
nix run github:semi710/utils#center-align
```

---

## `bstat`

Battery status tool with KDE Connect support, from
[`niksingh710/basic-battery-stat`](https://github.com/niksingh710/basic-battery-stat).

```nix
bstat = inputs'.bstat.packages.default;
```

| | |
|---|---|
| **Source** | `github:niksingh710/basic-battery-stat` |
| **Package** | `bstat` |

```bash
nix run github:semi710/utils#bstat
```

---

## `networkmanager` (input, not a package)

The flake also pulls in
[`firecat53/networkmanager-dmenu`](https://github.com/firecat53/networkmanager-dmenu)
as an input. This is **not** exposed as a standalone package - it's consumed
internally by the [`menus`](../rofi-menus/index.md#network-network-manager)
package's `network` script:

```nix
networkmanager.url = "github:firecat53/networkmanager-dmenu";
# ...
# In menus/default.nix:
inputs.networkmanager.packages.${pkgs.system}.default
```
