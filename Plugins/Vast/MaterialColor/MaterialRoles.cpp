#include "MaterialRoles.hpp"

#include <algorithm>
#include <cctype>
#include <functional>
#include <qnumeric.h>
#include <string>
#include <array>
#include <cmath>
#include <cstddef>
#include <optional>
#include <span>
#include <vector>

#include "cpp/cam/hct.h"
#include "cpp/contrast/contrast.h"
#include "cpp/dislike/dislike.h"
#include "cpp/dynamiccolor/dynamic_color.h"
#include "cpp/utils/utils.h"
#include "MaterialPalette.hpp"
#include "MaterialTemperatureCache.hpp"

using material_color_utilities::Argb;
using material_color_utilities::Darker;
using material_color_utilities::Hct;
using material_color_utilities::FixIfDisliked;
using material_color_utilities::ForegroundTone;
using material_color_utilities::Lighter;
using material_color_utilities::RatioOfTones;
using material_color_utilities::SanitizeDegreesDouble;
using material_color_utilities::TonePrefersLightForeground;

namespace {

    double clampDouble(double min, double max, double input) {
        if (input < min)
            return min;
        if (input > max)
            return max;
        return input;
    }

    // find_best_tone_for_chroma() from color_spec_2025.py.
    double findBestToneForChroma(double hue, double chroma, double tone, bool byDecreasingTone) {
        double answer        = tone;
        Hct    bestCandidate = Hct(hue, chroma, answer);
        while (bestCandidate.get_chroma() < chroma) {
            if (tone < 0 || tone > 100)
                break;
            tone += byDecreasingTone ? -1.0 : 1.0;
            const Hct newCandidate = Hct(hue, chroma, tone);
            if (bestCandidate.get_chroma() < newCandidate.get_chroma()) {
                bestCandidate = newCandidate;
                answer        = tone;
            }
        }
        return answer;
    }

    // t_max_c() from color_spec_2025.py.
    double tMaxC(const SMaterialPalette& palette, double lowerBound = 0, double upperBound = 100, double chromaMultiplier = 1) {
        const double answer = findBestToneForChroma(palette.hue, palette.chroma * chromaMultiplier, 100, true);
        return clampDouble(lowerBound, upperBound, answer);
    }

    // t_min_c() from color_spec_2025.py.
    double tMinC(const SMaterialPalette& palette, double lowerBound = 0, double upperBound = 100) {
        const double answer = findBestToneForChroma(palette.hue, palette.chroma, 0, false);
        return clampDouble(lowerBound, upperBound, answer);
    }

    // find_desired_chroma_by_tone() from color_spec_2021.py.
    double findDesiredChromaByTone(double hue, double chroma, double tone, bool byDecreasingTone) {
        double answer          = tone;
        Hct    closestToChroma = Hct(hue, chroma, tone);
        if (closestToChroma.get_chroma() < chroma) {
            double chromaPeak = closestToChroma.get_chroma();
            while (closestToChroma.get_chroma() < chroma) {
                answer += byDecreasingTone ? -1.0 : 1.0;
                const Hct potentialSolution = Hct(hue, chroma, answer);
                if (chromaPeak > potentialSolution.get_chroma())
                    break;
                if (std::abs(potentialSolution.get_chroma() - chroma) < 0.4)
                    break;
                if (std::abs(potentialSolution.get_chroma() - chroma) < std::abs(closestToChroma.get_chroma() - chroma))
                    closestToChroma = potentialSolution;
                chromaPeak = std::max(chromaPeak, potentialSolution.get_chroma());
            }
        }
        return answer;
    }

    // DynamicScheme.get_piecewise_hue().
    double getPiecewiseHue(const Hct& sourceColor, std::span<const double> hueBreakpoints, std::span<const double> hues) {
        const size_t segmentCount = std::min(hueBreakpoints.size() - 1, hues.size());
        for (size_t i = 0; i < segmentCount; i++) {
            if (sourceColor.get_hue() >= hueBreakpoints[i] && sourceColor.get_hue() < hueBreakpoints[i + 1])
                return SanitizeDegreesDouble(hues[i]);
        }
        return sourceColor.get_hue();
    }

    // DynamicScheme.get_rotated_hue().
    double getRotatedHue(const Hct& sourceColor, std::span<const double> hueBreakpoints, std::span<const double> rotations) {
        double rotation = getPiecewiseHue(sourceColor, hueBreakpoints, rotations);
        if (rotations.empty())
            rotation = 0;
        return SanitizeDegreesDouble(sourceColor.get_hue() + rotation);
    }

    bool isFidelity(const MaterialScheme& scheme) {
        return scheme.variant == EMaterialVariant::Fidelity || scheme.variant == EMaterialVariant::Content;
    }

    bool isMonochrome(const MaterialScheme& scheme) {
        return scheme.variant == EMaterialVariant::Monochrome;
    }

} // namespace

// ─────────────────────────────────────────────────────────────────────────────
// Palette construction (DynamicSchemePalettesDelegateImpl2021 / Impl2025,
// phone platform only — the shell never requests the watch platform).
// ─────────────────────────────────────────────────────────────────────────────

namespace {

    SMaterialPalette primaryPalette2021(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Content:
            case EMaterialVariant::Fidelity: return SMaterialPalette::fromHueAndChroma(source.get_hue(), source.get_chroma());
            case EMaterialVariant::FruitSalad: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() - 50.0), 48.0);
            case EMaterialVariant::Monochrome: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 12.0);
            case EMaterialVariant::Rainbow: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 48.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 36.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() + 240), 40.0);
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 200.0);
        }
        return SMaterialPalette::fromHueAndChroma(source.get_hue(), 36.0);
    }

    SMaterialPalette secondaryPalette2021(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Content:
            case EMaterialVariant::Fidelity: return SMaterialPalette::fromHueAndChroma(source.get_hue(), std::max(source.get_chroma() - 32.0, source.get_chroma() * 0.5));
            case EMaterialVariant::FruitSalad: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() - 50.0), 36.0);
            case EMaterialVariant::Monochrome: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 8.0);
            case EMaterialVariant::Rainbow:
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 16.0);
            case EMaterialVariant::Expressive: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 21, 51, 121, 151, 191, 271, 321, 360};
                static constexpr std::array<double, 9> kRotations   = {45, 95, 45, 20, 45, 90, 45, 45, 45};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 24.0);
            }
            case EMaterialVariant::Vibrant: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 41, 61, 101, 131, 181, 251, 301, 360};
                static constexpr std::array<double, 9> kRotations   = {18, 15, 10, 12, 15, 18, 15, 12, 12};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 24.0);
            }
        }
        return SMaterialPalette::fromHueAndChroma(source.get_hue(), 16.0);
    }

    SMaterialPalette tertiaryPalette2021(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Content: return SMaterialPalette::fromHct(FixIfDisliked(MaterialTemperatureCache(source).analogous(3, 6)[2]));
            case EMaterialVariant::Fidelity: return SMaterialPalette::fromHct(FixIfDisliked(MaterialTemperatureCache(source).complement()));
            case EMaterialVariant::FruitSalad: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 36.0);
            case EMaterialVariant::Monochrome: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 16.0);
            case EMaterialVariant::Rainbow:
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() + 60.0), 24.0);
            case EMaterialVariant::Expressive: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 21, 51, 121, 151, 191, 271, 321, 360};
                static constexpr std::array<double, 9> kRotations   = {120, 120, 20, 45, 20, 15, 20, 120, 120};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 32.0);
            }
            case EMaterialVariant::Vibrant: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 41, 61, 101, 131, 181, 251, 301, 360};
                static constexpr std::array<double, 9> kRotations   = {35, 30, 20, 25, 30, 35, 30, 25, 25};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 32.0);
            }
        }
        return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() + 60.0), 24.0);
    }

    SMaterialPalette neutralPalette2021(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Content:
            case EMaterialVariant::Fidelity: return SMaterialPalette::fromHueAndChroma(source.get_hue(), source.get_chroma() / 8.0);
            case EMaterialVariant::FruitSalad: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 10.0);
            case EMaterialVariant::Monochrome: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 2.0);
            case EMaterialVariant::Rainbow: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 6.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() + 15), 8.0);
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 10.0);
        }
        return SMaterialPalette::fromHueAndChroma(source.get_hue(), 6.0);
    }

    SMaterialPalette neutralVariantPalette2021(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Content:
            case EMaterialVariant::Fidelity: return SMaterialPalette::fromHueAndChroma(source.get_hue(), (source.get_chroma() / 8.0) + 4.0);
            case EMaterialVariant::FruitSalad: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 16.0);
            case EMaterialVariant::Monochrome: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 2.0);
            case EMaterialVariant::Rainbow: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 0.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 8.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(SanitizeDegreesDouble(source.get_hue() + 15), 12.0);
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 12.0);
        }
        return SMaterialPalette::fromHueAndChroma(source.get_hue(), 8.0);
    }

    double expressiveNeutralHue(const Hct& source) {
        static constexpr std::array<double, 7> kBreakpoints = {0, 71, 124, 253, 278, 300, 360};
        static constexpr std::array<double, 6> kRotations   = {10, 0, 10, 0, 10, 0};
        return getRotatedHue(source, kBreakpoints, kRotations);
    }

    double expressiveNeutralChroma(const Hct& source, bool isDark) {
        const double neutralHue = expressiveNeutralHue(source);
        if (isDark)
            return isYellowHue(neutralHue) ? 6.0 : 14.0;
        return 18.0;
    }

    double vibrantNeutralHue(const Hct& source) {
        static constexpr std::array<double, 6> kBreakpoints = {0, 38, 105, 140, 333, 360};
        static constexpr std::array<double, 5> kRotations   = {-14, 10, -14, 10, -14};
        return getRotatedHue(source, kBreakpoints, kRotations);
    }

    double vibrantNeutralChroma() {
        return 28.0;
    }

    SMaterialPalette primaryPalette2025(EMaterialVariant variant, const Hct& source, bool isDark) {
        switch (variant) {
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), isBlueHue(source.get_hue()) ? 12.0 : 8.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), isDark ? 26.0 : 32.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(source.get_hue(), isDark ? 36.0 : 48.0);
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 74.0);
            default: return primaryPalette2021(variant, source);
        }
    }

    SMaterialPalette secondaryPalette2025(EMaterialVariant variant, const Hct& source, bool isDark) {
        switch (variant) {
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), isBlueHue(source.get_hue()) ? 6.0 : 4.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 16.0);
            case EMaterialVariant::Expressive: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 105, 140, 204, 253, 278, 300, 333, 360};
                static constexpr std::array<double, 8> kRotations   = {-160, 155, -100, 96, -96, -156, -165, -160};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), isDark ? 16.0 : 24.0);
            }
            case EMaterialVariant::Vibrant: {
                static constexpr std::array<double, 6> kBreakpoints = {0, 38, 105, 140, 333, 360};
                static constexpr std::array<double, 5> kRotations   = {-14, 10, -14, 10, -14};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 56.0);
            }
            default: return secondaryPalette2021(variant, source);
        }
    }

    SMaterialPalette tertiaryPalette2025(EMaterialVariant variant, const Hct& source) {
        switch (variant) {
            case EMaterialVariant::Neutral: {
                static constexpr std::array<double, 8> kBreakpoints = {0, 38, 105, 161, 204, 278, 333, 360};
                static constexpr std::array<double, 7> kRotations   = {-32, 26, 10, -39, 24, -15, -32};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 20.0);
            }
            case EMaterialVariant::TonalSpot: {
                static constexpr std::array<double, 6> kBreakpoints = {0, 20, 71, 161, 333, 360};
                static constexpr std::array<double, 5> kRotations   = {-40, 48, -32, 40, -32};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 28.0);
            }
            case EMaterialVariant::Expressive: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 105, 140, 204, 253, 278, 300, 333, 360};
                static constexpr std::array<double, 8> kRotations   = {-165, 160, -105, 101, -101, -160, -170, -165};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 48.0);
            }
            case EMaterialVariant::Vibrant: {
                static constexpr std::array<double, 9> kBreakpoints = {0, 38, 71, 105, 140, 161, 253, 333, 360};
                static constexpr std::array<double, 8> kRotations   = {-72, 35, 24, -24, 62, 50, 62, -72};
                return SMaterialPalette::fromHueAndChroma(getRotatedHue(source, kBreakpoints, kRotations), 56.0);
            }
            default: return tertiaryPalette2021(variant, source);
        }
    }

    SMaterialPalette neutralPalette2025(EMaterialVariant variant, const Hct& source, bool isDark) {
        switch (variant) {
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 1.4);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 5.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(expressiveNeutralHue(source), expressiveNeutralChroma(source, isDark));
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(vibrantNeutralHue(source), vibrantNeutralChroma());
            default: return neutralPalette2021(variant, source);
        }
    }

    SMaterialPalette neutralVariantPalette2025(EMaterialVariant variant, const Hct& source, bool isDark) {
        switch (variant) {
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 1.4 * 2.2);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(source.get_hue(), 5.0 * 1.7);
            case EMaterialVariant::Expressive: {
                const double neutralHueValue    = expressiveNeutralHue(source);
                const double neutralChromaValue = expressiveNeutralChroma(source, isDark);
                return SMaterialPalette::fromHueAndChroma(neutralHueValue, neutralChromaValue * (neutralHueValue >= 105 && neutralHueValue < 125 ? 1.6 : 2.3));
            }
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(vibrantNeutralHue(source), vibrantNeutralChroma() * 1.29);
            default: return neutralVariantPalette2021(variant, source);
        }
    }

    SMaterialPalette errorPalette2025(EMaterialVariant variant, const Hct& source) {
        static constexpr std::array<double, 9> kBreakpoints = {0, 3, 13, 23, 33, 43, 153, 273, 360};
        static constexpr std::array<double, 8> kHues        = {12, 22, 32, 12, 22, 32, 22, 12};
        const double                           errorHue     = getPiecewiseHue(source, kBreakpoints, kHues);
        switch (variant) {
            case EMaterialVariant::Neutral: return SMaterialPalette::fromHueAndChroma(errorHue, 50.0);
            case EMaterialVariant::TonalSpot: return SMaterialPalette::fromHueAndChroma(errorHue, 60.0);
            case EMaterialVariant::Expressive: return SMaterialPalette::fromHueAndChroma(errorHue, 64.0);
            case EMaterialVariant::Vibrant: return SMaterialPalette::fromHueAndChroma(errorHue, 80.0);
            default: return SMaterialPalette::fromHueAndChroma(25.0, 84.0);
        }
    }

} // namespace

MaterialScheme::MaterialScheme(Hct sourceColorHct, EMaterialVariant schemeVariant, bool dark, double contrast) :
    sourceColor(sourceColorHct), variant(schemeVariant), isDark(dark), contrastLevel(contrast),
    spec2025(schemeVariant == EMaterialVariant::TonalSpot || schemeVariant == EMaterialVariant::Neutral || schemeVariant == EMaterialVariant::Vibrant ||
             schemeVariant == EMaterialVariant::Expressive) {

    primaryPalette        = spec2025 ? primaryPalette2025(variant, sourceColor, isDark) : primaryPalette2021(variant, sourceColor);
    secondaryPalette      = spec2025 ? secondaryPalette2025(variant, sourceColor, isDark) : secondaryPalette2021(variant, sourceColor);
    tertiaryPalette       = spec2025 ? tertiaryPalette2025(variant, sourceColor) : tertiaryPalette2021(variant, sourceColor);
    neutralPalette        = spec2025 ? neutralPalette2025(variant, sourceColor, isDark) : neutralPalette2021(variant, sourceColor);
    neutralVariantPalette = spec2025 ? neutralVariantPalette2025(variant, sourceColor, isDark) : neutralVariantPalette2021(variant, sourceColor);
    errorPalette          = spec2025 ? errorPalette2025(variant, sourceColor) : SMaterialPalette::fromHueAndChroma(25.0, 84.0);
}

MaterialScheme MaterialScheme::withLightNoContrast() const {
    MaterialScheme temp(sourceColor, variant, false, 0.0);
    temp.primaryPalette        = primaryPalette;
    temp.secondaryPalette      = secondaryPalette;
    temp.tertiaryPalette       = tertiaryPalette;
    temp.neutralPalette        = neutralPalette;
    temp.neutralVariantPalette = neutralVariantPalette;
    temp.errorPalette          = errorPalette;
    return temp;
}

const char* materialRoleName(MaterialRole role) {
    switch (role) {
        case MaterialRole::Background: return "background";
        case MaterialRole::OnBackground: return "onBackground";
        case MaterialRole::Surface: return "surface";
        case MaterialRole::SurfaceDim: return "surfaceDim";
        case MaterialRole::SurfaceBright: return "surfaceBright";
        case MaterialRole::SurfaceContainerLowest: return "surfaceContainerLowest";
        case MaterialRole::SurfaceContainerLow: return "surfaceContainerLow";
        case MaterialRole::SurfaceContainer: return "surfaceContainer";
        case MaterialRole::SurfaceContainerHigh: return "surfaceContainerHigh";
        case MaterialRole::SurfaceContainerHighest: return "surfaceContainerHighest";
        case MaterialRole::OnSurface: return "onSurface";
        case MaterialRole::SurfaceVariant: return "surfaceVariant";
        case MaterialRole::OnSurfaceVariant: return "onSurfaceVariant";
        case MaterialRole::Outline: return "outline";
        case MaterialRole::OutlineVariant: return "outlineVariant";
        case MaterialRole::InverseSurface: return "inverseSurface";
        case MaterialRole::InverseOnSurface: return "inverseOnSurface";
        case MaterialRole::Shadow: return "shadow";
        case MaterialRole::Scrim: return "scrim";
        case MaterialRole::SurfaceTint: return "surfaceTint";
        case MaterialRole::Primary: return "primary";
        case MaterialRole::PrimaryDim: return "primaryDim";
        case MaterialRole::OnPrimary: return "onPrimary";
        case MaterialRole::PrimaryContainer: return "primaryContainer";
        case MaterialRole::OnPrimaryContainer: return "onPrimaryContainer";
        case MaterialRole::InversePrimary: return "inversePrimary";
        case MaterialRole::PrimaryFixed: return "primaryFixed";
        case MaterialRole::PrimaryFixedDim: return "primaryFixedDim";
        case MaterialRole::OnPrimaryFixed: return "onPrimaryFixed";
        case MaterialRole::OnPrimaryFixedVariant: return "onPrimaryFixedVariant";
        case MaterialRole::Secondary: return "secondary";
        case MaterialRole::SecondaryDim: return "secondaryDim";
        case MaterialRole::OnSecondary: return "onSecondary";
        case MaterialRole::SecondaryContainer: return "secondaryContainer";
        case MaterialRole::OnSecondaryContainer: return "onSecondaryContainer";
        case MaterialRole::SecondaryFixed: return "secondaryFixed";
        case MaterialRole::SecondaryFixedDim: return "secondaryFixedDim";
        case MaterialRole::OnSecondaryFixed: return "onSecondaryFixed";
        case MaterialRole::OnSecondaryFixedVariant: return "onSecondaryFixedVariant";
        case MaterialRole::Tertiary: return "tertiary";
        case MaterialRole::TertiaryDim: return "tertiaryDim";
        case MaterialRole::OnTertiary: return "onTertiary";
        case MaterialRole::TertiaryContainer: return "tertiaryContainer";
        case MaterialRole::OnTertiaryContainer: return "onTertiaryContainer";
        case MaterialRole::TertiaryFixed: return "tertiaryFixed";
        case MaterialRole::TertiaryFixedDim: return "tertiaryFixedDim";
        case MaterialRole::OnTertiaryFixed: return "onTertiaryFixed";
        case MaterialRole::OnTertiaryFixedVariant: return "onTertiaryFixedVariant";
        case MaterialRole::Error: return "error";
        case MaterialRole::ErrorDim: return "errorDim";
        case MaterialRole::OnError: return "onError";
        case MaterialRole::ErrorContainer: return "errorContainer";
        case MaterialRole::OnErrorContainer: return "onErrorContainer";
        case MaterialRole::PrimaryPaletteKeyColor: return "primaryPaletteKeyColor";
        case MaterialRole::SecondaryPaletteKeyColor: return "secondaryPaletteKeyColor";
        case MaterialRole::TertiaryPaletteKeyColor: return "tertiaryPaletteKeyColor";
        case MaterialRole::NeutralPaletteKeyColor: return "neutralPaletteKeyColor";
        case MaterialRole::NeutralVariantPaletteKeyColor: return "neutralVariantPaletteKeyColor";
        case MaterialRole::ErrorPaletteKeyColor: return "errorPaletteKeyColor";
        case MaterialRole::Count: return "";
    }
    return "";
}

namespace {
    constexpr bool contrastEquals(double a, double b, double eps = 1e-9) {
        return std::abs(a - b) < eps;
    }
}

SMaterialContrastCurve defaultContrastCurve(double defaultContrast) {
    if (contrastEquals(defaultContrast, 1.5))
        return {.low = 1.5, .normal = 1.5, .medium = 3, .high = 5.5};
    if (contrastEquals(defaultContrast, 3))
        return {.low = 3, .normal = 3, .medium = 4.5, .high = 7};
    if (contrastEquals(defaultContrast, 4.5))
        return {.low = 4.5, .normal = 4.5, .medium = 7, .high = 11};
    if (contrastEquals(defaultContrast, 6))
        return {.low = 6, .normal = 6, .medium = 7, .high = 11};
    if (contrastEquals(defaultContrast, 7))
        return {.low = 7, .normal = 7, .medium = 11, .high = 21};
    if (contrastEquals(defaultContrast, 9))
        return {.low = 9, .normal = 9, .medium = 11, .high = 21};
    if (contrastEquals(defaultContrast, 11))
        return {.low = 11, .normal = 11, .medium = 21, .high = 21};
    if (contrastEquals(defaultContrast, 21))
        return {.low = 21, .normal = 21, .medium = 21, .high = 21};
    return {.low = defaultContrast, .normal = defaultContrast, .medium = 7, .high = 21};
}

// ─────────────────────────────────────────────────────────────────────────────
// Role definitions. Ported from color_spec_2021.py (base table) and
// color_spec_2025.py (overrides). Watch-platform branches are not ported:
// the shell always uses the phone platform (materialyoucolor's default).
// ─────────────────────────────────────────────────────────────────────────────

namespace {

    struct SDynamicColorDef {
        std::function<const SMaterialPalette&(const MaterialScheme&)>               palette          = nullptr;
        std::function<double(const MaterialScheme&)>                                tone             = nullptr;
        std::function<double(const MaterialScheme&)>                                chromaMultiplier = nullptr;
        bool                                                                        isBackground     = false;
        std::function<std::optional<MaterialRole>(const MaterialScheme&)>           background       = nullptr;
        std::function<std::optional<MaterialRole>(const MaterialScheme&)>           secondBackground = nullptr;
        std::function<std::optional<SMaterialContrastCurve>(const MaterialScheme&)> contrastCurve    = nullptr;
        std::function<SMaterialToneDeltaPair(const MaterialScheme&)>                toneDeltaPair    = nullptr;

        // DynamicColor.from_palette's default tone: the background's resolved
        // tone, or 50 when there is no background.
        [[nodiscard]] double rawTone(const MaterialScheme& scheme) const {
            if (tone)
                return tone(scheme);
            if (background) {
                const auto bgRole = background(scheme);
                if (bgRole)
                    return scheme.resolveTone(*bgRole);
            }
            return 50.0;
        }
    };

    const SDynamicColorDef& definition(MaterialRole role, bool spec2025);

    MaterialRole            highestSurface(const MaterialScheme& scheme) {
        return scheme.isDark ? MaterialRole::SurfaceBright : MaterialRole::SurfaceDim;
    }

    std::optional<MaterialRole> highestSurfaceRole(const MaterialScheme& scheme) {
        return highestSurface(scheme);
    }

    bool isFixedDimName(MaterialRole role) {
        std::string name = materialRoleName(role);
        std::ranges::transform(name, name.begin(), [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
        return name.ends_with("_fixed_dim") || name.ends_with("fixeddim");
    }

    // ── 2021 base table (color_spec_2021.py) ────────────────────────────────────

    const SDynamicColorDef& def2021(MaterialRole role) {
        switch (role) {
            case MaterialRole::PrimaryPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.primaryPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::SecondaryPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.secondaryPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::TertiaryPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.tertiaryPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::NeutralPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.neutralPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::NeutralVariantPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralVariantPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.neutralVariantPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::ErrorPaletteKeyColor: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone    = [](const MaterialScheme& s) { return s.errorPalette.keyColor.get_tone(); }};
                return def;
            }
            case MaterialRole::Background: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 6.0 : 98.0; },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::OnBackground: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 90.0 : 10.0; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Background); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 3, .medium = 4.5, .high = 7}; }};
                return def;
            }
            case MaterialRole::Surface: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 6.0 : 98.0; },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceDim: {
                static const SDynamicColorDef def{
                    .palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                    .tone = [](const MaterialScheme& s) { return s.isDark ? 6.0 : SMaterialContrastCurve{.low = 87, .normal = 87, .medium = 80, .high = 75}.get(s.contrastLevel); },
                    .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceBright: {
                static const SDynamicColorDef def{
                    .palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                    .tone =
                        [](const MaterialScheme& s) { return s.isDark ? SMaterialContrastCurve{.low = 24, .normal = 24, .medium = 29, .high = 34}.get(s.contrastLevel) : 98.0; },
                    .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceContainerLowest: {
                static const SDynamicColorDef def{
                    .palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                    .tone = [](const MaterialScheme& s) { return s.isDark ? SMaterialContrastCurve{.low = 4, .normal = 4, .medium = 2, .high = 0}.get(s.contrastLevel) : 100.0; },
                    .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceContainerLow: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.isDark ? SMaterialContrastCurve{.low = 10, .normal = 10, .medium = 11, .high = 12}.get(s.contrastLevel) :
                                                                            SMaterialContrastCurve{.low = 96, .normal = 96, .medium = 96, .high = 95}.get(s.contrastLevel);
                                                      },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.isDark ? SMaterialContrastCurve{.low = 12, .normal = 12, .medium = 16, .high = 20}.get(s.contrastLevel) :
                                                                            SMaterialContrastCurve{.low = 94, .normal = 94, .medium = 92, .high = 90}.get(s.contrastLevel);
                                                      },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceContainerHigh: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.isDark ? SMaterialContrastCurve{.low = 17, .normal = 17, .medium = 21, .high = 25}.get(s.contrastLevel) :
                                                                            SMaterialContrastCurve{.low = 92, .normal = 92, .medium = 88, .high = 85}.get(s.contrastLevel);
                                                      },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::SurfaceContainerHighest: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.isDark ? SMaterialContrastCurve{.low = 22, .normal = 22, .medium = 26, .high = 30}.get(s.contrastLevel) :
                                                                            SMaterialContrastCurve{.low = 90, .normal = 90, .medium = 84, .high = 80}.get(s.contrastLevel);
                                                      },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::OnSurface: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 90.0 : 10.0; },
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::SurfaceVariant: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralVariantPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 30.0 : 90.0; },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::OnSurfaceVariant: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralVariantPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 80.0 : 30.0; },
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::InverseSurface: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 90.0 : 20.0; },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::InverseOnSurface: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 20.0 : 95.0; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::InverseSurface); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::Outline: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralVariantPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 60.0 : 50.0; },
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1.5, .normal = 3, .medium = 4.5, .high = 7}; }};
                return def;
            }
            case MaterialRole::OutlineVariant: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralVariantPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 30.0 : 80.0; },
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; }};
                return def;
            }
            case MaterialRole::Shadow: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone    = [](const MaterialScheme&) { return 0.0; }};
                return def;
            }
            case MaterialRole::Scrim: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone    = [](const MaterialScheme&) { return 0.0; }};
                return def;
            }
            case MaterialRole::SurfaceTint: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 80.0 : 40.0; },
                                                  .isBackground = true};
                return def;
            }
            case MaterialRole::Primary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 100.0 : 0.0) : (s.isDark ? 80.0 : 40.0); },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 7}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryContainer,
                                                                                        .roleB        = MaterialRole::Primary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnPrimary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 10.0 : 90.0) : (s.isDark ? 20.0 : 100.0); },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Primary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::PrimaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isFidelity(s) ? s.sourceColor.get_tone() : isMonochrome(s) ? (s.isDark ? 85.0 : 25.0) : (s.isDark ? 30.0 : 90.0);
                                                      },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryContainer,
                                                                                        .roleB        = MaterialRole::Primary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnPrimaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isFidelity(s) ? ForegroundTone(definition(MaterialRole::PrimaryContainer, s.spec2025).rawTone(s), 4.5) :
                                                              isMonochrome(s)  ? (s.isDark ? 0.0 : 100.0) :
                                                                                 (s.isDark ? 90.0 : 30.0);
                                                      },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::InversePrimary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 40.0 : 80.0; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::InverseSurface); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 7}; }};
                return def;
            }
            case MaterialRole::Secondary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 80.0 : 40.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 7}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryContainer,
                                                                                        .roleB        = MaterialRole::Secondary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnSecondary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 10.0 : 100.0) : (s.isDark ? 20.0 : 100.0); },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Secondary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::SecondaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isMonochrome(s) ?
                                                              (s.isDark ? 30.0 : 85.0) :
                                                              isFidelity(s) ?
                                                              findDesiredChromaByTone(s.secondaryPalette.hue, s.secondaryPalette.chroma, s.isDark ? 30.0 : 90.0, !s.isDark) :
                                                              (s.isDark ? 30.0 : 90.0);
                                                      },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryContainer,
                                                                                        .roleB        = MaterialRole::Secondary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnSecondaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isMonochrome(s) ? (s.isDark ? 90.0 : 10.0) :
                                                              isFidelity(s)      ? ForegroundTone(definition(MaterialRole::SecondaryContainer, s.spec2025).rawTone(s), 4.5) :
                                                                                   (s.isDark ? 90.0 : 30.0);
                                                      },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::Tertiary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 90.0 : 25.0) : (s.isDark ? 80.0 : 40.0); },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 7}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryContainer,
                                                                                        .roleB        = MaterialRole::Tertiary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnTertiary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 10.0 : 90.0) : (s.isDark ? 20.0 : 100.0); },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Tertiary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::TertiaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isMonochrome(s) ? (s.isDark ? 60.0 : 49.0) :
                                                              isFidelity(s)      ? FixIfDisliked(Hct(s.tertiaryPalette.tone(s.sourceColor.get_tone()))).get_tone() :
                                                                                   (s.isDark ? 30.0 : 90.0);
                                                      },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryContainer,
                                                                                        .roleB        = MaterialRole::Tertiary,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnTertiaryContainer: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return isMonochrome(s) ? (s.isDark ? 0.0 : 100.0) :
                                                              isFidelity(s)      ? ForegroundTone(definition(MaterialRole::TertiaryContainer, s.spec2025).rawTone(s), 4.5) :
                                                                                   (s.isDark ? 90.0 : 30.0);
                                                      },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::Error: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 80.0 : 40.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 7}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::ErrorContainer,
                                                                                        .roleB        = MaterialRole::Error,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnError: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 20.0 : 100.0; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Error); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::ErrorContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.isDark ? 30.0 : 90.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::ErrorContainer,
                                                                                        .roleB        = MaterialRole::Error,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Nearer,
                                                                                        .stayTogether = false,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnErrorContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? (s.isDark ? 90.0 : 10.0) : (s.isDark ? 90.0 : 30.0); },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::ErrorContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::PrimaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 40.0 : 90.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryFixed,
                                                                                        .roleB        = MaterialRole::PrimaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::PrimaryFixedDim: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 30.0 : 80.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryFixed,
                                                                                        .roleB        = MaterialRole::PrimaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnPrimaryFixed: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone             = [](const MaterialScheme& s) { return isMonochrome(s) ? 100.0 : 10.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::OnPrimaryFixedVariant: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone             = [](const MaterialScheme& s) { return isMonochrome(s) ? 90.0 : 30.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::SecondaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 80.0 : 90.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryFixed,
                                                                                        .roleB        = MaterialRole::SecondaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::SecondaryFixedDim: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 70.0 : 80.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryFixed,
                                                                                        .roleB        = MaterialRole::SecondaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnSecondaryFixed: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone             = [](const MaterialScheme&) { return 10.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::OnSecondaryFixedVariant: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone             = [](const MaterialScheme& s) { return isMonochrome(s) ? 25.0 : 30.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            case MaterialRole::TertiaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 40.0 : 90.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryFixed,
                                                                                        .roleB        = MaterialRole::TertiaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::TertiaryFixedDim: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return isMonochrome(s) ? 30.0 : 80.0; },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 1, .normal = 1, .medium = 3, .high = 4.5}; },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryFixed,
                                                                                        .roleB        = MaterialRole::TertiaryFixedDim,
                                                                                        .delta        = 10,
                                                                                        .polarity     = EMaterialPolarity::Lighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return def;
            }
            case MaterialRole::OnTertiaryFixed: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone             = [](const MaterialScheme& s) { return isMonochrome(s) ? 100.0 : 10.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 4.5, .normal = 7, .medium = 11, .high = 21}; }};
                return def;
            }
            case MaterialRole::OnTertiaryFixedVariant: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone             = [](const MaterialScheme& s) { return isMonochrome(s) ? 90.0 : 30.0; },
                                                  .background       = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixedDim); },
                                                  .secondBackground = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixed); },
                                                  .contrastCurve = [](const MaterialScheme&) { return SMaterialContrastCurve{.low = 3, .normal = 4.5, .medium = 7, .high = 11}; }};
                return def;
            }
            default: break;
        }

        // The *Dim roles have no 2021 definition in materialyoucolor (they return
        // None there); their single definition from color_spec_2025.py is used
        // under both spec versions.
        switch (role) {
            case MaterialRole::PrimaryDim: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.variant == EMaterialVariant::Neutral ? 85.0 :
                                                              s.variant == EMaterialVariant::TonalSpot  ? tMaxC(s.primaryPalette, 0, 90) :
                                                                                                          tMaxC(s.primaryPalette);
                                                      },
                                                  .isBackground  = true,
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SurfaceContainerHigh); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryDim,
                                                                                        .roleB        = MaterialRole::Primary,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return def;
            }
            case MaterialRole::SecondaryDim: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone = [](const MaterialScheme& s) { return s.variant == EMaterialVariant::Neutral ? 85.0 : tMaxC(s.secondaryPalette, 0, 90); },
                                                  .isBackground  = true,
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SurfaceContainerHigh); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryDim,
                                                                                        .roleB        = MaterialRole::Secondary,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return def;
            }
            case MaterialRole::TertiaryDim: {
                static const SDynamicColorDef def{
                    .palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                    .tone          = [](const MaterialScheme& s) { return s.variant == EMaterialVariant::TonalSpot ? tMaxC(s.tertiaryPalette, 0, 90) : tMaxC(s.tertiaryPalette); },
                    .isBackground  = true,
                    .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SurfaceContainerHigh); },
                    .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                    .toneDeltaPair =
                        [](const MaterialScheme&) {
                            return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryDim,
                                                          .roleB        = MaterialRole::Tertiary,
                                                          .delta        = 5,
                                                          .polarity     = EMaterialPolarity::Darker,
                                                          .stayTogether = true,
                                                          .constraint   = EMaterialDeltaConstraint::Farther};
                        }};
                return def;
            }
            case MaterialRole::ErrorDim: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return tMinC(s.errorPalette); },
                                                  .isBackground  = true,
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SurfaceContainerHigh); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::ErrorDim,
                                                                                        .roleB        = MaterialRole::Error,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return def;
            }
            default: break;
        }
        return def2021(MaterialRole::Background); // unreachable
    }

    // ── 2025 overrides (color_spec_2025.py) ─────────────────────────────────────

    double surfaceTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 4.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 99.0;
        return s.variant == EMaterialVariant::Vibrant ? 97.0 : 98.0;
    }

    double surfaceDimTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 4.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 90.0;
        return s.variant == EMaterialVariant::Vibrant ? 85.0 : 87.0;
    }

    double surfaceDimChromaMultiplier2025(const MaterialScheme& s) {
        if (!s.isDark) {
            switch (s.variant) {
                case EMaterialVariant::Neutral: return 2.5;
                case EMaterialVariant::TonalSpot: return 1.7;
                case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 2.7 : 1.75;
                case EMaterialVariant::Vibrant: return 1.36;
                default: break;
            }
        }
        return 1.0;
    }

    double surfaceBrightTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 18.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 99.0;
        return s.variant == EMaterialVariant::Vibrant ? 97.0 : 98.0;
    }

    double surfaceBrightChromaMultiplier2025(const MaterialScheme& s) {
        if (s.isDark) {
            switch (s.variant) {
                case EMaterialVariant::Neutral: return 2.5;
                case EMaterialVariant::TonalSpot: return 1.7;
                case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 2.7 : 1.75;
                case EMaterialVariant::Vibrant: return 1.36;
                default: break;
            }
        }
        return 1.0;
    }

    double surfaceContainerLowTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 6.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 98.0;
        return s.variant == EMaterialVariant::Vibrant ? 95.0 : 96.0;
    }

    double surfaceContainerLowChromaMultiplier2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return 1.3;
            case EMaterialVariant::TonalSpot: return 1.25;
            case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 1.3 : 1.15;
            case EMaterialVariant::Vibrant: return 1.08;
            default: return 1.0;
        }
    }

    double surfaceContainerTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 9.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 96.0;
        return s.variant == EMaterialVariant::Vibrant ? 92.0 : 94.0;
    }

    double surfaceContainerChromaMultiplier2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return 1.6;
            case EMaterialVariant::TonalSpot: return 1.4;
            case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 1.6 : 1.3;
            case EMaterialVariant::Vibrant: return 1.15;
            default: return 1.0;
        }
    }

    double surfaceContainerHighTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 12.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 94.0;
        return s.variant == EMaterialVariant::Vibrant ? 90.0 : 92.0;
    }

    double surfaceContainerHighChromaMultiplier2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return 1.9;
            case EMaterialVariant::TonalSpot: return 1.5;
            case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 1.95 : 1.45;
            case EMaterialVariant::Vibrant: return 1.22;
            default: return 1.0;
        }
    }

    double surfaceContainerHighestTone2025(const MaterialScheme& s) {
        if (s.isDark)
            return 15.0;
        if (isYellowHue(s.neutralPalette.hue))
            return 92.0;
        return s.variant == EMaterialVariant::Vibrant ? 88.0 : 90.0;
    }

    double surfaceContainerHighestChromaMultiplier2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return 2.2;
            case EMaterialVariant::TonalSpot: return 1.7;
            case EMaterialVariant::Expressive: return isYellowHue(s.neutralPalette.hue) ? 2.3 : 1.6;
            case EMaterialVariant::Vibrant: return 1.29;
            default: return 1.0;
        }
    }

    double onSurfaceChromaMultiplier2025(const MaterialScheme& s) {
        if (s.variant == EMaterialVariant::Neutral)
            return 2.2;
        if (s.variant == EMaterialVariant::TonalSpot)
            return 1.7;
        if (s.variant == EMaterialVariant::Expressive)
            return isYellowHue(s.neutralPalette.hue) && s.isDark ? 3.0 : isYellowHue(s.neutralPalette.hue) ? 2.3 : 1.6;
        return 1.0;
    }

    SMaterialContrastCurve onSurfaceContrastCurve2025(const MaterialScheme& s) {
        return s.isDark ? defaultContrastCurve(11) : defaultContrastCurve(9);
    }

    double primaryTone2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return s.isDark ? 80.0 : 40.0;
            case EMaterialVariant::TonalSpot: return s.isDark ? 80.0 : tMaxC(s.primaryPalette);
            case EMaterialVariant::Expressive:
                if (isYellowHue(s.primaryPalette.hue))
                    return tMaxC(s.primaryPalette, 0, 25);
                if (isCyanHue(s.primaryPalette.hue))
                    return tMaxC(s.primaryPalette, 0, 88);
                return tMaxC(s.primaryPalette, 0, 98);
            case EMaterialVariant::Vibrant:
                if (isCyanHue(s.primaryPalette.hue))
                    return tMaxC(s.primaryPalette, 0, 88);
                return tMaxC(s.primaryPalette, 0, 98);
            default: return 0.0;
        }
    }

    SMaterialToneDeltaPair primaryToneDeltaPair2025([[maybe_unused]] const MaterialScheme& scheme) {
        return {.roleA        = MaterialRole::PrimaryContainer,
                .roleB        = MaterialRole::Primary,
                .delta        = 5,
                .polarity     = EMaterialPolarity::RelativeLighter,
                .stayTogether = true,
                .constraint   = EMaterialDeltaConstraint::Farther};
    }

    double primaryContainerTone2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return s.isDark ? 30.0 : 90.0;
            case EMaterialVariant::TonalSpot: return s.isDark ? tMinC(s.primaryPalette, 35, 93) : tMaxC(s.primaryPalette, 0, 90);
            case EMaterialVariant::Expressive:
                if (s.isDark)
                    return tMaxC(s.primaryPalette, 30, 93);
                if (isCyanHue(s.primaryPalette.hue))
                    return tMaxC(s.primaryPalette, 78, 88);
                return tMaxC(s.primaryPalette, 78, 90);
            case EMaterialVariant::Vibrant:
                if (s.isDark)
                    return tMinC(s.primaryPalette, 66, 93);
                if (isCyanHue(s.primaryPalette.hue))
                    return tMaxC(s.primaryPalette, 66, 88);
                return tMaxC(s.primaryPalette, 66, 93);
            default: return 0.0;
        }
    }

    std::optional<MaterialRole> primaryContainerBackground2025(const MaterialScheme& s) {
        return highestSurface(s);
    }

    std::optional<SMaterialContrastCurve> primaryContainerContrastCurve2025(const MaterialScheme& s) {
        if (s.contrastLevel > 0)
            return defaultContrastCurve(1.5);
        return std::nullopt;
    }

    double secondaryTone2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return s.isDark ? tMinC(s.secondaryPalette, 0, 98) : tMaxC(s.secondaryPalette);
            case EMaterialVariant::Vibrant: return s.isDark ? tMaxC(s.secondaryPalette, 0, 90) : tMaxC(s.secondaryPalette, 0, 98);
            default: return s.isDark ? 80.0 : tMaxC(s.secondaryPalette);
        }
    }

    double secondaryContainerTone2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Vibrant: return s.isDark ? tMinC(s.secondaryPalette, 30, 40) : tMaxC(s.secondaryPalette, 84, 90);
            case EMaterialVariant::Expressive: return s.isDark ? 15.0 : tMaxC(s.secondaryPalette, 90, 95);
            default: return s.isDark ? 25.0 : 90.0;
        }
    }

    double tertiaryTone2025(const MaterialScheme& s) {
        if (s.variant == EMaterialVariant::Expressive || s.variant == EMaterialVariant::Vibrant) {
            if (isCyanHue(s.tertiaryPalette.hue))
                return tMaxC(s.tertiaryPalette, 0, 88);
            if (s.isDark)
                return tMaxC(s.tertiaryPalette, 0, 98);
            return tMaxC(s.tertiaryPalette, 0, 100);
        }
        return s.isDark ? tMaxC(s.tertiaryPalette, 0, 98) : tMaxC(s.tertiaryPalette);
    }

    double tertiaryContainerTone2025(const MaterialScheme& s) {
        switch (s.variant) {
            case EMaterialVariant::Neutral: return s.isDark ? tMaxC(s.tertiaryPalette, 0, 93) : tMaxC(s.tertiaryPalette, 0, 96);
            case EMaterialVariant::TonalSpot: return s.isDark ? tMaxC(s.tertiaryPalette, 0, 93) : tMaxC(s.tertiaryPalette, 0, 100);
            case EMaterialVariant::Expressive:
                if (isCyanHue(s.tertiaryPalette.hue))
                    return tMaxC(s.tertiaryPalette, 75, 88);
                if (s.isDark)
                    return tMaxC(s.tertiaryPalette, 75, 93);
                return tMaxC(s.tertiaryPalette, 75, 100);
            case EMaterialVariant::Vibrant: return s.isDark ? tMaxC(s.tertiaryPalette, 0, 93) : tMaxC(s.tertiaryPalette, 72, 100);
            default: return 0.0;
        }
    }

    double errorTone2025(const MaterialScheme& s) {
        return s.isDark ? tMinC(s.errorPalette, 0, 98) : tMaxC(s.errorPalette);
    }

    double errorContainerTone2025(const MaterialScheme& s) {
        return s.isDark ? tMinC(s.errorPalette, 30, 93) : tMaxC(s.errorPalette, 0, 90);
    }

} // namespace

// ─────────────────────────────────────────────────────────────────────────────

namespace {

    // Returns the 2025-specific definition for a role, or nullptr when the role
    // has no 2025 override (extend_spec_version keeps the 2021 definition then).
    const SDynamicColorDef* def2025Override(MaterialRole role) {
        switch (role) {
            case MaterialRole::Surface: {
                static const SDynamicColorDef def{
                    .palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; }, .tone = surfaceTone2025, .isBackground = true};
                return &def;
            }
            case MaterialRole::SurfaceDim: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceDimTone2025,
                                                  .chromaMultiplier = surfaceDimChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceBright: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceBrightTone2025,
                                                  .chromaMultiplier = surfaceBrightChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceContainerLowest: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 0.0 : 100.0; },
                                                  .isBackground = true};
                return &def;
            }
            case MaterialRole::SurfaceContainerLow: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceContainerLowTone2025,
                                                  .chromaMultiplier = surfaceContainerLowChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceContainer: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceContainerTone2025,
                                                  .chromaMultiplier = surfaceContainerChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceContainerHigh: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceContainerHighTone2025,
                                                  .chromaMultiplier = surfaceContainerHighChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceContainerHighest: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceContainerHighestTone2025,
                                                  .chromaMultiplier = surfaceContainerHighestChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::OnSurface: {
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.variant == EMaterialVariant::Vibrant        ? tMaxC(s.neutralPalette, 0, 100, 1.1) :
                                                              highestSurface(s) == MaterialRole::SurfaceBright ? s.resolveTone(MaterialRole::SurfaceBright) :
                                                                                                                 s.resolveTone(MaterialRole::SurfaceDim);
                                                      },
                                                  .chromaMultiplier = onSurfaceChromaMultiplier2025,
                                                  .background       = highestSurfaceRole,
                                                  .contrastCurve    = onSurfaceContrastCurve2025};
                return &def;
            }
            case MaterialRole::OnSurfaceVariant: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .chromaMultiplier = onSurfaceChromaMultiplier2025,
                                                  .background       = highestSurfaceRole,
                                                  .contrastCurve    = [](const MaterialScheme& s) { return s.isDark ? defaultContrastCurve(6) : defaultContrastCurve(4.5); }};
                return &def;
            }
            case MaterialRole::Outline: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .chromaMultiplier = onSurfaceChromaMultiplier2025,
                                                  .background       = highestSurfaceRole,
                                                  .contrastCurve    = [](const MaterialScheme&) { return defaultContrastCurve(3); }};
                return &def;
            }
            case MaterialRole::OutlineVariant: {
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .chromaMultiplier = onSurfaceChromaMultiplier2025,
                                                  .background       = highestSurfaceRole,
                                                  .contrastCurve    = [](const MaterialScheme&) { return defaultContrastCurve(1.5); }};
                return &def;
            }
            case MaterialRole::InverseSurface: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.isDark ? 98.0 : 4.0; },
                                                  .isBackground = true};
                return &def;
            }
            case MaterialRole::InverseOnSurface: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::InverseSurface); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(7); }};
                return &def;
            }
            case MaterialRole::Primary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = primaryTone2025,
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair = primaryToneDeltaPair2025};
                return &def;
            }
            case MaterialRole::OnPrimary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Primary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::PrimaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = primaryContainerTone2025,
                                                  .isBackground  = true,
                                                  .background    = primaryContainerBackground2025,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::OnPrimaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::InversePrimary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return tMaxC(s.primaryPalette); },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::InverseSurface); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::Secondary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = secondaryTone2025,
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryContainer,
                                                                                        .roleB        = MaterialRole::Secondary,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::RelativeLighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return &def;
            }
            case MaterialRole::OnSecondary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Secondary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::SecondaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = secondaryContainerTone2025,
                                                  .isBackground  = true,
                                                  .background    = primaryContainerBackground2025,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::OnSecondaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::Tertiary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = tertiaryTone2025,
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryContainer,
                                                                                        .roleB        = MaterialRole::Tertiary,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::RelativeLighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return &def;
            }
            case MaterialRole::OnTertiary: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Tertiary); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::TertiaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = tertiaryContainerTone2025,
                                                  .isBackground  = true,
                                                  .background    = primaryContainerBackground2025,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::OnTertiaryContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::Error: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = errorTone2025,
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::ErrorContainer,
                                                                                        .roleB        = MaterialRole::Error,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::RelativeLighter,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Farther};
                                                      }};
                return &def;
            }
            case MaterialRole::OnError: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::Error); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(6); }};
                return &def;
            }
            case MaterialRole::ErrorContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .tone          = errorContainerTone2025,
                                                  .isBackground  = true,
                                                  .background    = primaryContainerBackground2025,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::OnErrorContainer: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.errorPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::ErrorContainer); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); }};
                return &def;
            }
            case MaterialRole::SurfaceVariant: {
                // 2025 surfaceVariant is a clone of surfaceContainerHighest.
                static const SDynamicColorDef def{.palette          = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone             = surfaceContainerHighestTone2025,
                                                  .chromaMultiplier = surfaceContainerHighestChromaMultiplier2025,
                                                  .isBackground     = true};
                return &def;
            }
            case MaterialRole::SurfaceTint: {
                // 2025 surfaceTint is a clone of primary.
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = primaryTone2025,
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); },
                                                  .toneDeltaPair = primaryToneDeltaPair2025};
                return &def;
            }
            case MaterialRole::Background: {
                // 2025 background is a clone of surface.
                static const SDynamicColorDef def{
                    .palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; }, .tone = surfaceTone2025, .isBackground = true};
                return &def;
            }
            case MaterialRole::OnBackground: {
                // 2025 onBackground is a clone of onSurface (phone platform).
                static const SDynamicColorDef def{.palette = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.neutralPalette; },
                                                  .tone =
                                                      [](const MaterialScheme& s) {
                                                          return s.variant == EMaterialVariant::Vibrant        ? tMaxC(s.neutralPalette, 0, 100, 1.1) :
                                                              highestSurface(s) == MaterialRole::SurfaceBright ? s.resolveTone(MaterialRole::SurfaceBright) :
                                                                                                                 s.resolveTone(MaterialRole::SurfaceDim);
                                                      },
                                                  .chromaMultiplier = onSurfaceChromaMultiplier2025,
                                                  .background       = highestSurfaceRole,
                                                  .contrastCurve    = onSurfaceContrastCurve2025};
                return &def;
            }
            case MaterialRole::PrimaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.withLightNoContrast().resolveTone(MaterialRole::PrimaryContainer); },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::PrimaryFixedDim: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.resolveTone(MaterialRole::PrimaryFixed); },
                                                  .isBackground = true,
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::PrimaryFixedDim,
                                                                                        .roleB        = MaterialRole::PrimaryFixed,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return &def;
            }
            case MaterialRole::OnPrimaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(7); }};
                return &def;
            }
            case MaterialRole::OnPrimaryFixedVariant: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.primaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::PrimaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); }};
                return &def;
            }
            case MaterialRole::SecondaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.withLightNoContrast().resolveTone(MaterialRole::SecondaryContainer); },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::SecondaryFixedDim: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.resolveTone(MaterialRole::SecondaryFixed); },
                                                  .isBackground = true,
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::SecondaryFixedDim,
                                                                                        .roleB        = MaterialRole::SecondaryFixed,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return &def;
            }
            case MaterialRole::OnSecondaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(7); }};
                return &def;
            }
            case MaterialRole::OnSecondaryFixedVariant: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.secondaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::SecondaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); }};
                return &def;
            }
            case MaterialRole::TertiaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone          = [](const MaterialScheme& s) { return s.withLightNoContrast().resolveTone(MaterialRole::TertiaryContainer); },
                                                  .isBackground  = true,
                                                  .background    = highestSurfaceRole,
                                                  .contrastCurve = [](const MaterialScheme& s) { return primaryContainerContrastCurve2025(s); }};
                return &def;
            }
            case MaterialRole::TertiaryFixedDim: {
                static const SDynamicColorDef def{.palette      = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .tone         = [](const MaterialScheme& s) { return s.resolveTone(MaterialRole::TertiaryFixed); },
                                                  .isBackground = true,
                                                  .toneDeltaPair =
                                                      [](const MaterialScheme&) {
                                                          return SMaterialToneDeltaPair{.roleA        = MaterialRole::TertiaryFixedDim,
                                                                                        .roleB        = MaterialRole::TertiaryFixed,
                                                                                        .delta        = 5,
                                                                                        .polarity     = EMaterialPolarity::Darker,
                                                                                        .stayTogether = true,
                                                                                        .constraint   = EMaterialDeltaConstraint::Exact};
                                                      }};
                return &def;
            }
            case MaterialRole::OnTertiaryFixed: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(7); }};
                return &def;
            }
            case MaterialRole::OnTertiaryFixedVariant: {
                static const SDynamicColorDef def{.palette       = [](const MaterialScheme& s) -> const SMaterialPalette& { return s.tertiaryPalette; },
                                                  .background    = [](const MaterialScheme&) { return std::optional(MaterialRole::TertiaryFixedDim); },
                                                  .contrastCurve = [](const MaterialScheme&) { return defaultContrastCurve(4.5); }};
                return &def;
            }
            default: return nullptr;
        }
    }

    const SDynamicColorDef& definition(MaterialRole role, bool spec2025) {
        if (spec2025)
            if (const SDynamicColorDef* override = def2025Override(role))
                return *override;
        return def2021(role);
    }

} // namespace

// ─────────────────────────────────────────────────────────────────────────────
// Tone/HCT resolution (ColorCalculationDelegateImpl2021 / Impl2025).
// ─────────────────────────────────────────────────────────────────────────────

double MaterialScheme::resolveTone(MaterialRole role) const {
    if (const auto it = mToneCache.find(role); it != mToneCache.end())
        return it->second;

    const SDynamicColorDef& def    = definition(role, spec2025);
    const auto              toneOf = [this](MaterialRole r) { return resolveTone(r); };
    double                  answer = 0.0;

    if (!spec2025) {
        // 2021 delegate.
        const bool decreasingContrast = contrastLevel < 0;
        if (def.toneDeltaPair) {
            const SMaterialToneDeltaPair pair = def.toneDeltaPair(*this);
            const bool                   aIsNearer =
                pair.polarity == EMaterialPolarity::Nearer || (pair.polarity == EMaterialPolarity::Lighter && !isDark) || (pair.polarity == EMaterialPolarity::Darker && isDark);
            const MaterialRole nearer       = aIsNearer ? pair.roleA : pair.roleB;
            const MaterialRole farther      = aIsNearer ? pair.roleB : pair.roleA;
            const bool         amNearer     = role == nearer;
            const double       expansionDir = isDark ? 1.0 : -1.0;
            double             nTone        = definition(nearer, spec2025).rawTone(*this);
            double             fTone        = definition(farther, spec2025).rawTone(*this);

            if (def.background && def.contrastCurve) {
                const auto bgRole = def.background(*this);
                const auto nCurve = definition(nearer, spec2025).contrastCurve ? definition(nearer, spec2025).contrastCurve(*this) : std::nullopt;
                const auto fCurve = definition(farther, spec2025).contrastCurve ? definition(farther, spec2025).contrastCurve(*this) : std::nullopt;
                if (bgRole && nCurve && fCurve) {
                    const double bgTone    = toneOf(*bgRole);
                    const double nContrast = nCurve->get(contrastLevel);
                    const double fContrast = fCurve->get(contrastLevel);
                    if (RatioOfTones(bgTone, nTone) < nContrast)
                        nTone = ForegroundTone(bgTone, nContrast);
                    if (RatioOfTones(bgTone, fTone) < fContrast)
                        fTone = ForegroundTone(bgTone, fContrast);
                    if (decreasingContrast) {
                        nTone = ForegroundTone(bgTone, nContrast);
                        fTone = ForegroundTone(bgTone, fContrast);
                    }
                }
            }

            if ((fTone - nTone) * expansionDir < pair.delta) {
                fTone = clampDouble(0, 100, nTone + pair.delta * expansionDir);
                if ((fTone - nTone) * expansionDir < pair.delta)
                    nTone = clampDouble(0, 100, fTone - pair.delta * expansionDir);
            }

            if (nTone >= 50 && nTone < 60) {
                if (expansionDir > 0) {
                    nTone = 60;
                    fTone = std::max(fTone, nTone + pair.delta * expansionDir);
                } else {
                    nTone = 49;
                    fTone = std::min(fTone, nTone + pair.delta * expansionDir);
                }
            } else if (fTone >= 50 && fTone < 60) {
                if (pair.stayTogether) {
                    if (expansionDir > 0) {
                        nTone = 60;
                        fTone = std::max(fTone, nTone + pair.delta * expansionDir);
                    } else {
                        nTone = 49;
                        fTone = std::min(fTone, nTone + pair.delta * expansionDir);
                    }
                } else {
                    fTone = expansionDir > 0 ? 60.0 : 49.0;
                }
            }
            answer = amNearer ? nTone : fTone;
        } else {
            answer            = def.rawTone(*this);
            auto runtimeCurve = def.contrastCurve ? def.contrastCurve(*this) : std::nullopt;
            if (!def.background || !def.contrastCurve || !runtimeCurve)
                return mToneCache.emplace(role, answer).first->second;

            const auto   bgRole       = def.background(*this);
            const double bgTone       = bgRole ? toneOf(*bgRole) : 50.0;
            const double desiredRatio = runtimeCurve->get(contrastLevel);

            if (RatioOfTones(bgTone, answer) < desiredRatio)
                answer = ForegroundTone(bgTone, desiredRatio);

            if (decreasingContrast)
                answer = ForegroundTone(bgTone, desiredRatio);

            if (def.isBackground && answer >= 50 && answer < 60)
                answer = RatioOfTones(49, bgTone) >= desiredRatio ? 49.0 : 60.0;

            if (!def.secondBackground)
                return mToneCache.emplace(role, answer).first->second;

            const auto bgRole2 = def.secondBackground(*this);
            if (!bgRole2 || !bgRole)
                return mToneCache.emplace(role, answer).first->second;

            const double bgTone1 = toneOf(*bgRole);
            const double bgTone2 = toneOf(*bgRole2);
            const double upper   = std::max(bgTone1, bgTone2);
            const double lower   = std::min(bgTone1, bgTone2);

            if (RatioOfTones(upper, answer) >= desiredRatio && RatioOfTones(lower, answer) >= desiredRatio)
                return mToneCache.emplace(role, answer).first->second;

            const double        lightOption = Lighter(upper, desiredRatio);
            const double        darkOption  = Darker(lower, desiredRatio);

            std::vector<double> availables;
            if (!qFuzzyCompare(lightOption, -1))
                availables.push_back(lightOption);
            if (!qFuzzyCompare(darkOption, -1))
                availables.push_back(darkOption);

            const bool prefersLight = TonePrefersLightForeground(bgTone1) || TonePrefersLightForeground(bgTone2);
            if (prefersLight)
                answer = lightOption < 0 ? 100.0 : lightOption;
            else if (availables.size() == 1)
                answer = availables[0];
            else
                answer = darkOption < 0 ? 0.0 : darkOption;
        }
    } else {
        // 2025 delegate.
        if (def.toneDeltaPair) {
            const SMaterialToneDeltaPair pair = def.toneDeltaPair(*this);

            const double                 absoluteDelta = pair.polarity == EMaterialPolarity::Darker || (pair.polarity == EMaterialPolarity::RelativeLighter && isDark) ||
                    (pair.polarity == EMaterialPolarity::RelativeDarker && !isDark) ?
                                -pair.delta :
                                pair.delta;

            const bool                   amRoleA       = role == pair.roleA;
            const MaterialRole           selfRole      = amRoleA ? pair.roleA : pair.roleB;
            const MaterialRole           refRole       = amRoleA ? pair.roleB : pair.roleA;
            double                       selfTone      = definition(selfRole, spec2025).rawTone(*this);
            const double                 refTone       = toneOf(refRole);
            const double                 relativeDelta = absoluteDelta * (amRoleA ? 1.0 : -1.0);

            switch (pair.constraint) {
                case EMaterialDeltaConstraint::Exact: selfTone = clampDouble(0, 100, refTone + relativeDelta); break;
                case EMaterialDeltaConstraint::Nearer:
                    selfTone = relativeDelta > 0 ? clampDouble(refTone, refTone + relativeDelta, selfTone) : clampDouble(refTone + relativeDelta, refTone, selfTone);
                    break;
                case EMaterialDeltaConstraint::Farther:
                    selfTone = relativeDelta > 0 ? clampDouble(refTone + relativeDelta, 100, selfTone) : clampDouble(0, refTone + relativeDelta, selfTone);
                    break;
            }

            if (def.background && def.contrastCurve) {
                const auto bgRole    = def.background(*this);
                const auto selfCurve = def.contrastCurve(*this);
                if (bgRole && selfCurve) {
                    const double bgTone       = toneOf(*bgRole);
                    const double selfContrast = selfCurve->get(contrastLevel);
                    selfTone                  = RatioOfTones(bgTone, selfTone) >= selfContrast && contrastLevel >= 0 ? selfTone : ForegroundTone(bgTone, selfContrast);
                }
            }

            if (def.isBackground && !isFixedDimName(role))
                selfTone = selfTone >= 57 ? clampDouble(65, 100, selfTone) : clampDouble(0, 49, selfTone);

            answer = selfTone;
        } else {
            answer            = def.rawTone(*this);
            auto runtimeCurve = def.contrastCurve ? def.contrastCurve(*this) : std::nullopt;
            if (!def.background || !def.contrastCurve || !runtimeCurve)
                return mToneCache.emplace(role, answer).first->second;

            const auto   bgRole       = def.background(*this);
            const double bgTone       = bgRole ? toneOf(*bgRole) : 50.0;
            const double desiredRatio = runtimeCurve->get(contrastLevel);

            answer = RatioOfTones(bgTone, answer) >= desiredRatio && contrastLevel >= 0 ? answer : ForegroundTone(bgTone, desiredRatio);

            if (def.isBackground && !isFixedDimName(role))
                answer = answer >= 57 ? clampDouble(65, 100, answer) : clampDouble(0, 49, answer);

            if (!def.secondBackground)
                return mToneCache.emplace(role, answer).first->second;

            const auto bgRole2 = def.secondBackground(*this);
            if (!bgRole2 || !bgRole)
                return mToneCache.emplace(role, answer).first->second;

            const double bgTone1 = toneOf(*bgRole);
            const double bgTone2 = toneOf(*bgRole2);
            const double upper   = std::max(bgTone1, bgTone2);
            const double lower   = std::min(bgTone1, bgTone2);

            if (RatioOfTones(upper, answer) >= desiredRatio && RatioOfTones(lower, answer) >= desiredRatio)
                return mToneCache.emplace(role, answer).first->second;

            const double        lightOption = Lighter(upper, desiredRatio);
            const double        darkOption  = Darker(lower, desiredRatio);

            std::vector<double> availables;
            if (!qFuzzyCompare(lightOption, -1))
                availables.push_back(lightOption);
            if (!qFuzzyCompare(darkOption, -1))
                availables.push_back(darkOption);

            const bool prefersLight = TonePrefersLightForeground(bgTone1) || TonePrefersLightForeground(bgTone2);
            if (prefersLight)
                answer = lightOption < 0 ? 100.0 : lightOption;
            else if (availables.size() == 1)
                answer = availables[0];
            else
                answer = darkOption < 0 ? 0.0 : darkOption;
        }
    }

    return mToneCache.emplace(role, answer).first->second;
}

Hct MaterialScheme::resolveHct(MaterialRole role) const {
    if (const auto it = mHctCache.find(role); it != mHctCache.end())
        return it->second;

    const SDynamicColorDef& def     = definition(role, spec2025);
    const SMaterialPalette& palette = def.palette(*this);
    const double            tone    = resolveTone(role);

    Hct                     hct{0xFF000000u};
    if (spec2025) {
        const double chromaMultiplier = def.chromaMultiplier ? def.chromaMultiplier(*this) : 1.0;
        hct                           = Hct(palette.hue, palette.chroma * chromaMultiplier, tone);
    } else {
        hct = Hct(palette.tone(tone));
    }

    return mHctCache.emplace(role, hct).first->second;
}
