#pragma once
#include <qobject.h>
#include <qcolor.h>
#include <qvariantmap.h>
#include <qqmlintegration.h>

class ColorUtils : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_ELEMENT
  public:
    explicit ColorUtils(QObject* parent = nullptr);

    // Perceptually blend two colors in OKLab. t=0 → src, t=1 → dst
    Q_INVOKABLE static QColor blendColors(const QColor& src, const QColor& dst, qreal t);

    Q_INVOKABLE static QColor fromString(const QString& value);

    // Blend two palette maps in one shot
    Q_INVOKABLE static QVariantMap blendPalettes(const QVariantMap& from, const QVariantMap& to, qreal t);

    Q_INVOKABLE static QVariantMap rgbToHct(const QColor& color);
    Q_INVOKABLE static QColor      hctToRgb(qreal hue, qreal chroma, qreal tone);
    Q_INVOKABLE static QColor      createTonalColor(const QColor& base, qreal tone);
    Q_INVOKABLE static QColor      createAnalogousColor(const QColor& base, qreal hueShift);

  private:
    struct OKLab {
        qreal l, a, b;
    };
    struct Hct {
        qreal h, c, t;
    };
    static OKLab  srgbToOklab(qreal r, qreal g, qreal b);
    static QColor oklabToSrgb(const OKLab& lab, qreal alpha);
    static QColor variantToColor(const QVariant& v);
    static Hct    rgbToHctInternal(const QColor& color);
    static QColor hctToRgbInternal(qreal hue, qreal chroma, qreal tone);
    static QColor hctToRgbWithGamutMapping(qreal hue, qreal chroma, qreal tone);
};
