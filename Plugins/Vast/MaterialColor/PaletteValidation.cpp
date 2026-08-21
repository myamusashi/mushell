#include "PaletteValidation.hpp"

#include <qchar.h>
#include <qlatin1stringview.h>
#include <qlist.h>
#include <qmap.h>
#include <qstring.h>
#include <QtCore/qnamespace.h>
#include <QtGlobal>
#include <cmath>
#include <utility>

#include "cpp/cam/hct.h"
#include "cpp/utils/utils.h"

using material_color_utilities::Argb;
using material_color_utilities::Hct;

namespace {

    material_color_utilities::Argb hexToArgb(const QString& hex) {
        return 0xFF000000u | static_cast<material_color_utilities::Argb>(hex.mid(1, 2).toUInt(nullptr, 16)) << 16 |
            static_cast<material_color_utilities::Argb>(hex.mid(3, 2).toUInt(nullptr, 16)) << 8 | static_cast<material_color_utilities::Argb>(hex.mid(5, 2).toUInt(nullptr, 16));
    }

    QString argbToHex(const Hct& hct) {
        const Argb argb = hct.ToInt();
        return QStringLiteral("#%1%2%3").arg((argb >> 16) & 0xFF, 2, 16, QChar('0')).arg((argb >> 8) & 0xFF, 2, 16, QChar('0')).arg(argb & 0xFF, 2, 16, QChar('0')).toUpper();
    }

    // SURFACE_ROLES in the Python script: every required role whose name
    // contains "surface" (substring match — includes onSurface etc.).
    bool isSurfaceRole(const QString& role) {
        return role.contains(QStringLiteral("surface"), Qt::CaseInsensitive);
    }

} // namespace

const QList<QString>& requiredRoles() {
    static const QList<QString> roles{
        QStringLiteral("background"),
        QStringLiteral("onBackground"),
        QStringLiteral("surface"),
        QStringLiteral("surfaceDim"),
        QStringLiteral("surfaceBright"),
        QStringLiteral("surfaceContainerLowest"),
        QStringLiteral("surfaceContainerLow"),
        QStringLiteral("surfaceContainer"),
        QStringLiteral("surfaceContainerHigh"),
        QStringLiteral("surfaceContainerHighest"),
        QStringLiteral("onSurface"),
        QStringLiteral("surfaceVariant"),
        QStringLiteral("onSurfaceVariant"),
        QStringLiteral("outline"),
        QStringLiteral("outlineVariant"),
        QStringLiteral("shadow"),
        QStringLiteral("scrim"),
        QStringLiteral("surfaceTint"),
        QStringLiteral("primary"),
        QStringLiteral("onPrimary"),
        QStringLiteral("primaryContainer"),
        QStringLiteral("onPrimaryContainer"),
        QStringLiteral("error"),
        QStringLiteral("onError"),
        QStringLiteral("errorContainer"),
        QStringLiteral("onErrorContainer"),
    };
    return roles;
}

bool fixSurfaceExtremes(QMap<QString, QString>& colors) {
    const auto keyColorIt = colors.constFind(QStringLiteral("neutralPaletteKeyColor"));
    Hct        neutral(50, 8, 50);
    if (keyColorIt != colors.constEnd() && keyColorIt->length() == 7)
        neutral = Hct(hexToArgb(*keyColorIt));

    for (const QString& role : requiredRoles()) {
        if (!isSurfaceRole(role))
            continue;

        const auto it = colors.constFind(role);
        if (it == colors.constEnd())
            continue;

        if (it->compare(QStringLiteral("#000000"), Qt::CaseInsensitive) == 0)
            colors[role] = argbToHex(Hct(neutral.get_hue(), neutral.get_chroma() * 0.25, 5.0));
        else if (it->compare(QStringLiteral("#FFFFFF"), Qt::CaseInsensitive) == 0)
            colors[role] = argbToHex(Hct(neutral.get_hue(), neutral.get_chroma() * 0.25, 99.0));
    }
    return true;
}

bool validatePalette(const QMap<QString, QString>& colors, QString& error) {
    for (const QString& role : requiredRoles()) {
        if (!colors.contains(role)) {
            error = QStringLiteral("missing roles: %1").arg(role);
            return false;
        }
    }

    for (const QString& role : requiredRoles()) {
        const QString value = colors.value(role).toUpper();
        if (value.length() != 7 || !value.startsWith(QLatin1Char('#'))) {
            error = QStringLiteral("role %1 is not a hex color: %2").arg(role, colors.value(role));
            return false;
        }
    }

    for (const QString& role : requiredRoles()) {
        if (!isSurfaceRole(role))
            continue;

        const QString value = colors.value(role).toUpper();
        if (value == QLatin1String("#000000") || value == QLatin1String("#FFFFFF")) {
            error = QStringLiteral("surface role %1 is pure %2").arg(role, colors.value(role));
            return false;
        }
    }

    static const QList<std::pair<QString, QString>> contrastPairs{
        {QStringLiteral("onSurface"), QStringLiteral("surface")},
        {QStringLiteral("onPrimary"), QStringLiteral("primary")},
        {QStringLiteral("onError"), QStringLiteral("error")},
        {QStringLiteral("onSurfaceVariant"), QStringLiteral("surfaceVariant")},
        {QStringLiteral("onPrimaryContainer"), QStringLiteral("primaryContainer")},
    };

    for (const auto& [fg, bg] : contrastPairs) {
        const double fgTone = Hct(hexToArgb(colors.value(fg))).get_tone();
        const double bgTone = Hct(hexToArgb(colors.value(bg))).get_tone();
        if (std::abs(fgTone - bgTone) < 40) {
            error = QStringLiteral("low contrast: %1 vs %2 tone gap %3").arg(fg, bg).arg(std::abs(fgTone - bgTone));
            return false;
        }
    }

    return true;
}
