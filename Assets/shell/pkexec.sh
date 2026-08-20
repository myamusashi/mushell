#!/usr/bin/env bash

set -euo pipefail

if [[ $# -eq 0 ]]; then
    echo "usage: $(basename "$0") <command> [args...]" >&2
    exit 64
fi

PKEXEC="/run/wrappers/bin/pkexec"
if [[ ! -x "$PKEXEC" ]]; then
    PKEXEC="$(command -v pkexec)"
fi

SHELL="/run/current-system/sw/bin/bash"
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
