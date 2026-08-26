# Project

[Back to README](../README.md)

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
│   │   │                      # FocusCage, NAnim, SettingRow, StyledRect,
│   │   │                      # StyledSlide, StyledSwitch, StyledText,
│   │   │                      # StyledTextInput, Wallpaper, Wavy
│   │   ├── Button/            # ConnectedButtonGroup, ExtendedFloatingButton,
│   │   │                      # FloatingButton, SplitButton
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
│       ├── Search/             # Vast.Search      — SearchEngine, DirectoryWalker, LaunchHistoryStore
│       └── Translation/        # Vast.Translation — TranslationManager
│
├── Assets/
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
