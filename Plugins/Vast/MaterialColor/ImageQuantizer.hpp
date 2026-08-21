#pragma once

#include <qstring.h>

#include "cpp/utils/utils.h"

material_color_utilities::Argb quantizeImage(const QString& imagePath, int bitmapSize = 128);
