#!/usr/bin/env bash
# Runs qmllint with Quickshell import paths from .qmlls.ini
# Requires Quickshell to be running (qs -p Qml/) to have the buildDir VFS

set -e

INI="$HOME/.config/quickshell/lock/Qml/.qmlls.ini"
BUILDDIR=$(grep buildDir "$INI" | cut -d'"' -f2)

if [ ! -d "$BUILDDIR/qs" ]; then
  echo "ERROR: Quickshell buildDir not available. Is qs running?" >&2
  exit 1
fi

IMPORTS=$(grep importPaths "$INI" | cut -d'"' -f2 | tr ':' '\n')

ARGS=("-I" "Qml" "-I" "$BUILDDIR")
for p in $IMPORTS; do
  ARGS+=("-I" "$p")
done

exec qmllint "${ARGS[@]}" "$@" 2> >(grep -v 'Two plugins named' >&2)
