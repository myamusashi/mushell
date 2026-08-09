<!-- BSD 3-Clause License -->
<!---->
<!-- Copyright (c) 2022-2026, vaxerski -->
<!-- All rights reserved. -->
<!---->
<!-- Redistribution and use in source and binary forms, with or without -->
<!-- modification, are permitted provided that the following conditions are met: -->
<!---->
<!-- 1. Redistributions of source code must retain the above copyright notice, this -->
<!--    list of conditions and the following disclaimer. -->
<!---->
<!-- 2. Redistributions in binary form must reproduce the above copyright notice, -->
<!--    this list of conditions and the following disclaimer in the documentation -->
<!--    and/or other materials provided with the distribution. -->
<!---->
<!-- 3. Neither the name of the copyright holder nor the names of its -->
<!--    contributors may be used to endorse or promote products derived from -->
<!--    this software without specific prior written permission. -->
<!---->
<!-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" -->
<!-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE -->
<!-- IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE -->
<!-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE -->
<!-- FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL -->
<!-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR -->
<!-- SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER -->
<!-- CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, -->
<!-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE -->
<!-- OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. -->

# AGENTS.md

## Review guidelines

- Prioritize correctness, lack of regressions, performance, API stability, and code clarity and readability.
- For performance-sensitive paths, flag obvious algorithmic regressions or slow paths.
- Flag silent config breakage: e.g. changing an existing option's behavior. This is not allowed.
- Flag bad config style that breaks this project's style guidelines (further below) and suggest fixes.
- Flag bad code approaches that break this project's core code guidelines (further below) and suggest improvements.
- Flag bad QML style that breaks this project's QML style guidelines (further below) and suggest fixes.
- Flag bad code approaches that break Qt C++ core code guidelines (further below) and suggest improvements.

## Style guidelines

- Code must be clang-formatted according to `.clang-format`.
- single-line if and else statements must come without braces. This rule applies only to if / else, not do / while / other.
- Avoid function bodies in headers as much as possible.
- Naming conventions:
 - class: `CMyClass`
 - struct: `SMyStruct`
 - interface: `IMyInterface`
 - class (not struct) member variables: `mVariable`
- Do not use absolute includes from `src/` in headers: instead of `#include "a/b.hpp"` use `#include "../a/b.hpp"` for example. Protocol headers do not require this.

## Core code guidelines

- Stick to good code practices:
 - Avoid complex classes / functions, prefer SRP.
 - Watch out for typical bad practices in code: feature envy, LSP, etc.
 - Use templating and inheritance to clean up code where appropriate.
- Do not, under any circumstance:
 - `using namespace std;`
 - leave uninitialized primitives (int, float, etc)
- Avoid, unless absolutely necessary:
 - the C standard library. Use the C++ STL.
 - `malloc` / `free` / etc
 - C-style pointers. Use std pointers from STL C++. C-style pointers may be used in select scenarios (e.g. destroying fns, where it's impossible to make a mistake) but everywhere else must not be used unless necessary.
- Avoid:
 - violating clang-tidy (`.clang-tidy`)
 - manual C-style cleanup: `some_c_thing_new()` and `some_c_thing_free()` can be wrapped.

## QML style guidelines

- Follow the existing `.qmlformat.ini` run the formatter before submitting.
- Component IDs: `camelCase`, descriptive, no abbreviations unless already established in the file (`root`, `rect`, `mouseArea` are fine defaults).
- Wannable `local property/variable` names: `camelCase`, descriptive, no shortname, no abbbreviations, no underscore. Flag the local property with a comment above them.
- Property declarations grouped and ordered: `id`, then `property` declarations, then signal handlers, then child items. Don't interleave.
- Avoid deeply nested `Loader`/`Instantiator` chains where a `Repeater` or direct binding would do — nesting hurts both readability and reactivity debugging.
- Anonymous inline `Component {}` blocks should be extracted to their own `.qml` file once they exceed ~30 lines or are reused more than once.
- Do not put business logic in QML that belongs in C++. QML is a view layer: bindings, layout, and simple glue only. Anything involving state machines, I/O, parsing, or non-trivial computation belongs in a C++-backed type exposed via `QML_ELEMENT`.
- Avoid `Qt.callLater` / imperative JS blocks as a substitute for proper property bindings — prefer declarative bindings unless there's a genuine ordering/timing need, and comment why when you do.
- Signals: name in past tense for "something happened" (`clicked`, `wallpaperChanged`), not imperative.

## Quickshell guidelines

Some of the QML component in this codebase is not on the Qt/QML library or .qmltypes, always fetching how to use Quickshell components from the website, the Quickshell components and types we use is:
1. Quickshell  — BoundComponent, ColorQuantizer, DesktopAction, DesktopEntries, DesktopEntry, EasingCurve, Edges, ElapsedTimer, ExclusionMode, FloatingWindow, Intersection, LazyLoader, ObjectModel, PanelWindow, PersistentProperties, PopupAdjustment, PopupAnchor, PopupWindow, QsMenuAnchor, QsMenuButtonType, QsMenuEntry, QsMenuHandle, QsMenuOpener, QsWindow, Quickshell, QuickshellSettings, Region, RegionShape, Reloadable, Retainable, RetainableLock, Scope, ScriptModel, ShellRoot, ShellScreen, Singleton, SystemClock, TransformWatcher, Variants
2. Quickshell.Bluetooth — Bluetooth, BluetoothAdapter, BluetoothAdapterState, BluetoothDevice, BluetoothDeviceState
3. Quickshell.DBusMenu — DBusMenuHandle, DBusMenuItem
4. Quickshell.Hyprland — GlobalShortcut, Hyprland, HyprlandEvent, HyprlandFocusGrab, HyprlandMonitor, HyprlandToplevel, HyprlandWindow, HyprlandWorkspace
5. Quickshell.I3 — I3, I3Event, I3IpcListener, I3Monitor, I3Workspace
6. Quickshell.Io — DataStream, DataStreamParser, FileView, FileViewAdapter, FileViewError, IpcHandler, JsonAdapter, JsonObject, Process, Socket, SocketServer, SplitParser, StdioCollector
7. Quickshell.Networking — ConnectionFailReason, ConnectionState, DeviceType, NMSettings, Network, NetworkBackendType, NetworkConnectivity, NetworkDevice, Networking, WifiDevice, WifiDeviceMode, WifiNetwork, WifiSecurityType, WiredDevice
8. Quickshell.Services.Greetd — Greetd, GreetdState
9. Quickshell.Services.Mpris — Mpris, MprisLoopState, MprisPlaybackState, MprisPlayer
10. Quickshell.Services.Notifications — Notification, NotificationAction, NotificationCloseReason, NotificationServer, NotificationUrgency
11. Quickshell.Services.Pam — PamContext, PamError, PamResult
12. Quickshell.Services.Pipewire — Pipewire, PwAudioChannel, PwLink, PwLinkGroup, PwLinkState, PwNode, PwNodeAudio, PwNodeLinkTracker, PwNodePeakMonitor, PwNodeType, PwObjectTracker
13. Quickshell.Services.Polkit — AuthFlow, PolkitAgent
14. Quickshell.Services.SystemTray — Category, Status, SystemTray, SystemTrayItem
15. Quickshell.Services.UPower — PerformanceDegradationReason, PowerProfile, PowerProfiles, UPower, UPowerDevice, UPowerDeviceState, UPowerDeviceType
16. Quickshell.Wayland — BackgroundEffect, IdleInhibitor, IdleMonitor, ScreencopyView, ShortcutInhibitor, Toplevel, ToplevelManager, WlSessionLock, WlSessionLockSurface, WlrKeyboardFocus, WlrLayer, WlrLayershell
17. Quickshell.Widgets — ClippingRectangle, ClippingWrapperRectangle, IconImage, MarginWrapperManager, WrapperItem, WrapperManager, WrapperMouseArea, WrapperRectangle

Where `<Module>` is the exact QML import path (e.g. `Quickshell`, `Quickshell.Bluetooth`, `Quickshell.Hyprland`, `Quickshell.Io`) and `<TypeName>` is the exact type/component name used in QML, case-sensitive.

Example: `import Quickshell.Bluetooth` exposes `Bluetooth` and `BluetoothAdapter`, so their docs are at:
- `https://quickshell.org/docs/v0.3.0/types/Quickshell.Bluetooth/Bluetooth`
- `https://quickshell.org/docs/v0.3.0/types/Quickshell.Bluetooth/BluetoothAdapter`

The one exception is the root `Quickshell` module itself: its types live directly under `Quickshell/<TypeName>` (e.g. `PanelWindow` → `https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow`), not under a submodule.

### Workflow for agents

1. Identify the QML `import` statement the type comes from (e.g. `import Quickshell.Wayland`).
2. Take the type name as written in the QML file (e.g. `ScreencopyView`).
3. Construct the URL: `https://quickshell.org/docs/v0.3.0/types/<import path>/<TypeName>`.
4. Fetch that URL before writing or reviewing code that uses the type. Do not guess property names, signals, or enums from memory or naming conventions alone — Quickshell's API is not always intuitive from the name.
5. If unsure which module a type belongs to, first fetch the module listing page (`https://quickshell.org/docs/v0.3.0/types/`) to confirm the correct import path before constructing the type URL.
6. If a fetch 404s, the type may have moved or been renamed between versions — check the module listing page or the changelog (`https://quickshell.org/changelog`) rather than assuming the type doesn't exist.

## Qt C++ guidelines

- Types exposed to QML must be registered via `QML_ELEMENT`/`QML_SINGLETON`, not manual `qmlRegisterType` calls, unless the project's existing pattern says otherwise — stay consistent with whatever vast-shell already does.
- `Q_PROPERTY` declarations require a `NOTIFY` signal unless the property is genuinely constant for the object's lifetime (`CONSTANT`) — no silently non-reactive properties.
- Ownership across the QML/C++ boundary must be explicit: document (comment) whether a `QObject*` exposed to QML is parented (QML engine may claim ownership) or held by C++ (`QQmlEngine::setObjectOwnership` set explicitly). This is a common source of use-after-free/double-free bugs at this boundary and should be called out in review every time.
- Avoid exposing raw `QObject*` lists to QML where a `QQmlListProperty` or model-based approach (`QAbstractListModel`) is more appropriate for anything that changes at runtime.
- Async work (D-Bus, file I/O, subprocess calls like `nmcli`/`ddcutil`) must never block the QML/UI thread — use Qt's `QtConcurrent`/signal-based async patterns, not synchronous blocking calls in a slot invoked from QML.
- Prefer `std::unique_ptr`/`std::shared_ptr` for non-QObject C++ types per the existing pointer rules; for `QObject`-derived types, Qt's parent-child ownership is the idiomatic substitute for `unique_ptr` — don't fight it by wrapping a parented `QObject*` in a smart pointer too.
