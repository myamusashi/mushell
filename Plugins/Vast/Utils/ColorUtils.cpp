#include "ColorUtils.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <qcontainerfwd.h>
#include <qstring.h>

namespace {
    inline qreal clamp01(qreal x) {
        return qBound(0.0, x, 1.0);
    }
    inline qreal toLinear(qreal c) {
        return c > 0.04045 ? std::pow((c + 0.055) / 1.055, 2.4) : c / 12.92;
    }
    inline qreal fromLinear(qreal c) {
        return c > 0.0031308 ? 1.055 * std::pow(c, 1.0 / 2.4) - 0.055 : 12.92 * c;
    }
}

ColorUtils::ColorUtils(QObject* parent) : QObject(parent) {}

ColorUtils::OKLab ColorUtils::srgbToOklab(qreal r, qreal g, qreal b) {
    r = toLinear(r);
    g = toLinear(g);
    b = toLinear(b);

    auto l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
    auto m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
    auto s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

    l = std::cbrt(l);
    m = std::cbrt(m);
    s = std::cbrt(s);

    return {.l = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
            .a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
            .b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s};
}

QColor ColorUtils::oklabToSrgb(const OKLab& lab, qreal alpha) {
    auto lValue = lab.l + 0.3963377774 * lab.a + 0.2158037573 * lab.b;
    auto mValue = lab.l - 0.1055613458 * lab.a - 0.0638541728 * lab.b;
    auto sValue = lab.l - 0.0894841775 * lab.a - 1.2914855480 * lab.b;

    auto l = lValue * lValue * lValue;
    auto m = mValue * mValue * mValue;
    auto s = sValue * sValue * sValue;

    auto r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    auto g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    auto b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

    // clang-format off
    return QColor::fromRgbF(
        static_cast<float>(clamp01(fromLinear(r))), 
        static_cast<float>(clamp01(fromLinear(g))), 
        static_cast<float>(clamp01(fromLinear(b))),
        static_cast<float>(clamp01(alpha))
    );
    // clang-format on
}

QColor ColorUtils::blendColors(const QColor& src, const QColor& dst, qreal t) {
    t = clamp01(t);
    if (t <= 0.0)
        return src;
    if (t >= 1.0)
        return dst;

    auto s = srgbToOklab(static_cast<qreal>(src.redF()), static_cast<qreal>(src.greenF()), static_cast<qreal>(src.blueF()));
    auto d = srgbToOklab(static_cast<qreal>(dst.redF()), static_cast<qreal>(dst.greenF()), static_cast<qreal>(dst.blueF()));

    // clang-format off
    return oklabToSrgb({
        .l = s.l + (d.l - s.l) * t, 
        .a = s.a + (d.a - s.a) * t, 
        .b = s.b + (d.b - s.b) * t}, 
        static_cast<qreal>(src.alphaF()) + (static_cast<qreal>(dst.alphaF() - src.alphaF())) * t);
    // clang-format on
}

QColor ColorUtils::fromString(const QString& value) {
    if (value.startsWith('#')) {
        QString h = value.mid(1);
        if (h.length() == 6 || h.length() == 8)
            return QColor::fromString(value);
    }
    return QColor(value);
}

QColor ColorUtils::variantToColor(const QVariant& v) {
    if (v.typeId() == QMetaType::QColor)
        return v.value<QColor>();
    if (v.typeId() == QMetaType::QString)
        return fromString(v.toString());
    return QColor();
}

QVariantMap ColorUtils::blendPalettes(const QVariantMap& from, const QVariantMap& to, qreal t) {
    QVariantMap out;

    for (auto it = to.cbegin(); it != to.cend(); ++it) {
        QColor dst = variantToColor(it.value());
        QColor src = from.contains(it.key()) ? variantToColor(from.value(it.key())) : dst;
        out.insert(it.key(), blendColors(src, dst, t));
    }
    return out;
}

QVariantMap ColorUtils::rgbToHct(const QColor& color) {
    const auto  hct = rgbToHctInternal(color);
    QVariantMap out;
    out.insert(QStringLiteral("h"), hct.h);
    out.insert(QStringLiteral("c"), hct.c);
    out.insert(QStringLiteral("t"), hct.t);
    return out;
}

QColor ColorUtils::hctToRgb(qreal hue, qreal chroma, qreal tone) {
    return hctToRgbInternal(hue, chroma, tone);
}

QColor ColorUtils::hctToRgbWithGamutMapping(qreal hue, qreal chroma, qreal tone) {
    constexpr int maxAttempts   = 20;
    const auto    step          = chroma / static_cast<qreal>(maxAttempts);
    auto          currentChroma = chroma;

    for (int i = 0; i < maxAttempts; ++i) {
        const QColor c = hctToRgbInternal(hue, currentChroma, tone);
        if (c.redF() >= -0.001F && c.redF() <= 1.001F && c.greenF() >= -0.001F && c.greenF() <= 1.001F && c.blueF() >= -0.001F && c.blueF() <= 1.001F)
            return c;
        currentChroma -= step;
        if (currentChroma < 0) {
            currentChroma = 0;
            break;
        }
    }
    return hctToRgbInternal(hue, currentChroma, tone);
}

QColor ColorUtils::createTonalColor(const QColor& base, qreal tone) {
    const auto hct      = rgbToHctInternal(base);
    auto       adjusted = hct.c;

    if (tone < 10)
        adjusted = hct.c * 0.4;
    else if (tone > 95)
        adjusted = hct.c * 0.3;
    else if (tone < 20)
        adjusted = hct.c * 0.7;
    else if (tone > 90)
        adjusted = hct.c * 0.8;

    adjusted = std::min(adjusted, 115.0);
    return hctToRgbWithGamutMapping(hct.h, adjusted, tone);
}

QColor ColorUtils::createAnalogousColor(const QColor& base, qreal hueShift) {
    const auto hct    = rgbToHctInternal(base);
    auto       newHue = std::fmod(hct.h + hueShift, 360.0);
    if (newHue < 0)
        newHue += 360.0;
    return hctToRgbInternal(newHue, hct.c, hct.t);
}

ColorUtils::Hct ColorUtils::rgbToHctInternal(const QColor& color) {
    auto r = static_cast<qreal>(color.redF());
    auto g = static_cast<qreal>(color.greenF());
    auto b = static_cast<qreal>(color.blueF());

    r = toLinear(r);
    g = toLinear(g);
    b = toLinear(b);

    auto x = r * 0.4124564 + g * 0.3575761 + b * 0.1804375;
    auto y = r * 0.2126729 + g * 0.7151522 + b * 0.0721750;
    auto z = r * 0.0193339 + g * 0.1191920 + b * 0.9503041;

    x /= 0.95047;
    z /= 1.08883;

    auto       toLabF = [](qreal v) -> qreal { return v > 0.008856 ? std::pow(v, 1.0 / 3.0) : (7.787 * v) + (16.0 / 116.0); };

    const auto fx = toLabF(x);
    const auto fy = toLabF(y);
    const auto fz = toLabF(z);

    const auto l    = (116.0 * fy) - 16.0;
    const auto a    = 500.0 * (fx - fy);
    const auto bLab = 200.0 * (fy - fz);

    const auto chroma = std::sqrt(a * a + bLab * bLab);
    auto       hue    = std::atan2(bLab, a) * 180.0 / std::numbers::pi;
    if (hue < 0)
        hue += 360.0;

    return {.h = hue, .c = chroma, .t = l};
}

QColor ColorUtils::hctToRgbInternal(qreal hue, qreal chroma, qreal tone) {
    constexpr auto pi     = std::numbers::pi;
    const auto     hueRad = hue * pi / 180.0;
    const auto     a      = chroma * std::cos(hueRad);
    const auto     bLab   = chroma * std::sin(hueRad);
    const auto     l      = tone;

    const auto     fy = (l + 16.0) / 116.0;
    const auto     fx = a / 500.0 + fy;
    const auto     fz = fy - bLab / 200.0;

    auto           fromLabF = [](qreal f) -> qreal { return f > 0.206897 ? std::pow(f, 3) : (f - 16.0 / 116.0) / 7.787; };

    auto           x = fromLabF(fx);
    auto           y = fromLabF(fy);
    auto           z = fromLabF(fz);

    x *= 0.95047;
    z *= 1.08883;

    auto r = x * 3.2404542 + y * -1.5371385 + z * -0.4985314;
    auto g = x * -0.9692660 + y * 1.8760108 + z * 0.0415560;
    auto b = x * 0.0556434 + y * -0.2040259 + z * 1.0572252;

    r = fromLinear(r);
    g = fromLinear(g);
    b = fromLinear(b);

    // clang-format off
    return QColor::fromRgbF(
        static_cast<float>(clamp01(r)),
        static_cast<float>(clamp01(g)),
        static_cast<float>(clamp01(b)),
        1.0F);
    // clang-format on
}
