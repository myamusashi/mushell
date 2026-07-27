#!/usr/bin/env bash

# Gunakan array agar spasi dalam "300 es" tidak di-split bash
FLAGS=(
    --glsl "450,330,300 es"
    --hlsl 50
    --msl 12
)

TRANSITIONS=(
    fade
    wipeDown
    circleExpand
    dissolve
    splitHorizontal
    hexTile
    slideUp
    pixelate
    diagonalWipe
    boxExpand
    roll
)

for name in "${TRANSITIONS[@]}"; do
    qsb "${FLAGS[@]}" \
        -o ${name}.frag.qsb \
           ${name}.frag \
    && echo "✓ ${name}.frag.qsb" \
    || echo "✗ ${name}.frag.qsb FAILED"
done
