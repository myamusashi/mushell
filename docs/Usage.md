# Usage

[Back to README](../README.md)

## vastctl (CLI Companion)

`vastctl` is a standalone Go binary for scripting vast-shell from the command line. It can launch the shell in the background and control every feature through IPC.

```
vastctl
├── wallpaper get / set
├── brightness get / set [+|-]<%>
├── audio profile list / set
│       device list / set
├── volume system get / set [+|-]<%> / mute / unmute / toggle-mute
│       app list / set <id> [+|-]<%> / mute <id> / unmute <id> / toggle-mute <id>
├── captureScreenImage screen / region / window [action]  # alias: capture
├── captureScreenVideo start / stop / toggle / status      # alias: record
├── mpris toggle-playing / next / previous / stop / list
├── lock lock / unlock / status
├── idle on / off / status
├── keylock capslock / numlock
├── dragAndDrop start / stop / toggle / status / shortcut
├── hypr dispatch / shortcuts list
├── daemon start / stop / restart / status [-v]
├── log [-n lines] [--no-follow]
└── completion bash / fish / zsh / nushell
```

`set` commands accept absolute percentages (`50`, `50%`) and relative adjustments (`+10%`, `-10%`) that change the current value instead of replacing it:

```sh
vastctl volume system set +10%
vastctl brightness set -5%
```

### Daemon auto-start

On the first IPC call, `vastctl` automatically launches quickshell in the background if it's not running. Explicit control is available:

```sh
vastctl daemon start               # background, logs to /tmp/vast-shell.log
vastctl daemon start --verbose     # show quickshell logs live
vastctl log                        # watch the daemon log (tail -f style)
vastctl log --no-follow -n 50      # print the last 50 lines and exit
vastctl daemon status
vastctl daemon restart
vastctl daemon stop
```

### Shell completions

```sh
vastctl completion bash   | sudo tee /etc/bash_completion.d/vastctl
vastctl completion fish   | sudo tee /usr/share/fish/vendor_completions.d/vastctl.fish
vastctl completion zsh    | sudo tee /usr/share/zsh/site-functions/_vastctl
vastctl completion nushell | sudo tee /usr/share/nushell/completions/vastctl.nu
```

### Development

Quickshell routes `ipc call` to the instance launched from the same config path, so vastctl targets whatever `VAST_SHELL_DIRECTORY` points at (falling back to the installed `shell` wrapper). To control a shell running from this repository:

```sh
quickshell -p "$PWD/Qml" &   # run the dev instance
VAST_SHELL_DIRECTORY="$PWD" vastctl idle status
```

The repo's `.envrc` exports `VAST_SHELL_DIRECTORY="$PWD"`, so with direnv enabled every vastctl invocation inside the repo automatically targets the dev instance.

## Hyprland Global Shortcuts

Dispatch a panel or action directly from Hyprland:

```sh
hyprctl dispatch global quickshell:<target>
```

Available targets: `wallpaperSwitcher`, `layershell`, `appLauncher`, `screencaptureLauncher`, `overview`, `QuickSettings`, `session`, `weather`, `dashboard`, `settings`, `clipboard`, `kdeConnect`, `dragAndDrop`

## IPC

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
| `captureScreenVideo` | `start()`, `stop()`, `toggle()`, `status(): bool`  # alias: `recorder` (compat) |
| `captureScreenImage` | `screen(action: string)`, `region(action: string)`, `window(action: string)`  # alias: `capture` (compat) |
| `audio` | `deviceList(): string`, `deviceSet(name: string)`, `profileList(): string`, `profileSet(name: string)` |
| `volume` | `systemGet(): string`, `systemSet(percent: int)`, `systemMute()`, `systemUnmute()`, `systemToggleMute()`, `appList(): string`, `appSet(id: int, percent: int)`, `appMute(id: int)`, `appUnmute(id: int)`, `appToggleMute(id: int)` |
| `mpris` | `togglePlaying()`, `next()`, `previous()`, `stop()`, `list(): string` |
| `idle` | `on()`, `off()`, `status(): bool` |
| `keylock` | `capslock(): bool`, `numlock(): bool` |
| `dragAndDrop` | `start()`, `stop()`, `toggle()`, `status(): bool` |
| `clipboardHistory` | `list(): string`, `status(): string`, `remove(id: int)`, `clear(): bool`, `search(query: string)` |
