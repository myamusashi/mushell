#include "ImageQuantizer.hpp"

#include <qbytearray.h>
#include <qdatastream.h>
#include <qfile.h>
#include <qimage.h>
#include <qimagereader.h>
#include <QtGui/qrgb.h>
#include <QtGlobal>
#include <algorithm>
#include <ranges>
#include <span>
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <utility>
#include <vector>

#include "cpp/quantize/celebi.h"
#include "cpp/quantize/wsmeans.h"
#include "cpp/score/score.h"
#include "cpp/utils/utils.h"

using material_color_utilities::Argb;
using material_color_utilities::QuantizeCelebi;
using material_color_utilities::QuantizerResult;
using material_color_utilities::RankedSuggestions;

namespace {

    std::pair<int, int> calculateOptimalSize(int width, int height, int bitmapSize) {
        const double imageArea  = width * height;
        const double bitmapArea = static_cast<double>(bitmapSize) * bitmapSize;
        const double scale      = imageArea > bitmapArea ? std::sqrt(bitmapArea / imageArea) : 1.0;
        int          newWidth   = static_cast<int>(std::round(width * scale));
        int          newHeight  = static_cast<int>(std::round(height * scale));
        newWidth                = std::max(newWidth, 1);
        newHeight               = std::max(newHeight, 1);
        return {newWidth, newHeight};
    }

    double bicubicFilter(double x) {
        const double coeff = -0.5;
        const double absX  = std::fabs(x);
        if (absX < 1) {
            const double x2 = absX * absX;
            return ((coeff + 2) * absX - (coeff + 3)) * x2 + 1;
        }
        if (absX < 2) {
            return (((absX - 5) * absX + 8) * absX - 4) * coeff;
        }
        return 0.0;
    }

    constexpr int     K_PRECISION_BITS = 22;
    constexpr int32_t K_ROUNDING_BIAS  = 1 << (K_PRECISION_BITS - 1);

    struct SResizeWeights {
        std::vector<int>                  mins;
        std::vector<std::vector<int32_t>> weights;
    };

    // precompute_coeffs() from Pillow's Resample.c (double precision stage).
    SResizeWeights makeWeights(int inSize, int outSize) {
        SResizeWeights result;
        result.mins.resize(static_cast<size_t>(outSize));
        result.weights.resize(static_cast<size_t>(outSize));

        double scale = static_cast<double>(inSize) / outSize;
        scale        = std::max(scale, 1.0);

        constexpr double    kSupport = 2.0;
        const double        support  = kSupport * scale;
        const double        invScale = 1.0 / scale;

        std::vector<double> kk;
        for (int xx = 0; xx < outSize; xx++) {
            const double center = (xx + 0.5) * scale;
            // Truncating casts on purpose: Pillow's precompute_coeffs uses C
            // (int) casts, and lround's half-away-from-zero flips a tap at
            // exact .5 boundaries, shifting fixed-point coefficients.
            // NOLINTNEXTLINE(bugprone-incorrect-roundings)
            int xmin = static_cast<int>(center - support + 0.5);
            xmin     = std::max(xmin, 0);
            // NOLINTNEXTLINE(bugprone-incorrect-roundings)
            int xmax = static_cast<int>(center + support + 0.5);
            xmax     = std::min(xmax, inSize);
            xmax -= xmin;

            kk.assign(static_cast<size_t>(xmax), 0.0);
            double ww = 0.0;
            for (int x = 0; x < xmax; x++) {
                const double w             = bicubicFilter((x + xmin - center + 0.5) * invScale);
                kk[static_cast<size_t>(x)] = w;
                ww += w;
            }
            if (std::fpclassify(ww) != FP_ZERO) {
                for (int x = 0; x < xmax; x++)
                    kk[static_cast<size_t>(x)] /= ww;
            }

            // normalize_coeffs_8bpc(): quantize to fixed point.
            std::vector<int32_t> ints(static_cast<size_t>(xmax));
            for (int x = 0; x < xmax; x++) {
                const double w               = kk[static_cast<size_t>(x)];
                ints[static_cast<size_t>(x)] = static_cast<int32_t>(w < 0 ? -0.5 + w * (1 << K_PRECISION_BITS) : 0.5 + w * (1 << K_PRECISION_BITS));
            }

            result.mins[static_cast<size_t>(xx)]    = xmin;
            result.weights[static_cast<size_t>(xx)] = ints;
        }
        return result;
    }

    // clip8(): lookup-table equivalent of Pillow's clip8_lookups.
    inline uint8_t clip8(int32_t v) {
        const auto shifted = static_cast<int32_t>(v >> K_PRECISION_BITS);
        return static_cast<uint8_t>(std::clamp(shifted, 0, 255));
    }

    // Pillow's MULDIV255: rounded (a*b)/255.
    inline int mulDiv255(const int A, const int B) {
        const int tmp = A * B + 128;
        return (tmp + (tmp >> 8)) >> 8;
    }

    // Separable bicubic resample, fixed-point port of Pillow's
    // _ImagingResample{Horizontal,Vertical}_8bpc. When processAlpha is set the
    // alpha band is resampled alongside RGB (needed for premultiplied input).
    QImage resizeBicubic(const QImage& source, int newWidth, int newHeight, const bool PROCESS_ALPHA) {
        const QImage in = source.convertToFormat(PROCESS_ALPHA ? QImage::Format_ARGB32 : QImage::Format_RGB32);

        // Horizontal pass.
        QImage mid(newWidth, in.height(), QImage::Format_RGB32);
        {
            const SResizeWeights wx = makeWeights(in.width(), newWidth);
            for (int y = 0; y < in.height(); y++) {
                const auto srcLine = std::span<const QRgb>(reinterpret_cast<const QRgb*>(in.constScanLine(y)), static_cast<size_t>(in.width()));
                auto       dstLine = std::span<QRgb>(reinterpret_cast<QRgb*>(mid.scanLine(y)), static_cast<size_t>(newWidth));
                for (int x = 0; x < newWidth; x++) {
                    const std::vector<int32_t>& taps = wx.weights[static_cast<size_t>(x)];
                    const int                   xmin = wx.mins[static_cast<size_t>(x)];
                    int32_t                     r    = K_ROUNDING_BIAS;
                    int32_t                     g    = K_ROUNDING_BIAS;
                    int32_t                     b    = K_ROUNDING_BIAS;
                    int32_t                     a    = K_ROUNDING_BIAS;
                    for (size_t i = 0; i < taps.size(); i++) {
                        const QRgb px = srcLine[static_cast<size_t>(xmin) + i];
                        r += static_cast<int32_t>(qRed(px)) * taps[i];
                        g += static_cast<int32_t>(qGreen(px)) * taps[i];
                        b += static_cast<int32_t>(qBlue(px)) * taps[i];
                        if (PROCESS_ALPHA)
                            a += static_cast<int32_t>(qAlpha(px)) * taps[i];
                    }
                    dstLine[static_cast<size_t>(x)] = qRgba(clip8(r), clip8(g), clip8(b), PROCESS_ALPHA ? clip8(a) : 255);
                }
            }
        }

        // Vertical pass.
        QImage out(newWidth, newHeight, PROCESS_ALPHA ? QImage::Format_ARGB32 : QImage::Format_RGB32);
        {
            const SResizeWeights wy = makeWeights(in.height(), newHeight);
            for (int y = 0; y < newHeight; y++) {
                auto                        dstLine = std::span<QRgb>(reinterpret_cast<QRgb*>(out.scanLine(y)), static_cast<size_t>(newWidth));
                const std::vector<int32_t>& taps    = wy.weights[static_cast<size_t>(y)];
                const int                   ymin    = wy.mins[static_cast<size_t>(y)];
                for (int x = 0; x < newWidth; x++) {
                    int32_t r = K_ROUNDING_BIAS;
                    int32_t g = K_ROUNDING_BIAS;
                    int32_t b = K_ROUNDING_BIAS;
                    int32_t a = K_ROUNDING_BIAS;
                    for (size_t i = 0; i < taps.size(); i++) {
                        const QRgb px = std::span<const QRgb>(reinterpret_cast<const QRgb*>(mid.constScanLine(ymin + static_cast<int>(i))),
                                                              static_cast<size_t>(newWidth))[static_cast<size_t>(x)];
                        r += static_cast<int32_t>(qRed(px)) * taps[i];
                        g += static_cast<int32_t>(qGreen(px)) * taps[i];
                        b += static_cast<int32_t>(qBlue(px)) * taps[i];
                        if (PROCESS_ALPHA)
                            a += static_cast<int32_t>(qAlpha(px)) * taps[i];
                    }
                    dstLine[static_cast<size_t>(x)] = qRgba(clip8(r), clip8(g), clip8(b), PROCESS_ALPHA ? clip8(a) : 255);
                }
            }
        }

        return out;
    }

} // namespace

Argb quantizeImage(const QString& imagePath, int bitmapSize) {
    QImageReader reader(imagePath);
    reader.setAutoTransform(true);

    if (reader.format() == QByteArrayLiteral("gif") && reader.imageCount() > 1)
        reader.jumpToImage(1);

    QImage image = reader.read();
    if (image.isNull())
        return 0;

    // PIL converts L/P modes to RGB.
    if (image.format() == QImage::Format_Indexed8 || image.format() == QImage::Format_Grayscale8)
        image = image.convertToFormat(QImage::Format_RGB32);

    // Pillow resizes RGBA through premultiplied RGBa (Image.resize converts
    // RGBA -> RGBa -> RGBA around the resample), so keep the alpha band and
    // follow the same round trip; RGB-only input skips it entirely.
    const bool hasAlpha = image.hasAlphaChannel();

    const auto [newWidth, newHeight] = calculateOptimalSize(image.width(), image.height(), bitmapSize);
    if (newWidth < image.width() || newHeight < image.height()) {
        if (hasAlpha) {
            // RGBA -> RGBa: MULDIV255(color, alpha).
            for (int y = 0; y < image.height(); y++) {
                auto line = std::span<QRgb>(reinterpret_cast<QRgb*>(image.scanLine(y)), static_cast<size_t>(image.width()));
                for (const int x : std::views::iota(0, image.width())) {
                    const QRgb px = line[static_cast<size_t>(x)];
                    const int  a  = qAlpha(px);
                    if (a != 255)
                        line[static_cast<size_t>(x)] = qRgba(mulDiv255(qRed(px), a), mulDiv255(qGreen(px), a), mulDiv255(qBlue(px), a), a);
                }
            }
            image = resizeBicubic(image, newWidth, newHeight, true);
            // RGBa -> RGBA: CLIP8(255 * color / alpha).
            for (int y = 0; y < newHeight; y++) {
                auto line = std::span<QRgb>(reinterpret_cast<QRgb*>(image.scanLine(y)), static_cast<size_t>(newWidth));
                for (const int x : std::views::iota(0, newWidth)) {
                    const QRgb px = line[static_cast<size_t>(x)];
                    const int  a  = qAlpha(px);
                    if (a != 255 && a != 0) {
                        const auto un                = [a](const int C) { return static_cast<int>(std::clamp((255 * C) / a, 0, 255)); };
                        line[static_cast<size_t>(x)] = qRgba(un(qRed(px)), un(qGreen(px)), un(qBlue(px)), a);
                    }
                }
            }
        } else {
            image = resizeBicubic(image, newWidth, newHeight, false);
        }
    }

    std::vector<Argb> pixels;
    pixels.reserve(static_cast<size_t>(image.width()) * static_cast<size_t>(image.height()));
    for (int y = 0; y < image.height(); y++) {
        const auto line = std::span<const QRgb>(reinterpret_cast<const QRgb*>(image.constScanLine(y)), static_cast<size_t>(image.width()));
        for (const int x : std::views::iota(0, image.width()))
            pixels.push_back(0xFF000000u | static_cast<Argb>(line[static_cast<size_t>(x)] & 0xFFFFFF));
    }

    const QuantizerResult quantized = QuantizeCelebi(pixels, 128);
    if (quantized.color_to_count.empty())
        return 0;

    const std::vector<Argb> ranked = RankedSuggestions(quantized.color_to_count);
    if (ranked.empty())
        return 0;

    return ranked[0];
}
