#pragma once

#include <cstdint>
#include <map>

#include "MaterialPalette.hpp"
#include "cpp/utils/utils.h"

// Dynamic color roles, in materialyoucolor's COLOR_NAMES order. The ordinal
// doubles as the JSON key via materialRoleName().
enum class MaterialRole : std::uint8_t {
    Background,
    OnBackground,
    Surface,
    SurfaceDim,
    SurfaceBright,
    SurfaceContainerLowest,
    SurfaceContainerLow,
    SurfaceContainer,
    SurfaceContainerHigh,
    SurfaceContainerHighest,
    OnSurface,
    SurfaceVariant,
    OnSurfaceVariant,
    Outline,
    OutlineVariant,
    InverseSurface,
    InverseOnSurface,
    Shadow,
    Scrim,
    SurfaceTint,
    Primary,
    PrimaryDim,
    OnPrimary,
    PrimaryContainer,
    OnPrimaryContainer,
    InversePrimary,
    PrimaryFixed,
    PrimaryFixedDim,
    OnPrimaryFixed,
    OnPrimaryFixedVariant,
    Secondary,
    SecondaryDim,
    OnSecondary,
    SecondaryContainer,
    OnSecondaryContainer,
    SecondaryFixed,
    SecondaryFixedDim,
    OnSecondaryFixed,
    OnSecondaryFixedVariant,
    Tertiary,
    TertiaryDim,
    OnTertiary,
    TertiaryContainer,
    OnTertiaryContainer,
    TertiaryFixed,
    TertiaryFixedDim,
    OnTertiaryFixed,
    OnTertiaryFixedVariant,
    Error,
    ErrorDim,
    OnError,
    ErrorContainer,
    OnErrorContainer,
    PrimaryPaletteKeyColor,
    SecondaryPaletteKeyColor,
    TertiaryPaletteKeyColor,
    NeutralPaletteKeyColor,
    NeutralVariantPaletteKeyColor,
    ErrorPaletteKeyColor,

    Count,
};

const char* materialRoleName(MaterialRole role);

// Scheme variants supported by generate_colors_material.py's --scheme.
enum class EMaterialVariant : std::uint8_t {
    TonalSpot,
    Neutral,
    Vibrant,
    Expressive,
    FruitSalad,
    Monochrome,
    Rainbow,
    Fidelity,
    Content,
};

struct SMaterialContrastCurve {
    double               low    = 0.0;
    double               normal = 0.0;
    double               medium = 0.0;
    double               high   = 0.0;

    [[nodiscard]] double get(double contrastLevel) const {
        if (contrastLevel <= -1.0)
            return low;
        if (contrastLevel < 0.0)
            return material_color_utilities::Lerp(low, normal, (contrastLevel - (-1)) / 1);
        if (contrastLevel < 0.5)
            return material_color_utilities::Lerp(normal, medium, (contrastLevel - 0) / 0.5);
        if (contrastLevel < 1.0)
            return material_color_utilities::Lerp(medium, high, (contrastLevel - 0.5) / 0.5);
        return high;
    }
};

// get_curve() from color_spec_2025.py: canonical curves for known defaults.
SMaterialContrastCurve defaultContrastCurve(double defaultContrast);

enum class EMaterialPolarity : std::uint8_t {
    Darker,
    Lighter,
    Nearer,
    Farther,
    RelativeDarker,
    RelativeLighter,
};

enum class EMaterialDeltaConstraint : std::uint8_t {
    Exact,
    Nearer,
    Farther,
};

struct SMaterialToneDeltaPair {
    MaterialRole             roleA        = MaterialRole::Background;
    MaterialRole             roleB        = MaterialRole::Background;
    double                   delta        = 0.0;
    EMaterialPolarity        polarity     = EMaterialPolarity::Darker;
    bool                     stayTogether = false;
    EMaterialDeltaConstraint constraint   = EMaterialDeltaConstraint::Exact;
};

// A dynamic color scheme: source color + variant + mode + the five derived
// tonal palettes. Tone/HCT resolution per role goes through resolveTone()/
// resolveHct(), which implement materialyoucolor's 2021 and 2025 calculation
// delegates and memoize per instance (mirroring DynamicColor.hct_cache).
struct MaterialScheme {
    material_color_utilities::Hct sourceColor{0xFF000000u};
    EMaterialVariant              variant       = EMaterialVariant::TonalSpot;
    bool                          isDark        = true;
    double                        contrastLevel = 0.0;

    SMaterialPalette              primaryPalette;
    SMaterialPalette              secondaryPalette;
    SMaterialPalette              tertiaryPalette;
    SMaterialPalette              neutralPalette;
    SMaterialPalette              neutralVariantPalette;
    SMaterialPalette              errorPalette;

    // Effective spec version: requested spec is kept only for the variants
    // materialyoucolor's _maybe_fallback_spec_version allows; everything else
    // resolves under the 2021 spec.
    bool spec2025 = false;

    explicit MaterialScheme(material_color_utilities::Hct sourceColorHct, EMaterialVariant schemeVariant, bool dark, double contrast);

    // Variant used by the 2025 fixed roles: same palettes, light mode and
    // zero contrast (mirrors _primary_fixed_tone_2025's temporary scheme).
    [[nodiscard]] MaterialScheme                withLightNoContrast() const;

    [[nodiscard]] double                        resolveTone(MaterialRole role) const;
    [[nodiscard]] material_color_utilities::Hct resolveHct(MaterialRole role) const;

  private:
    mutable std::map<MaterialRole, double>                        mToneCache;
    mutable std::map<MaterialRole, material_color_utilities::Hct> mHctCache;
};
