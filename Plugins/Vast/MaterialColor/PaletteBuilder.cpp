#include "PaletteBuilder.hpp"

#include <qchar.h>
#include <utility>
#include <qmap.h>
#include <qstring.h>
#include <qlatin1stringview.h>

#include "ImageQuantizer.hpp"
#include "MaterialRoles.hpp"
#include "PaletteValidation.hpp"

#include "cpp/cam/hct.h"
#include "cpp/utils/utils.h"
using material_color_utilities::Argb;
using material_color_utilities::Hct;

namespace {

    EMaterialVariant variantFromScheme(const QString& scheme) {
        if (scheme == QLatin1String("neutral"))
            return EMaterialVariant::Neutral;
        if (scheme == QLatin1String("vibrant"))
            return EMaterialVariant::Vibrant;
        if (scheme == QLatin1String("expressive"))
            return EMaterialVariant::Expressive;
        if (scheme == QLatin1String("fruit-salad"))
            return EMaterialVariant::FruitSalad;
        if (scheme == QLatin1String("monochrome"))
            return EMaterialVariant::Monochrome;
        if (scheme == QLatin1String("rainbow"))
            return EMaterialVariant::Rainbow;
        if (scheme == QLatin1String("fidelity"))
            return EMaterialVariant::Fidelity;
        if (scheme == QLatin1String("content"))
            return EMaterialVariant::Content;
        return EMaterialVariant::TonalSpot;
    }

    QString argbToHex(Argb argb) {
        return QStringLiteral("#%1%2%3").arg((argb >> 16) & 0xFF, 2, 16, QChar('0')).arg((argb >> 8) & 0xFF, 2, 16, QChar('0')).arg(argb & 0xFF, 2, 16, QChar('0')).toUpper();
    }

    void addSuccessColors(QMap<QString, QString>& colors, bool darkmode) {
        if (darkmode) {
            colors[QStringLiteral("success")]            = QStringLiteral("#B5CCBA");
            colors[QStringLiteral("onSuccess")]          = QStringLiteral("#213528");
            colors[QStringLiteral("successContainer")]   = QStringLiteral("#374B3E");
            colors[QStringLiteral("onSuccessContainer")] = QStringLiteral("#D1E9D6");
        } else {
            colors[QStringLiteral("success")]            = QStringLiteral("#4F6354");
            colors[QStringLiteral("onSuccess")]          = QStringLiteral("#FFFFFF");
            colors[QStringLiteral("successContainer")]   = QStringLiteral("#D1E8D5");
            colors[QStringLiteral("onSuccessContainer")] = QStringLiteral("#0C1F13");
        }
    }

} // namespace

SMaterialPaletteResult buildPalette(const QString& imagePath, const QString& mode, const QString& scheme, bool smart, int bitmapSize, double contrastLevel) {
    SMaterialPaletteResult result;

    const bool             darkmode = mode == QLatin1String("dark");

    const Argb             argb = quantizeImage(imagePath, bitmapSize);
    if (argb == 0) {
        result.error = QStringLiteral("failed to decode image: %1").arg(imagePath);
        return result;
    }

    result.sourceColor = argb;
    result.sourceHct   = Hct(argb);

    QString effectiveScheme = scheme;
    if (smart && result.sourceHct.get_chroma() < 20)
        effectiveScheme = QStringLiteral("neutral");

    const MaterialScheme materialScheme(result.sourceHct, variantFromScheme(effectiveScheme), darkmode, contrastLevel);

    for (int i = 0; i < static_cast<int>(MaterialRole::Count); i++) {
        const auto role                       = static_cast<MaterialRole>(i);
        result.colors[materialRoleName(role)] = argbToHex(materialScheme.resolveHct(role).ToInt());
    }

    addSuccessColors(result.colors, darkmode);
    result.colors[QStringLiteral("sourceColor")] = argbToHex(argb);

    fixSurfaceExtremes(result.colors);

    QString validationError;
    if (!validatePalette(result.colors, validationError)) {
        result.error = std::move(validationError);
        return result;
    }

    return result;
}
