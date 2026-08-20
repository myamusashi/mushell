#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: $(basename "$0") <command> [args...]" >&2
    exit 64
fi

PKEXEC=""
for candidate in "/run/wrappers/bin/pkexec" "$(command -v pkexec 2>/dev/null || true)"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
        PKEXEC="$candidate"
        break
    fi
done

if [[ -z "$PKEXEC" ]]; then
    echo "pkexec-wrapper: pkexec not found (checked /run/wrappers/bin and PATH)" >&2
    exit 127
fi

if [[ -x "/run/current-system/sw/bin/bash" ]]; then
    SHELL="/run/current-system/sw/bin/bash"
elif command -v bash >/dev/null 2>&1; then
    SHELL="$(command -v bash)"
else
    echo "pkexec-wrapper: no bash found" >&2
    exit 127
fi
export SHELL

: "${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
: "${WAYLAND_DISPLAY:=wayland-1}"
: "${DBUS_SESSION_BUS_ADDRESS:=unix:path=${XDG_RUNTIME_DIR}/bus}"

export XDG_RUNTIME_DIR WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS

bus_path="${DBUS_SESSION_BUS_ADDRESS#unix:path=}"
if [[ ! -S "$bus_path" ]]; then
    echo "pkexec-wrapper: session bus not found at $bus_path" \
         "(is DBUS_SESSION_BUS_ADDRESS correct for this session?)" >&2
    exit 1
fi

"$PKEXEC" "$@"
