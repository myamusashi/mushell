# Configuration

[Back to README](../README.md)

Vast-shell is configured by editing JSON files in the `Data/` directory or in your user config directory (`~/.config/vast-shell/`).

## Setup

```bash
mkdir -p ~/.config/vast-shell
cp -r /path/to/vast-shell/Data/{colors.json,configurations.json} ~/.config/vast-shell/
```

For Material color generation:

```bash
pip install materialyoucolor pillow
```

## configurations.json

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

## Reference

### Appearance

| Key | Default | Description |
|---|---|---|
| `animations.durations.scale` | `1` | Global scale for all animation durations. |
| `fonts.family` | — | Font families for `material`, `mono`, and `sans` text. |
| `fonts.size.scale` | `1.0` | Global font size scale. |
| `margin` / `padding` / `rounding` / `spacing` | `small`…`large` | Layout sizing in pixels. |

### Bar

| Key | Default | Description |
|---|---|---|
| `alwaysOpenBar` | `true` | Keep the bar always visible. |
| `barHeight` | `40` | Bar height in pixels. |
| `compact` | `false` | Enable compact bar mode. |
| `visibleWorkspace` | `5` | Number of workspaces shown. |
| `workspacesIndicator` | `"dot"` | Workspace indicator style (`dot` or `interactive`). |

### Colors

| Key | Default | Description |
|---|---|---|
| `isDarkMode` | `true` | Prefer dark mode. |
| `useMaterialColor` | `false` | Generate colors dynamically from the current wallpaper. |
| `scheme` | `"tonal-spot"` | Material scheme for color generation (`vibrant`, `tonal-spot`, `expressive`, `monochrome`, `rainbow`, `fruit-salad`, `neutral`, `fidelity`, `content`). |
| `useStaticColors` | `false` | Use a fixed color scheme from `colors.json`. |
| `staticColorsPath` | `$HOME/.config/vast-shell/colors.json` | Path to your static color scheme file. |

> [!NOTE]
> If both `useMaterialColor` and `useStaticColors` are `true`, Material colors take priority.

### Generals

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

### Media Player

| Key | Default | Description |
|---|---|---|
| `showLyrics` | `false` | Auto-fetch and display synced lyrics. |
| `dynamicColorsCover` | `true` | Adapt UI colors from the current track's cover art. |
| `sliderType` | `"WaveForm"` | Progress bar style (`WaveForm` or `Wavy`). |

### Wallpaper

| Key | Default | Description |
|---|---|---|
| `transition` | `"random"` | Transition effect (`fade`, `circle`, `wipe`, `random`, etc.). |
| `transitionDuration` | `300` | Transition duration in milliseconds. |
| `transitionLowPerfMode` | `false` | Reduce transition quality for lower-end hardware. |
| `wallpaperDir` | `$HOME/Pictures/wallpapers` | Directory to source wallpapers from. |
| `visibleWallpaper` | `3` | Number of wallpapers shown in the picker. |

### Weather

| Key | Default | Description |
|---|---|---|
| `latitude` / `longitude` | — | Your location coordinates for weather data. |
| `reloadTime` | `1800000` | Weather refresh interval in milliseconds (30 min). |
| `enableQuickSummary` | `false` | Show a compact weather summary in the bar. |

### KDE Connect

| Key | Default | Description |
|---|---|---|
| `pollingEnabled` | `true` | Enable periodic device discovery. |
| `pollInterval` | `15000` | Poll interval in milliseconds (15 s). |

### Depth Wallpaper

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

## Material Colors

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
