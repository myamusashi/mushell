#pragma once

#include <qcontainerfwd.h>
#include <qmap.h>
#include <qvariant.h>
#include <qstring.h>

#include "cpp/cam/hct.h"
#include "cpp/utils/utils.h"

struct SMaterialPaletteResult {
    QMap<QString, QString>         colors;
    material_color_utilities::Argb sourceColor = 0xFF000000u;
    material_color_utilities::Hct  sourceHct{0xFF000000u};
    QString                        error;
    int                            imageWidth  = 0;
    int                            imageHeight = 0;
};

inline QVariantMap colorsToVariantMap(const QMap<QString, QString>& colors) {
    QVariantMap map;
    for (auto it = colors.constBegin(); it != colors.constEnd(); ++it)
        map.insert(it.key(), it.value());
    return map;
}

SMaterialPaletteResult buildPalette(const QString& imagePath, const QString& mode, const QString& scheme, bool smart, int bitmapSize = 128, double contrastLevel = 0.0);
