#!/usr/bin/env bash

# MIT License
#
# Copyright (c) 2024-2026 Rexiel Scarlet
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# https://github.com/Rexcrazy804/Zaphkiel/blob/master/dots/quickshell/kurukurubar/scripts/extractFg.sh

SRCIMG=$1
CACHEDIR=$(realpath $2)

SRCHASH=$(sha256sum "$SRCIMG" | awk '{print substr($1, 0, 10)}')

DSTDIR=${CACHEDIR}/foregrounds
DSTIMG=${DSTDIR}/${SRCHASH}.png
mkdir -p "$DSTDIR"

if [ -f "${DSTIMG}" ]; then
  echo "[INFO] Foreground file in cache"
  echo "FOREGROUND $DSTIMG"
  exit 0
fi

echo "[INFO] Extracting wallpaper foreground"
if remove-bg.py -m birefnet-portrait "$SRCIMG" "$DSTIMG" &> "$CACHEDIR/remove-bg.log"; then
  echo "[INFO] Successfully extracted foreground"
  echo "FOREGROUND $DSTIMG"
else
  echo "[ERROR] Failed to extract foreground"
  echo "[INFO] find log in ${CACHEDIR}/remove-bg.log"
  exit 1
fi
