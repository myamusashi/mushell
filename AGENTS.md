# AGENTS.md

## Review focus

Prioritize: correctness, no regressions, performance, API stability, readability. Flag: algorithmic regressions in hot paths, silent config-behavior breakage, and violations of the style/code/QML/Go/Qt guidelines below.

## C++ style

- clang-format per `.clang-format`; single-line `if`/`else` without braces (not `do`/`while`).
- Minimize function bodies in headers.
- Naming: `CMyClass`, `SMyStruct`, `IMyInterface`, member vars `mVariable`.
- Headers: relative includes (`"../a/b.hpp"`), not `"src/a/b.hpp"` — except protocol headers.

## C++ code practices

- SRP over complex classes/functions; watch for feature envy, LSP violations; use templates/inheritance to de-duplicate.
- Never: `using namespace std;`, uninitialized primitives.
- Avoid unless necessary: C stdlib, `malloc`/`free`, raw C-style pointers (use STL smart pointers; raw pointers OK only where misuse is impossible, e.g. destructors).
- Avoid: `.clang-tidy` violations, manual C-style alloc/free pairs (wrap them).
- QML-exposed types: use `QML_ELEMENT`/`QML_SINGLETON`, not manual `qmlRegisterType` (unless vast-shell already does otherwise there).
- `Q_PROPERTY` needs `NOTIFY` unless truly constant (`CONSTANT`) — no silent non-reactive properties.
- Document QObject ownership across the QML/C++ boundary (QML-parented vs. C++-held via `setObjectOwnership`) — common use-after-free/double-free source, always flag if unclear.
- Prefer `QQmlListProperty`/`QAbstractListModel` over raw `QObject*` lists to QML for anything runtime-mutable.
- Async work (D-Bus, file I/O, subprocess calls) must not block the QML/UI thread — use `QtConcurrent`/signals, never sync blocking calls in a QML-invoked slot.
- Non-QObject types: `unique_ptr`/`shared_ptr`. QObject-derived types: use Qt parent-child ownership, don't also wrap in a smart pointer.

## QML style

- Format with `.qmlformat.ini`; lint with `Assets/shell/qmllint_qs.sh` against `.qmllint.ini`.
- Imports: `qs.<path_from_qml_root>` unless the target is in the same directory.
- IDs: `camelCase`, descriptive (`root`, `rect`, `mouseArea` OK as defaults).
- Local properties: `camelCase`, descriptive, no abbreviations/underscores; comment above if there are many.
- Order: `id` → `property` declarations → signal handlers → children. Don't interleave.
- Avoid nested `Loader`/`Instantiator` chains where `Repeater` or a direct binding works.
- Extract inline `Component {}` blocks >30 lines or reused more than once into their own file.
- No business logic in QML (state machines, I/O, parsing, non-trivial computation) — push to a `QML_ELEMENT` C++ type. QML stays bindings/layout/glue.
- Prefer declarative bindings over `Qt.callLater`/imperative JS; if used for real timing reasons, comment why.
- Signals named past-tense (`clicked`, `wallpaperChanged`), not imperative.

## Quickshell API lookups

Some components aren't in Qt/QML docs or `.qmltypes` — check quickshell.org instead:

1. Get the type's import (e.g. `Quickshell.Wayland`) and name (e.g. `ScreencopyView`).
2. URL: `https://quickshell.org/docs/v0.3.0/types/<import path>/<TypeName>`
   (root `Quickshell` module types live at `Quickshell/<TypeName>`, not under a submodule).
3. Fetch before writing/reviewing code using the type — don't guess properties/signals/enums from the name.
4. Unsure of the module? Check `https://quickshell.org/docs/v0.3.0/types/` first.
5. 404? Type may have moved/renamed — check the listing page or `https://quickshell.org/changelog`.

Modules in use: Quickshell (core), .Bluetooth, .DBusMenu, .Hyprland, .I3, .Io, .Networking, .Services.Greetd, .Services.Mpris, .Services.Notifications, .Services.Pam, .Services.Pipewire, .Services.Polkit, .Services.SystemTray, .Services.UPower, .Wayland, .Widgets.

## Go / Cobra CLI guidelines

- Never violate `golangci-lint` — treat lint failures as build failures, not warnings.
- Structure: one `cobra.Command` per file under `cmd/`; keep `RunE` thin — delegate real logic to an internal package (`internal/...`), don't inline business logic in the command handler.
- Always return errors (`RunE`, not `Run`); never `panic`/`os.Exit` outside `main`. Wrap errors with context via `fmt.Errorf("...: %w", err)`.
- Flags: define via `Flags()`/`PersistentFlags()` in `init()` or a constructor, bind to a local var or a config struct — no package-level global flag vars.
- Prefer a single static binary: avoid CGo unless unavoidable (breaks the static-binary goal).
- Table-driven tests for command logic; keep `main.go` minimal (build the root command, call `Execute()`, exit on error).
- Context propagation: pass `context.Context` through for anything IPC/network-bound (matches Quickshell IPC calls) rather than using bare goroutines with no cancellation path.
