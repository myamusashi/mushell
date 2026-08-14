#!/usr/bin/env bash

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/lock"
state_file="$state_dir/last-session"

if [ -n "$1" ]; then
    mkdir -p "$state_dir"
    printf '%s' "$1" > "$state_file"
    exit 0
fi

[ -f "$state_file" ] && cat "$state_file"
