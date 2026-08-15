<h1 align="center">vast-shell</h1>

![Preview](https://github.com/user-attachments/assets/8df0a484-f60b-44e5-831f-255e0cf4df8d)

![Last Commit](https://img.shields.io/github/last-commit/myamusashi/vast-shell?label=last+commit&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Commits](https://img.shields.io/github/commit-activity/t/myamusashi/vast-shell?label=commits&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Stars](https://img.shields.io/github/stars/myamusashi/vast-shell?label=stars&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)
![Repo Size](https://img.shields.io/github/repo-size/myamusashi/vast-shell?label=repo+size&style=for-the-badge&color=cba6f7&labelColor=1e1e2e)

![Nix](https://img.shields.io/badge/nix-flakes-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=nixos&logoColor=89b4fa)
![C++](https://img.shields.io/badge/c%2B%2B-23-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=cplusplus&logoColor=89b4fa)
![QML](https://img.shields.io/badge/qml-quickshell-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=qt&logoColor=89b4fa)

> [!WARNING]
> This project is still in **active development**. Some features may be incomplete or change without notice, but it is usable as a daily driver. Issues and feedback are welcome!

---

## Table of Contents

- [Showcase](#showcase)
- [Usage](#usage)
  - [Hyprland Global Shortcuts](#hyprland-global-shortcuts)
  - [IPC](#ipc)
- [Installation](#installation)
  - [NixOS (Flakes)](#nixos-flakes)
  - [Arch Linux](#arch-linux)
  - [Other Distros](#other-distros)
- [Configuration](#configuration)
  - [configurations.json](#configurationsjson)
  - [Reference](#reference)
  - [Material Colors](#material-colors)
- [Translations](#translations)
- [Project Structure](#project-structure)
- [Upcoming Features](#upcoming-features)
- [Credits](#credits)

---

## Showcase

https://github.com/user-attachments/assets/11651d0e-6929-4404-a24f-7e3dabc95ad1

<details>
  <summary>Screenshots</summary>
  <br/>
  <table>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/447c0b4a-a5b4-41ec-8f4a-05b57f523edb" width="480"/><br/>Bar & Workspaces</td>
      <td align="center"><img src="https://github.com/user-attachments/assets/a34f1a9f-f9ed-4f82-991f-e68e79e54fec" width="480"/><br/>Quick Settings</td>
    </tr>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/6283c0b6-6055-4fd0-900a-0dabafac46a3" width="480"/><br/>Launcher</td>
      <td align="center"><img src="https://github.com/user-attachments/assets/8049ec79-ade0-47d5-b2d8-cb5c5a25e895" width="480"/><br/>Notifications</td>
    </tr>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/74ddfbbd-269a-48fb-8380-bd11b0bcc82f" width="480"/><br/>Weather</td>
      <td align="center"><img src="https://github.com/user-attachments/assets/01cd558e-9beb-48a2-930c-bb48cfa493d4" width="480"/><br/>Dashboard</td>
    </tr>
    <tr>
      <td align="center"><img src="https://github.com/user-attachments/assets/9995e862-e6ff-45ee-88d8-68dbb98226e1" width="480"/><br/>Lockscreen</td>
      <td align="center"><img src="https://github.com/user-attachments/assets/7ba86a61-f957-440d-9aa8-0eb6c84c766c" width="480"/><br/>Settings</td>
    </tr>
  </table>
</details>

---

## Usage

### vastctl (CLI Companion)

`vastctl` is a standalone Go binary for scripting vast-shell from the command line. It can launch the shell in the background and control every feature through IPC.

```
vastctl
├── wallpaper get / set
├── brightness get / set
├── audio profile list / set
│       device list / set
├── volume system get / set / mute / unmute / toggle-mute
│       app list / set <id> / mute <id> / unmute <id> / toggle-mute <id>
├── capture screen / region / window [action]
├── record start / stop / toggle / status
├── mpris toggle-playing / next / previous / stop / list
├── lock lock / unlock / status
├── idle on / off / status
├── keylock capslock / numlock
├── dynamicIsland start / stop / toggle / status / shortcut
├── hypr dispatch / shortcuts list
├── daemon start / stop / restart / status [-v]
└── completion bash / fish / zsh / nushell
```

#### Daemon auto-start

On the first IPC call, `vastctl` automatically launches quickshell in the background if it's not running. Explicit control is available:

```sh
vastctl daemon start               # silent by default
vastctl daemon start --verbose     # show quickshell logs
vastctl daemon status
vastctl daemon restart
vastctl daemon stop
```

#### Shell completions

```sh
vastctl completion bash   | sudo tee /etc/bash_completion.d/vastctl
vastctl completion fish   | sudo tee /usr/share/fish/vendor_completions.d/vastctl.fish
vastctl completion zsh    | sudo tee /usr/share/zsh/site-functions/_vastctl
vastctl completion nushell | sudo tee /usr/share/nushell/completions/vastctl.nu
```

### Hyprland Global Shortcuts

Dispatch a panel or action directly from Hyprland:

```sh
hyprctl dispatch global quickshell:<target>
```

Available targets: `wallpaperSwitcher`, `layershell`, `appLauncher`, `screencaptureLauncher`, `overview`, `QuickSettings`, `session`, `weather`, `dashboard`, `settings`, `clipboard`, `kdeConnect`, `dynamicIsland`

### IPC

Call shell functions from a script or keybind:

```sh
# Full form
quickshell -c <shell directory> ipc call <target> <function>

# Short alias
qs -c <shell directory> ipc call <target> <function>

# If installed via archInstall.sh or the Nix flake
shell ipc call <target> <function>
```

**Available targets and functions:**

| Target | Functions |
|---|---|
| `bar`, `weather`, `quickSettings`, `launcher`, `session`, `dashboard`, `settings`, `overview`, `wallpaperSwitcher`, `screenCapture`, `clipboard`, `recordingPanel` | `toggle()`, `open()`, `close()` |
| `toast` | `open(header: string, description: string, icon: string, duration: int)` |
| `img` | `get(): string`, `set(path: string)` |
| `lock` | `lock()`, `unlock()`, `isLocked(): bool` |
| `recorder` | `start()`, `stop()`, `toggle()`, `status(): bool` |
| `capture` | `screen(action: string)`, `region(action: string)`, `window(action: string)` |
| `brightness` | `get(): string`, `set(percent: int)` |
| `audio` | `deviceList(): string`, `deviceSet(name: string)`, `profileList(): string`, `profileSet(name: string)` |
| `volume` | `systemGet(): string`, `systemSet(percent: int)`, `systemMute()`, `systemUnmute()`, `systemToggleMute()`, `appList(): string`, `appSet(id: int, percent: int)`, `appMute(id: int)`, `appUnmute(id: int)`, `appToggleMute(id: int)` |
| `mpris` | `togglePlaying()`, `next()`, `previous()`, `stop()`, `list(): string` |
| `idle` | `on()`, `off()`, `status(): bool` |
| `keylock` | `capslock(): bool`, `numlock(): bool` |
| `dynamicIsland` | `start()`, `stop()`, `toggle()`, `status(): bool` |

---

## Installation

### NixOS (Flakes)

Add vast-shell to your flake inputs:

```nix
inputs.vast-shell = {
  url = "github:myamusashi/vast-shell";
};
```

Then you can either add the package directly, or use the NixOS module:

**Option 1 — Add the package directly:**

```nix
environment.systemPackages = [
  inputs.vast-shell.packages.${system}.default
];
```

**Option 2 — Use the NixOS module (recommended):**

```nix
{
  imports = [ inputs.vast-shell.nixosModules.default ];

  programs.quickshell-shell = {
    enable = true;

    # Optional: install extra packages accessible to the shell
    extraPackages = with pkgs; [ spotify ];

    # Optional: disable font installation if you manage fonts separately
    installFonts = false;
  };
}
```

The module registers a systemd user service (`quickshell-shell.service`) that auto-starts with your graphical session, and automatically installs required fonts (`material-symbols`, `weather-icons`).

---

### Arch Linux

> [!IMPORTANT]
> Requires Arch Linux or an Arch-based distro. Run with `sudo`.

```bash
git clone https://github.com/myamusashi/vast-shell.git
cd vast-shell
sudo ./archInstall.sh
```

The script installs all dependencies, builds the plugins, compiles shaders, and sets up the shell. Once complete, start it with:

```bash
shell
```

#### Dependencies

**Build**

| Package | Purpose |
|---|---|
| `cmake`, `qt6-shadertools`, `qt6-tools` | Build system, shader compiler (`qsb`), translation compiler (`lrelease`) |
| `qt6-base`, `qt6-declarative`, `qt6-multimedia` | Qt6 build-time libraries |
| `wayland` | Provides `libwayland-client` + `wayland-scanner` for the clipboard manager's native `ext_data_control_v1` binding |

**Runtime**

| Category | Packages |
|---|---|
| Shell | `quickshell-git`, `hyprland`, `foot`, `polkit` |
| Qt6 | `qt6-base`, `qt6-declarative`, `qt6-multimedia`, `qt6-5compat`, `qt6-graphs`, `kf6-qtmultimedia` |
| Media | `ffmpeg`, `wireplumber`, `wl-clipboard`, `wl-screenrec` |
| Network / Notifications | `iw`, `libnotify` |
| Fonts | `ttf-material-symbols-variable-git`, `ttf-weather-icons`, `google-sans-flex` (optional), `Hack` (optional) |
| Utils | `findutils`, `grep`, `gawk`, `sed`, `util-linux` |
| AI / Depth Wallpaper | `python-rembg` |
| Other | `app2unit` |

> [!IMPORTANT]
> **Brightness control (ddcutil):** Controlling external monitor brightness requires non-root access to I2C devices. `archInstall.sh` handles this automatically. For manual setup, load the `i2c-dev` module, apply the appropriate udev rules (see `setup_i2c` in `archInstall.sh`), and add your user to the `i2c` and `video` groups.

---

### Other Distros

> [!WARNING]
> Package names below were accurate at time of writing but **may be outdated**. Always verify against your distro's official package index. PRs to keep this list updated are welcome.
>
> **`rembg`** is not available in most distro repositories. Install it via `pip install rembg` (requires Python 3.9+). NixOS users get it automatically via the flake definition.
>
> - **Fedora** → https://packages.fedoraproject.org
> - **openSUSE** → https://software.opensuse.org
> - **Gentoo** → https://packages.gentoo.org
> - **Void** → https://voidlinux.org/packages

The following packages must always be built from source, regardless of distro:

| Package | Source |
|---|---|
| `quickshell` | https://github.com/quickshell/quickshell |
| `materialyoucolor` | https://github.com/T-Dynamos/materialyoucolor-python |
| `app2unit` | https://github.com/valpackett/app2unit |
| `wl-screenrec` | https://github.com/russelltg/wl-screenrec |
| Material Symbols font | https://github.com/google/material-design-icons |
| Weather Icons font | https://github.com/erikflowers/weather-icons |

<details>
<summary>Fedora</summary>

```bash
# System & build
sudo dnf install git cmake ninja-build extra-cmake-modules patchelf pkgconf \
                 gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel qt6-qtsvg-devel \
                 qt6-qtmultimedia-devel qt6-qt5compat-devel \
                 qt6-qtshadertools-devel qt6-qttools-devel

# Runtime
sudo dnf install pipewire wireplumber iw libnotify polkit \
                 wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

> [!NOTE]
> `ffmpeg` requires [RPM Fusion](https://rpmfusion.org): `sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm`
>
> `qt6-qtgraphs` is not yet packaged in Fedora — build from source if required.

</details>

<details>
<summary>openSUSE Tumbleweed</summary>

```bash
# System & build
sudo zypper install git cmake ninja extra-cmake-modules patchelf pkgconf \
                    gcc gcc-c++ make rust cargo wayland-devel

# Qt6
sudo zypper install qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                    qt6-multimedia-devel qt6-5compat-devel \
                    qt6-shadertools-devel qt6-tools-devel

# Runtime
sudo zypper install pipewire wireplumber iw libnotify-tools polkit \
                    wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>

<details>
<summary>Gentoo</summary>

```bash
# System & build
sudo emerge -av dev-vcs/git dev-build/cmake dev-build/ninja \
                kde-frameworks/extra-cmake-modules dev-util/patchelf \
                dev-util/pkgconf dev-lang/rust dev-libs/wayland

# Qt6 (ensure USE="qt6" where applicable)
sudo emerge -av dev-qt/qtbase:6 dev-qt/qtdeclarative:6 dev-qt/qtsvg:6 \
                dev-qt/qtmultimedia:6 dev-qt/qt5compat:6 \
                dev-qt/qtshadertools:6 dev-qt/qttools:6

# Runtime
sudo emerge -av media-video/pipewire media-video/wireplumber net-wireless/iw \
                x11-libs/libnotify sys-auth/polkit \
                gui-apps/wl-clipboard media-video/ffmpeg gui-apps/foot \
                gui-wm/hyprland sys-apps/util-linux
```

</details>

<details>
<summary>Void Linux</summary>

```bash
# System & build
sudo xbps-install -S git cmake ninja extra-cmake-modules patchelf pkgconf \
                     base-devel rust cargo wayland-devel

# Qt6
sudo xbps-install -S qt6-base-devel qt6-declarative-devel qt6-svg-devel \
                     qt6-multimedia-devel qt6-5compat-devel \
                     qt6-shadertools-devel qt6-tools

# Runtime
sudo xbps-install -S pipewire wireplumber iw libnotify polkit \
                     wl-clipboard ffmpeg foot hyprland findutils grep sed gawk util-linux
```

</details>

---

## Configuration

Vast-shell is configured by editing JSON files in the `Data/` directory or in your user config directory (`~/.config/vast-shell/`).

### Setup

```bash
mkdir -p ~/.config/vast-shell
cp -r /path/to/vast-shell/Data/{colors.json,configurations.json} ~/.config/vast-shell/
```

For Material color generation:

```bash
pip install materialyoucolor pillow
```

### configurations.json

<details>
<summary>View full structure</summary>

```json
{
  "appearance": {
    "animations": { "durations": { "scale": 1 } },
    "fonts": {
      "family": {
        "material": "Material Symbols Rounded",
        "mono": "Hack",
        "sans": "Google Sans Flex"
      },
      "size": { "scale": 1 }
    },
    "margin":  { "small": 5, "smaller": 7, "normal": 10, "larger": 12, "large": 15 },
    "padding": { "small": 5, "smaller": 7, "normal": 10, "larger": 12, "large": 15 },
    "rounding": { "small": 12, "normal": 17, "large": 25, "full": 1000 },
    "spacing":  { "small": 7, "smaller": 10, "normal": 12, "larger": 15, "large": 20 }
  },
  "bar": {
    "alwaysOpenBar": true,
    "barHeight": 40,
    "compact": false,
    "visibleWorkspace": 5,
    "workspacesIndicator": "dot"
  },
  "colors": {
    "isDarkMode": true,
    "toDarkColor":  "$HOME/.config/vast-shell/dark-colors.json",
    "toWhiteColor": "$HOME/.config/vast-shell/light-colors.json",
    "staticColorsPath": "$HOME/.config/vast-shell/colors.json",
    "useMaterialColor": false,
    "useStaticColors": false
  },
  "generals": {
    "alpha": 1.0,
    "apps": {
      "audio": "pavucontrol-qt",
      "fileExplorer": "pcmanfm-qt",
      "imageViewer": "lximage-qt",
      "playback": "mpv",
      "terminal": "foot",
      "videoViewer": "mpv"
    },
    "battery": {
      "criticalLevel": 3,
      "warnLevels": [
        { "icon": "battery-020", "level": 20, "message": "Kamu mungkin mau colok chargernya",           "title": "Baterai lemah" },
        { "icon": "battery-010", "level": 10, "message": "Kamu mungkin ingin colok charger kamu <b>sekarang</b>", "title": "Kamu bisa lihat pesan sebelumnya kan?" },
        { "icon": "battery-000", "level": 5,  "message": "MASUKAN CHARGER NYA SEKARANG!!",              "title": "Level baterai kritis" }
      ]
    },
    "chargingGlowSpread": 10,
    "coverBlurRadius": 16,
    "enableOuterBorder": false,
    "followFocusMonitor": true,
    "outerBorderSize": 10,
    "transparent": false
  },
  "language": { "language": "" },
  "mediaPlayer": {
    "dynamicColorsCover": true,
    "showLyrics": false,
    "sliderType": "WaveForm"
  },
  "notification": {
    "maximumNotification": 100,
    "maximumNotificationAge": 604800000
  },
  "wallpaper": {
    "enabledWallpaper": true,
    "transition": "random",
    "transitionDuration": 300,
    "transitionLowPerfMode": false,
    "visibleWallpaper": 3,
    "wallpaperDir": "$HOME/Pictures/wallpapers"
  },
  "weather": {
    "enableQuickSummary": false,
    "latitude": "-6.4028",
    "longitude": "106.7744",
    "reloadTime": 1800000
  },
  "kdeConnect": {
    "pollingEnabled": true,
    "pollInterval": 15000
  }
}
```

</details>

### Reference

#### Appearance

| Key | Default | Description |
|---|---|---|
| `animations.durations.scale` | `1` | Global scale for all animation durations. |
| `fonts.family` | — | Font families for `material`, `mono`, and `sans` text. |
| `fonts.size.scale` | `1.0` | Global font size scale. |
| `margin` / `padding` / `rounding` / `spacing` | `small`…`large` | Layout sizing in pixels. |

#### Bar

| Key | Default | Description |
|---|---|---|
| `alwaysOpenBar` | `true` | Keep the bar always visible. |
| `barHeight` | `40` | Bar height in pixels. |
| `compact` | `false` | Enable compact bar mode. |
| `visibleWorkspace` | `5` | Number of workspaces shown. |
| `workspacesIndicator` | `"dot"` | Workspace indicator style (`dot` or `interactive`). |

#### Colors

| Key | Default | Description |
|---|---|---|
| `isDarkMode` | `true` | Prefer dark mode. |
| `useMaterialColor` | `false` | Generate colors dynamically from the current wallpaper. |
| `scheme` | `"tonal-spot"` | Material scheme for color generation (`vibrant`, `tonal-spot`, `expressive`, `monochrome`, `rainbow`, `fruit-salad`, `neutral`, `fidelity`, `content`). |
| `useStaticColors` | `false` | Use a fixed color scheme from `colors.json`. |
| `staticColorsPath` | `$HOME/.config/vast-shell/colors.json` | Path to your static color scheme file. |

> [!NOTE]
> If both `useMaterialColor` and `useStaticColors` are `true`, Material colors take priority.

#### Generals

| Key | Default | Description |
|---|---|---|
| `alpha` | `1.0` | Global transparency level. |
| `transparent` | `false` | Enable transparency for shell elements. |
| `enableOuterBorder` | `false` | Draw a border around the shell layout. |
| `outerBorderSize` | `10` | Outer border thickness in pixels. |
| `coverBlurRadius` | `16` | Blur radius applied to media cover art. |
| `chargingGlowSpread` | `10` | Glow spread radius when the device is charging. |
| `apps` | — | Default applications for terminal, audio, file manager, etc. |
| `battery.warnLevels` | — | Battery thresholds with custom notification titles and messages. |

#### Media Player

| Key | Default | Description |
|---|---|---|
| `showLyrics` | `false` | Auto-fetch and display synced lyrics. |
| `dynamicColorsCover` | `true` | Adapt UI colors from the current track's cover art. |
| `sliderType` | `"WaveForm"` | Progress bar style (`WaveForm` or `Wavy`). |

#### Wallpaper

| Key | Default | Description |
|---|---|---|
| `transition` | `"random"` | Transition effect (`fade`, `circle`, `wipe`, `random`, etc.). |
| `transitionDuration` | `300` | Transition duration in milliseconds. |
| `transitionLowPerfMode` | `false` | Reduce transition quality for lower-end hardware. |
| `wallpaperDir` | `$HOME/Pictures/wallpapers` | Directory to source wallpapers from. |
| `visibleWallpaper` | `3` | Number of wallpapers shown in the picker. |

#### Weather

| Key | Default | Description |
|---|---|---|
| `latitude` / `longitude` | — | Your location coordinates for weather data. |
| `reloadTime` | `1800000` | Weather refresh interval in milliseconds (30 min). |
| `enableQuickSummary` | `false` | Show a compact weather summary in the bar. |

#### KDE Connect

| Key | Default | Description |
|---|---|---|
| `pollingEnabled` | `true` | Enable periodic device discovery. |
| `pollInterval` | `15000` | Poll interval in milliseconds (15 s). |

#### Depth Wallpaper

> [!NOTE]
> Depth wallpaper extracts the foreground subject from your wallpaper and layers it separately over a blurred background, creating a **parallax depth effect** on the lock screen.

**How it works:**

1. When enabled, the first wallpaper change triggers foreground extraction via `rembg`
2. `rembg` processes the image using the **BiRefNet-portrait** model to separate the foreground subject from the background
3. The extracted foreground is cached by content hash so subsequent uses of the same wallpaper are instant
4. On the lock screen, the wallpaper blurs and the foreground layer sits on top with independent scaling

**Model details:**

| Property | Value |
|---|---|
| Model | `birefnet-portrait` (BiRefNet for portraits/foregrounds) |
| Download size | ~176 MB (downloaded once on first use) |
| RAM usage during inference | ~800 MB – 1.5 GB |
| Processing time (GPU) | ~2 – 8 seconds |
| Processing time (CPU) | ~10 – 40 seconds |

> [!TIP]
> - Processing runs **asynchronously** in the background — you can continue using the shell normally
> - The extracted foreground is cached in `~/.cache/vast-shell/depthwp/foregrounds/`
> - To reprocess a wallpaper, delete its cached foreground from that directory and trigger a wallpaper change
> - GPU acceleration requires `onnxruntime` with CUDA support — `pip install onnxruntime-gpu`

---

### Material Colors

Material You colors are generated from the current wallpaper by the Python script `Assets/shell/generate_colors_material.py` (wrapped as the `generate-colors-material` command). It writes two JSON files:

- `dark-colors.json` — dark color scheme
- `light-colors.json` — light color scheme

Both are read at runtime by `Qml/Services/Colours.qml` via the configured `toDarkColor` / `toWhiteColor` paths.

<details>
<summary>Example generated color scheme (dark)</summary>

```json
{
  "colors": {
    "background": "#171217",
    "error": "#ffb4ab",
    "errorContainer": "#93000a",
    "inverseOnSurface": "#342f34",
    "inversePrimary": "#7a4f80",
    "inverseSurface": "#eadfe6",
    "onBackground": "#eadfe6",
    "onError": "#690005",
    "onErrorContainer": "#ffdad6",
    "onPrimary": "#48204f",
    "onPrimaryContainer": "#fed6ff",
    "onPrimaryFixed": "#300939",
    "onPrimaryFixedVariant": "#603767",
    "onSecondary": "#3b2b3c",
    "onSecondaryContainer": "#f4dbf2",
    "onSecondaryFixed": "#251726",
    "onSecondaryFixedVariant": "#524153",
    "onSurface": "#eadfe6",
    "onSurfaceVariant": "#cfc3cd",
    "onTertiary": "#4c2520",
    "onTertiaryContainer": "#ffdad5",
    "onTertiaryFixed": "#33110d",
    "onTertiaryFixedVariant": "#673b35",
    "outline": "#988d97",
    "outlineVariant": "#4d444c",
    "primary": "#eab5ee",
    "primaryContainer": "#603767",
    "primaryFixed": "#fed6ff",
    "primaryFixedDim": "#eab5ee",
    "scrim": "#000000",
    "secondary": "#d7bfd5",
    "secondaryContainer": "#524153",
    "secondaryFixed": "#f4dbf2",
    "secondaryFixedDim": "#d7bfd5",
    "shadow": "#000000",
    "sourceColor": "#ce8fd6",
    "surface": "#171217",
    "surfaceBright": "#3d373d",
    "surfaceContainer": "#231e23",
    "surfaceContainerHigh": "#2e282d",
    "surfaceContainerHighest": "#393338",
    "surfaceContainerLow": "#1f1a1f",
    "surfaceContainerLowest": "#110d11",
    "surfaceDim": "#171217",
    "surfaceTint": "#eab5ee",
    "surfaceVariant": "#4d444c",
    "tertiary": "#f5b8af",
    "tertiaryContainer": "#673b35",
    "tertiaryFixed": "#ffdad5",
    "tertiaryFixedDim": "#f5b8af"
  }
}
```

</details>

---

## Translations

Vast-shell uses Qt's built-in translation system. Translation files live in `translations/`:

- `.ts` — source file (XML, human-editable)
- `.qm` — compiled binary used at runtime (do not edit directly)

| Locale | Language |
|---|---|
| `id_ID` | Indonesian |

> [!NOTE]
> `lupdate` and `lrelease` are provided by `qt6-tools` (Arch), `qt6-tools-dev-tools` (Debian/Ubuntu), or `qt6.qttools` (NixOS).

### Qt Linguist

The recommended way to translate vast-shell is with **Qt Linguist**, a GUI editor that ships with `qt6-tools`. It shows every string in context, tracks translation progress, and warns about missing or outdated entries.

<img src="https://github.com/user-attachments/assets/c5569311-99a3-4f99-9709-464ceda68495" width="720"/>

<table>
  <tr>
    <td>✅ Visual side-by-side editing</td>
    <td>✅ Progress tracker per file</td>
  </tr>
  <tr>
    <td>✅ Marks unfinished and obsolete strings</td>
    <td>✅ Built-in phrase book and search</td>
  </tr>
</table>

```bash
linguist translations/your_locale.ts
```

### Adding a New Language

```bash
# 1. Generate the .ts file
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts

# 2. Translate in Qt Linguist (or edit the XML by hand)
linguist translations/your_locale.ts

# 3. Compile to .qm
lrelease translations/your_locale.ts
```

Replace `your_locale` with a standard locale code, e.g. `fr_FR`, `ja_JP`, `de_DE`.

### Updating an Existing Translation

```bash
# Sync new strings without overwriting existing translations
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts

# Open in Linguist, finish unfinished entries, then recompile
lrelease translations/your_locale.ts
```

**NixOS:** Translations are compiled automatically during the build phase — no manual steps needed.

**Arch Linux:** `archInstall.sh` compiles translations automatically. To recompile manually:

```bash
/usr/lib/qt6/bin/lrelease translations/*.ts
```

---

## Project Structure

```
vast-shell/
├── shell.qml
├── archInstall.sh
├── flake.nix / flake.lock / shell.nix
│
├── vastctl/
│   ├── main.go
│   ├── go.mod / go.sum
│   ├── cmd/                    # audio, brightness, capture, daemon,
│   │                           # hypr, idle, keylock, lock, mpris,
│   │                           # record, root, volume, wallpaper
│   └── internal/
│       ├── hypr/dispatch.go    # hyprctl wrapper
│       └── ipc/client.go       # shell ipc call client + daemon launcher
│
├── nix/
│   ├── default.nix
│   ├── nixos-modules.nix
│   ├── packages/
│   │   ├── app2unit.nix
│   │   ├── material-symbols.nix
│   │   ├── qmlfmt.nix
│   │   └── vastctl.nix
│   └── plugins/
│       ├── AnotherRipple.nix
│       ├── m3Shapes.nix
│       └── vastPlugin.nix
│
├── Qml/
│   ├── shell.qml
│   ├── Components/
│   │   ├── Base/              # CAnim, Circular, Corner, CornerPair, Elevation,
│   │   │                      # FocusCage, NAnim, SettingRow, StyledButton,
│   │   │                      # StyledRect, StyledSlide, StyledSwitch,
│   │   │                      # StyledText, StyledTextInput, Wallpaper, Wavy
│   │   ├── Menu/              # ContextMenu, DropdownField, DropdownMenu,
│   │   │                      # MenuDivider, MenuItem, MenuSurface
│   │   ├── Dialog/
│   │   │   ├── DialogBox.qml
│   │   │   └── FileDialog/    # BottomActionBar, FileListView, PlacesSidebar,
│   │   │                      # TopAppBar, FileListItem, PlaceItem
│   │   └── Feedback/          # BorderProgress, LoadingIndicator, Progress, Toast
│   │
│   ├── Core/
│   │   ├── Configs/           # Appearance, Bar, Clipboard, ColorSystem, General,
│   │   │                      # Idle, KDEConnect, Localization, MediaPlayer,
│   │   │                      # Notification, ScreenRecorder, Wallpaper, Weather
│   │   ├── States/            # GlobalStates (IPC handlers, OSD, panels),
│   │   │                      # Workspaces
│   │   └── Utils/             # DistroAscii, Dots, HighlightText, Icon, Log,
│   │                          # MArea, Paths, ScreenSelection, Time, TimeAgo, WeatherIcon
│   │
│   ├── Services/              # Audio, Battery, Brightness, CalendarMajorEvents,
│   │                          # Colours, DepthWallpaperController, Fontlist, Hotspot,
│   │                          # Hypr, Hyprsunset, KeylockState, Lyrics, Notifs,
│   │                          # Players, PolAgent, Privacy, Record, ScreenCapture,
│   │                          # ScreenCaptureHistory, SystemUsage, ToastService,
│   │                          # WallpaperFileModels, Weather
│   │   └── ScreenRecorder/    # ScreenRecorder, ScreenshotSaver, Screenshotter
│   │
│   ├── Modules/
│   │   ├── Drawers/
│   │   │   ├── Bar/           # Bar, Left, Middle, Right
│   │   │   ├── Calendar/
│   │   │   ├── Clipboard/     # ClipboardItemDelegate, ClipboardPreview
│   │   │   ├── DynamicIsland/ # ConfirmDeviceContent, DeviceListContent, DoneContent,
│   │   │   │                  # DraggingContent, FilesDroppedContent, ProgressContent
│   │   │   ├── Launcher/      # App, CaptureItem, Screencapture, History
│   │   │   ├── Notifications/ # Content, NotifIcon, Wrapper
│   │   │   ├── OSD/           # CapsLockWidget, NumLockWidget
│   │   │   ├── QuickSettings/ # PerformancePages, VolumeSettings, WiFi, Network, Battery
│   │   │   ├── ScreenRecorder/# AudioDeviceItem, PageAudio, PageHistory, PageMain, PageSettings
│   │   │   ├── Session/
│   │   │   ├── Volume/
│   │   │   ├── WallpaperSelector/
│   │   │   └── Weather/       # Headers, WeatherItem/* (AQI, Cloudiness, Forecast, Humidity,
│   │   │                      # Moon, Precipitation, Pressure, Sun, UVIndex, Visibility, Wind)
│   │   ├── Lock/              # Bar, BottomItem, CapsLockPopup, Clock,
│   │   │                      # Lockscreen, MediaPlayer, Pam, Surface
│   │   ├── Polkit/            # Body, Header, InputField
│   │   ├── Settings/
│   │   │   ├── Components/    # SettingsCard, SettingsPageBase, SidebarItem
│   │   │   └── Pages/         # Appearance, Bar, Clipboard, DepthWallpaperSection,
│   │   │                      # General, Idle, Internet, KDEConnect, Language,
│   │   │                      # MediaPlayer, Notification, ScreenRecorder, Wallpaper, Weather
│   │   └── Wallpaper/         # Wall
│   │
│   └── Widgets/               # AudioProfiles, Battery, Clock, LyricsView,
│                              # MixerEntry, Mpris, NotificationDots, OsText,
│                              # RecordIndicator, Sound, Tray, TrayMenu,
│                              # WorkspaceName, Workspaces
│
├── Plugins/                   # C++ QML modules, URI per directory under the Vast namespace
│   ├── CMakeLists.txt
│   ├── cmake/qml-module.cmake  # shared vast_module() helper
│   └── Vast/
│       ├── CMakeLists.txt      # core module (URI Vast), shared FuzzyMatcher
│       ├── Audio/              # Vast.Audio       — AudioDevicesModel/Watcher, AudioProfilesModel/Watcher
│       ├── Brightness/         # Vast.Brightness  — BrightnessManager
│       ├── Clipboard/          # Vast.Clipboard   — Database, Entry, Manager, Model, WaylandDataControl
│       │   └── protocols/      # ext-data-control-v1.xml
│       ├── ImageCache/         # Vast.ImageCache  — ImageCache
│       ├── Keylock/            # Vast.Keylock     — KeylockState
│       ├── Lyrics/             # Vast.Lyrics      — LyricsProvider
│       ├── Search/             # Vast.Search      — SearchEngine, SearchResult
│       └── Translation/        # Vast.Translation — TranslationManager
│
├── Assets/
│   ├── go/formatting.go       # QML auto-formatter / linter
│   ├── images/                # image_not_found, wallpaper fallbacks
│   ├── shaders/               # borderProgress, waveForm, wavy, ImageTransition
│   │   └── transitions/       # boxExpand, circleExpand, diagonalWipe, dissolve,
│   │                          # fade, pixelate, roll, slideUp, splitHorizontal, wipeDown
│   ├── shell/extract-fg.sh    # Depth wallpaper foreground extraction
│   ├── shell/generate_colors_material.py  # Material You color generation
│   └── weather_icon/          # Moon phase SVGs
│
├── Data/                      # colors.json, color/scheme JSON outputs
└── translations/              # id_ID.ts, id_ID.qm
```

---

## Upcoming Features

> [!NOTE]
> These features are planned and may change in scope or priority. Contributions are welcome!

**KDE Connect**
- [x] Device discovery, pairing, and transfer UI
- [x] Drag-and-drop file sharing via Dynamic Island
- [x] Settings page with polling controls and device management

**Bluetooth**
- [ ] Device discovery and pairing
- [ ] Connection management and status in Quick Settings

**Screen Capture Rework**
- [x] Redesign the screen recorder
- [x] Window selection mode for targeted recording
- [x] Merged multi-monitor screenshot support
- [x] Reduced external dependencies (less reliance on `slurp`, `hyprshot`, `grim`)

**VPN & Tunnel Detection**
- [ ] Warp (Cloudflare) and WireGuard connection detection
- [ ] Generic VPN status indicator in the network settings page

**Clipboard Manager**
- [x] Persistent clipboard history with image preview
- [x] Selected text snippets with source context
- [x] Vim keybindings for navigation, visual mode for selection, copy, delete and search
- [x] Built-in storage via `sqlite`
- [x] Native `ext_data_control_v1` Wayland backend
- [x] Fuzzy search over history

---

## Credits

Thanks to everyone in the Quickshell Discord server, especially **@m7moud_el_zayat** for the advice.

Thanks to **@outfoxxed** for [quickshell](https://github.com/quickshell-mirror/quickshell).

Thanks to **[@Soramane](https://github.com/caelestia-dots/shell)** for the inspiration — lots of references taken from your shell, and thanks for the material shapes too.

Also check out [qtengine](https://github.com/kossLAN/qtengine) by **@koss** — a Qt config that doesn't suck.
