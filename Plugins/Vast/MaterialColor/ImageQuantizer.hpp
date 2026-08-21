#pragma once

#include <qstring.h>

#include "cpp/utils/utils.h"

// Decodes an image file and produces the dominant ARGB color via MCU's
// Celebi quantizer + scoring, mirroring the Python script's image path.
material_color_utilities::Argb quantizeImage(const QString& imagePath, int bitmapSize = 128);
