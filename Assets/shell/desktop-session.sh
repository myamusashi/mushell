#!/usr/bin/env bash

printf '%s' "${XDG_DATA_HOME:-$HOME/.local/share}:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}:/run/current-system/sw/share:/nix/var/nix/profiles/default/share" | 
tr ':' '\n' | 
while read -r d; do
    [ -z "$d" ] && continue
    find "$d/wayland-sessions" "$d/xsessions" -name '*.desktop' 2>/dev/null
done | 
sort -u | 
while read -r f; do
    n=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
    e=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | awk '{print $1}')
    [ -n "$n" ] && [ -n "$e" ] && echo "$n|||$e"
done
