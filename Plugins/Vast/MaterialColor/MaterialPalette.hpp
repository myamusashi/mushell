#pragma once

#include <cmath>
#include <qnumeric.h>

#include "cpp/cam/hct.h"
#include "cpp/palettes/tones.h"
#include "cpp/utils/utils.h"

// Hue-range predicates matching materialyoucolor's Hct.is_blue/is_yellow/is_cyan.
inline bool isBlueHue(double hue) {
    return hue >= 250 && hue < 270;
}

inline bool isYellowHue(double hue) {
    return hue >= 105 && hue < 125;
}

inline bool isCyanHue(double hue) {
    return hue >= 170 && hue < 207;
}

// Rounds half to even, matching Python's round() used by average_argb.
inline int roundHalfToEven(double value) {
    const double floor = std::floor(value);
    const double diff  = value - floor;
    if (diff > 0.5)
        return static_cast<int>(floor) + 1;
    if (diff < 0.5)
        return static_cast<int>(floor);
    return static_cast<int>(floor) % 2 == 0 ? static_cast<int>(floor) : static_cast<int>(floor) + 1;
}

inline bool toneNearlyEqual(double a, double b, double epsilon = 0.01) {
    return std::fabs(a - b) < epsilon;
}

// A tonal palette defined by a hue and chroma, mirroring
// materialyoucolor.palettes.tonal_palette.TonalPalette including its
// tone-99 yellow-hue averaging rule.
struct SMaterialPalette {
    double                        hue    = 0.0;
    double                        chroma = 0.0;
    material_color_utilities::Hct keyColor{0xFF000000u};

    static SMaterialPalette       fromHueAndChroma(double hue, double chroma) {
        SMaterialPalette palette;
        palette.hue      = hue;
        palette.chroma   = chroma;
        palette.keyColor = material_color_utilities::KeyColor(hue, chroma).create();
        return palette;
    }

    // Mirrors TonalPalette.from_hct: the HCT itself becomes the key color.
    static SMaterialPalette fromHct(const material_color_utilities::Hct& hct) {
        SMaterialPalette palette;
        palette.hue      = hct.get_hue();
        palette.chroma   = hct.get_chroma();
        palette.keyColor = hct;
        return palette;
    }

    [[nodiscard]] material_color_utilities::Argb tone(double toneValue) const {
        using material_color_utilities::Argb;
        using material_color_utilities::Hct;

        if (toneNearlyEqual(toneValue, 99) && isYellowHue(hue)) {
            const Argb lower = tone(98);
            const Argb upper = tone(100);
            const int  red   = roundHalfToEven((static_cast<int>((lower >> 16) & 0xFF) + static_cast<int>((upper >> 16) & 0xFF)) / 2.0);
            const int  green = roundHalfToEven((static_cast<int>((lower >> 8) & 0xFF) + static_cast<int>((upper >> 8) & 0xFF)) / 2.0);
            const int  blue  = roundHalfToEven((static_cast<int>(lower & 0xFF) + static_cast<int>(upper & 0xFF)) / 2.0);
            return 0xFF000000u | static_cast<Argb>(red << 16) | static_cast<Argb>(green << 8) | static_cast<Argb>(blue);
        }
        return Hct(hue, chroma, toneValue).ToInt();
    }
};
