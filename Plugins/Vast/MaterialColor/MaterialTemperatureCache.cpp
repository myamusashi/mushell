#include "MaterialTemperatureCache.hpp"

#include "MaterialPalette.hpp"
#include "cpp/cam/hct.h"

#include <algorithm>
#include <cmath>
#include <cstddef>
#include <map>
#include <numbers>
#include <utility>
#include <vector>

#include "cpp/quantize/lab.h"
#include "cpp/utils/utils.h"

using material_color_utilities::Argb;
using material_color_utilities::Hct;
using material_color_utilities::Lab;
using material_color_utilities::LabFromInt;
using material_color_utilities::SanitizeDegreesDouble;

namespace {

    double sanitizeDegreesInt(int degrees) {
        const double formatted = std::fmod(static_cast<double>(degrees), 360.0);
        return formatted < 0 ? formatted + 360.0 : formatted;
    }

} // namespace

MaterialTemperatureCache::MaterialTemperatureCache(const Hct& input) : mInput(input) {}

const std::vector<Hct>& MaterialTemperatureCache::hctsByHue() {
    if (!mHctsByHueCache.empty())
        return mHctsByHueCache;

    mHctsByHueCache.reserve(361);
    for (int hue = 0; hue <= 360; hue++)
        mHctsByHueCache.emplace_back(static_cast<double>(hue), mInput.get_chroma(), mInput.get_tone());
    return mHctsByHueCache;
}

const std::map<Hct, double>& MaterialTemperatureCache::tempsByHct() {
    if (!mTempsByHctCache.empty())
        return mTempsByHctCache;

    for (const Hct& hct : hctsByHue())
        mTempsByHctCache.emplace(hct, rawTemperature(hct));
    mTempsByHctCache.emplace(mInput, rawTemperature(mInput));
    return mTempsByHctCache;
}

const std::vector<Hct>& MaterialTemperatureCache::hctsByTemp() {
    if (!mHctsByTempCache.empty())
        return mHctsByTempCache;

    const auto& temps = tempsByHct();
    mHctsByTempCache  = hctsByHue();
    mHctsByTempCache.push_back(mInput);
    std::ranges::stable_sort(mHctsByTempCache, [&temps](const Hct& a, const Hct& b) {
        const auto ia = temps.find(a);
        const auto ib = temps.find(b);
        return (ia != temps.end() ? ia->second : 0.0) < (ib != temps.end() ? ib->second : 0.0);
    });
    return mHctsByTempCache;
}

double MaterialTemperatureCache::rawTemperature(const Hct& color) {
    const Lab    lab    = LabFromInt(color.ToInt());
    const double hue    = SanitizeDegreesDouble(std::atan2(lab.b, lab.a) * 180.0 / std::numbers::pi);
    const double chroma = std::sqrt(lab.a * lab.a + lab.b * lab.b);
    return -0.5 + 0.02 * std::pow(chroma, 1.07) * std::cos(SanitizeDegreesDouble(hue - 50.0) * std::numbers::pi / 180.0);
}

bool MaterialTemperatureCache::isBetween(double angle, double a, double b) {
    if (a < b)
        return a <= angle && angle <= b;
    return a <= angle || angle <= b;
}

double MaterialTemperatureCache::relativeTemperature(const Hct& hct) {
    const auto&  temps                 = tempsByHct();
    const double rangeTemp             = temps.at(hctsByTemp().back()) - temps.at(hctsByTemp().front());
    const double differenceFromColdest = temps.at(hct) - temps.at(hctsByTemp().front());
    if (std::fpclassify(rangeTemp) == FP_ZERO)
        return 0.5;
    return differenceFromColdest / rangeTemp;
}

double MaterialTemperatureCache::inputRelativeTemperature() {
    if (mInputRelativeTemperatureCache >= 0.0)
        return mInputRelativeTemperatureCache;
    mInputRelativeTemperatureCache = relativeTemperature(mInput);
    return mInputRelativeTemperatureCache;
}

const Hct& MaterialTemperatureCache::complement() {
    if (mComplementCache)
        return *mComplementCache;

    const auto&  huesByIndex = hctsByHue();
    const auto&  temps       = tempsByHct();

    const Hct&   coldest     = hctsByTemp().front();
    const Hct&   warmest     = hctsByTemp().back();
    const double coldestHue  = coldest.get_hue();
    const double coldestTemp = temps.at(coldest);
    const double warmestHue  = warmest.get_hue();
    const double warmestTemp = temps.at(warmest);
    const double rangeTemp   = warmestTemp - coldestTemp;

    if (std::fpclassify(rangeTemp) == FP_ZERO) {
        mComplementCache = huesByIndex[static_cast<size_t>(roundHalfToEven(mInput.get_hue()))];
        return *mComplementCache;
    }

    const bool       startHueIsColdestToWarmest = isBetween(mInput.get_hue(), coldestHue, warmestHue);
    const double     startHue                   = startHueIsColdestToWarmest ? warmestHue : coldestHue;
    const double     endHue                     = startHueIsColdestToWarmest ? coldestHue : warmestHue;
    constexpr double directionOfRotation        = 1.0;
    double           smallestError              = 1000.0;
    const Hct*       answer                     = &huesByIndex[static_cast<size_t>(roundHalfToEven(mInput.get_hue()))];

    const double     complementRelativeTemp = 1.0 - inputRelativeTemperature();
    for (int hueAddend = 0; hueAddend <= 360; hueAddend++) {
        const double hue = SanitizeDegreesDouble(startHue + directionOfRotation * hueAddend);
        if (!isBetween(hue, startHue, endHue))
            continue;
        const Hct&   possibleAnswer = huesByIndex[static_cast<size_t>(roundHalfToEven(hue))];
        const double relativeTemp   = (temps.at(possibleAnswer) - coldestTemp) / rangeTemp;
        const double error          = std::abs(complementRelativeTemp - relativeTemp);
        if (error < smallestError) {
            smallestError = error;
            answer        = &possibleAnswer;
        }
    }

    mComplementCache = *answer;
    return *mComplementCache;
}

std::vector<Hct> MaterialTemperatureCache::analogous(int count, int divisions) {
    const auto&      huesByIndex = hctsByHue();
    const int        startHue    = roundHalfToEven(mInput.get_hue());
    const Hct        startHct    = huesByIndex[static_cast<size_t>(startHue)];
    double           lastTemp    = relativeTemperature(startHct);
    std::vector<Hct> allColors{startHct};

    double           absoluteTotalTempDelta = 0.0;
    for (int i = 0; i < 360; i++) {
        const double hue       = sanitizeDegreesInt(startHue + i);
        const Hct&   hct       = huesByIndex[static_cast<size_t>(hue)];
        const double temp      = relativeTemperature(hct);
        const double tempDelta = std::abs(temp - lastTemp);
        lastTemp               = temp;
        absoluteTotalTempDelta += tempDelta;
    }

    int          hueAddend      = 1;
    const double tempStep       = absoluteTotalTempDelta / divisions;
    double       totalTempDelta = 0.0;
    lastTemp                    = relativeTemperature(startHct);

    while (std::cmp_less(allColors.size(), divisions)) {
        const double hue       = sanitizeDegreesInt(startHue + hueAddend);
        const Hct&   hct       = huesByIndex[static_cast<size_t>(hue)];
        const double temp      = relativeTemperature(hct);
        const double tempDelta = std::abs(temp - lastTemp);
        totalTempDelta += tempDelta;

        double desiredTotalTempDeltaForIndex = static_cast<double>(allColors.size()) * tempStep;
        bool   indexSatisfied                = totalTempDelta >= desiredTotalTempDeltaForIndex;
        int    indexAddend                   = 1;

        while (indexSatisfied && std::cmp_less(allColors.size(), divisions)) {
            allColors.push_back(hct);
            desiredTotalTempDeltaForIndex = static_cast<double>(allColors.size() + static_cast<size_t>(indexAddend)) * tempStep;
            indexSatisfied                = totalTempDelta >= desiredTotalTempDeltaForIndex;
            indexAddend++;
        }

        lastTemp = temp;
        hueAddend++;

        if (hueAddend > 360) {
            while (std::cmp_less(allColors.size(), divisions))
                allColors.push_back(hct);
            break;
        }
    }

    std::vector<Hct> answers{mInput};

    const int        increaseHueCount = static_cast<int>(std::floor((count - 1) / 2.0));
    for (int i = 1; i <= increaseHueCount; i++) {
        int index = 0 - i;
        while (index < 0)
            index += static_cast<int>(allColors.size());
        if (std::cmp_greater_equal(index, allColors.size()))
            index %= static_cast<int>(allColors.size());
        answers.insert(answers.begin(), allColors[static_cast<size_t>(index)]);
    }

    const int decreaseHueCount = count - increaseHueCount - 1;
    for (int i = 1; i <= decreaseHueCount; i++) {
        int index = i;
        while (index < 0)
            index += static_cast<int>(allColors.size());
        if (std::cmp_greater_equal(index, allColors.size()))
            index %= static_cast<int>(allColors.size());
        answers.push_back(allColors[static_cast<size_t>(index)]);
    }

    return answers;
}
