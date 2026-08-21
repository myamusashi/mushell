#pragma once

#include <map>
#include <optional>
#include <vector>

#include "cpp/cam/hct.h"

// Port of materialyoucolor.temperature.temperature_cache.TemperatureCache.
// The vendored C++ implementation predates the Python package's version and
// produces different complements/analogous colors, so this pipeline uses the
// ported one for the Fidelity/Content variants' tertiary palettes.
class MaterialTemperatureCache {
  public:
    explicit MaterialTemperatureCache(const material_color_utilities::Hct& input);

    [[nodiscard]] const material_color_utilities::Hct&       complement();
    [[nodiscard]] std::vector<material_color_utilities::Hct> analogous(int count, int divisions);

  private:
    const std::vector<material_color_utilities::Hct>&      hctsByHue();
    const std::vector<material_color_utilities::Hct>&      hctsByTemp();
    const std::map<material_color_utilities::Hct, double>& tempsByHct();
    double                                                 relativeTemperature(const material_color_utilities::Hct& hct);
    double                                                 inputRelativeTemperature();
    static double                                          rawTemperature(const material_color_utilities::Hct& color);
    static bool                                            isBetween(double angle, double a, double b);

    material_color_utilities::Hct                          mInput{0xFF000000u};
    std::vector<material_color_utilities::Hct>             mHctsByTempCache;
    std::vector<material_color_utilities::Hct>             mHctsByHueCache;
    std::map<material_color_utilities::Hct, double>        mTempsByHctCache;
    double                                                 mInputRelativeTemperatureCache = -1.0;
    std::optional<material_color_utilities::Hct>           mComplementCache;
};
