# System controls

Cross-cutting system utilities: volume, brightness, CPU info, a `bat`
wrapper, IP lookup, and clipboard image annotation.

---

## `volume`

Volume control for PipeWire/WirePlumber with dunst-compatible notifications.
Handles sink (output) and source (microphone) muting, and volume up/down in
5% steps (capped at 150%).

```bash
MOD=1  # Volume increment steps (5%)

case $1 in
up)
  isSinkMuted && toggleSinkMute
  wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "$MOD"%+
  sendNotification
  ;;
down)
  isSinkMuted && toggleSinkMute
  wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "$MOD"%-
  sendNotification
  ;;
mute)
  toggleSinkMute
  muteNotification isSinkMuted getSinkName "Speaker"
  ;;
mic-mute)
  toggleSourceMute
  muteNotification isSourceMuted getSourceName "Microphone"
  ;;
esac
```

### Arguments

| Argument | Action |
|----------|--------|
| `up` | Unmute if muted, raise volume 5%, notify |
| `down` | Unmute if muted, lower volume 5%, notify |
| `mute` | Toggle output mute, notify with device name |
| `mic-mute` | Toggle microphone mute, notify with device name |

### Notifications

Uses `notify-send` with dunst stack tags (`x-dunst-stack-tag`) so volume
notifications replace each other, and a progress value hint (`-h int:value`)
for a visual bar:

```bash
notify -a "Volume" -u low \
  --hint=string:x-dunst-stack-tag:"$NOTIFY_TAG" \
  --hint=string:synchronous:"$NOTIFY_TAG" \
  -h int:value:"$volume" "Volume: $volume%" -t 1000
```

| | |
|---|---|
| **Package** | `volume` |
| **Runtime deps** | `wpctl` (wireplumber), `libnotify`, `bc`, `jq`, `gawk` |
| **Volume cap** | 150% (`-l 1.5`) |
| **Step** | 5% |

```bash
nix run github:semi710/utils#volume -- up
nix run github:semi710/utils#volume -- down
nix run github:semi710/utils#volume -- mute
nix run github:semi710/utils#volume -- mic-mute
```

!!! tip "Fallback notifications"
    The `notify()` helper falls back to `echo` if `notify-send` isn't
    available, so the script still works in a headless context.

---

## `brightness`

Screen brightness control via `brightnessctl`, with dunst-compatible
notifications and a progress bar.

```bash
case $1 in
up)
  brightnessctl s +5%
  sendNotification
  ;;
down)
  brightnessctl s 5%-
  sendNotification
  ;;
esac
```

### Arguments

| Argument | Action |
|----------|--------|
| `up` | Increase brightness 5%, notify |
| `down` | Decrease brightness 5%, notify |

### Notification

Computes the percentage from `brightnessctl g` (current) and `brightnessctl m`
(max):

```bash
brightness=$(($(brightnessctl g) * 100 / $(brightnessctl m)))
```

| | |
|---|---|
| **Package** | `brightness` |
| **Runtime deps** | `brightnessctl`, `libnotify` |
| **Step** | 5% |

```bash
nix run github:semi710/utils#brightness -- up
nix run github:semi710/utils#brightness -- down
```

---

## `icpu`

CPU information viewer with multiple modes, all using `watch` for live
updates.

```bash
case $arg in
  "freq")     watch -n1 -t "grep 'MHz' /proc/cpuinfo" ;;
  "temp")     watch -n1 -t sensors | grep 'Core' ;;
  "usage")    watch -n1 -t mpstat -P ALL 1 1 ;;
  "turbo")    cat /sys/devices/system/cpu/intel_pstate/no_turbo ;;
  "governor") cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor ;;
esac
```

### Arguments

| Argument | Default | Shows |
|----------|---------|-------|
| `freq` | yes | Per-core clock speeds from `/proc/cpuinfo` |
| `temp` | | Core temperatures from `sensors` |
| `usage` | | Per-CPU usage via `mpstat` |
| `turbo` | | Intel P-State turbo status |
| `governor` | | CPU governor for each core |

| | |
|---|---|
| **Package** | `icpu` |
| **Runtime deps** | `sysstat` (`mpstat`), `lm_sensors` (`sensors`) |

```bash
nix run github:semi710/utils#icpu
nix run github:semi710/utils#icpu -- temp
nix run github:semi710/utils#icpu -- usage
nix run github:semi710/utils#icpu -- governor
```

---

## `cat`

A `bat` wrapper with sane defaults: tab width 2, and plain (non-paged) output
unless `-p` is explicitly passed.

```bash
paged=false
batarg=("--tabs" "2")

for arg in "$@"; do
  case "$arg" in
  -p) paged=true ;;
  *) batarg+=("$arg") ;;
  esac
done

if ! "$paged"; then
  batarg+=(-pp)
fi

bat "${batarg[@]}"
```

### Behavior

- All arguments except `-p` are forwarded to `bat`.
- `-p` switches to **paged** mode (bat's default pager behavior).
- Without `-p`, adds `-pp` (plain, no paging, no decorations) for clean pipe
  output.

| | |
|---|---|
| **Package** | `cat` |
| **Runtime deps** | `bat` |

```bash
nix run github:semi710/utils#cat -- file.txt
nix run github:semi710/utils#cat -- -p file.txt   # paged
```

---

## `myip`

IP address lookup with two modes: global (public, via Google DNS) and local.

### Arguments

| Flag | Description |
|------|-------------|
| `-g` | Global/public IP via `dig` against `ns1.google.com` (IPv4 + IPv6) |
| `-l` | Local IP addresses from `ip addr` / `ifconfig` (excludes loopback) |

```bash
case "$1" in
-g)
  echo "ipv4: $(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com)" | sed 's/"//g'
  output=$(dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com)
  # ... prints ipv6 or "Not available"
  ;;
-l)
  (ip addr show || ifconfig) 2>/dev/null |
    awk '/inet / && !/127.0.0.1/ {print $NF ": " $2}' |
    sed 's#/.*##'
  ;;
esac
```

| | |
|---|---|
| **Package** | `myip` |
| **Runtime deps** | `dnsutils` (`dig`), `ip` / `ifconfig` |

```bash
nix run github:semi710/utils#myip -- -g
nix run github:semi710/utils#myip -- -l
```

!!! note "IPv6 graceful degradation"
    The `-g` mode tries IPv6 and prints "Not available" if the `dig` fails,
    rather than erroring.

---

## `img-annotate`

A one-liner that pipes the clipboard image into [Swappy](https://github.com/jtheoof/swappy)
for annotation, with a notification on failure.

```bash
wl-paste | swappy -f - &>/dev/null ||
  "notify-send" "swappy failed" "Maybe clipboard is not having a image as input"
```

### Workflow

1. Screenshot to clipboard (e.g. via `grimblast` / `hyprpicker`).
2. Run `img-annotate` - Swappy opens with the clipboard image.
3. Annotate, save, and the result goes back to the clipboard.

| | |
|---|---|
| **Package** | `img-annotate` |
| **Runtime deps** | `wl-clipboard` (`wl-paste`), `swappy`, `libnotify` |

```bash
nix run github:semi710/utils#img-annotate
```

!!! tip "Hyprland keybinding"
    ```nix
    "$mod SHIFT, s, exec, grimblast --notify copysave area && ${lib.getExe u.img-annotate}"
    ```
