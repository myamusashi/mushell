#!/usr/bin/env bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <qml-file>"
    exit 1
fi

QML_FILE="$1"

[ ! -f "$QML_FILE" ] && { echo "Error: File '$QML_FILE' not found"; exit 1; }

NEW_COLORS=$(matugen image "$(qs -c lock ipc call img get)" -t scheme-tonal-spot -j hex | jq '.colors.dark')
[ -z "$NEW_COLORS" ] && { echo "Error: Failed to get colors"; exit 1; }

echo "$NEW_COLORS" | jq -r 'to_entries[] | "s/readonly property color \(.key): \"[^\"]*\"/readonly property color \(.key): \"\(.value)\"/g"' | sed -f - -i "$QML_FILE"
